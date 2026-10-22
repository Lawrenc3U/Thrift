local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
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
local guideText = UI.label(billboard, "▼ YOUR NEXT STEP", 20, UI.Colors.Gold)
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
    if target then marker.Position = target; guideText.Text = "▼ " .. string.upper(location); billboard.Enabled = true; guideExpires = os.clock() + 30 end
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
for _, entry in ipairs({{"Town","⌂"},{"Bag","▣"},{"Shop","✦"},{"Find","⌕"},{"Quests","✓"}}) do
    ui:addNav(entry[1], entry[2], function() open(if entry[1] == "Find" then "Source" else entry[1]) end)
end
ui:addQuickAction("ϟ\nTravel", UI.Colors.Teal, function() open("Town") end)
ui:addQuickAction("▣\nRewards", UI.Colors.Rose, function() open("Quests") end)
ui:addQuickAction("◇\nStore", Color3.fromRGB(122, 92, 224), function() open("Boutique") end)

local tutorialHints = {
    [0]="Find your first treasure in Dumpster Alley", [1]="Open your bag and inspect the mystery find",
    [2]="Restore it at your shop workbench", [3]="Place it on one of your displays",
    [4]="Open Shop and welcome your first customer",
}
local lastOffer, lastTutorial
local function updateHud()
    ui.Balance.Text = tostring(math.floor(state.Cash))
    ui.Level.Text = "LV " .. state.Level
    local levelStart, levelEnd = 30 * (state.Level - 1) ^ 2, 30 * state.Level ^ 2
    ui.LevelProgress.Size = UDim2.fromScale(math.clamp((state.XP - levelStart) / math.max(1, levelEnd - levelStart), 0, 1), 1)
    ui.Hint.Text = tutorialHints[state.Tutorial] or (state.Demand .. " finds are trending  •  Reputation " .. state.Reputation)
    ui:setSubtitle(if state.Ephemeral then "STUDIO PRACTICE • PROGRESS DOES NOT SAVE" else "YOUR COZY CORNER OF THRIFT STREET")
    ui.Effects = state.Settings.Effects
    audio:setEnabled(state.Settings.Music, state.Settings.Effects)
    audio:setZone(page == "Auction" and "auction_music" or page == "Town" and "town" or "shop")
end

event.OnClientEvent:Connect(function(kind, payload)
    if kind == "State" then
        local wasVisible = ui.Panel.Visible; local oldCash = state and state.Cash or payload.Cash
        state = payload; updateHud()
        if state.Cash > oldCash then ui:cashFeedback(state.Cash - oldCash); audio:play("sale") end
        if state.Tutorial ~= lastTutorial then
            lastTutorial = state.Tutorial
            if state.Tutorial == 0 then guide("Source") elseif state.Tutorial >= 2 and state.Tutorial <= 4 then guide("Shop") end
        end
        if state.Offer and state.Offer.Uid ~= lastOffer then ui:notice(state.Offer.Customer .. " is browsing your shop!"); audio:play("reveal") end
        lastOffer = state.Offer and state.Offer.Uid or nil
        if wasVisible and not session then render() end
    elseif kind == "Notice" then ui:notice(payload)
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
        else ui:notice(payload.Quality .. " restoration • now " .. payload.Condition); audio:play("reward") end
        page = "Bag"; render()
    end
end)
task.spawn(function() while not state do send("Sync", {}); task.wait(2) end end)
RunService.Heartbeat:Connect(function() if billboard.Enabled and os.clock() > guideExpires then billboard.Enabled = false end end)
