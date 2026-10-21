-- Service doubles only; the production modules below are bundled unchanged apart
-- from module-import resolution. Studio-only geometry/UI are not simulated.
local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for key, child in pairs(value) do out[key] = deepCopy(child) end
    return out
end
local stores, roster, guid, failStore = {}, {}, 0, false
local services = {
    Players = {GetPlayers = function() return roster end, GetPlayerByUserId = function(_, id)
        for _, player in ipairs(roster) do if player.UserId == id then return player end end
        return nil
    end},
    HttpService = {GenerateGUID = function() guid += 1; return "uid-" .. guid end},
    RunService = {IsStudio = function() return false end},
    AnalyticsService = {LogCustomEvent = function() end},
    ReplicatedStorage = {},
    DataStoreService = {GetDataStore = function(_, name)
        if not stores[name] then
            stores[name] = {Records = {}, UpdateAsync = function(self, key, transform)
                if failStore then error("simulated unavailable datastore") end
                local updated = transform(deepCopy(self.Records[key]))
                if updated == nil then return nil end
                self.Records[key] = deepCopy(updated)
                return deepCopy(updated)
            end}
        end
        return stores[name]
    end},
}
local game = {JobId = "test-server", GetService = function(_, name) return assert(services[name], name) end}
local workspace = {GetAttribute = function() return false end}
local task = {wait = function() end, spawn = function(callback) callback() end}
local function warn(...) print("[expected test warning]", ...) end
local Random = {new = function()
    return {NextInteger = function(_, low) return low end, NextNumber = function(_, low, high)
        if low then return (low + high) / 2 end
        return 0.5
    end}
end}
