local passed = 0
local function test(name, callback)
    local ok, problem = pcall(callback)
    if not ok then error("FAIL " .. name .. ": " .. tostring(problem)) end
    passed += 1; print("PASS " .. name)
end
local function equal(actual, expected)
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function fixture()
    local events = {}
    local player = {UserId = 101, DisplayName = "Tester", Parent = true, FindFirstChild = function() return nil end}
    local profile = Profile.new()
    local data = {Profiles = {[101] = profile}, Closing = {}, Ephemeral = true}
    local world = {Allowed = true, Owners = {[101] = {Index = 1}}, near = function(self) return self.Allowed end,
        render = function() end, customer = function() end}
    local event = {FireClient = function(_, _, kind, payload) table.insert(events, {Kind = kind, Payload = payload}) end}
    local service = GameService.new(data, world, event)
    service.Ready[101] = true; roster = {player}
    service:resetQuests(profile)
    return service, player, profile, world, events
end
local function addItem(profile, condition)
    local item = {Uid = "one", DefId = Catalog.Items[1].Id, Rarity = 2, Condition = condition or 2,
        Variance = 1, Style = "Retro", Inspected = true}
    table.insert(profile.Inventory, item); return item
end

test("catalog has 80 unique, valid definitions in eight categories", function()
    equal(#Catalog.Items, 80); equal(#Catalog.Categories, 8)
    local seen = {}
    for _, item in ipairs(Catalog.Items) do
        assert(not seen[item.Id]); seen[item.Id] = true
        assert(Catalog.ById[item.Id] == item and item.BaseValue > 0)
        assert(table.find(Config.Styles, item.Style))
    end
end)
test("weighted rarity boundaries and distribution", function()
    local counts = {0, 0, 0, 0, 0}
    for index = 0, 9999 do
        local rarity = Economy.pick(Config.Sources.Dumpster.Weights, index / 10000)
        counts[rarity] += 1
    end
    for i, percent in ipairs(Config.Sources.Dumpster.Weights) do assert(math.abs(counts[i] - percent * 100) <= 1) end
    equal(Economy.pick({1, 1}, 0), 1); equal(Economy.pick({1, 1}, 1), 2)
end)
test("valuation increases with rarity and condition; multipliers compose", function()
    local item = {Rarity = 1, Condition = 1, Variance = 1}
    local definition = {BaseValue = 100}
    local old = 0
    for rarity = 1, 5 do
        item.Rarity = rarity
        local value = Economy.value(definition, item, Config.RarityMultipliers, Config.ConditionMultipliers, 1.2, 1.1)
        assert(value > old); old = value
    end
    item.Rarity = 1; item.Condition = 5
    equal(Economy.value(definition, item, Config.RarityMultipliers, Config.ConditionMultipliers, 1.2, 1.1), 264)
end)
test("restoration always helps and caps at Mint", function()
    equal(Economy.restore(1, 0, 0), 2); equal(Economy.restore(1, 1, 0), 3)
    equal(Economy.restore(4, 1, 3), 5)
end)
test("invalid amounts reject NaN, infinity, fractional and negative values", function()
    for _, value in ipairs({0 / 0, math.huge, -1, 1.5, "100", false}) do assert(not Economy.validAmount(value, 1, 1000)) end
    assert(Economy.validAmount(100, 1, 1000))
end)
test("profile reconciliation preserves saved state and isolates inventories", function()
    local p = Profile.reconcile({Cash = 999, Inventory = {{Uid = "saved"}}, Stats = {Sold = 5}})
    equal(p.Cash, 999); equal(p.Stats.Sold, 5); equal(p.Stats.Found, 0); equal(p.Inventory[1].Uid, "saved")
    local a, b = Profile.new(), Profile.new(); a.Inventory[1] = {}; equal(#b.Inventory, 0)
end)
test("datastore leases reject competing sessions and permit released saves", function()
    stores = {}
    local a, b = DataService.new(), DataService.new()
    assert(a:load(1)); assert(b:load(1) == nil)
    a.Profiles[1].Cash = 432; assert(a:save(1, false))
    equal(stores.ThriftFlip_Backups_v1.Records.p_1.Data.Cash, 432)
    assert(a:release(1)); assert(b:load(1)); equal(b.Profiles[1].Cash, 432)
end)
test("lost lease cannot overwrite another server's data", function()
    stores = {}
    local a = DataService.new(); assert(a:load(2))
    stores.ThriftFlip_Profiles_v1.Records.p_2.Lock.Token = "other-server"
    a.Profiles[2].Cash = 99999
    assert(not a:save(2, false)); equal(stores.ThriftFlip_Profiles_v1.Records.p_2.Data.Cash, 75)
end)
test("datastore outage refuses to create an empty fallback save", function()
    stores = {}; failStore = true
    local a = DataService.new(); assert(a:load(3) == nil); assert(a.Profiles[3] == nil)
    failStore = false
end)
test("sourcing checks location, costs, cooldown, daily delivery and capacity", function()
    local s, p, profile, world = fixture()
    world.Allowed = false; s:source(p, {Source = "Dumpster"}); equal(#profile.Inventory, 0)
    world.Allowed = true; s:source(p, {Source = "Dumpster"}); equal(#profile.Inventory, 1); equal(profile.Tutorial, 1)
    s:source(p, {Source = "Dumpster"}); equal(#profile.Inventory, 1)
    s:source(p, {Source = "Delivery"}); equal(#profile.Inventory, 2)
    s:source(p, {Source = "Delivery"}); equal(#profile.Inventory, 2)
    s:source(p, {Source = "Estate"}); equal(#profile.Inventory, 2)
end)
test("inspect cannot duplicate discovery XP or reveal twice", function()
    local s, p, profile = fixture(); local item = addItem(profile); item.Inspected = false
    s:inspect(p, {Uid = item.Uid}); equal(profile.XP, 8)
    s:inspect(p, {Uid = item.Uid}); equal(profile.XP, 8)
    assert(profile.Collection[item.DefId .. ":2"])
end)
test("mystery snapshots hide rarity, variance and value", function()
    local s, p, profile, _, events = fixture(); local item = addItem(profile); item.Inspected = false
    s:snapshot(p)
    local view = events[#events].Payload.Inventory[1]
    assert(view.Rarity == nil and view.Variance == nil and view.Value == nil)
end)
test("restoration blocks forged tokens, early finish and replay", function()
    local s, p, profile = fixture(); local item = addItem(profile)
    s:beginRestore(p, {Uid = item.Uid, Kind = "Scrub"})
    local session = s.Sessions[p.UserId]; assert(session)
    s:restoreInput(p, {Token = "forged", Cell = 1}); equal(session.Progress, 0)
    s:finishRestore(p, {Token = session.Token}); equal(item.Condition, 2)
    for i = 1, 16 do session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = i}) end
    equal(session.Progress, 16)
    session.Started = os.clock() - 9; s:finishRestore(p, {Token = session.Token})
    equal(item.Condition, 4); equal(profile.Stats.Restored, 1)
    s:finishRestore(p, {Token = session.Token}); equal(profile.Stats.Restored, 1)
end)
test("polish validates ordered path; repaint requires requested palette", function()
    local s, p, profile = fixture(); local item = addItem(profile)
    s:beginRestore(p, {Uid = item.Uid, Kind = "Polish"}); local session = s.Sessions[101]
    s:restoreInput(p, {Token = session.Token, Cell = 16}); equal(session.Progress, 0); equal(session.Mistakes, 1)
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = 1}); equal(session.Progress, 1)
    s.Sessions[101] = nil; s:beginRestore(p, {Uid = item.Uid, Kind = "Repaint"}); session = s.Sessions[101]
    session.Palette = 1; session.RequiredPalette = 3
    s:restoreInput(p, {Token = session.Token, Cell = 1}); equal(session.Progress, 0)
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Palette = 3})
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = 1}); equal(session.Progress, 1)
end)
test("display rejects occupied and locked slots", function()
    local s, p, profile = fixture(); local first = addItem(profile)
    s:display(p, {Uid = first.Uid, Slot = 5}); assert(first.Slot == nil)
    s:display(p, {Uid = first.Uid, Slot = 1}); equal(first.Slot, 1)
    local second = addItem(profile); second.Uid = "two"
    s:display(p, {Uid = second.Uid, Slot = 1}); assert(second.Slot == nil)
end)
test("sale executes once and removes the exact inventory item", function()
    local s, p, profile = fixture(); local item = addItem(profile); item.Slot = 1
    s.Offers[101] = {Uid = item.Uid, Amount = 200, Ends = os.time() + 20}
    s:haggle(p, {Choice = "Accept"}); equal(profile.Cash, 275); equal(#profile.Inventory, 0)
    s:haggle(p, {Choice = "Accept"}); equal(profile.Cash, 275); equal(profile.Stats.Sold, 1)
end)
test("daily and weekly rewards cannot be claimed twice", function()
    local s, p, profile = fixture()
    s:quest(p, {Id = "Find"}); equal(profile.Cash, 75)
    profile.Daily.Found = 3; s:quest(p, {Id = "Find"}); equal(profile.Cash, 140)
    s:quest(p, {Id = "Find"}); equal(profile.Cash, 140)
    profile.Weekly.Restored = 20; profile.Weekly.Sold = 15
    s:quest(p, {Id = "Weekly"}); equal(profile.Cash, 1340)
    s:quest(p, {Id = "Weekly"}); equal(profile.Cash, 1340)
end)
test("auction reservations prevent overspending without persisting escrow", function()
    local s, p, profile = fixture(); profile.Cash = 1000; profile.XP = 1000
    s.Auction = {Bid = 0, Started = os.time(), Ends = os.time() + 30}
    s:bid(p, {Amount = 900}); equal(profile.Cash, 1000); equal(s:spendable(p, profile), 100)
    s:upgrade(p, {Kind = "Tool"}); equal(profile.Tool, 0); equal(profile.Cash, 1000)
    s:bid(p, {Amount = 999999}); equal(s.Auction.Bid, 900)
end)
test("auction settles cash and item in the same winning profile", function()
    local s, p, profile = fixture(); local item = addItem(profile); table.clear(profile.Inventory)
    s.Auction = {Bid = 50, Bidder = p.UserId, Started = os.time() - 60, Ends = os.time() - 1, Item = item}
    s:tick(); equal(profile.Cash, 25); equal(#profile.Inventory, 1); assert(s.Auction == nil)
    s:tick(); equal(profile.Cash, 25); equal(#profile.Inventory, 1)
end)
test("remote input rejects nested data, non-finite numbers and unknown actions", function()
    local s, p, profile = fixture()
    for _, payload in ipairs({{Source = {}}, {Source = string.rep("x", 101)}, {Amount = 0 / 0}, {Amount = math.huge}}) do
        s:request(p, "Source", payload)
    end
    s:request(p, "leave", {}); equal(profile.Cash, 75); equal(#profile.Inventory, 0)
end)
test("one showcase entry cannot reset earned votes on re-entry", function()
    local s, p = fixture(); s:showcase(p, {Choice = "Enter"})
    s.Showcase.Entries["101"].Votes = 5
    s:showcase(p, {Choice = "Enter"}); equal(s.Showcase.Entries["101"].Votes, 5)
end)


test("rewiring requires matching ends and assembly requires the correct piece", function()
    local s, p, profile = fixture(); local item = addItem(profile)
    s:beginRestore(p, {Uid = item.Uid, Kind = "Rewire"}); local session = s.Sessions[101]
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = session.Targets[1]})
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = session.Targets[3]})
    equal(session.Progress, 0); equal(session.Mistakes, 1)
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = session.Targets[1]})
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = session.Targets[2]})
    equal(session.Progress, 2)
    s.Sessions[101] = nil; s:beginRestore(p, {Uid = item.Uid, Kind = "Assemble"}); session = s.Sessions[101]
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = session.Targets[1], Piece = 2})
    equal(session.Progress, 0)
    session.LastInput = -100; s:restoreInput(p, {Token = session.Token, Cell = session.Targets[1], Piece = 1})
    equal(session.Progress, 1)
end)
test("owned decorations toggle without repeated charges; cannot spend reserved cash", function()
    local s, p, profile = fixture(); profile.Cash = 1000
    s:upgrade(p, {Kind = "Decor", Decor = "Rug"}); equal(profile.Cash, 880); assert(profile.PlacedDecor.Rug)
    s:upgrade(p, {Kind = "Decor", Decor = "Rug"}); equal(profile.Cash, 880); assert(not profile.PlacedDecor.Rug)
    s.Auction = {Bidder = 101, Bid = 850}
    s:upgrade(p, {Kind = "Decor", Decor = "Neon"}); equal(profile.Cash, 880); assert(not profile.Decorations.Neon)
end)
test("active restorations cannot be moved onto displays", function()
    local s, p, profile = fixture(); local item = addItem(profile)
    s:beginRestore(p, {Uid = item.Uid, Kind = "Scrub"})
    s:display(p, {Uid = item.Uid, Slot = 1}); assert(item.Slot == nil)
end)
print("FINAL: " .. passed .. " tests passed")
