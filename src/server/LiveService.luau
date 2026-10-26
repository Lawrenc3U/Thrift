-- Live operations are isolated from core economy mutations. All awards are
-- permanent cosmetic set-membership grants, so uncertain saves are safely retryable.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LiveConfig = require(Shared.LiveConfig)
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local LiveService = {}
LiveService.__index = LiveService
local WEEK = 7 * 86400
local MONDAY_OFFSET = 3 * 86400
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for key, child in pairs(value) do result[key] = copy(child) end
    return result
end
local function validId(value)
    return type(value) == "number" and value == value and value > 0 and value < 9007199254740991 and value % 1 == 0
end
local function ensure(profile)
    profile.Live = profile.Live or {Events = {}, ShowcaseClaims = {}}
    profile.Live.Events = profile.Live.Events or {}
    profile.Live.ShowcaseClaims = profile.Live.ShowcaseClaims or {}
    profile.AppliedReceipts = profile.AppliedReceipts or {}
    profile.Themes = profile.Themes or {}; profile.Decorations = profile.Decorations or {}; profile.Titles = profile.Titles or {}
    return profile.Live
end
function LiveService.week(now)
    return math.floor((now + MONDAY_OFFSET) / WEEK)
end
function LiveService.weekEnd(week)
    return (week + 1) * WEEK - MONDAY_OFFSET
end
function LiveService.neighborhood(userId)
    return userId % LiveConfig.Showcase.Neighborhoods + 1
end
function LiveService.theme(week)
    local themes = LiveConfig.Showcase.Themes
    return themes[week % #themes + 1]
end
function LiveService.activeEvents(now)
    local active = {}
    for _, event in ipairs(LiveConfig.Events) do
        if now >= event.Starts and now < event.Ends then table.insert(active, event) end
    end
    return active
end
function LiveService.rank(record)
    local entries = {}
    for _, entry in pairs(record.Entries or {}) do
        if (entry.Votes or 0) >= LiveConfig.Showcase.MinimumVotes then table.insert(entries, copy(entry)) end
    end
    table.sort(entries, function(a, b)
        if a.Votes ~= b.Votes then return a.Votes > b.Votes end
        return a.UserId < b.UserId
    end)
    local winners = {}
    for place = 1, math.min(#entries, LiveConfig.Showcase.WinnerCount) do
        local entry = entries[place]
        table.insert(winners, {UserId = entry.UserId, Name = entry.Name, Votes = entry.Votes, Place = place})
    end
    return winners
end
function LiveService.applyReward(profile, reward)
    ensure(profile)
    if reward.Theme then profile.Themes[reward.Theme] = true end
    if reward.Decoration then profile.Decorations[reward.Decoration] = true end
    if reward.Title then profile.Titles[reward.Title] = true end
end
function LiveService.ownsReward(profile, reward)
    if reward.Theme and not profile.Themes[reward.Theme] then return false end
    if reward.Decoration and not profile.Decorations[reward.Decoration] then return false end
    if reward.Title and not profile.Titles[reward.Title] then return false end
    return reward.Theme ~= nil or reward.Decoration ~= nil or reward.Title ~= nil
end
local function memoryStore()
    local records = {}
    return {
        GetAsync = function(_, key) return copy(records[key]) end,
        UpdateAsync = function(_, key, transform)
            local result = transform(copy(records[key]))
            if result ~= nil then records[key] = copy(result) end
            return copy(result)
        end,
    }
end
function LiveService.new(data, gameService, options)
    options = options or {}
    local self = setmetatable({}, LiveService)
    self.Data = data; self.Game = gameService
    self.Marketplace = options.Marketplace or game:GetService("MarketplaceService")
    self.Players = options.Players or game:GetService("Players")
    self.Now = options.Now or os.time
    self.Store = options.Store or (if data.Ephemeral then memoryStore() else game:GetService("DataStoreService"):GetDataStore("ThriftFlip_Showcase_v1"))
    self.Cache = {}; self.RequestAt = {}; self.Busy = {}; self.Products = {}; self.Passes = {}; self.ProductInfo = {}
    self.Data.MutationLocks = self.Data.MutationLocks or {}
    self.LastTick = 0
    for _, entry in ipairs(LiveConfig.Products) do if validId(entry.Id) then self.Products[entry.Id] = entry end end
    for _, entry in ipairs(LiveConfig.Passes) do if validId(entry.Id) then self.Passes[entry.Id] = entry end end
    -- Keep the original configuration path supported when migrating existing games.
    for id, theme in pairs(Config.CosmeticPasses or {}) do
        if validId(id) and not self.Passes[id] then self.Passes[id] = {Id = id, Name = theme .. " theme", Description = "Permanent cosmetic shop theme", Reward = {Theme = theme}} end
    end
    return self
end
function LiveService:updateWorldShowcase(record, preferredUserId)
    local world = self.Game and self.Game.World
    if not world or not world.setShowcaseItems or not record then return end
    local entries = record.Entries or {}
    local entry = preferredUserId and entries[tostring(preferredUserId)]
    if not entry then
        for _, candidate in pairs(entries) do
            if not entry or (candidate.Votes or 0) > (entry.Votes or 0)
                or ((candidate.Votes or 0) == (entry.Votes or 0) and (candidate.UserId or math.huge) < (entry.UserId or math.huge)) then entry = candidate end
        end
    end
    world:setShowcaseItems(entry and entry.Preview or nil, Catalog, Config, entry and entry.Name or nil)
end
function LiveService:rawProfile(userId)
    if self.Data.Closing[userId] then return nil end
    return self.Data.Profiles[userId]
end
function LiveService:notice(player, message)
    if player and player.Parent then self.Game:notify(player, message) end
end
function LiveService:key(week, neighborhood)
    return "week_" .. week .. "_n_" .. neighborhood
end
function LiveService:retry(callback)
    if self.Data.retry then return self.Data:retry(callback) end
    return pcall(callback)
end
function LiveService:emptyRecord(week, neighborhood)
    return {Week = week, Neighborhood = neighborhood, Entries = {}, Votes = {}, VoterCount = 0, EntryCount = 0, Closed = false}
end
function LiveService:read(week, neighborhood, force)
    local key = self:key(week, neighborhood)
    local cached = self.Cache[key]
    if not force and cached and self.Now() - cached.At < LiveConfig.Showcase.CacheSeconds then return cached.Record end
    local ok, record = self:retry(function() return self.Store:GetAsync(key) end)
    if not ok then return cached and cached.Record or nil end
    record = record or self:emptyRecord(week, neighborhood)
    self.Cache[key] = {At = self.Now(), Record = record}
    return record
end
function LiveService:refresh(player)
    local profile = self:rawProfile(player.UserId)
    if not profile then return end
    local week = LiveService.week(self.Now())
    local neighborhood = LiveService.neighborhood(player.UserId)
    local record = self:read(week, neighborhood, true)
    self:updateWorldShowcase(record)
    if self:rawProfile(player.UserId) == profile and player.Parent then self.Game:snapshot(player) end
end
function LiveService:grant(player, mutate)
    local userId = player.UserId
    local profile = self:rawProfile(userId)
    if not profile or self.Data.Busy[userId] or self.Data.MutationLocks[userId]
        or (self.Data.ExchangeLocks and self.Data.ExchangeLocks[userId]) then return false end
    local token = {}
    self.Data.MutationLocks[userId] = token
    local ok, result = pcall(function()
        ensure(profile)
        mutate(profile)
        return self.Data:save(userId, false)
    end)
    if self.Data.MutationLocks[userId] == token then self.Data.MutationLocks[userId] = nil end
    if not ok then warn("Live cosmetic award failed: " .. tostring(result)); return false end
    return result == true
end
function LiveService:recordStat(profile, name, amount)
    if (name ~= "Found" and name ~= "Restored" and name ~= "Sold") or type(amount) ~= "number" or amount <= 0 then return end
    local live = ensure(profile)
    for _, event in ipairs(LiveService.activeEvents(self.Now())) do
        local progress = live.Events[event.Id] or {Found = 0, Restored = 0, Sold = 0, Claimed = false}
        live.Events[event.Id] = progress
        progress[name] = math.min(100000, (progress[name] or 0) + amount)
    end
end
function LiveService:eventClaim(player, payload)
    if type(payload.Id) ~= "string" or #payload.Id > 50 then return end
    local profile = self:rawProfile(player.UserId)
    if not profile then return end
    local event
    for _, entry in ipairs(LiveService.activeEvents(self.Now())) do if entry.Id == payload.Id then event = entry; break end end
    if not event then return self:notice(player, "That seasonal event is not active.") end
    local progress = ensure(profile).Events[event.Id]
    if not progress then return self:notice(player, "Make a little progress in the event first.") end
    if progress.Claimed then return self:notice(player, "You already collected this event reward.") end
    for stat, goal in pairs(event.Goal) do
        if (progress[stat] or 0) < goal then return self:notice(player, "Complete the event goals to collect this reward.") end
    end
    local saved = self:grant(player, function(current)
        LiveService.applyReward(current, event.Reward)
        current.Live.Events[event.Id].Claimed = true
    end)
    self:notice(player, if saved then "Event complete! " .. event.RewardName else "Your reward is pending a successful save. Please try again shortly.")
    if self:rawProfile(player.UserId) == profile then self.Game:refresh(player) end
end
function LiveService:enter(player)
    local profile = self:rawProfile(player.UserId)
    if not profile then return end
    if profile.Tutorial < 5 then return self:notice(player, "Complete your first sale before entering the showcase.") end
    local now = self.Now(); local week = LiveService.week(now)
    local neighborhood = LiveService.neighborhood(player.UserId)
    local preview = {}
    for _, item in ipairs(profile.Inventory) do
        if item.Slot and item.Inspected then
            table.insert(preview, {DefId = item.DefId, Rarity = item.Rarity, Condition = item.Condition, Style = item.Style})
            if #preview >= 3 then break end
        end
    end
    if #preview == 0 then return self:notice(player, "Place at least one item on display before entering.") end
    local name = string.sub(player.DisplayName, 1, 64)
    local entry = {UserId = player.UserId, Name = name, Theme = profile.Theme, Tier = profile.Tier, Preview = preview, Votes = 0}
    local accepted, reason = false, "The showcase is temporarily unavailable."
    local key = self:key(week, neighborhood)
    local ok, record = self:retry(function()
        accepted = false
        return self.Store:UpdateAsync(key, function(current)
            current = current or self:emptyRecord(week, neighborhood)
            if current.Closed or self.Now() >= LiveService.weekEnd(week) then reason = "This week's showcase has closed."; return nil end
            local userKey = tostring(player.UserId)
            local existing = current.Entries[userKey]
            if not existing and current.EntryCount >= LiveConfig.Showcase.MaxEntries then reason = "Your neighborhood's showcase is full this week."; return nil end
            entry.Votes = if existing then existing.Votes else 0
            current.Entries[userKey] = copy(entry)
            if not existing then current.EntryCount += 1 end
            accepted = true
            return current
        end)
    end)
    if ok and accepted and record then
        self.Cache[key] = {At = now, Record = record}
        self:updateWorldShowcase(record, player.UserId)
        self:notice(player, "Your shop is entered! Your display travels with the entry across servers.")
    else self:notice(player, reason) end
    if self:rawProfile(player.UserId) == profile then self.Game:snapshot(player) end
end
function LiveService:vote(player, payload)
    if not validId(payload.UserId) or payload.UserId == player.UserId then return end
    local profile = self:rawProfile(player.UserId)
    if not profile or profile.Tutorial < 5 then return self:notice(player, "Complete your first sale before voting.") end
    local now = self.Now(); local week = LiveService.week(now)
    local neighborhood = LiveService.neighborhood(player.UserId)
    if LiveService.neighborhood(payload.UserId) ~= neighborhood then return end
    local accepted, reason = false, "The showcase is temporarily unavailable."
    local key = self:key(week, neighborhood)
    local ok, record = self:retry(function()
        accepted = false
        return self.Store:UpdateAsync(key, function(current)
            if not current or current.Closed or self.Now() >= LiveService.weekEnd(week) then reason = "Voting is closed."; return nil end
            local voterKey, targetKey = tostring(player.UserId), tostring(payload.UserId)
            if current.Votes[voterKey] then reason = "You have already voted this week."; return nil end
            if not current.Entries[targetKey] then reason = "That shop is not entered."; return nil end
            if current.VoterCount >= LiveConfig.Showcase.MaxVoters then reason = "This week's voting has reached its limit."; return nil end
            current.Votes[voterKey] = payload.UserId; current.VoterCount += 1
            current.Entries[targetKey].Votes += 1; accepted = true
            return current
        end)
    end)
    if ok and accepted and record then self.Cache[key] = {At = now, Record = record}; self:updateWorldShowcase(record); self:notice(player, "Vote counted. Thank you for supporting another creator!")
    else self:notice(player, reason) end
    if self:rawProfile(player.UserId) == profile then self.Game:snapshot(player) end
end
function LiveService:finalize(week, neighborhood)
    if self.Now() < LiveService.weekEnd(week) then return nil end
    local key = self:key(week, neighborhood)
    local ok, record = self:retry(function()
        return self.Store:UpdateAsync(key, function(current)
            if not current then return nil end
            if not current.Closed then
                current.Closed = true; current.Winners = LiveService.rank(current)
                current.FinalizedAt = self.Now()
                -- Finalized voting receipts are no longer needed to resolve a result.
                current.Votes = {}; current.VoterCount = 0
            end
            return current
        end)
    end)
    if ok and record then self.Cache[key] = {At = self.Now(), Record = record}; return record end
    return nil
end
function LiveService:claimShowcase(player, quiet)
    local profile = self:rawProfile(player.UserId)
    if not profile then return end
    local currentWeek = LiveService.week(self.Now())
    local neighborhood = LiveService.neighborhood(player.UserId)
    local awards = {}
    for offset = 1, LiveConfig.Showcase.HistoryWeeks do
        local week = currentWeek - offset
        local claimKey = tostring(week)
        if not ensure(profile).ShowcaseClaims[claimKey] then
            local record = self:finalize(week, neighborhood)
            if self:rawProfile(player.UserId) ~= profile then return end
            if record then
                for _, winner in ipairs(record.Winners or {}) do
                    if winner.UserId == player.UserId then table.insert(awards, {Week = week, Place = winner.Place}) end
                end
            end
        end
    end
    if #awards == 0 then
        if not quiet then self:notice(player, "No unclaimed showcase prizes from the last four weeks. Keep creating!") end
        return
    end
    local saved = self:grant(player, function(current)
        for _, award in ipairs(awards) do
            LiveService.applyReward(current, LiveConfig.Showcase.Rewards[award.Place])
            current.Live.ShowcaseClaims[tostring(award.Week)] = true
        end
        for week in pairs(current.Live.ShowcaseClaims) do
            if tonumber(week) < currentWeek - LiveConfig.Showcase.HistoryWeeks - 1 then current.Live.ShowcaseClaims[week] = nil end
        end
    end)
    self:notice(player, if saved then "Your showcase prize is here! Check your cosmetic titles and decorations." else "Your showcase award is pending a successful save. Please retry shortly.")
    if self:rawProfile(player.UserId) == profile then self.Game:refresh(player) end
end
function LiveService:purchase(player, payload)
    if self.Data.Ephemeral then return self:notice(player, "Purchases are unavailable in Studio practice mode.") end
    if not validId(payload.Id) then return end
    local entry = if payload.Kind == "Pass" then self.Passes[payload.Id] elseif payload.Kind == "Product" then self.Products[payload.Id] else nil
    if not entry then return end
    local profile = self:rawProfile(player.UserId)
    if not profile then return end
    ensure(profile)
    if LiveService.ownsReward(profile, entry.Reward) then return self:notice(player, "You already own this cosmetic.") end
    local ok = pcall(function()
        if payload.Kind == "Pass" then self.Marketplace:PromptGamePassPurchase(player, payload.Id)
        else self.Marketplace:PromptProductPurchase(player, payload.Id) end
    end)
    if not ok then self:notice(player, "The Roblox purchase prompt is unavailable. Please try later.") end
end
function LiveService:reconcilePasses(player)
    if self.Data.Ephemeral then return end
    local profile = self:rawProfile(player.UserId)
    if not profile then return end
    local awards = {}
    for passId, entry in pairs(self.Passes) do
        local ok, owns = pcall(function() return self.Marketplace:UserOwnsGamePassAsync(player.UserId, passId) end)
        if self:rawProfile(player.UserId) ~= profile then return end
        if ok and owns and not LiveService.ownsReward(profile, entry.Reward) then table.insert(awards, entry.Reward) end
    end
    if #awards > 0 then
        local saved = self:grant(player, function(current)
            for _, reward in ipairs(awards) do LiveService.applyReward(current, reward) end
        end)
        if saved and self:rawProfile(player.UserId) == profile then self.Game:refresh(player) end
    end
end
function LiveService:passPurchased(player, passId, purchased)
    if purchased and self.Passes[passId] then self:reconcilePasses(player) end
end
function LiveService:processReceipt(receipt)
    local retryDecision = Enum.ProductPurchaseDecision.NotProcessedYet
    local grantedDecision = Enum.ProductPurchaseDecision.PurchaseGranted
    if self.Data.Ephemeral or type(receipt) ~= "table" then return retryDecision end
    local entry = self.Products[receipt.ProductId]
    if not entry or type(receipt.PurchaseId) ~= "string" or #receipt.PurchaseId > 200 then return retryDecision end
    local player = self.Players:GetPlayerByUserId(receipt.PlayerId)
    local profile = player and self:rawProfile(player.UserId)
    if not profile then return retryDecision end
    local purchaseId = receipt.PurchaseId
    local saved = self:grant(player, function(current)
        if not current.AppliedReceipts[purchaseId] then
            LiveService.applyReward(current, entry.Reward)
            current.AppliedReceipts[purchaseId] = self.Now()
            -- Every grant is permanent set-membership. Even a much older receipt
            -- safely replays after bounded history retention; no currency is issued.
            local history = {}
            for id, at in pairs(current.AppliedReceipts) do table.insert(history, {Id = id, At = if type(at) == "number" then at else 0}) end
            if #history > LiveConfig.ReceiptHistoryLimit then
                table.sort(history, function(a, b) return a.At < b.At end)
                for i = 1, #history - LiveConfig.ReceiptHistoryLimit do current.AppliedReceipts[history[i].Id] = nil end
            end
        end
    end)
    if not saved then return retryDecision end
    if self:rawProfile(player.UserId) == profile then self.Game:refresh(player); self:notice(player, "Your cosmetic is ready. Thank you for supporting Thrift Flip!") end
    return grantedDecision
end
function LiveService:loadProductInfo()
    for kind, entries in pairs({Pass = self.Passes, Product = self.Products}) do
        for id in pairs(entries) do
            local ok, info = pcall(function()
                return self.Marketplace:GetProductInfo(id, if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
            end)
            if ok and type(info) == "table" then self.ProductInfo[kind .. ":" .. id] = {Price = info.PriceInRobux, ForSale = info.IsForSale} end
        end
    end
end
function LiveService:snapshot(player)
    local profile = self:rawProfile(player.UserId)
    if not profile then return nil end
    local now = self.Now(); local week = LiveService.week(now)
    local neighborhood = LiveService.neighborhood(player.UserId)
    local key = self:key(week, neighborhood)
    local cached = self.Cache[key]
    local record = if cached then cached.Record else self:emptyRecord(week, neighborhood)
    local entries = {}
    for _, entry in pairs(record.Entries) do table.insert(entries, copy(entry)) end
    table.sort(entries, function(a, b)
        if a.Votes ~= b.Votes then return a.Votes > b.Votes end
        return a.UserId < b.UserId
    end)
    local previous = self.Cache[self:key(week - 1, neighborhood)]
    local live = ensure(profile)
    local events = {}
    for _, event in ipairs(LiveService.activeEvents(now)) do
        local progress = live.Events[event.Id] or {}
        table.insert(events, {Id = event.Id, Name = event.Name, Description = event.Description,
            Ends = event.Ends, Goal = copy(event.Goal), Progress = copy(progress), RewardName = event.RewardName,
            Claimed = progress.Claimed == true, Accent = event.Accent})
    end
    local shop = {}
    for kind, definitions in pairs({Pass = self.Passes, Product = self.Products}) do
        for id, definition in pairs(definitions) do
            local info = self.ProductInfo[kind .. ":" .. id]
            if not info or info.ForSale ~= false then
                table.insert(shop, {Kind = kind, Id = id, Name = definition.Name, Description = definition.Description,
                    Owned = LiveService.ownsReward(profile, definition.Reward), Price = info and info.Price})
            end
        end
    end
    table.sort(shop, function(a, b) if a.Kind ~= b.Kind then return a.Kind < b.Kind end; return a.Id < b.Id end)
    return {
        Showcase = {Week = week, Neighborhood = neighborhood, Theme = LiveService.theme(week), Ends = LiveService.weekEnd(week),
            Entries = entries, VotedFor = record.Votes[tostring(player.UserId)], Entered = record.Entries[tostring(player.UserId)] ~= nil,
            Status = if cached then "Ready" else "Loading", Mode = if self.Data.Ephemeral then "Practice" else "Persistent",
            LastWinners = previous and previous.Record.Winners or {}, MaxEntries = LiveConfig.Showcase.MaxEntries},
        Events = events, Shop = shop,
    }
end
function LiveService:handle(player, action, payload)
    if action ~= "Showcase" and action ~= "EventClaim" and action ~= "ShopPurchase" and action ~= "LiveRefresh" then return false end
    local now = self.Now()
    if self.Busy[player.UserId] or now < (self.RequestAt[player.UserId] or 0) then return true end
    self.Busy[player.UserId] = true; self.RequestAt[player.UserId] = now + 1
    local ok, problem = pcall(function()
        if action == "Showcase" then
            if payload.Choice == "Enter" then self:enter(player)
            elseif payload.Choice == "Vote" then self:vote(player, payload)
            elseif payload.Choice == "Claim" then self:claimShowcase(player, false)
            elseif payload.Choice == "Refresh" then self:refresh(player) end
        elseif action == "EventClaim" then self:eventClaim(player, payload)
        elseif action == "ShopPurchase" then self:purchase(player, payload)
        else self:refresh(player) end
    end)
    self.Busy[player.UserId] = nil
    if not ok then warn("Live operation failed: " .. tostring(problem)); self:notice(player, "This service is temporarily unavailable. Your items are safe.") end
    return true
end
function LiveService:join(player)
    local profile = self:rawProfile(player.UserId)
    if not profile then return end
    ensure(profile)
    self:refresh(player)
    if self:rawProfile(player.UserId) ~= profile then return end
    self:reconcilePasses(player)
    if self:rawProfile(player.UserId) ~= profile then return end
    self:claimShowcase(player, true)
end
function LiveService:leave(player)
    self.Busy[player.UserId] = nil; self.RequestAt[player.UserId] = nil
end
function LiveService:tick()
    local now = self.Now()
    if now - self.LastTick < LiveConfig.Showcase.CacheSeconds then return end
    self.LastTick = now
    local groups = {}
    for _, player in ipairs(self.Players:GetPlayers()) do
        if self:rawProfile(player.UserId) then
            local group = LiveService.neighborhood(player.UserId)
            groups[group] = groups[group] or {}; table.insert(groups[group], player)
        end
    end
    for group, players in pairs(groups) do
        task.spawn(function()
            local week = LiveService.week(self.Now())
            self:read(week, group, true)
            for _, player in ipairs(players) do
                if self:rawProfile(player.UserId) and player.Parent then self.Game:snapshot(player) end
            end
        end)
    end
    local week = LiveService.week(now)
    for key, cached in pairs(self.Cache) do
        if cached.Record.Week < week - LiveConfig.Showcase.HistoryWeeks then self.Cache[key] = nil end
    end
end
return LiveService
