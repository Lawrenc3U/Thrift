local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local UI = require(script.Parent.UI)
local Pages = require(script.Parent.Pages)
local Audio = require(script.Parent.Audio)
local Minigames = require(script.Parent.Minigames)
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game")
local player = Players.LocalPlayer
local ui = UI.new()
local audio = Audio.new()
ui.playSound = function(_, name) audio:play(name) end
UI.OnClick = function() audio:play("click") end

local state, page, context, session
local pages
local marker = Instance.new("Part")
marker.Name = "LocalGuide"; marker.Size = Vector3.one; marker.Anchored = true
marker.CanCollide = false; marker.CanTouch = false; marker.CanQuery = false; marker.Transparency = 1; marker.Parent = workspace
local billboard = Instance.new("BillboardGui")
billboard.Name = "Guide"; billboard.Size = UDim2.fromOffset(230, 62); billboard.AlwaysOnTop = true; billboard.Parent = marker
local guideText = UI.label(billboard, "YOUR NEXT STEP", 20, UI.Colors.Gold)
guideText.Size = UDim2.fromScale(1, 1); guideText.AutomaticSize = Enum.AutomaticSize.None; guideText.TextXAlignment = Enum.TextXAlignment.Center
local locations = {Source=Vector3.new(-82,8,-60),Estate=Vector3.new(68,8,-80),Delivery=Vector3.new(68,8,-35),
    Auction=Vector3.new(0,12,137),Market=Vector3.new(0,9,-90),Quests=Vector3.new(-26,8,-30),Workbench=Vector3.new(-40,8,-90)}
local guideExpires = 0
local function guide(location)
    local target = locations[location]
    if location == "Shop" then
        for _, shop in ipairs(state and state.Shops or {}) do
            if shop.UserId == player.UserId and shop.Plot then
                local left = shop.Plot <= 4
                local row = if left then shop.Plot - 1 else shop.Plot - 5
                target = Vector3.new(if left then -37 else 37, 12, row * 34)
                break
            end
        end
    end
    if target then
        marker.Position = target; guideText.Text = "NEXT: " .. string.upper(location); billboard.Enabled = true
        guideExpires = if state and state.Tutorial < 5 then math.huge else os.clock() + 30
    end
end

local function send(action, payload) event:FireServer(action, payload or {}) end
local function render()
    if not state or session then return end
    pages:setState(state); pages:render(page or "Town", context or {})
    ui:selectNav(page or "Town")
end
local function open(name, data)
    if session then ui:notice("Finish or cancel your restoration first."); return end
    page, context = name, data or {}; render()
end
pages = Pages.new(ui, send, open, guide)
for _, entry in ipairs({{"Town","home"},{"Bag","bag"},{"Shop","shop"},{"Find","search"},{"Quests","quests"}}) do
    ui:addNav(entry[1], entry[2], function() open(if entry[1] == "Find" then "Source" else entry[1]) end)
end
ui:addQuickAction("Travel", "travel", UI.Colors.Teal, function() open("Town") end)
local rewardsButton = ui:addQuickAction("Rewards", "gift", UI.Colors.Rose, function() open("Quests") end)
ui:addQuickAction("Store", "store", Color3.fromRGB(122, 92, 224), function() open("Boutique") end)
ui:addMoreAction("Style", "style", function() open("Themes") end)
ui:addMoreAction("Tools", "tools", function() open("Tools") end)
ui:addMoreAction("Expand", "expand", function() open("Expand") end)
ui:addMoreAction("Audio", "settings", function() open("Settings") end)
ui.AuctionBar.Activated:Connect(function() open("Auction") end)

local tutorialHints = {
    [0]="Find your first treasure in Dumpster Alley", [1]="Open your bag and inspect the mystery find",
    [2]="Restore it at your shop workbench", [3]="Place it on one of your displays",
    [4]="Open Shop and welcome your first customer",
}
local function nextObjective()
    if tutorialHints[state.Tutorial] then return tutorialHints[state.Tutorial] end
    if state.Held then return "Show off your find, then return it to your bag" end
    local daily = state.Daily
    if daily and ((daily.Found or 0) >= 3 and not daily.Claimed.Find
        or (daily.Restored or 0) >= 3 and not daily.Claimed.Restore
        or (daily.Sold or 0) >= 3 and not daily.Claimed.Sell) then
        return "A daily quest reward is ready to collect"
    end
    local nextTier = Config.Tiers[state.Tier + 1]
    if nextTier then
        if state.Level < nextTier.Level then return "Reach LV " .. nextTier.Level .. " to unlock " .. nextTier.Name end
        if state.AvailableCash < nextTier.Cost then return "Earn $" .. (nextTier.Cost - state.AvailableCash) .. " more for " .. nextTier.Name end
        return "Your " .. nextTier.Name .. " upgrade is ready"
    end
    local discoveries = 0; for _ in pairs(state.Collection or {}) do discoveries += 1 end
    return discoveries .. "/400 discoveries | hunt for a new " .. state.Demand .. " find"
end
local lastOffer, pendingOffer, lastTutorial, adminButton
local function updateHud()
    ui.Balance.Text = tostring(math.floor(state.Cash))
    ui.Level.Text = "LV " .. state.Level
    local levelStart, levelEnd = 30 * (state.Level - 1) ^ 2, 30 * state.Level ^ 2
    ui.LevelProgress.Size = UDim2.fromScale(math.clamp((state.XP - levelStart) / math.max(1, levelEnd - levelStart), 0, 1), 1)
    ui.Hint.Text = nextObjective()
    local auctionDefinition = state.Auction and state.Auction.Item and Catalog.ById[state.Auction.Item.DefId]
    ui:updateAuction(state.Auction, auctionDefinition and auctionDefinition.Name or nil, state.ServerTime)
    local daily = state.Daily or {Claimed = {}}
    local claimed = daily.Claimed or {}
    local weekly = state.Weekly or {}
    local rewardsReady = (state.Login and state.Login.ClaimedDay ~= state.Day)
        or ((daily.Found or 0) >= 3 and not claimed.Find)
        or ((daily.Restored or 0) >= 3 and not claimed.Restore)
        or ((daily.Sold or 0) >= 3 and not claimed.Sell)
        or ((weekly.Restored or 0) >= 20 and (weekly.Sold or 0) >= 15 and not weekly.Claimed)
    ui:setActionBadge(rewardsButton, rewardsReady == true)
    if state.Tutorial < 5 then ui.ObjectiveTitle.Text = "OBJECTIVE | 0/1"
    elseif not claimed.Find then ui.ObjectiveTitle.Text = "DAILY FIND | " .. math.min(3, daily.Found or 0) .. "/3"
    elseif not claimed.Restore then ui.ObjectiveTitle.Text = "DAILY RESTORE | " .. math.min(3, daily.Restored or 0) .. "/3"
    elseif not claimed.Sell then ui.ObjectiveTitle.Text = "DAILY SELL | " .. math.min(3, daily.Sold or 0) .. "/3"
    else ui.ObjectiveTitle.Text = "OBJECTIVE" end
    ui:setSubtitle(if state.Ephemeral then "STUDIO PRACTICE | PROGRESS DOES NOT SAVE" else "YOUR COZY CORNER OF THRIFT STREET")
    ui.Effects = state.Settings.Effects
    audio:setEnabled(state.Settings.Music, state.Settings.Effects, state.Settings.TownMusic, state.Settings.AuctionMusic)
    audio:setZone(page == "Auction" and "auction_music" or page == "Town" and "town" or "shop")
end

event.OnClientEvent:Connect(function(kind, payload)
    if kind == "State" then
        local wasVisible = ui.Panel.Visible; local oldCash = state and state.Cash or payload.Cash
        state = payload; updateHud()
        if state.IsAdmin and not adminButton then
            adminButton = ui:addMoreAction("Admin", "admin", function() open("Admin") end)
        end
        if state.Cash > oldCash then ui:cashFeedback(state.Cash - oldCash); audio:play("sale") end
        if state.Tutorial ~= lastTutorial then
            lastTutorial = state.Tutorial
            if state.Tutorial == 0 then guide("Source")
            elseif state.Tutorial == 1 then billboard.Enabled = false; open("Bag")
            elseif state.Tutorial >= 2 and state.Tutorial <= 4 then guide("Shop")
            else billboard.Enabled = false end
        end
        local offerId = state.Offer and state.Offer.Uid or nil
        if offerId and offerId ~= lastOffer then
            lastOffer = offerId; ui:notice(state.Offer.Customer .. " has made you an offer!"); audio:play("reveal")
            if session then pendingOffer = offerId else open("Offer") end
        elseif not offerId then
            lastOffer = nil; pendingOffer = nil
            if page == "Offer" then ui:hide(); page = "Town"; wasVisible = false end
        end
        if wasVisible and not session then render() end
    elseif kind == "Notice" then ui:notice(payload)
    elseif kind == "Announcement" then ui:notice("NOTICE: " .. tostring(payload)); audio:play("reward")
    elseif kind == "Reveal" then
        local item = payload and payload.Item
        local definition = item and Catalog.ById[item.DefId]
        if definition then
            audio:play(if item.Rarity >= 4 then "reward" else "reveal")
            ui:rarityReveal(definition, item, function() open("Item", {Uid = item.Uid}) end)
        end
    elseif kind == "Open" then
        if payload.Page == "Visit" then open("Visit", {Owner=payload.Owner})
        elseif payload.Page == "Display" then open("Display", {Slot=payload.Slot})
        elseif payload.Page == "Market" then open("Market") else open(payload.Page) end
    elseif kind == "Minigame" then
        Minigames.stop(session); session = Minigames.start(ui, UI, payload, send, Config); audio:play("restore")
    elseif kind == "MinigameProgress" then Minigames.progress(session, payload, UI)
    elseif kind == "MinigameDone" then
        Minigames.stop(session); session = nil
        if payload.Cancelled then ui:notice("Restoration paused. Your find is safe.")
        else ui:notice(payload.Quality .. " restoration | now " .. payload.Condition); audio:play("reward") end
        if pendingOffer and state and state.Offer and state.Offer.Uid == pendingOffer then
            pendingOffer = nil; open("Offer")
        else page = "Bag"; render() end
    end
end)
task.spawn(function() while not state do send("Sync", {}); task.wait(2) end end)
RunService.Heartbeat:Connect(function() if billboard.Enabled and os.clock() > guideExpires then billboard.Enabled = false end end)
