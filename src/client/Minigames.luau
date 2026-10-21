local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Minigames = {}
local descriptions = {
    Scrub = "Swipe over every dirty tile to scrub away the grime.",
    Polish = "Trace the shine: follow the numbered path, one tile at a time.",
    Rewire = "Connect pairs of matching wire symbols. Tap one end, then its matching partner.",
    Repaint = "Choose the requested paint, then swipe to fill every tile.",
    Assemble = "Pick a numbered piece from the tray, then fit it in the matching outline.",
}
function Minigames.start(ui, UI, challenge, send, config)
    ui.Locked = true
    ui:clear(challenge.Kind .. " · restoration")
    local card = UI.card(ui.Content)
    UI.label(card, descriptions[challenge.Kind], 17)
    UI.label(card, "8–20 seconds · every result improves condition", 14, UI.Colors.Muted)
    local meter = UI.label(card, "0 / 16 · Take your time", 18, UI.Colors.Teal)
    local clock = UI.label(card, "20s left", 16)
    if challenge.Kind == "Repaint" then
        UI.label(card, "Requested paint: " .. config.Styles[challenge.RequiredPalette], 18)
        for index, style in ipairs(config.Styles) do
            UI.button(card, style, function() send("RestoreInput", {Token = challenge.Token, Palette = index}) end, true)
        end
    end
    local selectedLabel
    local pieceTray
    if challenge.Kind == "Assemble" then
        selectedLabel = UI.label(card, "Select a piece from the tray", 17)
        pieceTray = Instance.new("Frame"); pieceTray.Size = UDim2.new(1, 0, 0, 170); pieceTray.BackgroundTransparency = 1; pieceTray.Parent = card
        local trayGrid = Instance.new("UIGridLayout"); trayGrid.CellSize = UDim2.new(0.25, -5, 0.25, -4); trayGrid.CellPadding = UDim2.fromOffset(5, 4); trayGrid.Parent = pieceTray
    end
    local board = Instance.new("Frame"); board.Size = UDim2.new(1, 0, 0, 250); board.BackgroundTransparency = 1; board.Parent = card
    local grid = Instance.new("UIGridLayout"); grid.CellSize = UDim2.new(0.25, -6, 0.25, -6); grid.CellPadding = UDim2.fromOffset(6, 6); grid.SortOrder = Enum.SortOrder.LayoutOrder; grid.Parent = board
    local buttons, ranks = {}, {}
    for rank, cell in ipairs(challenge.Targets) do ranks[cell] = rank end
    local session = {Ui = ui, Token = challenge.Token, Buttons = buttons, Meter = meter, Active = true, Connections = {}}
    if pieceTray then
        for piece = 1, 16 do
            UI.button(pieceTray, tostring(piece), function()
                session.Piece = piece; selectedLabel.Text = "Piece " .. piece .. " selected → tap its outline"
            end, true)
        end
    end
    local dragging = false
    local lastCell, lastAt = nil, 0
    local function hit(index)
        if not session.Active then return end
        if buttons[index] and buttons[index].Text == "✓" then return end
        if lastCell == index and os.clock() - lastAt < 0.2 then return end
        lastCell = index; lastAt = os.clock()
        send("RestoreInput", {Token = challenge.Token, Cell = index, Piece = session.Piece})
    end
    for cell = 1, 16 do
        local text = if challenge.Kind == "Scrub" then "✦" elseif challenge.Kind == "Repaint" then "□" else tostring(ranks[cell])
        if challenge.Kind == "Rewire" then
            local symbols = {"●", "▲", "■", "◆", "★", "✚", "○", "☀"}
            text = symbols[math.ceil(ranks[cell] / 2)]
        end
        local button = UI.button(board, text, function() hit(cell) end, true); button.LayoutOrder = cell
        button.TextSize = 24; buttons[cell] = button
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; hit(cell) end
        end)
        button.MouseEnter:Connect(function() if dragging then hit(cell) end end)
    end
    table.insert(session.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    table.insert(session.Connections, UserInputService.TouchMoved:Connect(function(input)
        if not dragging then return end
        for index, button in ipairs(buttons) do
            local p, s = button.AbsolutePosition, button.AbsoluteSize
            if input.Position.X >= p.X and input.Position.X <= p.X + s.X and input.Position.Y >= p.Y and input.Position.Y <= p.Y + s.Y then hit(index); break end
        end
    end))
    local started = os.clock()
    local finish = UI.button(card, "Finish (available after 8s)", function()
        if os.clock() - started >= 8 then send("FinishRestore", {Token = challenge.Token}) end
    end)
    UI.button(card, "Cancel", function() send("CancelRestore", {}) end, true)
    table.insert(session.Connections, RunService.Heartbeat:Connect(function()
        if not session.Active then return end
        local elapsed = os.clock() - started
        clock.Text = tostring(math.max(0, math.ceil(challenge.Duration - elapsed))) .. "s left"
        finish.Text = if elapsed >= 8 then "Finish restoration" else "Ready in " .. math.ceil(8 - elapsed) .. "s"
    end))
    return session
end
function Minigames.progress(session, data, UI)
    if not session or not session.Active then return end
    session.Meter.Text = data.Progress .. " / 16 · " .. data.Mistakes .. " slips"
    if data.Selected then
        session.Buttons[data.Cell].BackgroundColor3 = UI.Colors.Gold
        return
    end
    if data.Other and session.Buttons[data.Other] then
        local other = session.Buttons[data.Other]
        other.BackgroundColor3 = if data.Valid then UI.Colors.Teal else Color3.fromRGB(232, 230, 211)
        if data.Valid then other.Text = "✓"; other.TextColor3 = UI.Colors.Panel end
    end
    if data.Valid and session.Buttons[data.Cell] then
        session.Buttons[data.Cell].BackgroundColor3 = UI.Colors.Teal
        session.Buttons[data.Cell].TextColor3 = UI.Colors.Panel
        session.Buttons[data.Cell].Text = "✓"
    end
end
function Minigames.stop(session)
    if not session then return end
    session.Active = false
    session.Ui.Locked = false
    for _, connection in ipairs(session.Connections) do connection:Disconnect() end
end
return Minigames
