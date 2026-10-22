-- Shared visual language for the Thrift Flip client. All art here is vector UI or
-- an in-game model, so menus work without third-party image dependencies.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = {}
UI.Colors = {
    Cream = Color3.fromRGB(255, 248, 232), Panel = Color3.fromRGB(255, 253, 246),
    Ink = Color3.fromRGB(22, 30, 48), Teal = Color3.fromRGB(20, 190, 164),
    Muted = Color3.fromRGB(100, 116, 139), Rose = Color3.fromRGB(246, 96, 114),
    Gold = Color3.fromRGB(255, 190, 55), Line = Color3.fromRGB(218, 226, 238),
    Light = Color3.fromRGB(239, 244, 235), White = Color3.fromRGB(255, 255, 255),
    Wood = Color3.fromRGB(146, 103, 72), Night = Color3.fromRGB(12, 18, 32),
}
local Models, SharedConfig
local function tween(object, properties, duration)
    local animation = TweenService:Create(object, TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    animation:Play(); return animation
end
function UI.corner(object, radius)
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 12); corner.Parent = object
    return corner
end
function UI.stroke(object, color, thickness, transparency)
    local stroke = Instance.new("UIStroke"); stroke.Color = color or UI.Colors.Line; stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = object
    return stroke
end
function UI.gradient(object, first, second, rotation)
    local gradient = Instance.new("UIGradient"); gradient.Color = ColorSequence.new(first, second)
    gradient.Rotation = rotation or 0; gradient.Parent = object; return gradient
end
function UI.padding(object, horizontal, vertical)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, horizontal or 12); p.PaddingRight = p.PaddingLeft
    p.PaddingTop = UDim.new(0, vertical or horizontal or 12); p.PaddingBottom = p.PaddingTop; p.Parent = object
    return p
end
function UI.label(parent, text, size, color)
    local label = Instance.new("TextLabel"); label.Name = "Label"; label.Text = text; label.TextSize = size or 17
    label.Font = Enum.Font.GothamMedium; label.TextColor3 = color or UI.Colors.Ink
    label.TextXAlignment = Enum.TextXAlignment.Left; label.TextYAlignment = Enum.TextYAlignment.Center
    label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 0, (size or 17) + 8)
    label.TextWrapped = true; label.AutomaticSize = Enum.AutomaticSize.Y; label.Parent = parent
    return label
end
function UI.eyebrow(parent, text, color)
    local label = UI.label(parent, string.upper(text), 12, color or UI.Colors.Muted)
    label.Font = Enum.Font.GothamBold; return label
end
function UI.button(parent, text, callback, secondary)
    local button = Instance.new("TextButton"); button.Name = "Button"; button.Text = text
    button.Font = Enum.Font.GothamBold; button.TextSize = 16; button.TextWrapped = true
    button.TextColor3 = if secondary then UI.Colors.Ink else UI.Colors.Panel
    button.BackgroundColor3 = if secondary then UI.Colors.Light else UI.Colors.Teal
    button.Size = UDim2.new(1, 0, 0, 50); button.AutoButtonColor = false; button.Parent = parent
    UI.corner(button, 14); UI.padding(button, 10, 3)
    UI.stroke(button, if secondary then UI.Colors.Line else UI.Colors.White, 1, if secondary then 0.15 else 0.72)
    if not secondary then UI.gradient(button, Color3.fromRGB(16, 202, 171), Color3.fromRGB(20, 154, 213), 15) end
    local scale = Instance.new("UIScale"); scale.Parent = button
    local baseColor = button.BackgroundColor3
    button.MouseEnter:Connect(function() tween(button, {BackgroundColor3 = baseColor:Lerp(UI.Colors.Gold, 0.12)}) end)
    button.MouseLeave:Connect(function() tween(button, {BackgroundColor3 = baseColor}) end)
    button.SelectionGained:Connect(function() tween(button, {BackgroundColor3 = baseColor:Lerp(UI.Colors.Gold, 0.2)}) end)
    button.SelectionLost:Connect(function() tween(button, {BackgroundColor3 = baseColor}) end)
    button.Activated:Connect(function(...)
        scale.Scale = 0.96; tween(scale, {Scale = 1}, 0.14)
        if UI.OnClick then UI.OnClick() end
        callback(...)
    end)
    return button
end
function UI.disabled(parent, text)
    local label = UI.label(parent, text, 15, UI.Colors.Muted)
    label.Size = UDim2.new(1, 0, 0, 44); label.TextXAlignment = Enum.TextXAlignment.Center
    label.BackgroundColor3 = UI.Colors.Light; label.BackgroundTransparency = 0.4; UI.corner(label, 10)
    return label
end
function UI.input(parent, placeholder, value, numeric)
    local field = Instance.new("TextBox"); field.Name = "Input"; field.Size = UDim2.new(1, 0, 0, 48)
    field.BackgroundColor3 = UI.Colors.White; field.TextColor3 = UI.Colors.Ink; field.PlaceholderColor3 = UI.Colors.Muted
    field.PlaceholderText = placeholder; field.Text = value or ""; field.ClearTextOnFocus = false
    field.Font = Enum.Font.GothamMedium; field.TextSize = 16; field.TextXAlignment = Enum.TextXAlignment.Left
    field.Parent = parent; UI.corner(field, 10); UI.stroke(field); UI.padding(field, 12, 4)
    if numeric then
        field:GetPropertyChangedSignal("Text"):Connect(function()
            local cleaned = string.gsub(field.Text, "[^0-9]", "")
            if cleaned ~= field.Text then field.Text = cleaned end
        end)
    end
    return field
end
function UI.list(parent, gap)
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, gap or 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = parent; return layout
end
function UI.row(parent, height, gap)
    local row = Instance.new("Frame"); row.Name = "Row"; row.Size = UDim2.new(1, 0, 0, height or 48)
    row.BackgroundTransparency = 1; row.Parent = parent
    local layout = UI.list(row, gap or 8); layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    return row
end
function UI.rowButton(row, text, callback, count, secondary)
    local button = UI.button(row, text, callback, secondary)
    button.Size = UDim2.new(1 / count, -8 * (count - 1) / count, 1, 0)
    return button
end
function UI.card(parent)
    local frame = Instance.new("Frame"); frame.Name = "Card"
    frame.Size = UDim2.new(1, -2, 0, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = UI.Colors.Panel; frame.Parent = parent; UI.corner(frame, 16)
    UI.stroke(frame, Color3.fromRGB(205, 215, 201), 1, 0.2); UI.padding(frame, 18, 16); UI.list(frame, 10)
    return frame
end
function UI.hero(parent, kicker, title, body, color)
    local frame = UI.card(parent); frame.BackgroundColor3 = color or UI.Colors.Ink
    if not color then UI.gradient(frame, Color3.fromRGB(19, 31, 55), Color3.fromRGB(25, 95, 109), 20) end
    UI.eyebrow(frame, kicker, UI.Colors.Cream)
    local heading = UI.label(frame, title, 28, UI.Colors.Panel); heading.Font = Enum.Font.GothamBold
    if body and body ~= "" then UI.label(frame, body, 16, UI.Colors.Cream) end
    return frame
end
function UI.pill(parent, text, color)
    local label = UI.label(parent, text, 13, color or UI.Colors.Teal)
    label.Font = Enum.Font.GothamBold; label.AutomaticSize = Enum.AutomaticSize.X
    label.Size = UDim2.fromOffset(0, 28); label.TextWrapped = false; label.BackgroundTransparency = 0
    label.BackgroundColor3 = (color or UI.Colors.Teal):Lerp(UI.Colors.Panel, 0.87)
    UI.padding(label, 10, 2); UI.corner(label, 8); return label
end
function UI.progress(parent, fraction, color)
    local track = Instance.new("Frame"); track.Name = "Progress"; track.Size = UDim2.new(1, 0, 0, 8)
    track.BackgroundColor3 = UI.Colors.Line; track.BorderSizePixel = 0; track.Parent = parent; UI.corner(track, 6)
    local fill = Instance.new("Frame"); fill.Name = "Fill"; fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
    fill.BackgroundColor3 = color or UI.Colors.Teal; fill.BorderSizePixel = 0; fill.Parent = track; UI.corner(fill, 6)
    return fill
end
function UI.grid(parent, cellHeight, minimumWidth)
    local frame = Instance.new("Frame"); frame.Name = "Grid"; frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1; frame.Parent = parent
    local layout = Instance.new("UIGridLayout"); layout.CellPadding = UDim2.fromOffset(10, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = frame
    local updating = false
    local function resize()
        if updating then return end
        updating = true
        local width = frame.AbsoluteSize.X
        local columns = math.max(1, math.floor((width + 10) / (minimumWidth or 190)))
        local count = 0; for _, child in ipairs(frame:GetChildren()) do if child:IsA("GuiObject") then count += 1 end end
        layout.CellSize = UDim2.new(1 / columns, -10 * (columns - 1) / columns, 0, cellHeight)
        frame.Size = UDim2.new(1, 0, 0, math.max(0, math.ceil(count / columns) * (cellHeight + 10) - 10))
        updating = false
    end
    frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    frame.ChildAdded:Connect(resize); frame.ChildRemoved:Connect(resize); task.defer(resize)
    return frame
end
function UI.preview(parent, definition, item, height, hidden)
    local viewport = Instance.new("ViewportFrame"); viewport.Name = "ItemPreview"
    local rarityColor = if item and item.Inspected and item.Rarity and SharedConfig
        then Color3.fromHex(SharedConfig.RarityColors[item.Rarity]) else nil
    if item and item.Inspected and item.Rarity and not SharedConfig then
        SharedConfig = require(ReplicatedStorage.Shared.Config)
        rarityColor = Color3.fromHex(SharedConfig.RarityColors[item.Rarity])
    end
    viewport.Size = UDim2.new(1, 0, 0, height or 180); viewport.BackgroundColor3 = UI.Colors.Light
    viewport.Ambient = Color3.fromRGB(128, 143, 159); viewport.LightColor = Color3.fromRGB(255, 242, 216)
    viewport.LightDirection = Vector3.new(-1.4, -1.8, -1); viewport.Parent = parent; UI.corner(viewport, 12)
    if rarityColor then
        UI.gradient(viewport, Color3.fromRGB(250, 247, 237), rarityColor:Lerp(Color3.fromRGB(237, 244, 247), 0.72), 35)
        UI.stroke(viewport, rarityColor, if item.Rarity >= 4 then 2 else 1, if item.Rarity >= 4 then 0.12 else 0.42)
    else
        UI.gradient(viewport, Color3.fromRGB(247, 241, 228), Color3.fromRGB(203, 225, 224), 35)
    end
    local world = Instance.new("WorldModel"); world.Parent = viewport
    local camera = Instance.new("Camera"); camera.FieldOfView = 35; camera.Parent = viewport; viewport.CurrentCamera = camera
    if hidden then
        local box = Instance.new("Part"); box.Size = Vector3.new(2.5, 2, 2.2); box.Anchored = true
        box.Color = UI.Colors.Wood; box.Material = Enum.Material.Wood; box.Parent = world
        for offset = -1, 1, 2 do
            local tape = Instance.new("Part"); tape.Size = Vector3.new(0.25, 2.03, 2.23); tape.Position = Vector3.new(offset * 0.6, 0, 0)
            tape.Color = UI.Colors.Gold; tape.Anchored = true; tape.Parent = world
        end
        camera.CFrame = CFrame.lookAt(Vector3.new(5, 3.5, -6), Vector3.zero)
        local label = UI.label(viewport, "?", 46, UI.Colors.Cream); label.Size = UDim2.fromScale(1, 1)
        label.AutomaticSize = Enum.AutomaticSize.None; label.TextXAlignment = Enum.TextXAlignment.Center; label.Font = Enum.Font.GothamBlack
        return viewport
    end
    local ok, model = pcall(function()
        if not Models then
            Models = require(ReplicatedStorage.Shared:WaitForChild("ItemModels"))
            SharedConfig = require(ReplicatedStorage.Shared.Config)
        end
        return Models.create(world, definition, item, CFrame.new(), SharedConfig)
    end)
    if ok and model then
        local cf, size = model:GetBoundingBox()
        local diameter = math.max(size.X, size.Y, size.Z, 1)
        local shadow = Instance.new("Part"); shadow.Name = "ProductShadow"; shadow.Shape = Enum.PartType.Cylinder
        shadow.Size = Vector3.new(0.025, diameter * 1.15, diameter * 1.15)
        shadow.CFrame = CFrame.new(cf.Position.X, cf.Position.Y - size.Y / 2 - 0.04, cf.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
        shadow.Color = Color3.fromRGB(45, 58, 64); shadow.Material = Enum.Material.SmoothPlastic
        shadow.Transparency = 0.72; shadow.Anchored = true; shadow.CanCollide = false; shadow.CanQuery = false; shadow.Parent = world
        camera.FieldOfView = 30
        camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(diameter * 1.35, diameter * 0.78, -diameter * 2.05), cf.Position + Vector3.new(0, size.Y * 0.05, 0))
        -- Rotate only while the player drags the preview, never in a render loop.
        local rotating, lastX = false, 0
        viewport.Active = true
        viewport.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                rotating = true; lastX = input.Position.X
            end
        end)
        viewport.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then rotating = false end
        end)
        viewport.InputChanged:Connect(function(input)
            if rotating and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position.X - lastX; lastX = input.Position.X
                model:PivotTo(CFrame.new(cf.Position) * CFrame.Angles(0, delta * 0.012, 0) * CFrame.new(-cf.Position) * model:GetPivot())
            end
        end)
    else
        local label = UI.label(viewport, definition and definition.Name or "Your find", 20, UI.Colors.Teal)
        label.Size = UDim2.fromScale(1, 1); label.AutomaticSize = Enum.AutomaticSize.None; label.TextXAlignment = Enum.TextXAlignment.Center
        warn("Item preview failed: " .. tostring(model))
    end
    return viewport
end
function UI.new()
    local self = setmetatable({Locked = false, ToastVersion = 0, PageConnections = {}, Effects = true}, {__index = UI})
    local gui = Instance.new("ScreenGui"); gui.Name = "ThriftFlip"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui"); self.Gui = gui
    local splash = Instance.new("Frame"); splash.Name = "LaunchSplash"; splash.Size = UDim2.fromScale(1, 1)
    splash.BackgroundColor3 = UI.Colors.Night; splash.BorderSizePixel = 0; splash.ZIndex = 100; splash.Parent = gui
    UI.gradient(splash, Color3.fromRGB(10, 17, 31), Color3.fromRGB(19, 92, 100), 35)
    local splashTitle = UI.label(splash, "THRIFT FLIP", 42, UI.Colors.White); splashTitle.Font = Enum.Font.GothamBlack
    splashTitle.AnchorPoint = Vector2.new(0.5, 0.5); splashTitle.Position = UDim2.fromScale(0.5, 0.45)
    splashTitle.Size = UDim2.new(0.9, 0, 0, 58); splashTitle.AutomaticSize = Enum.AutomaticSize.None; splashTitle.TextXAlignment = Enum.TextXAlignment.Center; splashTitle.ZIndex = 101
    local splashTag = UI.label(splash, "FIND  •  RESTORE  •  BUILD YOUR DREAM SHOP", 13, UI.Colors.Gold)
    splashTag.AnchorPoint = Vector2.new(0.5, 0); splashTag.Position = UDim2.fromScale(0.5, 0.51)
    splashTag.Size = UDim2.new(0.9, 0, 0, 30); splashTag.AutomaticSize = Enum.AutomaticSize.None; splashTag.TextXAlignment = Enum.TextXAlignment.Center; splashTag.ZIndex = 101
    task.delay(1.1, function()
        tween(splash, {BackgroundTransparency = 1}, 0.35); tween(splashTitle, {TextTransparency = 1}, 0.25); tween(splashTag, {TextTransparency = 1}, 0.25)
        task.wait(0.38); if splash.Parent then splash:Destroy() end
    end)
    local hud = Instance.new("Frame"); hud.Name = "TownHUD"; hud.Position = UDim2.fromOffset(10, 10)
    hud.Size = UDim2.new(1, -20, 0, 112); hud.BackgroundTransparency = 1; hud.Parent = gui
    local brand = Instance.new("Frame"); brand.Name = "BrandPill"; brand.Size = UDim2.fromOffset(256, 46)
    brand.BackgroundColor3 = Color3.fromRGB(255, 248, 232); brand.Parent = hud; UI.corner(brand, 23); UI.stroke(brand, UI.Colors.White, 2, 0.15)
    local badge = Instance.new("Frame"); badge.Size = UDim2.fromOffset(36, 36); badge.Position = UDim2.fromOffset(5, 5)
    badge.BackgroundColor3 = Color3.fromRGB(23, 132, 124); badge.Parent = brand; UI.corner(badge, 18)
    local icon = UI.label(badge, "⌄", 24, UI.Colors.White); icon.Size = UDim2.fromScale(1, 1); icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.AutomaticSize = Enum.AutomaticSize.None; icon.Font = Enum.Font.GothamBold
    self.Brand = UI.label(brand, "Thrift Flip", 16, Color3.fromRGB(8, 91, 84)); self.Brand.Font = Enum.Font.GothamBold
    self.Brand.Position = UDim2.fromOffset(48, 5); self.Brand.Size = UDim2.new(1, -55, 0, 20); self.Brand.AutomaticSize = Enum.AutomaticSize.None
    local tagline = UI.label(brand, "Every find has a story", 10, Color3.fromRGB(67, 86, 83))
    tagline.Position = UDim2.fromOffset(48, 24); tagline.Size = UDim2.new(1, -55, 0, 16); tagline.AutomaticSize = Enum.AutomaticSize.None
    local objective = Instance.new("Frame"); objective.Name = "Objective"; objective.Position = UDim2.fromOffset(0, 54)
    objective.Size = UDim2.fromOffset(256, 58); objective.BackgroundColor3 = Color3.fromRGB(20, 132, 124); objective.Parent = hud; UI.corner(objective, 14)
    UI.stroke(objective, Color3.fromRGB(8, 107, 101), 1, 0.25)
    local arrow = UI.label(objective, "➜", 18, UI.Colors.White); arrow.Position = UDim2.fromOffset(13, 16); arrow.Size = UDim2.fromOffset(23, 27); arrow.AutomaticSize = Enum.AutomaticSize.None
    local objectiveTitle = UI.label(objective, "OBJECTIVE", 9, Color3.fromRGB(187, 235, 226)); objectiveTitle.Font = Enum.Font.GothamBold
    objectiveTitle.Position = UDim2.fromOffset(36, 6); objectiveTitle.Size = UDim2.new(1, -45, 0, 14); objectiveTitle.AutomaticSize = Enum.AutomaticSize.None
    self.Hint = UI.label(objective, "Find your first treasure", 12, UI.Colors.White); self.Hint.Font = Enum.Font.GothamBold
    self.Hint.Position = UDim2.fromOffset(36, 18); self.Hint.Size = UDim2.new(1, -45, 0, 34); self.Hint.AutomaticSize = Enum.AutomaticSize.None
    self.Hint.TextTruncate = Enum.TextTruncate.AtEnd; self.Hint.TextWrapped = true
    local stats = Instance.new("Frame"); stats.Name = "Stats"; stats.AnchorPoint = Vector2.new(1, 0); stats.Position = UDim2.new(1, 0, 0, 0)
    stats.Size = UDim2.fromOffset(164, 42); stats.BackgroundTransparency = 1; stats.Parent = hud
    local cashPill = Instance.new("Frame"); cashPill.Size = UDim2.fromOffset(76, 38); cashPill.BackgroundColor3 = Color3.fromRGB(255, 248, 232); cashPill.Parent = stats; UI.corner(cashPill, 19)
    local coin = UI.label(cashPill, "$", 13, Color3.fromRGB(17, 92, 84)); coin.Size = UDim2.fromOffset(27, 27); coin.Position = UDim2.fromOffset(5, 5)
    coin.AutomaticSize = Enum.AutomaticSize.None; coin.TextXAlignment = Enum.TextXAlignment.Center; coin.BackgroundTransparency = 0; coin.BackgroundColor3 = UI.Colors.Gold; coin.Font = Enum.Font.GothamBold; UI.corner(coin, 14)
    self.Balance = UI.label(cashPill, "75", 16, Color3.fromRGB(20, 75, 70)); self.Balance.Font = Enum.Font.GothamBold
    self.Balance.Position = UDim2.fromOffset(36, 5); self.Balance.Size = UDim2.new(1, -42, 0, 28); self.Balance.AutomaticSize = Enum.AutomaticSize.None
    local levelPill = Instance.new("Frame"); levelPill.Position = UDim2.fromOffset(82, 0); levelPill.Size = UDim2.fromOffset(82, 38)
    levelPill.BackgroundColor3 = Color3.fromRGB(255, 248, 232); levelPill.Parent = stats; UI.corner(levelPill, 19)
    local star = UI.label(levelPill, "★", 14, UI.Colors.White); star.Size = UDim2.fromOffset(27, 27); star.Position = UDim2.fromOffset(5, 5)
    star.AutomaticSize = Enum.AutomaticSize.None; star.TextXAlignment = Enum.TextXAlignment.Center; star.BackgroundTransparency = 0; star.BackgroundColor3 = Color3.fromRGB(20, 132, 124); star.Font = Enum.Font.GothamBold; UI.corner(star, 14)
    self.Level = UI.label(levelPill, "LV 1", 15, Color3.fromRGB(20, 75, 70)); self.Level.Font = Enum.Font.GothamBold
    self.Level.Position = UDim2.fromOffset(36, 5); self.Level.Size = UDim2.new(1, -40, 0, 28); self.Level.AutomaticSize = Enum.AutomaticSize.None
    local levelTrack = Instance.new("Frame"); levelTrack.Name = "LevelProgress"; levelTrack.Position = UDim2.new(0, 36, 1, -5)
    levelTrack.Size = UDim2.new(1, -48, 0, 3); levelTrack.BackgroundColor3 = Color3.fromRGB(31, 111, 104); levelTrack.BorderSizePixel = 0; levelTrack.Parent = objective; UI.corner(levelTrack, 3)
    local levelFill = Instance.new("Frame"); levelFill.Name = "Fill"; levelFill.Size = UDim2.fromScale(0, 1)
    levelFill.BackgroundColor3 = UI.Colors.Gold; levelFill.BorderSizePixel = 0; levelFill.Parent = levelTrack; UI.corner(levelFill, 3); self.LevelProgress = levelFill
    local nav = Instance.new("Frame"); nav.Name = "Navigation"; nav.AnchorPoint = Vector2.new(0.5, 1)
    nav.Position = UDim2.new(0.5, 0, 1, -12); nav.Size = UDim2.new(1, -24, 0, 70)
    nav.BackgroundColor3 = Color3.fromRGB(255, 248, 232); nav.Parent = gui; nav.ZIndex = 12; UI.corner(nav, 22); UI.padding(nav, 6, 6)
    UI.stroke(nav, Color3.fromRGB(122, 143, 135), 1, 0.45)
    local navLimit = Instance.new("UISizeConstraint"); navLimit.MaxSize = Vector2.new(410, 70); navLimit.Parent = nav
    local grid = Instance.new("UIGridLayout"); grid.CellSize = UDim2.new(0.2, -4, 1, 0); grid.CellPadding = UDim2.fromOffset(5, 0)
    grid.SortOrder = Enum.SortOrder.LayoutOrder; grid.Parent = nav; self.Nav = nav; self.NavButtons = {}
    local actions = Instance.new("Frame"); actions.Name = "QuickActions"; actions.AnchorPoint = Vector2.new(1, 0.5)
    actions.Position = UDim2.new(1, -14, 0.64, 0); actions.Size = UDim2.fromOffset(74, 214)
    actions.BackgroundTransparency = 1; actions.Parent = gui; actions.ZIndex = 12; UI.list(actions, 8); self.QuickActions = actions
    local camera = workspace.CurrentCamera
    local function fitQuickActions() actions.Visible = not camera or camera.ViewportSize.X >= 700 end
    if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitQuickActions) end
    fitQuickActions()
    local overlay = Instance.new("TextButton"); overlay.Name = "ModalBackdrop"; overlay.Text = ""; overlay.AutoButtonColor = false
    overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = UI.Colors.Night; overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0; overlay.Visible = false; overlay.ZIndex = 4; overlay.Parent = gui; self.Overlay = overlay
    local shadow = Instance.new("Frame"); shadow.Name = "ModalShadow"; shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 4, 0.5, -16); shadow.Size = UDim2.new(1, -24, 1, -100)
    shadow.BackgroundColor3 = Color3.fromRGB(12, 52, 48); shadow.BackgroundTransparency = 0.62; shadow.Visible = false; shadow.ZIndex = 5; shadow.Parent = gui
    UI.corner(shadow, 26); local shadowLimit = Instance.new("UISizeConstraint"); shadowLimit.MaxSize = Vector2.new(780, 730); shadowLimit.MinSize = Vector2.new(270, 170); shadowLimit.Parent = shadow; self.PanelShadow = shadow
    local panel = Instance.new("Frame"); panel.Name = "Journal"; panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, -22); panel.Size = UDim2.new(1, -24, 1, -100)
    panel.BackgroundColor3 = UI.Colors.Cream; panel.Visible = false; panel.Parent = gui; panel.ZIndex = 6
    UI.corner(panel, 26); UI.stroke(panel, UI.Colors.White, 2, 0.12)
    local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(780, 730); limit.MinSize = Vector2.new(270, 170); limit.Parent = panel
    local panelScale = Instance.new("UIScale"); panelScale.Parent = panel; self.PanelScale = panelScale; self.Panel = panel
    local header = Instance.new("Frame"); header.Name = "ModalHeader"; header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = Color3.fromRGB(20, 132, 124); header.BorderSizePixel = 0; header.Parent = panel; header.ZIndex = 7; UI.corner(header, 25)
    local headerMask = Instance.new("Frame"); headerMask.Position = UDim2.new(0, 0, 1, -24); headerMask.Size = UDim2.new(1, 0, 0, 24)
    headerMask.BackgroundColor3 = header.BackgroundColor3; headerMask.BorderSizePixel = 0; headerMask.Parent = header; headerMask.ZIndex = 7
    self.Title = UI.label(header, "Your finds", 24, UI.Colors.White); self.Title.Font = Enum.Font.GothamBold; self.Title.ZIndex = 8
    self.Title.Position = UDim2.fromOffset(20, 8); self.Title.Size = UDim2.new(1, -88, 0, 30); self.Title.AutomaticSize = Enum.AutomaticSize.None
    self.Title.TextTruncate = Enum.TextTruncate.AtEnd; self.Title.TextWrapped = false
    self.Subtitle = UI.label(header, "THRIFT STREET", 10, Color3.fromRGB(191, 237, 229)); self.Subtitle.ZIndex = 8
    self.Subtitle.Font = Enum.Font.GothamBold; self.Subtitle.Position = UDim2.fromOffset(21, 38)
    self.Subtitle.Size = UDim2.new(1, -90, 0, 18); self.Subtitle.AutomaticSize = Enum.AutomaticSize.None
    self.Subtitle.TextTruncate = Enum.TextTruncate.AtEnd; self.Subtitle.TextWrapped = false
    local close = UI.button(header, "×", function() self:hide() end, true)
    close.Size = UDim2.fromOffset(42, 42); close.Position = UDim2.new(1, -54, 0, 13); close.TextSize = 25; close.ZIndex = 9; close.BackgroundColor3 = UI.Colors.Cream
    local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Pages"; scroll.Position = UDim2.fromOffset(15, 84)
    scroll.Size = UDim2.new(1, -30, 1, -98); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = UI.Colors.Teal
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new()
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y; scroll.Parent = panel; UI.list(scroll, 12); self.Content = scroll
    local toast = Instance.new("TextLabel"); toast.Name = "Toast"; toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.Position = UDim2.new(0.5, 0, 0, 96); toast.Size = UDim2.new(0.9, 0, 0, 58)
    toast.BackgroundColor3 = UI.Colors.Ink; toast.TextColor3 = UI.Colors.Panel; toast.TextWrapped = true
    toast.Font = Enum.Font.GothamBold; toast.TextSize = 16; toast.Visible = false; toast.ZIndex = 30; toast.Parent = gui
    UI.corner(toast, 13); UI.padding(toast, 14, 8); UI.stroke(toast, UI.Colors.Gold, 1, 0.4)
    local toastLimit = Instance.new("UISizeConstraint"); toastLimit.MaxSize = Vector2.new(630, 90); toastLimit.Parent = toast; self.Toast = toast
    overlay.Activated:Connect(function() self:hide() end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.Escape and self.Panel.Visible then self:hide() end
    end)
    return self
end
function UI:addQuickAction(text, color, callback)
    local button = UI.button(self.QuickActions, text, callback, true)
    button.Size = UDim2.new(1, 0, 0, 66); button.TextSize = 12; button.ZIndex = 13
    for _, child in ipairs(button:GetChildren()) do if child:IsA("UIGradient") then child:Destroy() end end
    button.BackgroundColor3 = Color3.fromRGB(255, 248, 232); button.TextColor3 = Color3.fromRGB(8, 91, 84)
    UI.corner(button, 16)
    return button
end
function UI:addNav(name, symbol, callback)
    local button = UI.button(self.Nav, symbol .. "\n" .. name, callback, true)
    button.TextSize = 12; button.BackgroundColor3 = Color3.fromRGB(255, 248, 232); button.TextColor3 = Color3.fromRGB(8, 91, 84); button.ZIndex = 13
    self.NavButtons[name] = button; return button
end
function UI:selectNav(name)
    for label, button in pairs(self.NavButtons) do
        local selected = label == name or (label == "Find" and name == "Source")
        button.BackgroundColor3 = if selected then Color3.fromRGB(20, 132, 124) else Color3.fromRGB(255, 248, 232)
        button.TextColor3 = if selected then UI.Colors.White else Color3.fromRGB(8, 91, 84)
    end
end
function UI:setSubtitle(text) self.Subtitle.Text = string.upper(text) end
function UI:hide()
    if self.Locked then self:notice("Finish or cancel your restoration first."); return end
    self.Panel.Visible = false; self.PanelShadow.Visible = false; self.Overlay.Visible = false; self:selectNav(nil)
end
function UI:clear(title, subtitle, preserveScroll)
    for _, connection in ipairs(self.PageConnections) do connection:Disconnect() end; self.PageConnections = {}
    local scroll = if preserveScroll then self.Content.CanvasPosition else Vector2.zero
    for _, child in ipairs(self.Content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    self.Title.Text = title; self:setSubtitle(subtitle or "THE THRIFT STREET JOURNAL")
    local opening = not self.Panel.Visible
    self.Panel.Visible = true; self.PanelShadow.Visible = true; self.Overlay.Visible = true
    if opening and self.Effects then
        self.Overlay.BackgroundTransparency = 1; tween(self.Overlay, {BackgroundTransparency = 0.4}, 0.18)
        self.PanelScale.Scale = 0.94; tween(self.PanelScale, {Scale = 1}, 0.2)
    end
    self.Content.CanvasPosition = scroll
    if preserveScroll then task.defer(function() self.Content.CanvasPosition = scroll end) end
end
function UI:searchTreasure(source, callback)
    if self.Searching then return end
    self.Searching = true
    local layer = Instance.new("Frame"); layer.Name = "TreasureSearch"; layer.Size = UDim2.fromScale(1, 1)
    layer.BackgroundColor3 = UI.Colors.Night; layer.BackgroundTransparency = 0.28; layer.BorderSizePixel = 0; layer.ZIndex = 40; layer.Parent = self.Gui
    local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.new(0.86, 0, 0, 250); card.BackgroundColor3 = UI.Colors.Cream; card.ZIndex = 41; card.Parent = layer; UI.corner(card, 24); UI.stroke(card, UI.Colors.White, 2, 0.08)
    local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(390, 250); limit.Parent = card
    local scale = Instance.new("UIScale"); scale.Scale = 0.9; scale.Parent = card; tween(scale, {Scale = 1}, 0.2)
    local title = UI.label(card, if source == "Delivery" then "Unwrapping your parcel…" elseif source == "Estate" then "Browsing the estate…" else "Searching for treasure…", 22, Color3.fromRGB(8, 91, 84))
    title.Font = Enum.Font.GothamBold; title.Position = UDim2.fromOffset(18, 18); title.Size = UDim2.new(1, -36, 0, 32); title.AutomaticSize = Enum.AutomaticSize.None; title.TextXAlignment = Enum.TextXAlignment.Center; title.ZIndex = 42
    local bin = Instance.new("Frame"); bin.AnchorPoint = Vector2.new(0.5, 0); bin.Position = UDim2.new(0.5, 0, 0, 68); bin.Size = UDim2.fromOffset(112, 82)
    bin.BackgroundColor3 = Color3.fromRGB(20, 132, 124); bin.ZIndex = 42; bin.Parent = card; UI.corner(bin, 13)
    local lid = Instance.new("Frame"); lid.AnchorPoint = Vector2.new(0.5, 1); lid.Position = UDim2.new(0.5, 0, 0, 3); lid.Size = UDim2.fromOffset(122, 17)
    lid.BackgroundColor3 = Color3.fromRGB(8, 91, 84); lid.ZIndex = 43; lid.Parent = bin; UI.corner(lid, 8)
    local shine = UI.label(card, "✦   ◇   ✦", 24, UI.Colors.Gold); shine.Position = UDim2.new(0.5, -80, 0, 53); shine.Size = UDim2.fromOffset(160, 36)
    shine.AutomaticSize = Enum.AutomaticSize.None; shine.TextXAlignment = Enum.TextXAlignment.Center; shine.ZIndex = 44
    local status = UI.label(card, "Rummaging through forgotten finds", 13, UI.Colors.Muted); status.Position = UDim2.fromOffset(18, 166)
    status.Size = UDim2.new(1, -36, 0, 24); status.AutomaticSize = Enum.AutomaticSize.None; status.TextXAlignment = Enum.TextXAlignment.Center; status.ZIndex = 42
    local track = Instance.new("Frame"); track.Position = UDim2.fromOffset(24, 207); track.Size = UDim2.new(1, -48, 0, 10)
    track.BackgroundColor3 = Color3.fromRGB(218, 225, 211); track.ZIndex = 42; track.Parent = card; UI.corner(track, 6)
    local fill = Instance.new("Frame"); fill.Size = UDim2.fromScale(0, 1); fill.BackgroundColor3 = UI.Colors.Teal; fill.ZIndex = 43; fill.Parent = track; UI.corner(fill, 6)
    tween(fill, {Size = UDim2.fromScale(1, 1)}, 2.25)
    task.spawn(function()
        for step = 1, 6 do
            lid.Rotation = if step % 2 == 0 then 7 else -7; bin.Rotation = if step % 2 == 0 then -2 else 2
            shine.TextTransparency = if step % 2 == 0 then 0.15 else 0.55
            if step == 3 then status.Text = "Something interesting is in here…" elseif step == 5 then status.Text = "You found something!" end
            task.wait(0.36)
        end
        lid.Rotation = -18; bin.Rotation = 0; shine.TextTransparency = 0
        task.wait(0.2)
        if layer.Parent then layer:Destroy() end
        self.Searching = false; callback()
    end)
end
function UI:rarityReveal(definition, item, callback)
    if self.RevealLayer then self.RevealLayer:Destroy() end
    if not SharedConfig then SharedConfig = require(ReplicatedStorage.Shared.Config) end
    local rarity = math.clamp(item.Rarity or 1, 1, #SharedConfig.Rarities)
    local color = Color3.fromHex(SharedConfig.RarityColors[rarity])
    local layer = Instance.new("Frame"); layer.Name = "RarityReveal"; layer.Size = UDim2.fromScale(1, 1)
    layer.BackgroundColor3 = UI.Colors.Night; layer.BackgroundTransparency = 0.12; layer.BorderSizePixel = 0
    layer.ZIndex = 50; layer.Parent = self.Gui; self.RevealLayer = layer

    if self.Effects then
        for index = 1, (if rarity >= 5 then 22 elseif rarity >= 4 then 14 else 8) do
            local symbol = UI.label(layer, if index % 3 == 0 then SharedConfig.RarityIcons[rarity] else "✦", 16 + index % 4 * 5, color)
            symbol.AnchorPoint = Vector2.new(0.5, 0.5); symbol.Position = UDim2.fromScale(0.08 + ((index * 37) % 84) / 100, 0.18 + ((index * 53) % 68) / 100)
            symbol.Size = UDim2.fromOffset(36, 36); symbol.AutomaticSize = Enum.AutomaticSize.None
            symbol.TextXAlignment = Enum.TextXAlignment.Center; symbol.ZIndex = 51; symbol.Rotation = (index * 29) % 60 - 30
            symbol.TextTransparency = 0.15 + (index % 3) * 0.18
            tween(symbol, {Position = symbol.Position - UDim2.fromOffset(0, 70), TextTransparency = 1, Rotation = symbol.Rotation + 90}, 1.4 + (index % 4) * 0.18)
        end
    end

    local aura = Instance.new("Frame"); aura.AnchorPoint = Vector2.new(0.5, 0.5); aura.Position = UDim2.fromScale(0.5, 0.49)
    aura.Size = UDim2.fromOffset(520, 520); aura.BackgroundColor3 = color; aura.BackgroundTransparency = 0.78
    aura.BorderSizePixel = 0; aura.ZIndex = 51; aura.Parent = layer; UI.corner(aura, 260)
    local auraScale = Instance.new("UIScale"); auraScale.Scale = 0.72; auraScale.Parent = aura
    if self.Effects then tween(auraScale, {Scale = 1.08}, 0.75) end

    local card = Instance.new("Frame"); card.Name = "RevealCard"; card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5); card.Size = UDim2.new(0.9, 0, 0, 535)
    card.BackgroundColor3 = UI.Colors.Panel; card.BorderSizePixel = 0; card.ZIndex = 52; card.Parent = layer
    UI.corner(card, 26); UI.stroke(card, color, if rarity >= 4 then 3 else 2, 0.04)
    UI.gradient(card, UI.Colors.Panel, color:Lerp(UI.Colors.Panel, 0.82), 90)
    local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(470, 535); limit.MinSize = Vector2.new(290, 500); limit.Parent = card
    local scale = Instance.new("UIScale"); scale.Scale = if self.Effects then 0.72 else 1; scale.Parent = card
    if self.Effects then tween(scale, {Scale = 1}, if rarity >= 4 then 0.46 else 0.28) end

    local kicker = UI.label(card, SharedConfig.RarityIcons[rarity] .. "  " .. string.upper(SharedConfig.Rarities[rarity]) .. "  " .. SharedConfig.RarityIcons[rarity], 22, color)
    kicker.Font = Enum.Font.GothamBlack; kicker.Position = UDim2.fromOffset(18, 18); kicker.Size = UDim2.new(1, -36, 0, 34)
    kicker.AutomaticSize = Enum.AutomaticSize.None; kicker.TextXAlignment = Enum.TextXAlignment.Center; kicker.ZIndex = 53
    local effectName = SharedConfig.RarityEffectNames and SharedConfig.RarityEffectNames[rarity] or "Treasure"
    local effect = UI.label(card, string.upper(effectName), 11, color:Lerp(UI.Colors.Ink, 0.3))
    effect.Font = Enum.Font.GothamBold; effect.Position = UDim2.fromOffset(18, 53); effect.Size = UDim2.new(1, -36, 0, 20)
    effect.AutomaticSize = Enum.AutomaticSize.None; effect.TextXAlignment = Enum.TextXAlignment.Center; effect.ZIndex = 53
    local preview = UI.preview(card, definition, item, 265, false); preview.Position = UDim2.fromOffset(18, 80)
    preview.Size = UDim2.new(1, -36, 0, 265); preview.ZIndex = 53
    local name = UI.label(card, definition.Name, 25, UI.Colors.Ink); name.Font = Enum.Font.GothamBlack
    name.Position = UDim2.fromOffset(18, 357); name.Size = UDim2.new(1, -36, 0, 34); name.AutomaticSize = Enum.AutomaticSize.None
    name.TextXAlignment = Enum.TextXAlignment.Center; name.ZIndex = 53
    local detail = UI.label(card, SharedConfig.Conditions[item.Condition] .. " • " .. (item.Style or definition.Style) .. " • $" .. tostring(math.floor(item.Value or 0)), 15, UI.Colors.Muted)
    detail.Position = UDim2.fromOffset(18, 394); detail.Size = UDim2.new(1, -36, 0, 28); detail.AutomaticSize = Enum.AutomaticSize.None
    detail.TextXAlignment = Enum.TextXAlignment.Center; detail.ZIndex = 53
    local button = UI.button(card, if rarity >= 5 then "★ Keep this legendary find" else "Add to my collection", function()
        if self.RevealLayer ~= layer then return end
        self.RevealLayer = nil
        if self.Effects then
            tween(scale, {Scale = 0.92}, 0.16); tween(layer, {BackgroundTransparency = 1}, 0.2); task.wait(0.2)
        end
        if layer.Parent then layer:Destroy() end
        if callback then callback() end
    end, false)
    button.Position = UDim2.new(0, 18, 1, -68); button.Size = UDim2.new(1, -36, 0, 50); button.ZIndex = 54
end
function UI:notice(text)
    self.ToastVersion += 1; local version = self.ToastVersion
    self.Toast.Text = text; self.Toast.Visible = true; self.Toast.TextTransparency = 0; self.Toast.BackgroundTransparency = 0.04
    if self.Effects then
        self.Toast.Position = UDim2.new(0.5, 0, 0, 86); tween(self.Toast, {Position = UDim2.new(0.5, 0, 0, 96)}, 0.18)
    end
    task.delay(4, function()
        if self.ToastVersion == version then
            tween(self.Toast, {TextTransparency = 1, BackgroundTransparency = 1}, 0.25)
            task.wait(0.25); if self.ToastVersion == version then self.Toast.Visible = false end
        end
    end)
end
function UI:cashFeedback(amount)
    if not self.Effects or amount <= 0 then return end
    local label = UI.label(self.Gui, "+$" .. tostring(math.floor(amount)), 24, UI.Colors.Teal)
    label.Font = Enum.Font.GothamBold; label.AnchorPoint = Vector2.new(1, 0); label.Position = UDim2.new(1, -30, 0, 90)
    label.Size = UDim2.fromOffset(180, 36); label.TextXAlignment = Enum.TextXAlignment.Right; label.ZIndex = 25
    tween(label, {Position = UDim2.new(1, -30, 0, 55), TextTransparency = 1}, 1.25)
    task.delay(1.3, function() label:Destroy() end)
end
return UI
