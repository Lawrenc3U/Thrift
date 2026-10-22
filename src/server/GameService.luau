local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Economy = require(Shared.Economy)
local DecorPlacement = require(Shared.DecorPlacement)
local GameService = {}
GameService.__index = GameService
local customers = {
    {Name = "Mabel · Collector", Style = "Antique", Budget = 20000},
    {Name = "Jules · Designer", Style = "Retro", Budget = 10000},
    {Name = "Pip · Pocket money", Style = "Cute", Budget = 180},
    {Name = "Robin · Decorator", Style = "Cozy", Budget = 5000},
    {Name = "Alex · Inventor", Style = "Futuristic", Budget = 6000},
    {Name = "Sam · Bargain hunter", Style = "Retro", Budget = 1000},
    {Name = "Lee · Neighbor", Style = "Cozy", Budget = 600},
    {Name = "Bea · Curator", Style = "Antique", Budget = 40000},
}
local function shallowPublicItem(item)
    if item.Inspected then return table.clone(item) end
    return {Uid = item.Uid, DefId = item.DefId, Inspected = false, Condition = item.Condition}
end
function GameService.new(data, world, event)
    return setmetatable({Data = data, World = world, Event = event,
        Random = Random.new(), Sessions = {}, Offers = {}, Cooldowns = {}, Buckets = {}, TeleportAt = {},
        Auction = nil, NextAuction = os.time() + 45, NextCustomer = {}, Ready = {},
        Closing = false, JoinedAt = {}, Showcase = {Week = Economy.week(os.time()), Entries = {}, Votes = {}}}, GameService)
end
function GameService:profile(player)
    if not self.Ready[player.UserId] or self.Data.Closing[player.UserId]
        or (self.Data.ExchangeLocks and self.Data.ExchangeLocks[player.UserId])
        or (self.Data.MutationLocks and self.Data.MutationLocks[player.UserId]) then return nil end
    return self.Data.Profiles[player.UserId]
end
function GameService:notify(player, message)
    self.Event:FireClient(player, "Notice", message)
end
function GameService:spendable(player, profile)
    local held = if self.Auction and self.Auction.Bidder == player.UserId then self.Auction.Bid else 0
    if self.Exchange then held += self.Exchange:reservedCash(player.UserId) end
    return profile.Cash - held
end
function GameService:find(profile, uid)
    if type(uid) ~= "string" or #uid > 60 then return nil end
    for index, item in ipairs(profile.Inventory) do if item.Uid == uid then return item, index end end
    return nil
end
function GameService:demandStyle()
    return Config.Styles[Economy.daily(os.time()) % #Config.Styles + 1]
end
function GameService:value(profile, item)
    local definition = Catalog.ById[item.DefId]
    local demand = if (item.Style or definition.Style) == self:demandStyle() then 1.2 else 1
    local bonus = if (item.Style or definition.Style) == profile.Theme then 1.1 else 1
    return Economy.value(definition, item, Config.RarityMultipliers, Config.ConditionMultipliers, demand, bonus)
end
function GameService:resetQuests(profile)
    local day, week = Economy.daily(os.time()), Economy.week(os.time())
    if profile.Daily.Day ~= day then
        profile.Daily = {Day = day, Claimed = {}, Found = 0, Restored = 0, Sold = 0}
    end
    if profile.Weekly.Week ~= week then
        profile.Weekly = {Week = week, Restored = 0, Sold = 0, Claimed = false}
    end
end
function GameService:prepareLogin(profile, day)
    day = day or Economy.daily(os.time())
    profile.Login = profile.Login or {Day = -2, Streak = 0, ClaimedDay = -2}
    if profile.Login.Day ~= day then
        profile.Login.Streak = if profile.Login.Day == day - 1 then math.min(7, profile.Login.Streak + 1) else 1
        profile.Login.Day = day
    end
end
function GameService:stat(profile, name, amount)
    self:resetQuests(profile)
    if self.Live then self.Live:recordStat(profile, name, amount) end
    profile.Stats[name] = (profile.Stats[name] or 0) + amount
    profile.Daily[name] = (profile.Daily[name] or 0) + amount
    profile.Weekly[name] = (profile.Weekly[name] or 0) + amount
    if profile.Stats.Sold >= 10 then profile.Titles.Shopkeeper = true end
    if profile.Stats.Restored >= 100 then profile.Titles.Restorer = true end
    if profile.Stats.Earned >= 50000 then profile.Titles.Mogul = true end
end
function GameService:analytics(player, name, value)
    -- Custom events require a published experience. Failure must not break gameplay.
    pcall(function() game:GetService("AnalyticsService"):LogCustomEvent(player, name, value or 1) end)
end
function GameService:snapshot(player)
    local profile = self:profile(player)
    if not profile then return end
    self:resetQuests(profile)
    local inventory = {}
    for _, item in ipairs(profile.Inventory) do
        local view = shallowPublicItem(item)
        if item.Inspected then view.Value = self:value(profile, item) end
        if self.Exchange and self.Exchange:itemReserved(player.UserId, item.Uid) then view.Locked = true end
        table.insert(inventory, view)
    end
    local shops = {}
    for _, other in ipairs(Players:GetPlayers()) do
        local otherProfile = self:profile(other)
        if otherProfile then
            local plot = self.World.Owners[other.UserId]
            table.insert(shops, {UserId = other.UserId, Name = other.DisplayName, Tier = otherProfile.Tier,
                Rating = if otherProfile.RatingCount > 0 then otherProfile.RatingTotal / otherProfile.RatingCount else 0,
                Plot = plot and plot.Index})
        end
    end
    local auction
    if self.Auction then
        auction = {Ends = self.Auction.Ends, Bid = self.Auction.Bid, Bidder = self.Auction.Bidder,
            Item = self.Auction.PublicItem}
    end
    local market, trade
    if self.Exchange then market, trade = self.Exchange:snapshot(player) end
    self.Event:FireClient(player, "State", {
        Cash = profile.Cash, AvailableCash = self:spendable(player, profile), XP = profile.XP,
        Level = Economy.level(profile.XP), Tier = profile.Tier, Tool = profile.Tool,
        Inventory = inventory, Tutorial = profile.Tutorial, Reputation = profile.Reputation,
        DecorLayout = profile.DecorLayout, Decorations = profile.Decorations, PlacedDecor = profile.PlacedDecor, Collection = profile.Collection, Themes = profile.Themes, Theme = profile.Theme,
        Daily = profile.Daily, Weekly = profile.Weekly, Login = profile.Login, Stats = profile.Stats,
        LastDelivery = profile.LastDelivery, Day = Economy.daily(os.time()),
        Settings = profile.Settings, Titles = profile.Titles, Shops = shops,
        Demand = self:demandStyle(), Auction = auction, NextAuction = self.NextAuction,
        Offer = self.Offers[player.UserId], Ephemeral = self.Data.Ephemeral,
        Market = market, Trade = trade, Live = self.Live and self.Live:snapshot(player),
        Showcase = self.Showcase, ServerTime = os.time(),
    })
end
function GameService:broadcast()
    for _, player in ipairs(Players:GetPlayers()) do self:snapshot(player) end
end
function GameService:refresh(player)
    local profile = self:profile(player)
    if profile then self.World:render(player, profile, Catalog, Config); self:snapshot(player) end
end
function GameService:generate(source, level, tutorial)
    local eligible = {}
    for _, definition in ipairs(Catalog.Items) do
        if definition.UnlockLevel <= level then table.insert(eligible, definition) end
    end
    local definition = eligible[self.Random:NextInteger(1, #eligible)]
    local rarity = if tutorial then 2 else Economy.pick(Config.Sources[source].Weights, self.Random:NextNumber())
    -- Free weekend event affects estate finds only; no Robux or odds manipulation.
    if source == "Estate" and (os.date("!*t").wday == 1 or os.date("!*t").wday == 7) then
        rarity = math.min(5, rarity + (if self.Random:NextNumber() < 0.08 then 1 else 0))
    end
    return {Uid = HttpService:GenerateGUID(false), DefId = definition.Id, Rarity = rarity,
        Condition = if tutorial then 2 else self.Random:NextInteger(1, 3),
        Variance = self.Random:NextNumber(0.92, 1.08), Inspected = false, Style = definition.Style}
end
function GameService:studioLegendary(player, query)
    if not RunService:IsStudio() then return false, "Studio-only command" end
    local profile = self:profile(player)
    if not profile then return false, "Profile is not ready" end
    if #profile.Inventory >= Config.InventoryLimit then return false, "Inventory is full" end
    query = string.lower(type(query) == "string" and query or "")
    local choices = {}
    for _, definition in ipairs(Catalog.Items) do
        if query == "" or string.find(string.lower(definition.Name), query, 1, true)
            or string.find(string.lower(definition.Category), query, 1, true)
            or string.find(string.lower(definition.Id), query, 1, true) then
            table.insert(choices, definition)
        end
    end
    if #choices == 0 then return false, "No item matches '" .. query .. "'" end
    local definition = choices[self.Random:NextInteger(1, #choices)]
    local item = {Uid = HttpService:GenerateGUID(false), DefId = definition.Id, Rarity = 5,
        Condition = 5, Variance = 1.08, Inspected = true, Style = definition.Style}
    table.insert(profile.Inventory, item); profile.Collection[definition.Id .. ":5"] = true
    self:refresh(player); self:notify(player, "Studio test item added: Legendary " .. definition.Name)
    return true, definition.Name
end
function GameService:source(player, payload)
    local profile = self:profile(player)
    local source = payload.Source
    if type(source) ~= "string" or not Config.Sources[source] then return end
    local location = if source == "Dumpster" then "Source" else source
    if not self.World:near(player, location) then return self:notify(player, "Walk to the sourcing spot first.") end
    local tuning = Config.Sources[source]
    if Economy.level(profile.XP) < tuning.Level then return self:notify(player, "Unlocks at level " .. tuning.Level .. ".") end
    if #profile.Inventory >= Config.InventoryLimit then return self:notify(player, "Inventory full. Sell an item first.") end
    if self:spendable(player, profile) < tuning.Cost then return self:notify(player, "Not enough available cash.") end
    local cooldowns = self.Cooldowns[player.UserId] or {}; self.Cooldowns[player.UserId] = cooldowns
    local remaining = (cooldowns[source] or 0) - os.clock()
    if remaining > 0 then return self:notify(player, "Come back in " .. math.ceil(remaining) .. "s.") end
    if source == "Delivery" then
        if profile.LastDelivery == Economy.daily(os.time()) then return self:notify(player, "Your next delivery arrives tomorrow (UTC).") end
        profile.LastDelivery = Economy.daily(os.time())
    end
    cooldowns[source] = os.clock() + tuning.Cooldown
    profile.Cash -= tuning.Cost
    table.insert(profile.Inventory, self:generate(source, Economy.level(profile.XP), profile.Tutorial == 0))
    profile.XP += 4; self:stat(profile, "Found", 1)
    if profile.Tutorial == 0 then profile.Tutorial = 1; self:analytics(player, "TutorialFind") end
    self:notify(player, "A mystery find! Open your bag to inspect it."); self:snapshot(player)
end
function GameService:inspect(player, payload)
    local profile = self:profile(player)
    local item = self:find(profile, payload.Uid)
    if item and self.Exchange and self.Exchange:itemReserved(player.UserId, item.Uid) then return self:notify(player, "Remove this item from its listing or trade first.") end
    if not item or item.Inspected then return end
    item.Inspected = true
    local key = item.DefId .. ":" .. item.Rarity
    if not profile.Collection[key] then
        profile.Collection[key] = true; profile.XP += 8
        local count = 0; for _ in pairs(profile.Collection) do count += 1 end
        if count % 10 == 0 then profile.Cash += 100; self:notify(player, "Collection milestone! +$100") end
    end
    if profile.Tutorial == 1 then profile.Tutorial = 2 end
    self:notify(player, Config.RarityIcons[item.Rarity] .. " " .. Config.Rarities[item.Rarity] .. " " .. Catalog.ById[item.DefId].Name)
    self:snapshot(player)
end
function GameService:beginRestore(player, payload)
    local profile = self:profile(player)
    if not self.World:near(player, "Workbench") then return self:notify(player, "Visit your workbench to restore.") end
    if self.Sessions[player.UserId] then return self:notify(player, "Finish your current restoration first.") end
    local item = self:find(profile, payload.Uid)
    if item and self.Exchange and self.Exchange:itemReserved(player.UserId, item.Uid) then return self:notify(player, "Remove this item from its listing or trade first.") end
    if not item or not item.Inspected or item.Slot or item.Condition >= 5 then return self:notify(player, "Choose an inspected item below Mint; take it off display first.") end
    local kind = payload.Kind or Catalog.ById[item.DefId].Minigame
    if not table.find({"Scrub", "Polish", "Rewire", "Repaint", "Assemble"}, kind) then return end
    local order = {}; for i = 1, 16 do order[i] = i end
    for i = #order, 2, -1 do local j = self.Random:NextInteger(1, i); order[i], order[j] = order[j], order[i] end
    local targets = if kind == "Polish" then {1, 2, 3, 4, 8, 7, 6, 5, 9, 10, 11, 12, 16, 15, 14, 13} else order
    local session = {Token = HttpService:GenerateGUID(false), Uid = item.Uid, Kind = kind,
        Started = os.clock(), Ends = os.clock() + 20, Progress = 0, Mistakes = 0, LastInput = 0,
        Targets = targets, Seen = {}, Palette = 1, RequiredPalette = self.Random:NextInteger(1, 5)}
    self.Sessions[player.UserId] = session
    self.Event:FireClient(player, "Minigame", {Token = session.Token, Kind = kind, Targets = targets,
        RequiredPalette = session.RequiredPalette, Duration = 20, Minimum = 8, Tool = profile.Tool, Item = shallowPublicItem(item), DefId = item.DefId})
end
function GameService:restoreInput(player, payload)
    local session = self.Sessions[player.UserId]
    if not session or session.Token ~= payload.Token or os.clock() > session.Ends then return end
    if not self.World:near(player, "Workbench") then return end
    if os.clock() - session.LastInput < 0.06 then return end
    session.LastInput = os.clock()
    if payload.Palette and session.Kind == "Repaint" and Economy.validAmount(payload.Palette, 1, 5) then
        session.Palette = payload.Palette; return
    end
    local cell = payload.Cell
    if not Economy.validAmount(cell, 1, 16) or session.Progress >= 16 then return end
    local valid = true
    local other
    local gain = 1
    if session.Kind == "Rewire" then
        if session.Seen[cell] then return end
        if not session.WireStart then
            session.WireStart = cell
            self.Event:FireClient(player, "MinigameProgress", {Progress = session.Progress, Mistakes = session.Mistakes, Cell = cell, Selected = true})
            return
        end
        other = session.WireStart
        if cell == other then return end
        session.WireStart = nil
        local a, b = table.find(session.Targets, cell), table.find(session.Targets, other)
        valid = math.ceil(a / 2) == math.ceil(b / 2)
        gain = 2
    elseif session.Kind == "Assemble" then
        valid = not session.Seen[cell] and payload.Piece == table.find(session.Targets, cell)
    elseif session.Kind == "Scrub" then valid = not session.Seen[cell]
    elseif session.Kind == "Repaint" then valid = not session.Seen[cell] and session.Palette == session.RequiredPalette
    else valid = cell == session.Targets[session.Progress + 1] end
    if valid then
        session.Progress += gain; session.Seen[cell] = true
        if other then session.Seen[other] = true end
    else session.Mistakes += 1 end
    self.Event:FireClient(player, "MinigameProgress", {Progress = session.Progress, Mistakes = session.Mistakes, Cell = cell, Other = other, Valid = valid})
end
function GameService:finishRestore(player, payload)
    local session = self.Sessions[player.UserId]
    if not session or session.Token ~= payload.Token then return end
    if os.clock() - session.Started < 8 then return end
    local profile = self:profile(player)
    local item = self:find(profile, session.Uid)
    self.Sessions[player.UserId] = nil
    if not item then return end
    if payload.Cancel or not self.World:near(player, "Workbench") then
        self.Event:FireClient(player, "MinigameDone", {Cancelled = true}); return
    end
    local score = math.clamp(session.Progress / 16 - session.Mistakes * 0.025 + profile.Tool * 0.025, 0, 1)
    item.Condition = Economy.restore(item.Condition, score, profile.Tool)
    if session.Kind == "Repaint" then item.Style = Config.Styles[session.RequiredPalette] end
    profile.XP += 15; self:stat(profile, "Restored", 1)
    if profile.Tutorial == 2 then profile.Tutorial = 3; self:analytics(player, "TutorialRestore") end
    local quality = if score >= 0.8 then "Perfect" elseif score >= 0.45 then "Good" else "Okay"
    self.Event:FireClient(player, "MinigameDone", {Quality = quality, Condition = Config.Conditions[item.Condition]})
    self:snapshot(player)
end
function GameService:display(player, payload)
    local profile = self:profile(player)
    if not self.World:near(player, "Display") then return self:notify(player, "Visit your shop to place items.") end
    local item = self:find(profile, payload.Uid)
    if item and self.Exchange and self.Exchange:itemReserved(player.UserId, item.Uid) then return self:notify(player, "Remove this item from its listing or trade first.") end
    if not item or not item.Inspected then return end
    local session = self.Sessions[player.UserId]
    if session and session.Uid == item.Uid then return self:notify(player, "Finish restoring this item first.") end
    if payload.Remove then
        if self.Offers[player.UserId] and self.Offers[player.UserId].Uid == item.Uid then self.Offers[player.UserId] = nil end
        item.Slot = nil; return self:refresh(player)
    end
    if not Economy.validAmount(payload.Slot, 1, Config.Tiers[profile.Tier].Slots) then return end
    for _, other in ipairs(profile.Inventory) do
        if other.Slot == payload.Slot then return self:notify(player, "That display is occupied.") end
    end
    item.Slot = payload.Slot
    if profile.Tutorial == 3 then profile.Tutorial = 4; self.NextCustomer[player.UserId] = os.time() + 3 end
    self:refresh(player)
end
function GameService:makeOffer(player)
    local profile = self:profile(player)
    if not profile or self.Offers[player.UserId] then return end
    local displayed = {}; for _, item in ipairs(profile.Inventory) do if item.Slot then table.insert(displayed, item) end end
    if #displayed == 0 then return end
    local customer = customers[self.Random:NextInteger(1, #customers)]
    local item = displayed[self.Random:NextInteger(1, #displayed)]
    local value = self:value(profile, item)
    local preferred = item.Style == customer.Style
    local amount = math.floor(value * (if preferred then 1.15 else self.Random:NextNumber(0.85, 1.05)))
    if profile.Tutorial == 4 then customer = {Name = "Mabel · Welcome gift", Budget = 100000}; amount = math.max(150, amount) end
    if amount > customer.Budget then return end
    self.Offers[player.UserId] = {Uid = item.Uid, Amount = amount, Customer = customer.Name,
        Ends = os.time() + 20, Countered = false, Preferred = preferred}
    self.World:customer(player.UserId, customer.Name); self:snapshot(player)
end
function GameService:haggle(player, payload)
    local profile = self:profile(player)
    local offer = self.Offers[player.UserId]
    if not offer or os.time() > offer.Ends then return end
    if not self.World:near(player, "Shop") then return self:notify(player, "Meet your customer in your shop.") end
    local item, index = self:find(profile, offer.Uid)
    if not item or not item.Slot then self.Offers[player.UserId] = nil; return end
    if payload.Choice == "Decline" then self.Offers[player.UserId] = nil
    elseif payload.Choice == "Counter" and not offer.Countered then
        offer.Countered = true
        if self.Random:NextNumber() < 0.65 then
            offer.Amount = math.floor(offer.Amount * 1.12); self:notify(player, "They accepted your counter! Accept to sell.")
        else self.Offers[player.UserId] = nil; self:notify(player, "They passed this time. Another customer will come.") end
    elseif payload.Choice == "Accept" then
        self.Offers[player.UserId] = nil; table.remove(profile.Inventory, index)
        profile.Cash += offer.Amount; profile.XP += 20; profile.Reputation += 1
        self:stat(profile, "Sold", 1); self:stat(profile, "Earned", offer.Amount)
        if profile.Tutorial == 4 then profile.Tutorial = 5; self:analytics(player, "TutorialFirstSale") end
        self:notify(player, "Sold! +$" .. offer.Amount); self:analytics(player, "ItemSold")
    else return end
    self:refresh(player)
end
function GameService:upgrade(player, payload)
    local profile = self:profile(player)
    if not self.World:near(player, "Shop") then return self:notify(player, "Upgrade at your shop counter.") end
    if payload.Kind == "Shop" then
        local nextTier = Config.Tiers[profile.Tier + 1]
        if not nextTier then return self:notify(player, "Your shop is fully upgraded!") end
        if Economy.level(profile.XP) < nextTier.Level then return self:notify(player, "Requires level " .. nextTier.Level .. ".") end
        if self:spendable(player, profile) < nextTier.Cost then return self:notify(player, "Not enough cash.") end
        profile.Cash -= nextTier.Cost; profile.Tier += 1; self:analytics(player, "ShopUpgrade")
    elseif payload.Kind == "Tool" then
        local cost = Config.ToolCosts[profile.Tool + 1]
        if not cost then return self:notify(player, "Tools fully upgraded!") end
        if self:spendable(player, profile) < cost then return self:notify(player, "Not enough cash.") end
        profile.Cash -= cost; profile.Tool += 1
    elseif payload.Kind == "Decor" then
        local decoration
        for _, entry in ipairs(Config.Decorations) do if entry.Id == payload.Decor then decoration = entry end end
        if not decoration then return end
        if not profile.Decorations[decoration.Id] then
            if self:spendable(player, profile) < decoration.Cost then return self:notify(player, "Not enough cash.") end
            profile.Cash -= decoration.Cost; profile.Decorations[decoration.Id] = true
        end
        profile.PlacedDecor[decoration.Id] = not profile.PlacedDecor[decoration.Id]
    elseif payload.Kind == "Theme" then
        local theme
        for _, candidate in ipairs(Config.Themes) do if candidate.Id == payload.Theme then theme = candidate end end
        if not theme then return end
        if not profile.Themes[theme.Id] then
            if self:spendable(player, profile) < theme.Cost then return self:notify(player, "Not enough cash.") end
            profile.Cash -= theme.Cost; profile.Themes[theme.Id] = true
        end
        profile.Theme = theme.Id
    end
    self:refresh(player)
end
function GameService:decorPlace(player, payload)
    local profile = self:profile(player)
    if not self.World:near(player, "Shop") then return self:notify(player, "Arrange decorations inside your shop.") end
    if type(payload.Decor) ~= "string" or not profile.Decorations[payload.Decor] or not profile.PlacedDecor[payload.Decor] then return end
    if payload.Reset then
        profile.DecorLayout[payload.Decor] = nil; self:refresh(player); return
    end
    local ok, result = DecorPlacement.validate(payload.Decor, {X = payload.X, Z = payload.Z, Rotation = payload.Rotation}, profile.DecorLayout, profile.PlacedDecor, Config.Tiers[profile.Tier].Slots)
    if not ok then return self:notify(player, result) end
    profile.DecorLayout[payload.Decor] = result
    self:refresh(player)
end
function GameService:quest(player, payload)
    local profile = self:profile(player); self:resetQuests(profile)
    local daily = {Find = {"Found", 3, 65}, Restore = {"Restored", 3, 100}, Sell = {"Sold", 3, 150}}
    local quest = daily[payload.Id]
    if quest then
        if profile.Daily.Claimed[payload.Id] then return end
        if (profile.Daily[quest[1]] or 0) < quest[2] then return self:notify(player, "Quest not finished yet.") end
        profile.Daily.Claimed[payload.Id] = true; profile.Cash += quest[3]; profile.XP += 20
        self:notify(player, "Daily quest complete! +$" .. quest[3])
    elseif payload.Id == "Weekly" then
        if profile.Weekly.Claimed then return end
        if profile.Weekly.Restored < 20 or profile.Weekly.Sold < 15 then return self:notify(player, "Restore 20 and sell 15 this week.") end
        profile.Weekly.Claimed = true; profile.Cash += 1200; profile.XP += 100
        profile.Titles.WeeklyWonder = true; self:notify(player, "Weekly quest complete! +$1200")
    end
    self:snapshot(player)
end
function GameService:dailyGift(player)
    local profile = self:profile(player)
    local day = Economy.daily(os.time()); self:prepareLogin(profile, day)
    if profile.Login.ClaimedDay == day then return self:notify(player, "Today's welcome gift is already collected.") end
    local rewards = {50, 75, 100, 150, 200, 300, 500}
    local reward = rewards[math.clamp(profile.Login.Streak, 1, #rewards)]
    profile.Login.ClaimedDay = day; profile.Cash += reward; profile.XP += 10
    self:analytics(player, "DailyGiftDay" .. tostring(profile.Login.Streak))
    self:notify(player, "Day " .. profile.Login.Streak .. " welcome gift: +$" .. reward)
    self:refresh(player)
end
function GameService:bid(player, payload)
    local profile = self:profile(player)
    local auction = self.Auction
    if not auction or os.time() >= auction.Ends then return end
    if not self.World:near(player, "Auction") then return self:notify(player, "Visit the auction house to bid.") end
    if #profile.Inventory >= Config.InventoryLimit then return self:notify(player, "Make room in your inventory first.") end
    local minimum = auction.Bid + math.max(10, math.floor(auction.Bid * 0.1))
    if not Economy.validAmount(payload.Amount, minimum, 10000000) or payload.Amount > profile.Cash - (if self.Exchange then self.Exchange:reservedCash(player.UserId) else 0) then return self:notify(player, "Your bid must beat $" .. (minimum - 1) .. " and fit your cash balance.") end
    auction.Bid = payload.Amount; auction.Bidder = player.UserId
    -- Cash is reserved, never removed before a win. Save cannot persist an orphan escrow.
    auction.Ends = math.max(auction.Ends, math.min(auction.Started + 90, os.time() + 8))
    self:broadcast()
end
function GameService:rating(player, payload)
    local profile = self:profile(player)
    if not Economy.validAmount(payload.UserId, 1, 9007199254740991) or payload.UserId == player.UserId then return end
    if not Economy.validAmount(payload.Stars, 1, 5) then return end
    local target = Players:GetPlayerByUserId(payload.UserId)
    local targetProfile = target and self:profile(target)
    local plot = self.World.Owners[payload.UserId]
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not targetProfile or not plot or not root or (root.Position - plot.CF.Position).Magnitude > 30 then return self:notify(player, "Visit that shop before rating it.") end
    local key = tostring(payload.UserId)
    if profile.Rated[key] == Economy.daily(os.time()) then return self:notify(player, "You rated this shop today.") end
    profile.Rated[key] = Economy.daily(os.time()); targetProfile.RatingTotal += payload.Stars; targetProfile.RatingCount += 1
    -- Remove old votes to bound saved data.
    for id, day in pairs(profile.Rated) do if day < Economy.daily(os.time()) - 2 then profile.Rated[id] = nil end end
    self:notify(player, "Thanks for visiting!"); self:refresh(target); self:snapshot(player)
end
function GameService:showcase(player, payload)
    local profile = self:profile(player)
    if payload.Choice == "Enter" then
        local existing = self.Showcase.Entries[tostring(player.UserId)]
        self.Showcase.Entries[tostring(player.UserId)] = {Name = player.DisplayName, Votes = if existing then existing.Votes else 0, Theme = profile.Theme}
        self:notify(player, "Shop entered in this server's weekly showcase.")
    elseif payload.Choice == "Vote" then
        if type(payload.UserId) ~= "number" or payload.UserId == player.UserId then return end
        local key = tostring(player.UserId)
        local entry = self.Showcase.Entries[tostring(payload.UserId)]
        if not entry or self.Showcase.Votes[key] then return end
        self.Showcase.Votes[key] = true; entry.Votes += 1
    end
    self:broadcast()
end
function GameService:settings(player, payload)
    local profile = self:profile(player)
    if (payload.Name == "Music" or payload.Name == "Effects") and type(payload.Enabled) == "boolean" then
        profile.Settings[payload.Name] = payload.Enabled; self:snapshot(player)
    end
end
function GameService:teleport(player, payload)
    if type(payload.Destination) ~= "string" or #payload.Destination > 20 then return end
    local now = os.clock()
    if now - (self.TeleportAt[player.UserId] or 0) < 1.5 then return end
    if self.Sessions[player.UserId] then return self:notify(player, "Finish or cancel your restoration first.") end
    local destination = self.World:teleportCFrame(player, payload.Destination)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not destination or not humanoid or humanoid.Health <= 0 then return self:notify(player, "That destination is not available yet.") end
    self.TeleportAt[player.UserId] = now
    character:PivotTo(destination)
    self:notify(player, "Arrived at " .. payload.Destination .. ".")
end
local handlers = {
    Source = GameService.source, Inspect = GameService.inspect, BeginRestore = GameService.beginRestore,
    RestoreInput = GameService.restoreInput, FinishRestore = GameService.finishRestore,
    Display = GameService.display, Haggle = GameService.haggle, Upgrade = GameService.upgrade,
    Quest = GameService.quest, Bid = GameService.bid, Rate = GameService.rating, DecorPlace = GameService.decorPlace,
    Showcase = GameService.showcase, Settings = GameService.settings, Teleport = GameService.teleport,
    DailyGift = GameService.dailyGift,
}
function GameService:request(player, action, payload)
    if self.Closing or not self:profile(player) then return end
    if type(action) ~= "string" or #action > 32 or type(payload) ~= "table" then return end
    local bucket = self.Buckets[player.UserId] or {Tokens = 35, At = os.clock()}
    self.Buckets[player.UserId] = bucket
    local now = os.clock(); bucket.Tokens = math.min(35, bucket.Tokens + (now - bucket.At) * 18); bucket.At = now
    if bucket.Tokens < 1 then return end
    bucket.Tokens -= 1
    -- Reject oversized/nested input before dispatch; all payloads are scalar.
    local count = 0
    for key, value in pairs(payload) do
        count += 1
        if count > 8 or type(key) ~= "string" or #key > 32 then return end
        if type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then return end
        if type(value) == "string" and #value > 100 then return end
        if type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then return end
    end
    if action == "Sync" then return self:snapshot(player) end
    if action == "CancelRestore" then
        local session = self.Sessions[player.UserId]
        if session then self.Sessions[player.UserId] = nil; self.Event:FireClient(player, "MinigameDone", {Cancelled = true}) end
        return
    end
    if self.Exchange then
        local ok, handled = pcall(self.Exchange.request, self.Exchange, player, action, payload)
        if not ok then warn("Exchange action failed: " .. tostring(handled)); self:notify(player, "That exchange could not finish. Please try again."); return end
        if handled then return end
    end
    if self.Live and self.Live:handle(player, action, payload) then return end
    local handler = handlers[action]
    if handler then
        local ok, err = pcall(handler, self, player, payload)
        if not ok then warn("Action " .. action .. " failed: " .. tostring(err)); self:notify(player, "That action could not finish. Please try again.") end
    end
end
function GameService:join(player)
    local profile = self.Data:load(player.UserId)
    if not profile then player:Kick("Your save is unavailable or still open in another server. Please rejoin shortly; no data was overwritten."); return end
    if self.Exchange and not self.Exchange:recover(player.UserId) then
        self.Data:release(player.UserId)
        if player.Parent then player:Kick("A previous exchange needs recovery. Please rejoin shortly; your save is protected.") end
        return
    end
    if not player.Parent then self.Data:release(player.UserId); return end
    if self.Closing then self.Data:release(player.UserId); player:Kick("Server closing. Please rejoin."); return end
    if not self.World:assign(player) then self.Data:release(player.UserId); player:Kick("This town is full. Please join another server."); return end
    self.Ready[player.UserId] = true; self.JoinedAt[player.UserId] = os.clock(); self:resetQuests(profile); self:prepareLogin(profile)
    self.NextCustomer[player.UserId] = os.time() + 10
    local leaderstats = Instance.new("Folder"); leaderstats.Name = "leaderstats"; leaderstats.Parent = player
    local cash = Instance.new("IntValue"); cash.Name = "Cash"; cash.Value = profile.Cash; cash.Parent = leaderstats
    local level = Instance.new("IntValue"); level.Name = "Level"; level.Value = Economy.level(profile.XP); level.Parent = leaderstats
    self:refresh(player); self:analytics(player, "SessionStart")
    if self.Live then task.spawn(function() self.Live:join(player) end) end
    self:notify(player, if profile.Tutorial < 5 then "Welcome! Find a mystery item in Dumpster Alley." else "Welcome back to Thrift Street!")
end
function GameService:leave(player)
    local joined = self.JoinedAt[player.UserId]
    if joined then self:analytics(player, "SessionSeconds", math.floor(os.clock() - joined)) end
    self.JoinedAt[player.UserId] = nil
    if self.Exchange then self.Exchange:leave(player.UserId) end
    if self.Live then self.Live:leave(player) end
    self.Ready[player.UserId] = nil
    if self.Auction and self.Auction.Bidder == player.UserId then self.Auction.Bidder = nil; self.Auction.Bid = 0 end
    self.Sessions[player.UserId] = nil; self.Offers[player.UserId] = nil
    self.Cooldowns[player.UserId] = nil; self.Buckets[player.UserId] = nil; self.NextCustomer[player.UserId] = nil
    self.World:release(player.UserId)
    self.Data:release(player.UserId)
end
function GameService:tick()
    local now = os.time()
    if self.Exchange then self.Exchange:tick() end
    if self.Live then self.Live:tick() end
    if not self.Live and self.Showcase.Week ~= Economy.week(now) then
        local winner, votes = nil, 0
        for id, entry in pairs(self.Showcase.Entries) do if entry.Votes > votes then winner = tonumber(id); votes = entry.Votes end end
        local winnerProfile = winner and self.Data.Profiles[winner]
        if winnerProfile then winnerProfile.Titles.ShowcaseWinner = true end
        self.Showcase = {Week = Economy.week(now), Entries = {}, Votes = {}}
    end
    if not self.Auction and now >= self.NextAuction then
        local item = self:generate("Estate", 100, false); item.Rarity = math.max(3, item.Rarity); item.Inspected = true
        self.Auction = {Item = item, PublicItem = shallowPublicItem(item), Bid = 0, Bidder = nil,
            Started = now, Ends = now + Config.AuctionDuration}
        self:broadcast()
    elseif self.Auction and now >= self.Auction.Ends then
        local auction = self.Auction
        local winner = auction.Bidder and Players:GetPlayerByUserId(auction.Bidder)
        local profile = winner and self:profile(winner)
        if winner and self.Ready[winner.UserId] and not profile and (self.Data.ExchangeLocks[winner.UserId] or self.Data.MutationLocks[winner.UserId]) then
            auction.Ends = now + 1; return
        end
        if profile and #profile.Inventory < Config.InventoryLimit and profile.Cash >= auction.Bid then
            profile.Cash -= auction.Bid; table.insert(profile.Inventory, auction.Item)
            profile.Collection[auction.Item.DefId .. ":" .. auction.Item.Rarity] = true
            self:notify(winner, "Going, going, yours! Your auction find is in your bag.")
        end
        self.Auction = nil; self.NextAuction = now + Config.AuctionInterval; self:broadcast()
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = self:profile(player)
        if profile then
            local offer = self.Offers[player.UserId]
            if offer and now >= offer.Ends then self.Offers[player.UserId] = nil; self:snapshot(player) end
            if now >= (self.NextCustomer[player.UserId] or 0) then
                self.NextCustomer[player.UserId] = now + math.max(8, Config.CustomerSeconds - math.floor(profile.Reputation / 30))
                self:makeOffer(player)
            end
            local session = self.Sessions[player.UserId]
            if session and os.clock() > session.Ends then self:finishRestore(player, {Token = session.Token}) end
            local stats = player:FindFirstChild("leaderstats")
            if stats then stats.Cash.Value = profile.Cash; stats.Level.Value = Economy.level(profile.XP) end
        end
    end
end
return GameService
