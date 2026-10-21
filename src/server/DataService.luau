local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Profile = require(Shared.Profile)
local DataService = {}
DataService.__index = DataService
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end
function DataService.new()
    local self = setmetatable({}, DataService)
    self.Token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
    self.Profiles = {}
    self.Busy = {}
    self.Closing = {}
    -- Explicit opt-in only. API failures must never silently create disposable profiles.
    self.Ephemeral = RunService:IsStudio() and (Config.StudioPracticeMode or workspace:GetAttribute("ThriftEphemeral") == true)
    if not self.Ephemeral then
        self.Store = DataStoreService:GetDataStore("ThriftFlip_Profiles_v1")
        self.Backup = DataStoreService:GetDataStore("ThriftFlip_Backups_v1")
    end
    return self
end
function DataService:retry(callback)
    local lastError
    for attempt = 1, 4 do
        local ok, result = pcall(callback)
        if ok then return true, result end
        lastError = result
        task.wait(math.min(8, 2 ^ (attempt - 1)))
    end
    warn("Thrift data operation failed: " .. tostring(lastError))
    return false, nil
end
function DataService:load(userId)
    if self.Ephemeral then
        self.Profiles[userId] = Profile.new()
        return self.Profiles[userId]
    end
    local blocked = false
    local ok, record = self:retry(function()
        blocked = false
        return self.Store:UpdateAsync("p_" .. userId, function(current)
            current = current or {Data = Profile.new()}
            local lock = current.Lock
            if lock and lock.Token ~= self.Token and lock.Expires > os.time() then
                blocked = true
                return nil
            end
            current.Lock = {Token = self.Token, Expires = os.time() + Config.SessionLease}
            return current
        end)
    end)
    if not ok or blocked or not record then return nil end
    self.Profiles[userId] = Profile.reconcile(record.Data)
    return self.Profiles[userId]
end
function DataService:save(userId, release)
    if not self.Profiles[userId] then return false end
    if self.Busy[userId] then return false end
    self.Busy[userId] = true
    local snapshot = copy(self.Profiles[userId])
    local savedAt = os.time()
    local lostLock = false
    local ok = true
    if not self.Ephemeral then
        ok = self:retry(function()
            lostLock = false
            return self.Store:UpdateAsync("p_" .. userId, function(current)
                if not current or not current.Lock or current.Lock.Token ~= self.Token then
                    lostLock = true
                    return nil
                end
                return {Data = snapshot, SavedAt = savedAt,
                    Lock = if release then nil else {Token = self.Token, Expires = os.time() + Config.SessionLease}}
            end)
        end)
        if ok and not lostLock then
            -- Separate recovery copy. Main UpdateAsync versions also remain available.
            task.spawn(function()
                self:retry(function()
                    self.Backup:UpdateAsync("p_" .. userId, function(old)
                        if old and old.SavedAt >= savedAt then return nil end
                        return {Data = snapshot, SavedAt = savedAt}
                    end)
                end)
            end)
        end
    end
    self.Busy[userId] = nil
    return ok and not lostLock
end
function DataService:release(userId)
    if self.Closing[userId] then
        while self.Closing[userId] do task.wait(0.1) end
        return true
    end
    self.Closing[userId] = true
    while self.Busy[userId] do task.wait(0.1) end
    local ok = self:save(userId, true)
    self.Profiles[userId] = nil
    self.Closing[userId] = nil
    return ok
end
return DataService
