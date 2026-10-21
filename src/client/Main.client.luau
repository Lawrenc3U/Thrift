local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local UI = require(script.Parent:WaitForChild("UI"))
local Minigames = require(script.Parent:WaitForChild("Minigames"))
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game")
local player = Players.LocalPlayer
local ui = UI.new()
local state, page, context, session = nil, nil, {}, nil
local render
local function send(action, payload) event:FireServer(action, payload or {}) end
local function money(value) return "$" .. tostring(math.floor(value)) end
local function open(name, data)
    if session then ui:notice("Finish or cancel your restoration first."); return end
    page = name; context = data or {}; render()
end
local function card(text)
    local frame = UI.card(ui.Content); if text then UI.label(frame, text, 18) end; return frame
end
local function button(parent, text, action, payload, secondary)
    return UI.button(parent, text, function() send(action, payload) end, secondary)
end
local function navigate(parent, text, name, data)
    return UI.button(parent, text, function() open(name, data) end, true)
end
local function inventory(filter, displaySlot)
    local count = 0
    for _, item in ipairs(state.Inventory) do
        if not filter or filter(item) then
            count += 1
            local definition = Catalog.ById[item.DefId]
            local frame = card(if item.Inspected then definition.Name else "Mystery " .. definition.Category)
            if not item.Inspected then
                UI.label(frame, "Hidden rarity · " .. Config.Conditions[item.Condition], 15, UI.Colors.Muted)
                button(frame, "Inspect find", "Inspect", {Uid = item.Uid})
            else
                local rarityLabel = Config.RarityIcons[item.Rarity] .. " " .. Config.Rarities[item.Rarity]
                UI.label(frame, rarityLabel .. " · " .. Config.Conditions[item.Condition] .. " · " .. money(item.Value), 16, Color3.fromHex(Config.RarityColors[item.Rarity]))
                UI.label(frame, (item.Style or definition.Style) .. " · " .. (if item.Slot then "Display " .. item.Slot else "In your bag"), 14, UI.Colors.Muted)
                if displaySlot then
                    button(frame, "Place on display " .. displaySlot, "Display", {Uid = item.Uid, Slot = displaySlot})
                elseif item.Slot then
                    button(frame, "Return to bag", "Display", {Uid = item.Uid, Remove = true}, true)
                else
                    if item.Condition < 5 then
                        navigate(frame, "Restore at workbench", "Restore", {Uid = item.Uid})
                    end
                    navigate(frame, "Choose a display", "Slots", {Uid = item.Uid})
                end
            end
        end
    end
    if count == 0 then UI.label(card(), "Nothing here yet. Find something wonderful in Dumpster Alley!", 18) end
end
local function sourcePage(source)
    local tuning = Config.Sources[source]
    local frame = card(if source == "Dumpster" then "Someone's junk. Your next treasure." elseif source == "Estate" then "A yard full of forgotten stories." else "A little something, just for you.")
    UI.label(frame, "Visit the marked spot in town to collect. Level " .. tuning.Level .. "+ · " .. money(tuning.Cost), 16, UI.Colors.Muted)
    local odds = {}; for i, weight in ipairs(tuning.Weights) do table.insert(odds, Config.Rarities[i] .. " " .. weight .. "%") end
    UI.label(frame, "Find odds: " .. table.concat(odds, " · "), 14)
    if source == "Estate" then UI.label(frame, "Weekend event: 8% of finds move up one rarity (capped at Legendary).", 14) end
    if source == "Delivery" and state.LastDelivery == state.Day then
        UI.label(frame, "Today's parcel is claimed. A new one arrives at midnight UTC.", 17)
    else button(frame, if source == "Delivery" then "Open today's parcel" else "Find a mystery item · " .. money(tuning.Cost), "Source", {Source = source}) end
    navigate(frame, "Open your bag", "Bag")
end
local function auctionPage()
    local frame = card("The next great find is under the spotlight.")
    if state.Auction then
        local auction = state.Auction
        local definition = Catalog.ById[auction.Item.DefId]
        UI.label(frame, Config.RarityIcons[auction.Item.Rarity] .. " " .. Config.Rarities[auction.Item.Rarity] .. " " .. definition.Name, 22)
        UI.label(frame, "Current bid " .. money(auction.Bid) .. " · " .. (if auction.Bidder == player.UserId then "You're leading!" else "Make it yours"), 18)
        local minimum = auction.Bid + math.max(10, math.floor(auction.Bid * 0.1))
        button(frame, "Bid " .. money(minimum), "Bid", {Amount = minimum})
        button(frame, "Bid " .. money(minimum + 100), "Bid", {Amount = minimum + 100}, true)
        UI.label(frame, "Auction ends at server time " .. auction.Ends .. ". Last-second bids extend by up to 8s. Stay in this server to win; leaving cancels your bid.", 14, UI.Colors.Muted)
        UI.label(frame, "Your leading bid is reserved cash. You're charged only when you win.", 14)
    else UI.label(frame, "Next auction in about " .. math.max(0, state.NextAuction - state.ServerTime) .. " seconds. Explore while you wait!", 18) end
    UI.label(frame, "Visit the auction house to bid. In-game cash only.", 14, UI.Colors.Muted)
end
local function questsPage()
    local definitions = {{"Find", "Find 3 items", "Found", 3, 65}, {"Restore", "Restore 3 items", "Restored", 3, 100}, {"Sell", "Sell 3 items", "Sold", 3, 150}}
    for _, definition in ipairs(definitions) do
        local frame = card(definition[2] .. " · " .. math.min(definition[4], state.Daily[definition[3]] or 0) .. "/" .. definition[4])
        if state.Daily.Claimed[definition[1]] then UI.label(frame, "✓ Claimed", 16, UI.Colors.Teal)
        else button(frame, "Claim " .. money(definition[5]), "Quest", {Id = definition[1]}) end
    end
    local weekly = card("Weekly workshop challenge")
    UI.label(weekly, "Restored " .. state.Weekly.Restored .. "/20 · Sold " .. state.Weekly.Sold .. "/15", 17)
    if state.Weekly.Claimed then UI.label(weekly, "✓ Weekly Wonder earned", 16)
    else button(weekly, "Claim $1200 + title", "Quest", {Id = "Weekly"}) end
    UI.label(weekly, "Daily quests reset at midnight UTC; weekly quests reset Monday UTC.", 14, UI.Colors.Muted)
end
local function visitPage()
    for _, shop in ipairs(state.Shops) do
        if not context.Owner or context.Owner == shop.UserId then
            local frame = card(shop.Name .. " · " .. Config.Tiers[shop.Tier].Name)
            UI.label(frame, "Shop " .. (shop.Plot or "?") .. " · ★ " .. string.format("%.1f", shop.Rating), 17)
            if shop.UserId ~= player.UserId then
                UI.label(frame, "Visit their interior to leave one rating per day.", 15)
                for stars = 1, 5 do button(frame, string.rep("★", stars), "Rate", {UserId = shop.UserId, Stars = stars}, true) end
            end
        end
    end
end
render = function()
    if not state or session then return end
    local titles = {Bag = "Your finds", Source = "Dumpster Alley", Estate = "Estate sale", Delivery = "Daily delivery",
        Workbench = "Restoration workbench", Restore = "Choose your restoration", Display = "Display an item",
        Slots = "Choose a display", Shop = "Make it yours", Auction = "The auction house", Quests = "A little progress, every day",
        Collection = "Your collection book", Town = "Explore Thrift Street", Visit = "The neighborhood", Market = "Market square",
        Showcase = "Weekly designer showcase", Settings = "Your preferences"}
    ui:clear(titles[page] or "Thrift Flip")
    if page == "Bag" then inventory()
    elseif page == "Source" then sourcePage("Dumpster")
    elseif page == "Estate" then sourcePage("Estate")
    elseif page == "Delivery" then sourcePage("Delivery")
    elseif page == "Workbench" then inventory(function(item) return item.Inspected and not item.Slot and item.Condition < 5 end)
    elseif page == "Restore" then
        local frame = card("Visit your own workbench, then choose a technique.")
        for _, kind in ipairs({"Scrub", "Polish", "Rewire", "Repaint", "Assemble"}) do
            button(frame, kind .. (if kind == "Repaint" then " · changes style" else ""), "BeginRestore", {Uid = context.Uid, Kind = kind})
        end
    elseif page == "Display" then inventory(function(item) return item.Inspected and not item.Slot end, context.Slot)
    elseif page == "Slots" then
        local frame = card("Place this find in your shop. Theme matches earn +10% value.")
        local occupied = {}; for _, item in ipairs(state.Inventory) do if item.Slot then occupied[item.Slot] = true end end
        for slot = 1, Config.Tiers[state.Tier].Slots do
            if not occupied[slot] then button(frame, "Display " .. slot, "Display", {Uid = context.Uid, Slot = slot}) end
        end
    elseif page == "Shop" then
        local offer = state.Offer
        if offer then
            local frame = card(offer.Customer .. " is browsing!")
            UI.label(frame, "Offer: " .. money(offer.Amount), 24, UI.Colors.Teal)
            button(frame, "Accept & sell", "Haggle", {Choice = "Accept"})
            if not offer.Countered then button(frame, "Counter +12% · 65% chance", "Haggle", {Choice = "Counter"}, true) end
            button(frame, "No thanks", "Haggle", {Choice = "Decline"}, true)
        else UI.label(card(), "Display items and customers will visit. Return to your shop to accept offers.", 17) end
        local upgrades = card(Config.Tiers[state.Tier].Name .. " · " .. Config.Tiers[state.Tier].Slots .. " display slots")
        local nextTier = Config.Tiers[state.Tier + 1]
        if nextTier then button(upgrades, nextTier.Name .. " · " .. money(nextTier.Cost) .. " · level " .. nextTier.Level, "Upgrade", {Kind = "Shop"}) end
        local toolCost = Config.ToolCosts[state.Tool + 1]
        if toolCost then button(upgrades, "Tool upgrade " .. (state.Tool + 1) .. " · " .. money(toolCost), "Upgrade", {Kind = "Tool"}, true) end
        for _, theme in ipairs(Config.Themes) do
            local frame = card(theme.Name .. (if state.Theme == theme.Id then " · selected" else ""))
            button(frame, if state.Themes[theme.Id] then "Use theme" else "Unlock · " .. money(theme.Cost), "Upgrade", {Kind = "Theme", Theme = theme.Id}, true)
        end
        for _, decoration in ipairs(Config.Decorations) do
            local frame = card(decoration.Name)
            local label = if state.PlacedDecor[decoration.Id] then "Put away" elseif state.Decorations[decoration.Id] then "Place decoration" else "Buy & place · " .. money(decoration.Cost)
            button(frame, label, "Upgrade", {Kind = "Decor", Decor = decoration.Id}, true)
        end
        navigate(upgrades, "Collection book", "Collection")
    elseif page == "Auction" then auctionPage()
    elseif page == "Quests" then questsPage()
    elseif page == "Collection" then
        local total = 0; for _ in pairs(state.Collection) do total += 1 end
        UI.label(card(), total .. " / 400 item-rarity discoveries · +$100 per 10 new finds", 18)
        for _, category in ipairs(Catalog.Categories) do
            local frame = card(category)
            for _, definition in ipairs(Catalog.Items) do
                if definition.Category == category then
                    local found = {}; for rarity = 1, 5 do
                        table.insert(found, if state.Collection[definition.Id .. ":" .. rarity] then Config.RarityIcons[rarity] else "–")
                    end
                    UI.label(frame, definition.Name .. "  " .. table.concat(found, " "), 16)
                end
            end
        end
    elseif page == "Visit" then visitPage()
    elseif page == "Market" then
        local frame = card("Meet your neighbors")
        UI.label(frame, "Player listings and trading are held for a later release while durable transfer protection is built. Your items stay safe in your inventory.", 18)
        navigate(frame, "Visit & rate shops", "Visit"); navigate(frame, "Designer showcase", "Showcase")
    elseif page == "Showcase" then
        local frame = card("This server's weekly showcase · " .. state.Demand .. " inspiration")
        UI.label(frame, "Show off your shop. One vote per player each week; no voting for yourself. This local contest resets when the server closes. A winner online at the weekly rollover earns a cosmetic title.", 16)
        button(frame, "Enter my shop", "Showcase", {Choice = "Enter"})
        for id, entry in pairs(state.Showcase.Entries) do
            local entryCard = card(entry.Name .. " · " .. entry.Theme .. " · " .. entry.Votes .. " votes")
            button(entryCard, "Vote", "Showcase", {Choice = "Vote", UserId = tonumber(id)}, true)
        end
    elseif page == "Settings" then
        local frame = card("Comfort comes first")
        button(frame, "Effects: " .. (if state.Settings.Effects then "on" else "off"), "Settings", {Name = "Effects", Enabled = not state.Settings.Effects}, true)
        UI.label(frame, "Rarity always uses a shape and a name alongside color. Roblox handles chat filtering. No paid gameplay advantages.", 16)
        local earnedTitles = {}; for title in pairs(state.Titles) do table.insert(earnedTitles, title) end; table.sort(earnedTitles)
        UI.label(frame, "Your titles: " .. (if #earnedTitles == 0 then "Keep creating!" else table.concat(earnedTitles, ", ")), 16)
        UI.label(frame, if state.Ephemeral then "STUDIO PRACTICE MODE · progress will not save" else "Progress saves automatically every 60 seconds and when you leave.", 15)
    else
        local frame = card("A cozy street full of second chances.")
        UI.label(frame, "Walk with the Roblox controls. Use the prompts at stalls and inside shops. Your shop sign shows your name. Today's demand: " .. state.Demand .. " (+20% value).", 17)
        for _, entry in ipairs({{"Dumpster Alley", "Source"}, {"Estate sale · level 3+", "Estate"}, {"Daily delivery", "Delivery"}, {"Auctions", "Auction"}, {"Neighbor shops", "Visit"}, {"Designer showcase", "Showcase"}, {"Collection book", "Collection"}, {"Settings", "Settings"}}) do navigate(frame, entry[1], entry[2]) end
    end
end
for _, entry in ipairs({{"Bag", "Bag"}, {"Shop", "Shop"}, {"Find", "Source"}, {"Quests", "Quests"}, {"Town", "Town"}}) do
    UI.button(ui.Nav, entry[1], function() open(entry[2]) end)
end
local tutorialHints = {
    [0] = "① Walk to Dumpster Alley → find your first treasure",
    [1] = "② Open Bag → inspect your mystery find",
    [2] = "③ Visit your shop workbench → restore your find",
    [3] = "④ Choose a display → place your restored find",
    [4] = "⑤ A friendly customer is coming → accept the offer in Shop",
}
local lastOffer
local function updateHud()
    ui.Balance.Text = money(state.Cash) .. "  ·  LV " .. state.Level
    ui.Hint.Text = tutorialHints[state.Tutorial] or ("Today's favorites: " .. state.Demand .. " · Reputation " .. state.Reputation)
    if state.AvailableCash < state.Cash then ui.Hint.Text ..= " · " .. money(state.Cash - state.AvailableCash) .. " reserved for auction" end
end
event.OnClientEvent:Connect(function(kind, payload)
    if kind == "State" then
        local wasVisible = ui.Panel.Visible
        state = payload; updateHud()
        if state.Offer and state.Offer.Uid ~= lastOffer then
            ui:notice(state.Offer.Customer .. " has an offer! Open Shop.")
            if not session then page = "Shop"; wasVisible = true end
        end
        lastOffer = if state.Offer then state.Offer.Uid else nil
        if wasVisible and not session then render() end
    elseif kind == "Notice" then ui:notice(payload)
    elseif kind == "Open" then
        if payload.Page == "Visit" then open("Visit", {Owner = payload.Owner})
        elseif payload.Page == "Display" then open("Display", {Slot = payload.Slot})
        else open(payload.Page) end
    elseif kind == "Minigame" then
        Minigames.stop(session); session = Minigames.start(ui, UI, payload, send, Config)
    elseif kind == "MinigameProgress" then Minigames.progress(session, payload, UI)
    elseif kind == "MinigameDone" then
        Minigames.stop(session); session = nil
        ui:notice(if payload.Cancelled then "Restoration cancelled." else payload.Quality .. " restoration! Now " .. payload.Condition .. ".")
        page = "Bag"; if state then render() end
    end
end)
-- Retry sync only until the asynchronous save load has completed.
task.spawn(function()
    while not state do send("Sync", {}); task.wait(2) end
end)
-- Small action feedback respects the effects preference; no camera shake.
local lastCash = 0
RunService.Heartbeat:Connect(function()
    if not state then return end
    if state.Cash > lastCash and lastCash > 0 and state.Settings.Effects then
        ui.Balance.TextColor3 = UI.Colors.Gold
        task.delay(0.5, function() ui.Balance.TextColor3 = UI.Colors.Teal end)
    end
    lastCash = state.Cash
end)

-- A local tutorial marker remains available even when distant shop parts stream out.
local marker = Instance.new("Part"); marker.Name = "TutorialGuide"; marker.Size = Vector3.one
marker.Anchored = true; marker.CanCollide = false; marker.CanTouch = false; marker.CanQuery = false; marker.Transparency = 1; marker.Parent = workspace
local billboard = Instance.new("BillboardGui"); billboard.Size = UDim2.fromOffset(230, 65); billboard.AlwaysOnTop = true; billboard.Parent = marker
local guideText = UI.label(billboard, "▼ START HERE", 22, UI.Colors.Gold); guideText.Size = UDim2.fromScale(1, 1); guideText.TextXAlignment = Enum.TextXAlignment.Center
local lastGuide = 0
RunService.Heartbeat:Connect(function()
    if not state or os.clock() - lastGuide < 0.5 then return end
    lastGuide = os.clock()
    billboard.Enabled = state.Tutorial == 0 or (state.Tutorial >= 2 and state.Tutorial <= 4)
    if state.Tutorial == 0 then marker.Position = Vector3.new(-40, 8, -120); guideText.Text = "▼ YOUR FIRST FIND"
    elseif state.Tutorial >= 2 and state.Tutorial <= 4 then
        for _, shop in ipairs(state.Shops) do
            if shop.UserId == player.UserId and shop.Plot then
                local row = math.ceil(shop.Plot / 2)
                local side = if shop.Plot % 2 == 1 then -1 else 1
                marker.Position = Vector3.new(side * 52, 12, -83 + (row - 1) * 35)
                guideText.Text = "▼ YOUR SHOP"
            end
        end
    end
end)
