-- Same-server player listings and confirmed trades. A durable two-phase journal
-- makes both profiles recoverable if the process stops between participant saves.
-- No offline/global marketplace: a seller must be in this town to list or sell.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local ExchangeRules = require(Shared.ExchangeRules)
local ExchangeService = {}
ExchangeService.__index = ExchangeService
local copy = ExchangeRules.copy
local MIN_LEVEL = 3
local MAX_LISTINGS = 6
local MAX_TRADE_ITEMS = 4
local PRICE_CAP = 1000000
local CASH_CAP = 1000000
local FEE_RATE = 0.03
local TRADE_REVIEW = 3
local TRADE_COOLDOWN = 15
local function memoryStore()
    local records = {}
    return {UpdateAsync = function(_, key, transform)
        local result = transform(copy(records[key]))
        if result ~= nil then records[key] = copy(result) end
        return copy(result)
    end}
end
function ExchangeService.new(data, service, options)
    options = options or {}
    data.ExchangeLocks = data.ExchangeLocks or {}
    data.MutationLocks = data.MutationLocks or {}
    return setmetatable({Data = data, Service = service,
        Store = options.Store or (if data.Ephemeral then memoryStore() else DataStoreService:GetDataStore("ThriftFlip_ExchangeJournal_v1")),
        Clock = options.Clock or os.time,
        Guid = options.Guid or function() return HttpService:GenerateGUID(false) end,
        Listings = {}, Trades = {}, PlayerTrades = {}, Cooldowns = {},
        Capacity = Config.InventoryLimit, LastTick = 0}, ExchangeService)
end
function ExchangeService:_notice(player, message)
    if player and player.Parent then self.Service:notify(player, message) end
end
function ExchangeService:_broadcast()
    self.Service:broadcast()
end
function ExchangeService:_journal(id, transform)
    return self.Data:retry(function()
        return self.Store:UpdateAsync("x_" .. id, transform)
    end)
end
function ExchangeService:_save(userId)
    local deadline = os.clock() + 20
    while self.Data.Busy[userId] and os.clock() < deadline do task.wait(0.05) end
    if self.Data.Busy[userId] then return false end
    return self.Data:save(userId, false)
end
function ExchangeService:_fault(userIds, id)
    -- Disallow gameplay before yielding locks to PlayerRemoving. Persisting the
    -- pending marker/receipt again during release is safe even after a timeout.
    for _, userId in ipairs(userIds) do
        self.Service.Ready[userId] = nil
        if self.Data.ExchangeLocks[userId] == id then self.Data.ExchangeLocks[userId] = nil end
    end
    for _, userId in ipairs(userIds) do
        local player = Players:GetPlayerByUserId(userId)
        if player then player:Kick("Your exchange is safely queued for recovery. Please rejoin shortly; do not repeat the purchase.") end
    end
end
function ExchangeService:_finishSide(userId, transaction)
    local profile = self.Data.Profiles[userId]
    local side = ExchangeRules.side(transaction, userId)
    if not profile or not side then return false end
    local marker = ExchangeRules.ensure(profile)
    if transaction.Status == "ABORTED" then
        if marker.Pending == transaction.Id then marker.Pending = nil end
        return self:_save(userId)
    end
    if transaction.Status ~= "COMMITTED" and transaction.Status ~= "COMPLETE" then return false end
    if not transaction.Acks[tostring(userId)] then
        local applied = ExchangeRules.apply(profile, transaction, side, self.Capacity)
        if not applied or not self:_save(userId) then return false end
        local ok, updated = self:_journal(transaction.Id, function(record)
            if not record or (record.Status ~= "COMMITTED" and record.Status ~= "COMPLETE") then return nil end
            record.Acks[tostring(userId)] = true
            if ExchangeRules.allAcknowledged(record) then record.Status = "COMPLETE"; record.CompletedAt = self.Clock() end
            return record
        end)
        if not ok or not updated or not updated.Acks[tostring(userId)] then return false end
    end
    -- Receipt remains as LastApplied until a later exchange. The durable journal
    -- acknowledgement means an old callback can never apply this side again.
    marker.Pending = nil
    return self:_save(userId)
end
function ExchangeService:recover(userId)
    local profile = self.Data.Profiles[userId]
    if not profile then return false end
    local marker = ExchangeRules.ensure(profile)
    local id = marker.Pending
    if not id then return true end
    if self.Data.MutationLocks[userId] or self.Data.ExchangeLocks[userId] then return false end
    self.Data.ExchangeLocks[userId] = id
    -- Called only after DataService acquired this profile's session lock and
    -- before the player is Ready. An old process can no longer save this side.
    local ok, transaction = self:_journal(id, function(record)
        if not record or not ExchangeRules.side(record, userId) then return nil end
        if record.Status == "PREPARING" then record.Status = "ABORTED"; record.AbortedAt = self.Clock() end
        return record
    end)
    local completed = ok and transaction and self:_finishSide(userId, transaction)
    self.Data.ExchangeLocks[userId] = nil
    return completed == true
end
function ExchangeService:_transaction(kind, sides)
    local id = self.Guid()
    local users = {}
    -- Acquiring these in-memory locks contains no yields; actions, autosaves and
    -- commerce all honor the same profile ownership/locking contracts.
    for _, side in ipairs(sides) do
        local profile = self.Data.Profiles[side.UserId]
        if not profile or self.Data.Closing[side.UserId] or self.Data.MutationLocks[side.UserId]
            or self.Data.ExchangeLocks[side.UserId] or ExchangeRules.ensure(profile).Pending then return false end
        table.insert(users, side.UserId)
    end
    for _, userId in ipairs(users) do self.Data.ExchangeLocks[userId] = id end
    local proposal = {Id = id, Kind = kind, Status = "PREPARING", CreatedAt = self.Clock(), Owner = self.Data.Token,
        Sides = copy(sides), Prepared = {}, Acks = {}}
    local created, transaction = self:_journal(id, function(old) return old or proposal end)
    if not created or not transaction or transaction.Owner ~= self.Data.Token then
        for _, userId in ipairs(users) do self.Data.ExchangeLocks[userId] = nil end
        return false
    end
    local prepared = true
    for _, userId in ipairs(users) do
        local profile = self.Data.Profiles[userId]
        if not profile or self.Data.Closing[userId] or self.Data.MutationLocks[userId] then prepared = false; break end
        ExchangeRules.ensure(profile).Pending = id
        if not self:_save(userId) then prepared = false; break end
        local ok, record = self:_journal(id, function(current)
            if not current or current.Status ~= "PREPARING" or current.Owner ~= self.Data.Token then return nil end
            current.Prepared[tostring(userId)] = true
            return current
        end)
        if not ok or not record then prepared = false; break end
    end
    local committed, decided = self:_journal(id, function(current)
        if not current then return nil end
        if current.Status ~= "PREPARING" then return current end
        if current.Owner ~= self.Data.Token then return nil end
        local allPrepared = prepared
        for _, side in ipairs(current.Sides) do if not current.Prepared[tostring(side.UserId)] then allPrepared = false end end
        current.Status = if allPrepared then "COMMITTED" else "ABORTED"
        if allPrepared then current.CommittedAt = self.Clock() else current.AbortedAt = self.Clock() end
        return current
    end)
    if not committed or not decided then self:_fault(users, id); return false end
    for _, userId in ipairs(users) do
        if not self:_finishSide(userId, decided) then self:_fault(users, id); return false end
    end
    for _, userId in ipairs(users) do self.Data.ExchangeLocks[userId] = nil end
    return decided.Status == "COMMITTED" or decided.Status == "COMPLETE"
end
function ExchangeService:reservedCash(userId)
    local id = self.PlayerTrades[userId]
    local trade = id and self.Trades[id]
    return if trade then trade.Offers[tostring(userId)].Cash else 0
end
function ExchangeService:itemReserved(userId, uid)
    for _, listing in pairs(self.Listings) do if listing.SellerId == userId and listing.Item.Uid == uid then return true end end
    local id = self.PlayerTrades[userId]
    local trade = id and self.Trades[id]
    if trade then
        for _, itemId in ipairs(trade.Offers[tostring(userId)].Items) do if itemId == uid then return true end end
    end
    return false
end
function ExchangeService:_eligible(player)
    local profile = self.Service:profile(player)
    if not profile then return nil end
    if Economy.level(profile.XP) < MIN_LEVEL or profile.Tutorial < 5 then
        self:_notice(player, "Finish your first sale and reach level 3 to use the player market and trading."); return nil
    end
    if not self.Service.World:near(player, "Market") then self:_notice(player, "Meet at Market Square to exchange finds."); return nil end
    return profile
end
function ExchangeService:_availableItem(userId, uid, profile)
    local item = ExchangeRules.find(profile, uid)
    if not item or not item.Inspected or item.Slot or self:itemReserved(userId, uid) then return nil end
    local session = self.Service.Sessions[userId]
    if session and session.Uid == uid then return nil end
    return item
end
function ExchangeService:list(player, payload)
    local profile = self:_eligible(player)
    if not profile or type(payload.Uid) ~= "string" then return end
    local count = 0; for _, listing in pairs(self.Listings) do if listing.SellerId == player.UserId then count += 1 end end
    if count >= MAX_LISTINGS then return self:_notice(player, "You can list up to six finds at a time.") end
    local item = self:_availableItem(player.UserId, payload.Uid, profile)
    if not item then return self:_notice(player, "Choose an inspected item from your bag that is not reserved.") end
    local cap = math.min(PRICE_CAP, math.max(100, self.Service:value(profile, item) * 10))
    if not Economy.validAmount(payload.Price, 1, cap) then return self:_notice(player, "Choose a whole-dollar price between $1 and $" .. cap .. ".") end
    local fee = math.max(1, math.ceil(payload.Price * FEE_RATE))
    if self.Service:spendable(player, profile) < fee then return self:_notice(player, "The listing fee is $" .. fee .. ".") end
    profile.Cash -= fee
    local id = self.Guid()
    self.Listings[id] = {Id = id, SellerId = player.UserId, SellerName = player.DisplayName,
        Item = copy(item), Price = payload.Price, Fee = fee, Expires = self.Clock() + 1800}
    self:_notice(player, "Listed for this town. The 3% listing fee is not refundable."); self:_broadcast()
end
function ExchangeService:cancelListing(player, payload)
    local listing = self.Listings[payload.ListingId]
    if not listing or listing.SellerId ~= player.UserId or listing.Busy then return end
    self.Listings[payload.ListingId] = nil; self:_broadcast()
end
function ExchangeService:buy(player, payload)
    local buyer = self:_eligible(player)
    if not buyer then return end
    local listing = self.Listings[payload.ListingId]
    if not listing or listing.Busy or listing.Expires <= self.Clock() or listing.SellerId == player.UserId then return end
    local sellerPlayer = Players:GetPlayerByUserId(listing.SellerId)
    local seller = sellerPlayer and self.Service:profile(sellerPlayer)
    if not seller then return self:_notice(player, "That seller is no longer available.") end
    local item = ExchangeRules.find(seller, listing.Item.Uid)
    if not item or item.Slot then self.Listings[listing.Id] = nil; return self:_broadcast() end
    if self.Service:spendable(player, buyer) < listing.Price then return self:_notice(player, "Not enough available cash.") end
    if #buyer.Inventory >= self.Capacity then return self:_notice(player, "Make a little room in your bag first.") end
    listing.Busy = true
    local success = self:_transaction("Market", {
        {UserId = player.UserId, CashDelta = -listing.Price, Outgoing = {}, Incoming = {copy(item)}},
        {UserId = sellerPlayer.UserId, CashDelta = listing.Price, Outgoing = {item.Uid}, Incoming = {}},
    })
    if success then
        self.Listings[listing.Id] = nil
        self:_notice(player, "A wonderful find! Your purchase is in your bag.")
        self:_notice(sellerPlayer, "Your market listing sold for $" .. listing.Price .. "!")
    else listing.Busy = nil end
    self:_broadcast()
end
function ExchangeService:_tradeFor(player, id)
    if type(id) ~= "string" or self.PlayerTrades[player.UserId] ~= id then return nil end
    return self.Trades[id]
end
function ExchangeService:_resetConfirmations(trade)
    trade.Revision += 1; trade.ConfirmAfter = self.Clock() + TRADE_REVIEW
    for _, offer in pairs(trade.Offers) do offer.Confirmed = false end
end
function ExchangeService:invite(player, payload)
    local profile = self:_eligible(player)
    if not profile or not Economy.validAmount(payload.UserId, 1, 9007199254740991) or payload.UserId == player.UserId then return end
    if self.PlayerTrades[player.UserId] or self.PlayerTrades[payload.UserId] then return self:_notice(player, "One of you is already considering a trade.") end
    if self.Clock() < (self.Cooldowns[player.UserId] or 0) then return self:_notice(player, "Give your last trade a moment before starting another.") end
    local other = Players:GetPlayerByUserId(payload.UserId)
    local otherProfile = other and self.Service:profile(other)
    if not otherProfile or Economy.level(otherProfile.XP) < MIN_LEVEL or otherProfile.Tutorial < 5
        or not self.Service.World:near(other, "Market") then return self:_notice(player, "Both players must meet at Market Square and reach level 3.") end
    local id = self.Guid()
    local trade = {Id = id, InviterId = player.UserId, A = player.UserId, B = other.UserId,
        Names = {[tostring(player.UserId)] = player.DisplayName, [tostring(other.UserId)] = other.DisplayName},
        Status = "Invited", Ends = self.Clock() + 45, Revision = 1, ConfirmAfter = self.Clock() + TRADE_REVIEW,
        Offers = {[tostring(player.UserId)] = {Cash = 0, Items = {}, Confirmed = false},
            [tostring(other.UserId)] = {Cash = 0, Items = {}, Confirmed = false}}}
    self.Trades[id] = trade; self.PlayerTrades[player.UserId] = id; self.PlayerTrades[other.UserId] = id
    self:_notice(other, player.DisplayName .. " invited you to trade. Open Market Square."); self:_broadcast()
end
function ExchangeService:respond(player, payload)
    local trade = self:_tradeFor(player, payload.TradeId)
    if not trade or trade.Status ~= "Invited" or trade.InviterId == player.UserId then return end
    if payload.Accept ~= true then return self:cancelTrade(player, payload) end
    if not self:_eligible(player) then return end
    trade.Status = "Open"; trade.Ends = self.Clock() + 180; self:_resetConfirmations(trade); self:_broadcast()
end
function ExchangeService:offer(player, payload)
    local trade = self:_tradeFor(player, payload.TradeId)
    local profile = self:_eligible(player)
    if not trade or not profile or trade.Status ~= "Open" then return end
    local offer = trade.Offers[tostring(player.UserId)]
    if payload.Cash ~= nil then
        if not Economy.validAmount(payload.Cash, 0, CASH_CAP) or payload.Cash > self.Service:spendable(player, profile) + offer.Cash then
            return self:_notice(player, "Choose an amount within your available cash.")
        end
        offer.Cash = payload.Cash
    elseif type(payload.Uid) == "string" and type(payload.Add) == "boolean" then
        local index = table.find(offer.Items, payload.Uid)
        if payload.Add then
            if index then return end
            if #offer.Items >= MAX_TRADE_ITEMS then return self:_notice(player, "Each player can offer up to four items.") end
            if not self:_availableItem(player.UserId, payload.Uid, profile) then return self:_notice(player, "That item cannot be offered right now.") end
            table.insert(offer.Items, payload.Uid)
        elseif index then table.remove(offer.Items, index) else return end
    else return end
    self:_resetConfirmations(trade); self:_broadcast()
end
function ExchangeService:_removeTrade(trade)
    self.Trades[trade.Id] = nil
    self.PlayerTrades[trade.A] = nil; self.PlayerTrades[trade.B] = nil
    self.Cooldowns[trade.A] = self.Clock() + TRADE_COOLDOWN
    self.Cooldowns[trade.B] = self.Clock() + TRADE_COOLDOWN
end
function ExchangeService:cancelTrade(player, payload)
    local trade = self:_tradeFor(player, payload.TradeId)
    if not trade or trade.Status == "Processing" then return end
    self:_removeTrade(trade); self:_broadcast()
end
function ExchangeService:confirm(player, payload)
    local trade = self:_tradeFor(player, payload.TradeId)
    if not trade or trade.Status ~= "Open" or not self:_eligible(player) then return end
    if self.Clock() < trade.ConfirmAfter then return self:_notice(player, "Review both sides for three seconds after the last change.") end
    local own = trade.Offers[tostring(player.UserId)]
    own.Confirmed = true
    local aOffer, bOffer = trade.Offers[tostring(trade.A)], trade.Offers[tostring(trade.B)]
    if not aOffer.Confirmed or not bOffer.Confirmed then return self:_broadcast() end
    local aPlayer, bPlayer = Players:GetPlayerByUserId(trade.A), Players:GetPlayerByUserId(trade.B)
    local a = aPlayer and self.Service:profile(aPlayer); local b = bPlayer and self.Service:profile(bPlayer)
    if not a or not b or not self.Service.World:near(aPlayer, "Market") or not self.Service.World:near(bPlayer, "Market") then
        self:_removeTrade(trade); return self:_broadcast()
    end
    if #aOffer.Items + #bOffer.Items == 0 and aOffer.Cash + bOffer.Cash == 0 then
        self:_resetConfirmations(trade); self:_notice(player, "Add a find or some cash before confirming."); return self:_broadcast()
    end
    if a.Cash < aOffer.Cash or b.Cash < bOffer.Cash then self:_resetConfirmations(trade); return self:_broadcast() end
    -- AvailableCash excludes this offer and any auction reservation; adding the
    -- offer back validates the money without consuming someone else's hold.
    if self.Service:spendable(aPlayer, a) < 0 or self.Service:spendable(bPlayer, b) < 0 then self:_resetConfirmations(trade); return self:_broadcast() end
    if #a.Inventory - #aOffer.Items + #bOffer.Items > self.Capacity or #b.Inventory - #bOffer.Items + #aOffer.Items > self.Capacity then
        self:_notice(player, "One bag has no room for the proposed exchange."); self:_resetConfirmations(trade); return self:_broadcast()
    end
    local aItems, bItems = {}, {}
    for _, uid in ipairs(aOffer.Items) do
        local item = ExchangeRules.find(a, uid); if not item or item.Slot then self:_removeTrade(trade); return self:_broadcast() end
        table.insert(aItems, copy(item))
    end
    for _, uid in ipairs(bOffer.Items) do
        local item = ExchangeRules.find(b, uid); if not item or item.Slot then self:_removeTrade(trade); return self:_broadcast() end
        table.insert(bItems, copy(item))
    end
    trade.Status = "Processing"; self:_broadcast()
    local success = self:_transaction("Trade", {
        {UserId = trade.A, CashDelta = bOffer.Cash - aOffer.Cash, Outgoing = copy(aOffer.Items), Incoming = bItems},
        {UserId = trade.B, CashDelta = aOffer.Cash - bOffer.Cash, Outgoing = copy(bOffer.Items), Incoming = aItems},
    })
    self:_removeTrade(trade)
    if success then self:_notice(aPlayer, "Trade complete. Enjoy your new finds!"); self:_notice(bPlayer, "Trade complete. Enjoy your new finds!") end
    self:_broadcast()
end
function ExchangeService:snapshot(player)
    local listings = {}
    for _, listing in pairs(self.Listings) do
        if not listing.Busy and listing.Expires > self.Clock() then
            local view = copy(listing)
            local seller = self.Data.Profiles[listing.SellerId]
            if seller then view.Item.Value = self.Service:value(seller, view.Item) end
            table.insert(listings, view)
        end
    end
    table.sort(listings, function(a, b) return a.Expires < b.Expires end)
    local view
    local id = self.PlayerTrades[player.UserId]; local trade = id and self.Trades[id]
    if trade then
        local otherId = if trade.A == player.UserId then trade.B else trade.A
        local function offered(userId)
            local original = trade.Offers[tostring(userId)]; local out = {Cash = original.Cash, Confirmed = original.Confirmed, Items = {}}
            local profile = self.Data.Profiles[userId]
            if profile then for _, uid in ipairs(original.Items) do
                local item = ExchangeRules.find(profile, uid)
                if item then local record = copy(item); record.Value = self.Service:value(profile, item); table.insert(out.Items, record) end
            end end
            return out
        end
        view = {Id = trade.Id, PartnerId = otherId, PartnerName = trade.Names[tostring(otherId)],
            InviterId = trade.InviterId, Status = trade.Status, Ends = trade.Ends, Revision = trade.Revision,
            ConfirmAfter = trade.ConfirmAfter, You = offered(player.UserId), Them = offered(otherId)}
    end
    return {Listings = listings, ListingFeeRate = FEE_RATE, PriceCap = PRICE_CAP, MinLevel = MIN_LEVEL,
        MaxListings = MAX_LISTINGS, MaxTradeItems = MAX_TRADE_ITEMS, SameServer = true}, view
end
function ExchangeService:tick()
    local now = self.Clock()
    if now == self.LastTick then return end
    self.LastTick = now
    local changed = false
    for id, listing in pairs(self.Listings) do
        if not listing.Busy and listing.Expires <= now then self.Listings[id] = nil; changed = true end
    end
    for _, trade in pairs(self.Trades) do
        if trade.Status ~= "Processing" and trade.Ends <= now then self:_removeTrade(trade); changed = true end
    end
    if changed then self:_broadcast() end
end
function ExchangeService:leave(userId)
    for id, listing in pairs(self.Listings) do
        if listing.SellerId == userId and not listing.Busy then self.Listings[id] = nil end
    end
    local id = self.PlayerTrades[userId]; local trade = id and self.Trades[id]
    if trade and trade.Status ~= "Processing" then self:_removeTrade(trade) end
end
function ExchangeService:request(player, action, payload)
    local handlers = {
        MarketList = self.list, MarketCancel = self.cancelListing, MarketBuy = self.buy,
        TradeInvite = self.invite, TradeRespond = self.respond, TradeOffer = self.offer,
        TradeConfirm = self.confirm, TradeCancel = self.cancelTrade,
    }
    local handler = handlers[action]
    if not handler then return false end
    handler(self, player, payload)
    return true
end
return ExchangeService
