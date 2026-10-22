-- Pure transfer invariants, shared with the headless fault-injection suite.
local ExchangeRules = {}
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for key, child in pairs(value) do out[key] = copy(child) end
    return out
end
ExchangeRules.copy = copy
function ExchangeRules.ensure(profile)
    profile.Exchange = profile.Exchange or {Pending = nil, LastApplied = nil}
    return profile.Exchange
end
function ExchangeRules.find(profile, uid)
    for index, item in ipairs(profile.Inventory) do if item.Uid == uid then return item, index end end
    return nil
end
function ExchangeRules.apply(profile, transaction, side, capacity)
    local exchange = ExchangeRules.ensure(profile)
    if exchange.LastApplied == transaction.Id then return true, false end
    if exchange.Pending ~= transaction.Id then return false, "Missing durable preparation marker" end
    if profile.Cash + side.CashDelta < 0 then return false, "Insufficient cash during recovery" end
    local outgoing = {}
    for _, uid in ipairs(side.Outgoing) do
        if outgoing[uid] or not ExchangeRules.find(profile, uid) then return false, "Outgoing item missing or duplicated" end
        outgoing[uid] = true
    end
    if #profile.Inventory - #side.Outgoing + #side.Incoming > capacity then return false, "Recovery inventory capacity exceeded" end
    local incoming = {}
    for _, item in ipairs(side.Incoming) do
        if incoming[item.Uid] or (ExchangeRules.find(profile, item.Uid) and not outgoing[item.Uid]) then
            return false, "Incoming item already exists without a receipt"
        end
        incoming[item.Uid] = true
    end
    -- All assertions precede mutation. Caller holds the session's mutation lock.
    for index = #profile.Inventory, 1, -1 do
        if outgoing[profile.Inventory[index].Uid] then table.remove(profile.Inventory, index) end
    end
    for _, original in ipairs(side.Incoming) do
        local item = copy(original); item.Slot = nil
        table.insert(profile.Inventory, item)
        if item.Inspected then profile.Collection[item.DefId .. ":" .. item.Rarity] = true end
    end
    profile.Cash += side.CashDelta
    exchange.LastApplied = transaction.Id
    return true, true
end
function ExchangeRules.side(transaction, userId)
    for _, side in ipairs(transaction.Sides) do if side.UserId == userId then return side end end
    return nil
end
function ExchangeRules.allAcknowledged(transaction)
    for _, side in ipairs(transaction.Sides) do
        if not transaction.Acks[tostring(side.UserId)] then return false end
    end
    return true
end
return ExchangeRules
