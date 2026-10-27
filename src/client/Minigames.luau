local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Minigames = {}
local descriptions = {
    Scrub = {Title = "Wash away the wear", Instruction = "Hold and sweep across every stained patch until the fabric looks fresh.", Tool = "GARMENT BRUSH"},
    Polish = {Title = "Steam every crease", Instruction = "Trace the numbered steam path, starting at 1. Slow, smooth strokes work best.", Tool = "HAND STEAMER"},
    Rewire = {Title = "Stitch the seams", Instruction = "Join matching thread symbols. Drag between a pair, or tap each end.", Tool = "SEWING KIT"},
    Repaint = {Title = "A fresh color", Instruction = "Choose the requested dye, then brush across every fabric section.", Tool = "FABRIC DYE"},
    Assemble = {Title = "Mend it piece by piece", Instruction = "Drag a pattern piece to its matching outline, or select it and tap the outline.", Tool = "MENDING KIT"},
}
local paintColors = {
    Color3.fromRGB(210, 141, 103), Color3.fromRGB(127, 174, 145), Color3.fromRGB(121, 158, 199),
    Color3.fromRGB(190, 157, 91), Color3.fromRGB(214, 151, 166),
}
local wireColors = {
    Color3.fromRGB(230, 141, 115), Color3.fromRGB(112, 186, 170), Color3.fromRGB(232, 190, 102),
    Color3.fromRGB(147, 164, 221), Color3.fromRGB(200, 153, 198), Color3.fromRGB(133, 191, 126),
    Color3.fromRGB(114, 183, 210), Color3.fromRGB(231, 169, 112),
}
local wireSymbols = {"1", "2", "3", "4", "5", "6", "7", "8"}
local pieceSymbols = {"A", "B", "C", "D"}

local function corner(object, amount)
    local value = Instance.new("UICorner")
    value.CornerRadius = UDim.new(0, amount)
    value.Parent = object
end
local function stroke(object, color, thickness, transparency)
    local value = Instance.new("UIStroke")
    value.Color = color
    value.Thickness = thickness or 1
    value.Transparency = transparency or 0
    value.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    value.Parent = object
    return value
end
local function text(parent, value, size, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = value
    label.Font = Enum.Font.GothamMedium
    label.TextSize = size
    label.TextColor3 = color
    label.TextWrapped = true
    label.Size = UDim2.fromScale(1, 1)
    label.Parent = parent
    return label
end
local function frame(parent, color, position, size, radius)
    local value = Instance.new("Frame")
    value.BackgroundColor3 = color
    value.BorderSizePixel = 0
    value.Position = position or UDim2.new()
    value.Size = size or UDim2.fromScale(1, 1)
    value.Parent = parent
    if radius then corner(value, radius) end
    return value
end
local function ease(object, duration, properties)
    if object and object.Parent then
        TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
    end
end
local function listen(session, signal, callback)
    local connection = signal:Connect(callback)
    table.insert(session.Connections, connection)
    return connection
end
local function isPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
local function isActivation(input)
    return not input or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch)
end
local function localPoint(session, screenPosition)
    local point = Vector2.new(screenPosition.X, screenPosition.Y)
    if not session.Ui.Gui.IgnoreGuiInset then
        local inset = GuiService:GetGuiInset()
        point -= inset
    end
    return point
end
local function inside(point, object)
    local p, s = object.AbsolutePosition, object.AbsoluteSize
    return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
end
local function atCell(session, point)
    for index, button in ipairs(session.Buttons) do
        if button.Visible and inside(point, button) then return index end
    end
    return nil
end
local function sound(session, name)
    if session.Ui.playSound then session.Ui:playSound(name) end
end

local function preview(parent, challenge, config)
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local modelModule = shared and shared:FindFirstChild("ItemModels")
    local catalogModule = shared and shared:FindFirstChild("Catalog")
    local item = challenge.Item
    if not modelModule or not catalogModule or not item then return nil end
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "RestorationPreview"
    viewport.BackgroundTransparency = 1
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.Ambient = Color3.fromRGB(197, 190, 170)
    viewport.LightColor = Color3.fromRGB(255, 244, 217)
    viewport.LightDirection = Vector3.new(-1, -1.5, -0.6)
    viewport.Parent = parent
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    local camera = Instance.new("Camera")
    camera.FieldOfView = 34
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    local ok = pcall(function()
        local catalog = require(catalogModule)
        local definition = catalog.ById[challenge.DefId or item.DefId]
        if not definition then error("Missing item definition") end
        local model = require(modelModule).create(world, definition, item, CFrame.new(), config)
        local cf, size = model:GetBoundingBox()
        local extent = math.max(size.X, size.Y, size.Z, 1)
        local center = cf.Position
        -- Authored item fronts face -Z, so restoration should show the controls,
        -- clock faces and camera lenses rather than their backs.
        camera.CFrame = CFrame.lookAt(center + Vector3.new(extent * 0.85, extent * 0.45, -extent * 1.7), center)
    end)
    if not ok then viewport:Destroy(); return nil end
    return viewport
end

local function line(parent, from, to, color, thickness, zindex)
    local delta = to - from
    local result = frame(parent, color, UDim2.fromScale((from.X + to.X) / 2, (from.Y + to.Y) / 2), UDim2.new(0, 1, 0, thickness or 3), 3)
    result.AnchorPoint = Vector2.new(0.5, 0.5)
    result.ZIndex = zindex or 4
    local function layout()
        local size = parent.AbsoluteSize
        local dx, dy = delta.X * size.X, delta.Y * size.Y
        result.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), thickness or 3)
        result.Rotation = math.deg(math.atan2(dy, dx))
    end
    layout()
    return result, layout
end

local function setPiece(session, piece)
    if session.Done[session.Challenge.Targets[piece]] then return end
    session.Piece = piece
    if session.PieceLabel then session.PieceLabel.Text = "PIECE " .. piece .. " SELECTED  ·  FIND ITS OUTLINE" end
    for index, button in pairs(session.PieceButtons) do
        local selected = index == piece
        button.BackgroundColor3 = if selected then session.Colors.Teal else session.Colors.Panel
        button.TextColor3 = if selected then session.Colors.Panel else session.Colors.Ink
    end
end

local function updatePieces(session)
    local remaining = {}
    for piece = 1, 16 do
        if not session.Done[session.Challenge.Targets[piece]] then table.insert(remaining, piece) end
    end
    local selectedStillExists = table.find(remaining, session.Piece)
    if #remaining > 0 and not selectedStillExists then session.Piece = remaining[1] end
    for piece, button in pairs(session.PieceButtons) do
        local index = table.find(remaining, piece)
        button.Visible = index ~= nil and index <= 4
        if button.Visible then
            button.Position = UDim2.new((index - 1) / 4, 3, 0, 2)
        end
    end
    if #remaining > 0 then setPiece(session, session.Piece)
    elseif session.PieceLabel then session.PieceLabel.Text = "ALL PIECES FIT · BEAUTIFULLY DONE" end
end

local function updateWireStage(session)
    if session.Kind ~= "Rewire" then return end
    local stage = if session.Progress >= 8 then 2 else 1
    session.WireStage = stage
    for cell, button in ipairs(session.Buttons) do
        local pair = math.ceil(session.Ranks[cell] / 2)
        button.Visible = math.ceil(pair / 4) == stage
    end
    for _, wire in ipairs(session.Wires) do wire.Line.Visible = wire.Stage == stage end
    session.StageLabel.Text = if session.Progress >= 16 then "ALL CIRCUITS CONNECTED" else "CIRCUIT " .. stage .. " / 2 · MATCH THE SYMBOLS"
end

local function enqueue(session, cell)
    if not session.Active or session.Finishing or not cell or session.Done[cell] or session.PendingCells[cell] then return end
    if session.Kind == "Assemble" and not session.Piece then return end
    if session.Kind == "Repaint" and not session.SelectedPalette then
        session.Status.Text = "Choose a paint color first."
        return
    end
    if session.Kind == "Rewire" and session.LocalWireStart == cell then return end
    session.PendingCells[cell] = true
    table.insert(session.Queue, {Cell = cell, Piece = session.Piece})
    if session.Kind == "Rewire" then
        session.LocalWireStart = if session.LocalWireStart then nil else cell
    end
end

local function selectPalette(session, index)
    session.SelectedPalette = index
    -- Palette selection uses the same outgoing queue as tile strokes, so a quick
    -- brush gesture cannot arrive at the server before the palette message.
    table.insert(session.Queue, {Palette = index})
    for i, button in ipairs(session.PaletteButtons) do
        local selected = i == index
            button.Text = (if selected then "OK  " else "") .. session.Config.Styles[i]
        session.PaletteStrokes[i].Thickness = if selected then 3 else 1
        session.PaletteStrokes[i].Color = if selected then session.Colors.Ink else Color3.fromRGB(255, 249, 234)
    end
    session.Status.Text = if index == session.Challenge.RequiredPalette then "Perfect palette. Brush each section." else "Requested finish: " .. session.Config.Styles[session.Challenge.RequiredPalette]
end

function Minigames.start(ui, UI, challenge, send, config)
    ui.Locked = true
    ui:clear(challenge.Kind .. " · restoration")
    local info = descriptions[challenge.Kind] or descriptions.Scrub
    local session = {
        Ui = ui, Challenge = challenge, Config = config, Token = challenge.Token,
        Kind = challenge.Kind, Colors = UI.Colors, Send = send, Active = true,
        Connections = {}, Queue = {}, PendingCells = {}, PendingAt = {}, Done = {},
        Buttons = {}, Ranks = {}, CellStyles = {}, PieceButtons = {}, PaletteButtons = {}, PaletteStrokes = {},
        Wires = {}, LineLayouts = {}, Progress = 0, Mistakes = 0, LastSend = -1,
        Started = os.clock(), WireStage = 1, ScrollEnabled = ui.Content.ScrollingEnabled,
    }
    for rank, cell in ipairs(challenge.Targets) do session.Ranks[cell] = rank end
    local card = UI.card(ui.Content)
    session.Card = card
    local heading = UI.label(card, info.Title, 20, UI.Colors.Ink)
    heading.Font = Enum.Font.GothamBold
    local instruction = UI.label(card, info.Instruction, 15, UI.Colors.Muted)
    instruction.Size = UDim2.new(1, 0, 0, 36)
    local tool = UI.label(card, info.Tool .. "  ·  TOOL LEVEL " .. (challenge.Tool or 0), 12, UI.Colors.Teal)
    tool.Font = Enum.Font.GothamBold
    tool.Size = UDim2.new(1, 0, 0, 20)

    local meterRow = frame(card, UI.Colors.Panel, nil, UDim2.new(1, 0, 0, 28))
    meterRow.BackgroundTransparency = 1
    session.Meter = text(meterRow, "0% RESTORED", 14, UI.Colors.Teal)
    session.Meter.Font = Enum.Font.GothamBold
    session.Meter.Size = UDim2.new(0.65, 0, 1, 0)
    session.Meter.TextXAlignment = Enum.TextXAlignment.Left
    session.Clock = text(meterRow, "20s", 18, UI.Colors.Ink)
    session.Clock.Size = UDim2.new(0.35, 0, 1, 0)
    session.Clock.Position = UDim2.fromScale(0.65, 0)
    session.Clock.TextXAlignment = Enum.TextXAlignment.Right
    local progressTrack = frame(card, Color3.fromRGB(223, 225, 209), nil, UDim2.new(1, 0, 0, 7), 4)
    session.ProgressBar = frame(progressTrack, UI.Colors.Teal, nil, UDim2.fromScale(0, 1), 4)

    local board = frame(card, Color3.fromRGB(222, 209, 184), nil, UDim2.new(1, 0, 0, 260), 14)
    board.Name = "RestorationBoard"
    board.ClipsDescendants = true
    board.Active = true
    session.Board = board
    stroke(board, Color3.fromRGB(194, 174, 144), 1)
    -- Warm workbench grain is intentionally subtle so targets stay readable.
    for index = 1, 7 do
        local grain = frame(board, Color3.fromRGB(183, 159, 125), UDim2.new(0, 0, index / 8, 0), UDim2.new(1, 0, 0, 1))
        grain.BackgroundTransparency = 0.77
    end
    local previewArea = frame(board, UI.Colors.Panel, UDim2.fromScale(0.08, 0.04), UDim2.fromScale(0.84, 0.92), 30)
    previewArea.BackgroundTransparency = 0.83
    local viewport = preview(previewArea, challenge, config)
    if not viewport then
    local fallback = text(previewArea, "ITEM", 42, Color3.fromRGB(177, 150, 104))
        fallback.TextTransparency = 0.45
    end
    if challenge.Kind == "Rewire" then
        local circuit = frame(board, Color3.fromRGB(50, 77, 68), UDim2.fromScale(0.04, 0.035), UDim2.fromScale(0.92, 0.93), 12)
        circuit.BackgroundTransparency = 0.08
        for row = 1, 6 do
            local etched = frame(circuit, Color3.fromRGB(117, 150, 115), UDim2.fromScale(0.18, row / 7), UDim2.new(0.64, 0, 0, 1))
            etched.BackgroundTransparency = 0.72
        end
    end
    local targets = frame(board, UI.Colors.Panel, UDim2.fromScale(0.035, 0.025), UDim2.fromScale(0.93, 0.95))
    targets.BackgroundTransparency = 1
    session.Targets = targets

    local ranks = session.Ranks
    local centers = {}
    for cell = 1, 16 do
        if challenge.Kind == "Rewire" then
            local rank = ranks[cell]
            local pair = math.ceil(rank / 2)
            local localPair = (pair - 1) % 4
            local left = rank % 2 == 1
            local row = if left then localPair else (localPair * 3 + 1) % 4
            centers[cell] = Vector2.new(if left then 0.12 else 0.88, 0.125 + row * 0.25)
        else
            local column, row = (cell - 1) % 4, math.floor((cell - 1) / 4)
            centers[cell] = Vector2.new((column + 0.5) / 4, (row + 0.5) / 4)
        end
    end
    session.Centers = centers
    if challenge.Kind == "Polish" then
        for index = 1, #challenge.Targets - 1 do
            local route, layout = line(targets, centers[challenge.Targets[index]], centers[challenge.Targets[index + 1]], Color3.fromRGB(255, 242, 189), 5, 2)
            route.BackgroundTransparency = 0.28
            table.insert(session.LineLayouts, layout)
        end
    end

    local function beginPointer(cell, input)
        if not isPointer(input) or not session.Active then return end
        session.Pointer = input
        session.PointerKind = input.UserInputType
        session.PointerStartCell = cell
        session.LastPointer = localPoint(session, input.Position)
        session.Ui.Content.ScrollingEnabled = false
        if challenge.Kind ~= "Assemble" then enqueue(session, cell) end
    end
    for cell = 1, 16 do
        local button = Instance.new("TextButton")
        button.Name = "RestorationTarget" .. cell
        button.AnchorPoint = Vector2.new(0.5, 0.5)
        button.Position = UDim2.fromScale(centers[cell].X, centers[cell].Y)
        button.Size = if challenge.Kind == "Rewire" then UDim2.new(0.2, 0, 0.22, 0) else UDim2.new(0.25, -4, 0.25, -4)
        button.BackgroundColor3 = Color3.fromRGB(239, 232, 212)
        button.BackgroundTransparency = 0.15
        button.BorderSizePixel = 0
        button.Text = ""
        button.AutoButtonColor = false
        button.Selectable = true
        button.ZIndex = 5
        button.Parent = targets
        corner(button, if challenge.Kind == "Rewire" then 14 else 10)
        local outline = stroke(button, Color3.fromRGB(255, 247, 228), 1.5, 0.25)
        session.Buttons[cell] = button
        session.CellStyles[cell] = {Stroke = outline}
        if challenge.Kind == "Scrub" then
            button.BackgroundColor3 = Color3.fromRGB(143, 126, 91)
            button.BackgroundTransparency = 0.18
            for stain = 1, 5 do
                local speck = frame(button, Color3.fromRGB(103 + stain * 5, 95 + stain * 4, 67 + stain * 3),
                    UDim2.fromScale(((cell * 7 + stain * 3) % 9 + 1) / 12, ((cell * 3 + stain * 7) % 9 + 1) / 12),
                    UDim2.fromScale(0.1 + (stain % 3) * 0.08, 0.12 + ((cell + stain) % 3) * 0.08), 20)
                speck.BackgroundTransparency = 0.15
                speck.ZIndex = 6
            end
        elseif challenge.Kind == "Polish" then
            button.BackgroundTransparency = 0.63
            button.Text = tostring(ranks[cell])
            button.TextSize = 19
            button.Font = Enum.Font.GothamBold
            button.TextColor3 = UI.Colors.Ink
            outline.Transparency = 0.65
        elseif challenge.Kind == "Rewire" then
            local pair = math.ceil(ranks[cell] / 2)
            button.BackgroundColor3 = wireColors[pair]
            button.BackgroundTransparency = 0
            button.Text = wireSymbols[pair]
            button.Font = Enum.Font.GothamBold
            button.TextSize = 27
            button.TextColor3 = Color3.fromRGB(37, 58, 52)
            outline.Color = Color3.fromRGB(239, 241, 217)
            local socket = frame(button, Color3.fromRGB(30, 52, 45), UDim2.fromScale(0.43, 0.81), UDim2.fromScale(0.14, 0.08), 4)
            socket.ZIndex = 6
        elseif challenge.Kind == "Repaint" then
            button.BackgroundColor3 = Color3.fromRGB(230, 221, 202)
            button.BackgroundTransparency = 0.38
        local patch = text(button, "O", 24, Color3.fromRGB(168, 153, 125))
            patch.ZIndex = 6
            session.CellStyles[cell].Label = patch
        else
            button.BackgroundColor3 = Color3.fromRGB(118, 116, 101)
            button.BackgroundTransparency = 0.48
            button.Text = pieceSymbols[(ranks[cell] - 1) % #pieceSymbols + 1] .. " " .. ranks[cell]
            button.TextSize = 18
            button.Font = Enum.Font.GothamBold
            button.TextColor3 = Color3.fromRGB(255, 246, 216)
            outline.Transparency = 0.1
        end
        listen(session, button.InputBegan, function(input) beginPointer(cell, input) end)
        listen(session, button.Activated, function(input)
            -- Mouse/touch are handled on pointer down/up, so releasing after a
            -- long press never submits a duplicate stroke or mismatching wire.
            if isActivation(input) then enqueue(session, cell) end
        end)
        listen(session, button.SelectionGained, function() outline.Thickness = 3 end)
        listen(session, button.SelectionLost, function() outline.Thickness = 1.5 end)
    end

    if challenge.Kind == "Rewire" then
        session.StageLabel = UI.label(card, "CIRCUIT 1 / 2 · MATCH THE SYMBOLS", 12, UI.Colors.Teal)
        session.StageLabel.Font = Enum.Font.GothamBold
        session.StageLabel.Size = UDim2.new(1, 0, 0, 22)
        updateWireStage(session)
    elseif challenge.Kind == "Repaint" then
        local paintLabel = UI.label(card, "REQUESTED FINISH: " .. string.upper(config.Styles[challenge.RequiredPalette]), 12, UI.Colors.Teal)
        paintLabel.Font = Enum.Font.GothamBold
        paintLabel.Size = UDim2.new(1, 0, 0, 24)
        local palette = frame(card, UI.Colors.Panel, nil, UDim2.new(1, 0, 0, 48))
        palette.BackgroundTransparency = 1
        for index, style in ipairs(config.Styles) do
            local button = Instance.new("TextButton")
            button.Position = UDim2.new((index - 1) / #config.Styles, 2, 0, 0)
            button.Size = UDim2.new(1 / #config.Styles, -4, 1, 0)
            button.BackgroundColor3 = paintColors[index]
            button.BorderSizePixel = 0
            button.Text = style
            button.TextSize = 11
            button.TextWrapped = true
            button.TextColor3 = Color3.fromRGB(39, 52, 47)
            button.Font = Enum.Font.GothamBold
            button.Parent = palette
            corner(button, 10)
            session.PaletteButtons[index] = button
            session.PaletteStrokes[index] = stroke(button, Color3.fromRGB(255, 249, 234), 1)
            listen(session, button.Activated, function() if session.Active then selectPalette(session, index) end end)
        end
    elseif challenge.Kind == "Assemble" then
        session.PieceLabel = UI.label(card, "SELECT A PIECE, THEN ITS OUTLINE", 12, UI.Colors.Teal)
        session.PieceLabel.Size = UDim2.new(1, 0, 0, 22)
        session.PieceLabel.Font = Enum.Font.GothamBold
        local tray = frame(card, Color3.fromRGB(218, 206, 182), nil, UDim2.new(1, 0, 0, 54), 10)
        for piece = 1, 16 do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0.25, -6, 1, -4)
            button.BackgroundColor3 = UI.Colors.Panel
            button.TextColor3 = UI.Colors.Ink
            button.Text = pieceSymbols[(piece - 1) % #pieceSymbols + 1] .. " " .. piece
            button.Font = Enum.Font.GothamBold
            button.TextSize = 21
            button.Parent = tray
            corner(button, 9)
            session.PieceButtons[piece] = button
            listen(session, button.Activated, function() if session.Active then setPiece(session, piece) end end)
            listen(session, button.InputBegan, function(input)
                if not isPointer(input) or not session.Active then return end
                setPiece(session, piece)
                session.DragPiece = piece
                session.Pointer = input
                session.PointerKind = input.UserInputType
                session.LastPointer = localPoint(session, input.Position)
                session.Ui.Content.ScrollingEnabled = false
                session.Ghost.Text = button.Text
                session.Ghost.Visible = true
                session.Ghost.Position = UDim2.fromOffset(session.LastPointer.X, session.LastPointer.Y - 28)
            end)
        end
        updatePieces(session)
    end
    local ghost = Instance.new("TextLabel")
    ghost.Name = "RestorationPieceGhost"
    ghost.AnchorPoint = Vector2.new(0.5, 0.5)
    ghost.Size = UDim2.fromOffset(68, 48)
    ghost.BackgroundColor3 = UI.Colors.Teal
    ghost.TextColor3 = UI.Colors.Panel
    ghost.BackgroundTransparency = 0.08
    ghost.Font = Enum.Font.GothamBold
    ghost.TextSize = 22
    ghost.Visible = false
    ghost.ZIndex = 100
    ghost.Parent = ui.Gui
    corner(ghost, 10)
    session.Ghost = ghost
    session.Status = UI.label(card, if challenge.Kind == "Assemble" then "The next piece is selected for you. Tap its outline to fit it." else "Small improvements still count. There is no hard failure.", 13, UI.Colors.Muted)
    session.Status.Size = UDim2.new(1, 0, 0, 32)
    local actions = frame(card, UI.Colors.Panel, nil, UDim2.new(1, 0, 0, 48))
    actions.BackgroundTransparency = 1
    local finish = UI.button(actions, "Ready in 8s", function()
        if session.Active and not session.Finishing and os.clock() - session.Started >= (challenge.Minimum or 8) then
            session.Finishing = true
            send("FinishRestore", {Token = challenge.Token})
        end
    end)
    finish.Size = UDim2.new(0.72, -4, 1, 0)
    local cancel = UI.button(actions, "Cancel", function()
        if session.Active then send("CancelRestore", {}) end
    end, true)
    cancel.Position = UDim2.new(0.72, 4, 0, 0)
    cancel.Size = UDim2.new(0.28, -4, 1, 0)
    session.Finish = finish

    local function sizeBoard()
        local available = math.max(210, ui.Content.AbsoluteSize.Y - 215)
        local width = math.max(220, board.AbsoluteSize.X)
        local height = math.clamp(math.min(width * 0.74, available), 220, 380)
        board.Size = UDim2.new(1, 0, 0, height)
        for _, layout in ipairs(session.LineLayouts) do layout() end
    end
    sizeBoard()
    listen(session, ui.Content:GetPropertyChangedSignal("AbsoluteSize"), sizeBoard)
    listen(session, board:GetPropertyChangedSignal("AbsoluteSize"), function()
        for _, layout in ipairs(session.LineLayouts) do layout() end
    end)
    local function moved(input)
        if not session.Pointer or not session.Active then return end
        if session.PointerKind == Enum.UserInputType.Touch and input ~= session.Pointer then return end
        if session.PointerKind == Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local point = localPoint(session, input.Position)
        if session.DragPiece then
            ghost.Position = UDim2.fromOffset(point.X, point.Y - 28)
        elseif challenge.Kind == "Scrub" or challenge.Kind == "Polish" or challenge.Kind == "Repaint" then
            local before = session.LastPointer or point
            local steps = math.clamp(math.ceil((point - before).Magnitude / 12), 1, 24)
            for step = 1, steps do enqueue(session, atCell(session, before:Lerp(point, step / steps))) end
        end
        session.LastPointer = point
    end
    listen(session, UserInputService.InputChanged, moved)
    listen(session, UserInputService.InputEnded, function(input)
        if not session.Pointer or not isPointer(input) then return end
        if session.PointerKind == Enum.UserInputType.Touch and input ~= session.Pointer then return end
        local point = localPoint(session, input.Position)
        local cell = atCell(session, point)
        if challenge.Kind == "Assemble" then
            if cell then enqueue(session, cell) end
        elseif challenge.Kind == "Rewire" and cell ~= session.PointerStartCell then
            enqueue(session, cell)
        end
        session.Pointer = nil
        session.DragPiece = nil
        session.PointerStartCell = nil
        session.Ui.Content.ScrollingEnabled = session.ScrollEnabled
        ghost.Visible = false
    end)
    listen(session, UserInputService.WindowFocusReleased, function()
        session.Pointer = nil; session.DragPiece = nil; ghost.Visible = false
        session.Ui.Content.ScrollingEnabled = session.ScrollEnabled
    end)
    listen(session, RunService.Heartbeat, function()
        if not session.Active then return end
        local now = os.clock()
        local elapsed = now - session.Started
        local left = math.max(0, (challenge.Duration or 20) - elapsed)
        session.Clock.Text = math.ceil(left) .. "s"
        session.Clock.TextColor3 = if left <= 5 then UI.Colors.Rose else UI.Colors.Ink
        if session.Finishing then
            finish.Text = "Finishing…"
        elseif elapsed < (challenge.Minimum or 8) then
            finish.Text = "Ready in " .. math.ceil((challenge.Minimum or 8) - elapsed) .. "s"
            finish.BackgroundTransparency = 0.35
        else
            finish.Text = if session.Progress >= 16 then "Finish · beautiful work!" else "Finish restoration"
            finish.BackgroundTransparency = 0
        end
        -- One ordered queue prevents quick swipe samples being dropped by the
        -- server's per-session input interval. Palette changes share the queue.
        if not session.Finishing and #session.Queue > 0 and now - session.LastSend >= 0.085 then
            local request = table.remove(session.Queue, 1)
            request.Token = challenge.Token
            session.LastSend = now
            if request.Cell then session.PendingAt[request.Cell] = now end
            send("RestoreInput", request)
        end
        for cell, when in pairs(session.PendingAt) do
            if now - when > 1.5 then
                -- A rejected/late packet may not produce an acknowledgement.
                -- Permit a deliberate retry, without submitting it automatically.
                session.PendingAt[cell] = nil; session.PendingCells[cell] = nil
            end
        end
        if challenge.Kind == "Polish" and session.Progress < 16 then
            local nextCell = challenge.Targets[session.Progress + 1]
            for cell, style in ipairs(session.CellStyles) do
                if not session.Done[cell] then
                    style.Stroke.Color = if cell == nextCell then UI.Colors.Gold else Color3.fromRGB(255, 247, 228)
                    style.Stroke.Thickness = if cell == nextCell then 2.5 + math.sin(elapsed * 5) * 0.5 else 1
                end
            end
        end
    end)
    return session
end

local function completeCell(session, cell)
    local button = session.Buttons[cell]
    if not button then return end
    session.Done[cell] = true
    session.PendingCells[cell] = nil
    session.PendingAt[cell] = nil
    local style = session.CellStyles[cell]
    if session.Kind == "Scrub" then
        ease(button, 0.28, {BackgroundTransparency = 1})
        ease(style.Stroke, 0.28, {Transparency = 1})
        for _, child in ipairs(button:GetChildren()) do
            if child:IsA("Frame") then ease(child, 0.28, {BackgroundTransparency = 1}) end
        end
    elseif session.Kind == "Repaint" then
        ease(button, 0.2, {BackgroundColor3 = paintColors[session.Challenge.RequiredPalette], BackgroundTransparency = 0.18})
            if style.Label then style.Label.Text = "OK"; style.Label.TextColor3 = Color3.fromRGB(255, 252, 234) end
        style.Stroke.Transparency = 0.6
    elseif session.Kind == "Polish" then
            button.Text = "+"
        button.TextColor3 = Color3.fromRGB(255, 247, 205)
        ease(button, 0.3, {BackgroundTransparency = 1})
        style.Stroke.Transparency = 1
    elseif session.Kind == "Assemble" then
        ease(button, 0.18, {BackgroundColor3 = session.Colors.Teal, BackgroundTransparency = 0.1})
            button.Text = "OK " .. session.Ranks[cell]
        style.Stroke.Color = Color3.fromRGB(217, 234, 205)
    else
        ease(button, 0.18, {BackgroundTransparency = 0.15})
        style.Stroke.Color = Color3.fromRGB(255, 242, 184)
        style.Stroke.Thickness = 2.5
    end
end

function Minigames.progress(session, data, UI)
    if not session or not session.Active then return end
    session.Progress = data.Progress or session.Progress
    session.Mistakes = data.Mistakes or session.Mistakes
    if data.Cell then session.PendingCells[data.Cell] = nil; session.PendingAt[data.Cell] = nil end
    session.Meter.Text = math.floor(session.Progress / 16 * 100) .. "% RESTORED"
    ease(session.ProgressBar, 0.16, {Size = UDim2.fromScale(session.Progress / 16, 1)})
    if data.Selected then
        session.LocalWireStart = data.Cell
        session.CellStyles[data.Cell].Stroke.Color = UI.Colors.Gold
        session.CellStyles[data.Cell].Stroke.Thickness = 3
        session.Status.Text = "One end connected. Find its matching symbol."
        return
    end
    if data.Valid then
        completeCell(session, data.Cell)
        if data.Other then
            completeCell(session, data.Other)
            local pair = math.ceil(session.Ranks[data.Cell] / 2)
            local wire, layout = line(session.Targets, session.Centers[data.Cell], session.Centers[data.Other], wireColors[pair], 5, 3)
            table.insert(session.Wires, {Line = wire, Stage = session.WireStage})
            table.insert(session.LineLayouts, layout)
            session.LocalWireStart = nil
        end
        sound(session, "restore")
        if session.Kind == "Assemble" then updatePieces(session) end
        session.Status.Text = if session.Progress >= 16 then "Beautiful work. Finish when you are ready." else (if session.Mistakes == 0 then "Lovely progress. Keep that steady hand." else "Keep going. Every bit of care makes a difference.")
        if session.Kind == "Rewire" then updateWireStage(session) end
    else
        if data.Other then
            local outline = session.CellStyles[data.Other].Stroke
            outline.Color = Color3.fromRGB(239, 241, 217); outline.Thickness = 1.5
            session.LocalWireStart = nil
        end
        local style = session.CellStyles[data.Cell]
        if style then
            local old = style.Stroke.Color
            style.Stroke.Color = UI.Colors.Rose
            task.delay(0.22, function()
                if session.Active and style.Stroke.Parent then style.Stroke.Color = old end
            end)
        end
        session.Status.Text = if session.Kind == "Repaint" then "Try the requested dye: " .. session.Config.Styles[session.Challenge.RequiredPalette]
            elseif session.Kind == "Polish" then "Follow the highlighted steam mark. You can still improve this piece."
            elseif session.Kind == "Rewire" then "Those thread symbols differ. Pick a matching pair."
            elseif session.Kind == "Assemble" then "That pattern piece belongs in another outline. Match its number."
            else "Sweep across a fabric patch you have not cleaned yet."
    end
end

function Minigames.stop(session)
    if not session then return end
    session.Active = false
    session.Ui.Locked = false
    session.Ui.Content.ScrollingEnabled = session.ScrollEnabled
    for _, connection in ipairs(session.Connections) do connection:Disconnect() end
    table.clear(session.Connections)
    table.clear(session.Queue)
    if session.Ghost then session.Ghost:Destroy() end
end
return Minigames
