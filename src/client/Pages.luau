-- The journal pages share one visual vocabulary and preserve drafts between updates.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UI = require(script.Parent.UI)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Pages = {}
Pages.__index = Pages
local player = Players.LocalPlayer
local function money(value)
    local amount = math.floor(value or 0)
    local str = tostring(math.abs(amount)); local out = str
    while true do local count; out, count = string.gsub(out, "^(%d+)(%d%d%d)", "%1,%2"); if count == 0 then break end end
    return (if amount < 0 then "−$" else "$") .. out
end
local function remaining(seconds)
    seconds = math.max(0, math.floor(seconds))
    if seconds >= 86400 then return math.floor(seconds / 86400) .. "d " .. math.floor(seconds % 86400 / 3600) .. "h" end
    if seconds >= 3600 then return math.floor(seconds / 3600) .. "h " .. math.floor(seconds % 3600 / 60) .. "m" end
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end
local function inspectable(item)
    return item.Inspected and not item.Slot and not item.ListingId and not item.TradeId and not item.Locked
end
local function findItem(state, uid)
    for _, item in ipairs(state.Inventory) do if item.Uid == uid then return item end end
    return nil
end
function Pages.new(ui, send, open, guide)
    return setmetatable({UI = ui, Send = send, Open = open, Guide = guide, State = nil,
        BagCategory = "All", BagSort = "Newest", BagSearch = "", BagPage = 1,
        CollectionCategory = Catalog.Categories[1], Drafts = {}, ClockOffset = 0}, Pages)
end
function Pages:setState(state)
    self.State = state; self.ClockOffset = (state.ServerTime or os.time()) - os.time()
end
function Pages:now() return os.time() + self.ClockOffset end
function Pages:card(title, parent)
    local frame = UI.card(parent or self.UI.Content)
    if title then local label = UI.label(frame, title, 20); label.Font = Enum.Font.GothamBold end
    return frame
end
function Pages:button(parent, text, action, payload, secondary)
    return UI.button(parent, text, function() self.Send(action, payload or {}) end, secondary)
end
function Pages:nav(parent, text, page, context, secondary)
    return UI.button(parent, text, function() self.Open(page, context) end, secondary ~= false)
end
function Pages:timer(parent, prefix, deadline, onFinish)
    local label = UI.label(parent, prefix .. remaining(deadline - self:now()), 17, UI.Colors.Teal)
    label.Font = Enum.Font.GothamBold
    local last, completed = 0, false
    table.insert(self.UI.PageConnections, RunService.Heartbeat:Connect(function()
        if os.clock() - last < 0.25 then return end; last = os.clock()
        local left = deadline - self:now(); label.Text = prefix .. remaining(left)
        if left <= 0 and not completed then completed = true; if onFinish then onFinish() end end
    end))
    return label
end
function Pages:itemTile(parent, item, actionText, callback)
    local definition = Catalog.ById[item.DefId]
    if not definition then return end
    local tile = Instance.new("Frame"); tile.Name = "FindCard"; tile.BackgroundColor3 = UI.Colors.Panel
    tile.Size = UDim2.new(1, 0, 0, 258); tile.Parent = parent; UI.corner(tile, 14); UI.stroke(tile, UI.Colors.Line, 1, 0.25)
    local preview = UI.preview(tile, definition, item, 132, not item.Inspected)
    preview.Size = UDim2.new(1, -16, 0, 132); preview.Position = UDim2.fromOffset(8, 8)
    local title = UI.label(tile, if item.Inspected then definition.Name else "Mystery " .. definition.Category, 16)
    title.Font = Enum.Font.GothamBold; title.Position = UDim2.fromOffset(12, 147)
    title.Size = UDim2.new(1, -24, 0, 39); title.AutomaticSize = Enum.AutomaticSize.None
    title.TextYAlignment = Enum.TextYAlignment.Top
    local subtitle = if item.Inspected then Config.RarityIcons[item.Rarity] .. " " .. Config.Rarities[item.Rarity] .. " · " .. money(item.Value) else "A hidden treasure awaits"
    local color = if item.Inspected then Color3.fromHex(Config.RarityColors[item.Rarity]):Lerp(UI.Colors.Ink, 0.3) else UI.Colors.Muted
    local detail = UI.label(tile, subtitle, 13, color); detail.Position = UDim2.fromOffset(12, 185)
    detail.Size = UDim2.new(1, -24, 0, 20); detail.AutomaticSize = Enum.AutomaticSize.None; detail.TextTruncate = Enum.TextTruncate.AtEnd; detail.TextWrapped = false
    local button = UI.button(tile, actionText or "Take a closer look", callback, true)
    button.Size = UDim2.new(1, -16, 0, 44); button.Position = UDim2.new(0, 8, 1, -52); button.TextSize = 14
    if item.Slot or item.ListingId or item.TradeId or item.Locked then
        local status = UI.label(preview, if item.Slot then "ON DISPLAY" elseif item.ListingId then "LISTED" else "RESERVED", 10, UI.Colors.Panel)
        status.Font = Enum.Font.GothamBold; status.AutomaticSize = Enum.AutomaticSize.None
        status.Size = UDim2.new(1, 0, 0, 25); status.Position = UDim2.new(0, 0, 1, -25)
        status.BackgroundColor3 = UI.Colors.Teal; status.BackgroundTransparency = 0.1; status.TextXAlignment = Enum.TextXAlignment.Center
    end
    return tile
end
function Pages:itemSummary(parent, item, height)
    local definition = Catalog.ById[item.DefId]
    if not definition then return end
    UI.preview(parent, definition, item, height or 215, not item.Inspected)
    if item.Inspected then
        local tags = UI.row(parent, 29, 6)
        UI.pill(tags, Config.RarityIcons[item.Rarity] .. " " .. Config.Rarities[item.Rarity], Color3.fromHex(Config.RarityColors[item.Rarity]):Lerp(UI.Colors.Ink, 0.25))
        UI.pill(tags, Config.Conditions[item.Condition], UI.Colors.Teal)
        UI.label(parent, definition.Name, 24).Font = Enum.Font.GothamBold
        UI.label(parent, (item.Style or definition.Style) .. " • " .. definition.Category, 15, UI.Colors.Muted)
    else UI.label(parent, "Your mystery " .. definition.Category, 23).Font = Enum.Font.GothamBold end
end
function Pages:guideButton(parent, location, label)
    return UI.button(parent, label or "Show me the way", function()
        self.Guide(location); self.UI:hide()
    end, true)
end
function Pages:inventory(context, mode)
    local state = self.State
    local header = self:card()
    local categories = {"All"}; for _, category in ipairs(Catalog.Categories) do table.insert(categories, category) end
    local row = UI.row(header)
    UI.rowButton(row, "Category: " .. self.BagCategory, function()
        local current = table.find(categories, self.BagCategory) or 1
        self.BagCategory = categories[current % #categories + 1]; self.BagPage = 1; self.Open(mode or "Bag", context)
    end, 2, true)
    UI.rowButton(row, "Sort: " .. self.BagSort, function()
        local sorts = {"Newest", "Value", "Rarity", "Condition"}
        self.BagSort = sorts[(table.find(sorts, self.BagSort) or 1) % #sorts + 1]; self.BagPage = 1; self.Open(mode or "Bag", context)
    end, 2, true)
    local search = UI.input(header, "Search your finds…", self.BagSearch)
    search.FocusLost:Connect(function()
        if self.BagSearch ~= search.Text then self.BagSearch = search.Text; self.BagPage = 1; self.Open(mode or "Bag", context) end
    end)
    local items = {}
    for index = #state.Inventory, 1, -1 do
        local item = state.Inventory[index]
        local definition = Catalog.ById[item.DefId]
        local name = if item.Inspected then definition.Name else "Mystery " .. definition.Category
        local allowed = (self.BagCategory == "All" or self.BagCategory == definition.Category)
            and string.find(string.lower(name), string.lower(self.BagSearch), 1, true) ~= nil
        if mode == "Workbench" then allowed = allowed and inspectable(item) and item.Condition < 5 end
        if mode == "Display" then allowed = allowed and inspectable(item) end
        if mode == "List" then allowed = allowed and inspectable(item) end
        if allowed then table.insert(items, item) end
    end
    if self.BagSort ~= "Newest" then
        local field = self.BagSort
        table.sort(items, function(a, b)
            local av, bv = a[field] or 0, b[field] or 0
            if av == bv then return a.Uid < b.Uid end
            return av > bv
        end)
    end
    UI.eyebrow(header, #items .. " finds • " .. #state.Inventory .. "/" .. Config.InventoryLimit .. " in your bag")
    if #items == 0 then
        local empty = UI.hero(self.UI.Content, "Your next story", "Something wonderful is waiting.", if mode == "Workbench" then "Inspect a find and take it off display before restoring it." else "Try a different filter, or explore Dumpster Alley for a new find.")
        self:guideButton(empty, "Source", "Head to Dumpster Alley"); return
    end
    local perPage = 8
    local pageCount = math.ceil(#items / perPage); self.BagPage = math.clamp(self.BagPage, 1, pageCount)
    local grid = UI.grid(self.UI.Content, 258, 183)
    for index = (self.BagPage - 1) * perPage + 1, math.min(#items, self.BagPage * perPage) do
        local item = items[index]
        local action = if mode == "Display" then "Place in slot " .. (context.Slot or "?") elseif mode == "Workbench" then "Restore this find" elseif mode == "List" then "Set a price" else "Take a closer look"
        self:itemTile(grid, item, action, function()
            if mode == "Display" then self.Send("Display", {Uid = item.Uid, Slot = context.Slot})
            elseif mode == "Workbench" then self.Open("Restore", {Uid = item.Uid})
            elseif mode == "List" then self.Open("ListingEditor", {Uid = item.Uid})
            else self.Open("Item", {Uid = item.Uid}) end
        end)
    end
    if pageCount > 1 then
        local pageRow = UI.row(self.UI.Content)
        UI.rowButton(pageRow, "‹ Previous", function() self.BagPage = math.max(1, self.BagPage - 1); self.Open(mode or "Bag", context) end, 3, true)
        UI.rowButton(pageRow, self.BagPage .. " / " .. pageCount, function() end, 3, true)
        UI.rowButton(pageRow, "Next ›", function() self.BagPage = math.min(pageCount, self.BagPage + 1); self.Open(mode or "Bag", context) end, 3, true)
    end
end
function Pages:itemPage(context)
    local item = findItem(self.State, context.Uid)
    if not item then UI.label(self:card(), "This find has moved on to a new home.", 18); self:nav(self.UI.Content, "Back to your bag", "Bag"); return end
    local frame = self:card(); self:itemSummary(frame, item, 245)
    if not item.Inspected then
        UI.label(frame, "There is a story under all that dust. Inspect to reveal its rarity, style, and value.", 17, UI.Colors.Muted)
        self:button(frame, "✦ Reveal your find", "Inspect", {Uid = item.Uid}); return
    end
    local value = UI.label(frame, money(item.Value), 30, UI.Colors.Teal); value.Font = Enum.Font.GothamBold
    UI.eyebrow(frame, "Estimated value • includes today's demand and shop style")
    UI.progress(frame, item.Condition / 5, UI.Colors.Teal)
    if item.ListingId or item.TradeId or item.Locked then
        UI.disabled(frame, "This item is reserved in the market or a trade."); self:nav(frame, "Open market", "Market")
    elseif item.Slot then
        UI.label(frame, "On display in slot " .. item.Slot .. ". Your customers can make an offer.", 17)
        self:button(frame, "Return to your bag", "Display", {Uid = item.Uid, Remove = true}, true)
    else
        if item.Condition < 5 then self:nav(frame, "Restore at your workbench", "Restore", {Uid = item.Uid}, false)
        else UI.disabled(frame, "✓ Mint condition — beautifully restored") end
        self:nav(frame, "Display in your shop", "Slots", {Uid = item.Uid})
        if self.State.Market then self:nav(frame, "List in the player market", "ListingEditor", {Uid = item.Uid}) end
    end
    self:nav(frame, "Back to your finds", "Bag")
end
function Pages:sourcePage(source)
    local state, tuning = self.State, Config.Sources[source]
    local copy = {
        Dumpster = {"Everyday treasure", "Someone's junk. Your next great find.", "Free finds, fresh possibilities. There is always another story in the alley."},
        Estate = {"The estate collection", "Good things come with a little history.", "Browse mystery lots with better rare-find odds. Estate Sale Weekend brings an extra surprise."},
        Delivery = {"A daily little delight", "A parcel with your name on it.", "Your free daily find is ready to unwrap. Come back tomorrow for another."},
    }
    local words = copy[source]
    local frame = UI.hero(self.UI.Content, words[1], words[2], words[3], if source == "Estate" then UI.Colors.Rose else UI.Colors.Teal)
    local info = self:card()
    UI.eyebrow(info, "Level " .. tuning.Level .. "+ • " .. (if tuning.Cost == 0 then "Always free" else money(tuning.Cost) .. " per lot"))
    if source == "Delivery" and state.LastDelivery == state.Day then
        UI.disabled(info, "✓ Today's parcel is yours")
        self:timer(info, "Next delivery in ", (state.Day + 1) * 86400)
    elseif state.Level < tuning.Level then
        UI.disabled(info, "Unlock at level " .. tuning.Level)
    elseif state.AvailableCash < tuning.Cost then
        UI.disabled(info, "You need " .. money(tuning.Cost) .. " available cash")
    else
        self:button(info, if source == "Delivery" then "Open today's parcel" elseif source == "Dumpster" then "Search for a treasure" else "Choose a mystery lot · " .. money(tuning.Cost), "Source", {Source = source})
    end
    self:guideButton(info, if source == "Dumpster" then "Source" else source, "Find this spot in town")
    local odds = self:card("A little surprise, with clear odds")
    for index, chance in ipairs(tuning.Weights) do
        local line = UI.label(odds, Config.RarityIcons[index] .. " " .. Config.Rarities[index] .. "  ·  " .. chance .. "%", 16)
        line.TextColor3 = Color3.fromHex(Config.RarityColors[index]):Lerp(UI.Colors.Ink, 0.35)
        UI.progress(odds, chance / 100, Color3.fromHex(Config.RarityColors[index]))
    end
    if source == "Estate" then UI.label(odds, "Weekend bonus: 8% of finds move up one rarity, up to Legendary. In-game cash only.", 14, UI.Colors.Muted) end
    self:nav(frame, "Look in your bag", "Bag")
end
function Pages:restorePage(context)
    local item = findItem(self.State, context.Uid)
    if not item then return self:inventory({}, "Workbench") end
    local frame = self:card(); self:itemSummary(frame, item, 190)
    UI.label(frame, "A little care goes a long way.", 22).Font = Enum.Font.GothamBold
    UI.label(frame, "Work at your own shop bench. Every attempt improves the item, and careful work gives a bigger condition boost.", 16, UI.Colors.Muted)
    self:guideButton(frame, "Workbench", "Guide me to my workbench")
    local techniques = {
        {"Scrub", "✦", "Swipe away the grime", "Relaxing, generous and satisfying."},
        {"Polish", "◇", "Trace a clean shine", "Follow the path with a steady hand."},
        {"Rewire", "↔", "Bring it back to life", "Match wire colors and symbols."},
        {"Repaint", "▧", "Make it your own", "Choose paint, fill the surface, change its style."},
        {"Assemble", "▦", "Put the story together", "Fit the missing pieces into their outlines."},
    }
    for _, technique in ipairs(techniques) do
        local choice = self:card(technique[2] .. " " .. technique[1])
        UI.label(choice, technique[3], 17); UI.label(choice, technique[4], 14, UI.Colors.Muted)
        self:button(choice, "Start " .. string.lower(technique[1]) .. " · 8–20 sec", "BeginRestore", {Uid = item.Uid, Kind = technique[1]})
    end
end
function Pages:slotsPage(context)
    local occupied = {}; for _, item in ipairs(self.State.Inventory) do if item.Slot then occupied[item.Slot] = item end end
    UI.label(self:card(), "Choose a free display in your shop. Customers browse displayed finds; matching your shop theme adds 10% value.", 17)
    local grid = UI.grid(self.UI.Content, 88, 160)
    for slot = 1, Config.Tiers[self.State.Tier].Slots do
        if occupied[slot] then
            local button = UI.button(grid, "Display " .. slot .. "\n" .. Catalog.ById[occupied[slot].DefId].Name, function() self.Open("Item", {Uid = occupied[slot].Uid}) end, true)
            button.TextSize = 14
        else self:button(grid, "＋ Display " .. slot, "Display", {Uid = context.Uid, Slot = slot}) end
    end
    self:guideButton(self.UI.Content, "Shop", "Guide me to my shop")
end
function Pages:shopPage()
    local state = self.State
    local offer = state.Offer
    if offer then
        local welcome = UI.hero(self.UI.Content, "A customer found something they love", offer.Customer, "A good find deserves a good home.")
        local item = findItem(state, offer.Uid)
        if item then UI.preview(welcome, Catalog.ById[item.DefId], item, 175, false) end
        UI.label(welcome, money(offer.Amount), 34, UI.Colors.Panel).Font = Enum.Font.GothamBold
        self:timer(welcome, "They can stay for ", offer.Ends)
        self:button(welcome, "Accept & make their day", "Haggle", {Choice = "Accept"})
        if not offer.Countered then self:button(welcome, "Ask for 12% more · 65% chance", "Haggle", {Choice = "Counter"}, true) end
        self:button(welcome, "Politely decline", "Haggle", {Choice = "Decline"}, true)
    else
        local hero = UI.hero(self.UI.Content, "Your little corner of the street", Config.Tiers[state.Tier].Name, "Display your favorite finds. Customers bring the conversation, you make the deal.")
        self:guideButton(hero, "Shop", "Take me to my shop")
    end
    local overview = self:card("A shop that feels like you")
    local displayed = 0; for _, item in ipairs(state.Inventory) do if item.Slot then displayed += 1 end end
    UI.label(overview, displayed .. "/" .. Config.Tiers[state.Tier].Slots .. " displays filled  •  " .. state.Reputation .. " reputation", 17)
    UI.progress(overview, displayed / Config.Tiers[state.Tier].Slots)
    local links = UI.row(overview)
    UI.rowButton(links, "Your displays", function() self.Open("Displays") end, 2, true)
    UI.rowButton(links, "Decorate", function() self.Open("Decor") end, 2, true)
    self:nav(overview, "Themes & collections", "Themes")
    local upgrades = self:card("Room to grow")
    local nextTier = Config.Tiers[state.Tier + 1]
    if nextTier then
        UI.label(upgrades, nextTier.Name .. " • " .. nextTier.Slots .. " display spaces", 19)
        UI.label(upgrades, "Unlocks at level " .. nextTier.Level .. " • " .. money(nextTier.Cost), 15, UI.Colors.Muted)
        if state.Level >= nextTier.Level and state.AvailableCash >= nextTier.Cost then self:button(upgrades, "Upgrade your shop", "Upgrade", {Kind = "Shop"})
        else UI.disabled(upgrades, if state.Level < nextTier.Level then "Keep creating to reach level " .. nextTier.Level else "Save up " .. money(nextTier.Cost)) end
    else UI.disabled(upgrades, "✦ Your shop has reached its grandest tier") end
    local tools = self:card("The right tools, a little more magic")
    UI.label(tools, "Tool level " .. state.Tool .. "/" .. #Config.ToolCosts .. " • steadier restoration and better results", 17)
    local cost = Config.ToolCosts[state.Tool + 1]
    if cost then self:button(tools, "Upgrade tools · " .. money(cost), "Upgrade", {Kind = "Tool"}) else UI.disabled(tools, "✓ Your workshop is fully equipped") end
end
function Pages:displaysPage()
    local displayed = {}; for _, item in ipairs(self.State.Inventory) do if item.Slot then displayed[item.Slot] = item end end
    for slot = 1, Config.Tiers[self.State.Tier].Slots do
        local frame = self:card("Display " .. slot)
        local item = displayed[slot]
        if item then
            UI.preview(frame, Catalog.ById[item.DefId], item, 150, false)
            UI.label(frame, Catalog.ById[item.DefId].Name .. " • " .. money(item.Value), 18)
            self:button(frame, "Return to bag", "Display", {Uid = item.Uid, Remove = true}, true)
        else self:nav(frame, "Choose a find for this display", "Display", {Slot = slot}) end
    end
end
function Pages:themesPage()
    UI.label(self:card(), "Your shop is your signature. Finds that match your theme earn a 10% display bonus.", 17)
    for _, theme in ipairs(Config.Themes) do
        local frame = self:card(theme.Name)
        local swatch = Instance.new("Frame"); swatch.Size = UDim2.new(1, 0, 0, 60); swatch.BackgroundColor3 = Color3.new(unpack(theme.Color)); swatch.Parent = frame; UI.corner(swatch, 10)
        UI.eyebrow(frame, if self.State.Theme == theme.Id then "✓ Your current signature" elseif self.State.Themes[theme.Id] then "In your collection" else "Make it yours • " .. money(theme.Cost))
        self:button(frame, if self.State.Themes[theme.Id] then "Use this theme" else "Unlock theme · " .. money(theme.Cost), "Upgrade", {Kind = "Theme", Theme = theme.Id}, self.State.Themes[theme.Id])
    end
    self:nav(self.UI.Content, "Visit the cosmetic boutique", "Boutique")
end
function Pages:decorPage()
    UI.label(self:card(), "Layer in a little personality. Pick a piece, then arrange the floor decorations to make the room yours.", 17)
    for _, decoration in ipairs(Config.Decorations) do
        local frame = self:card(decoration.Name)
        UI.eyebrow(frame, if self.State.PlacedDecor[decoration.Id] then "On display" elseif self.State.Decorations[decoration.Id] then "In storage" else money(decoration.Cost))
        local label = if self.State.PlacedDecor[decoration.Id] then "Put away" elseif self.State.Decorations[decoration.Id] then "Place decoration" else "Buy & place · " .. money(decoration.Cost)
        self:button(frame, label, "Upgrade", {Kind = "Decor", Decor = decoration.Id}, self.State.Decorations[decoration.Id])
        if self.State.PlacedDecor[decoration.Id] and table.find({"Rug", "Plant", "Trophy"}, decoration.Id) then self:nav(frame, "Arrange position", "Arrange", {Decor = decoration.Id}) end
    end
end
function Pages:questsPage()
    local state = self.State
    UI.hero(self.UI.Content, "Little goals. Lovely rewards.", "A little progress, every day.", "Find something. Fix something. Make someone's day.")
    local definitions = {{"Find", "Find 3 new stories", "Found", 3, 65}, {"Restore", "Restore 3 forgotten finds", "Restored", 3, 100}, {"Sell", "Send 3 finds to new homes", "Sold", 3, 150}}
    for _, definition in ipairs(definitions) do
        local frame = self:card(definition[2]); local progress = math.min(definition[4], state.Daily[definition[3]] or 0)
        UI.label(frame, progress .. " / " .. definition[4] .. " • " .. money(definition[5]) .. " reward", 16, UI.Colors.Muted)
        UI.progress(frame, progress / definition[4])
        if state.Daily.Claimed[definition[1]] then UI.disabled(frame, "✓ Collected — beautifully done")
        elseif progress >= definition[4] then self:button(frame, "Collect " .. money(definition[5]), "Quest", {Id = definition[1]})
        else UI.disabled(frame, "Keep going — " .. (definition[4] - progress) .. " to go") end
    end
    local weekly = self:card("The weekly workshop challenge")
    UI.label(weekly, "Restore " .. math.min(20, state.Weekly.Restored) .. "/20 • Sell " .. math.min(15, state.Weekly.Sold) .. "/15", 17)
    UI.progress(weekly, (math.min(20, state.Weekly.Restored) / 20 + math.min(15, state.Weekly.Sold) / 15) / 2, UI.Colors.Gold)
    if state.Weekly.Claimed then UI.disabled(weekly, "✓ Weekly Wonder title earned")
    elseif state.Weekly.Restored >= 20 and state.Weekly.Sold >= 15 then self:button(weekly, "Collect $1,200 + Weekly Wonder", "Quest", {Id = "Weekly"})
    else UI.label(weekly, "$1,200 and a title for a week of good work.", 16, UI.Colors.Muted) end
    self:nav(weekly, "What's happening this season?", "Events")
    self:timer(weekly, "Daily reset in ", (state.Day + 1) * 86400)
end
function Pages:collectionPage()
    local total = 0; for _ in pairs(self.State.Collection) do total += 1 end
    local hero = UI.hero(self.UI.Content, "The collector's journal", total .. " / 400 discoveries", "Every rarity has a story. Discover 10 new combinations to earn $100.")
    UI.progress(hero, total / 400, UI.Colors.Gold)
    local tabs = self:card()
    local categories = Catalog.Categories
    local index = table.find(categories, self.CollectionCategory) or 1
    local row = UI.row(tabs)
    UI.rowButton(row, "‹", function() self.CollectionCategory = categories[(index - 2) % #categories + 1]; self.Open("Collection") end, 3, true)
    UI.rowButton(row, self.CollectionCategory, function() end, 3, true)
    UI.rowButton(row, "›", function() self.CollectionCategory = categories[index % #categories + 1]; self.Open("Collection") end, 3, true)
    local grid = UI.grid(self.UI.Content, 258, 183)
    for _, definition in ipairs(Catalog.Items) do
        if definition.Category == self.CollectionCategory then
            local highest, found = 1, false
            local stamps = {}
            for rarity = 1, 5 do
                local discovered = self.State.Collection[definition.Id .. ":" .. rarity]
                if discovered then highest = rarity; found = true end
                table.insert(stamps, if discovered then Config.RarityIcons[rarity] else "–")
            end
            local previewItem = {DefId = definition.Id, Rarity = highest, Condition = 5, Style = definition.Style, Inspected = found, Value = 0}
            local tile = self:itemTile(grid, previewItem, table.concat(stamps, "   "), function()
                self.UI:notice(if found then definition.Name .. " · keep collecting to discover every rarity." else "Find this design to reveal its place in your collection.")
            end)
            if tile then
                local detail = tile:FindFirstChild("Label")
                if detail then detail.Text = if found then definition.Name else "Undiscovered design" end
            end
        end
    end
end
