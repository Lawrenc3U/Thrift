-- Shared visual language for the Thrift Flip client. All art here is vector UI or
-- an in-game model, so menus work without third-party image dependencies.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = {}
UI.Colors = {
    Cream = Color3.fromRGB(241, 245, 249), Panel = Color3.fromRGB(255, 255, 255),
    Ink = Color3.fromRGB(22, 30, 48), Teal = Color3.fromRGB(20, 190, 164),
    Muted = Color3.fromRGB(100, 116, 139), Rose = Color3.fromRGB(246, 96, 114),
    Gold = Color3.fromRGB(255, 190, 55), Line = Color3.fromRGB(218, 226, 238),
    Light = Color3.fromRGB(235, 241, 248), White = Color3.fromRGB(255, 255, 255),
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
    frame.BackgroundColor3 = UI.Colors.Panel; frame.Parent = parent; UI.corner(frame, 18)
    UI.stroke(frame, UI.Colors.Line, 1, 0.08); UI.padding(frame, 18, 16); UI.list(frame, 10)
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
    viewport.Size = UDim2.new(1, 0, 0, height or 180); viewport.BackgroundColor3 = UI.Colors.Light
    viewport.Ambient = Color3.fromRGB(197, 199, 183); viewport.LightColor = Color3.fromRGB(255, 239, 211)
    viewport.LightDirection = Vector3.new(-1, -1, -1); viewport.Parent = parent; UI.corner(viewport, 12)
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
        camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(diameter * 1.25, diameter * 0.7, -diameter * 1.85), cf.Position)
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
    local hud = Instance.new("Frame"); hud.Name = "TownHUD"; hud.Position = UDim2.fromOffset(14, 10)
    hud.Size = UDim2.new(1, -28, 0, 76); hud.BackgroundColor3 = UI.Colors.Night; hud.BackgroundTransparency = 0.05; hud.Parent = gui
    UI.corner(hud, 19); UI.stroke(hud, UI.Colors.White, 1, 0.82); UI.gradient(hud, Color3.fromRGB(13, 21, 38), Color3.fromRGB(23, 63, 75), 10)
    local badge = Instance.new("Frame"); badge.Size = UDim2.fromOffset(48, 48); badge.Position = UDim2.fromOffset(12, 10)
    badge.BackgroundColor3 = UI.Colors.Teal; badge.Parent = hud; UI.corner(badge, 15); UI.gradient(badge, UI.Colors.Teal, Color3.fromRGB(19, 151, 215), 45)
    local icon = UI.label(badge, "♻", 28, UI.Colors.White); icon.Size = UDim2.fromScale(1, 1); icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.AutomaticSize = Enum.AutomaticSize.None
    self.Brand = UI.label(hud, "THRIFT FLIP", 19); self.Brand.Font = Enum.Font.GothamBlack
    self.Brand.TextColor3 = UI.Colors.White; self.Brand.Position = UDim2.fromOffset(70, 8); self.Brand.Size = UDim2.new(0.54, -70, 0, 28); self.Brand.TextWrapped = false
    self.Brand.AutomaticSize = Enum.AutomaticSize.None
    self.Balance = UI.label(hud, "Connecting…", 21, UI.Colors.Gold); self.Balance.Font = Enum.Font.GothamBold
    self.Balance.Position = UDim2.new(0.54, 0, 0, 8); self.Balance.Size = UDim2.new(0.46, -14, 0, 28)
    self.Balance.TextXAlignment = Enum.TextXAlignment.Right; self.Balance.AutomaticSize = Enum.AutomaticSize.None
    self.Level = UI.label(hud, "EVERY FIND HAS A STORY", 11, UI.Colors.Muted); self.Level.Font = Enum.Font.GothamBold
    self.Level.TextColor3 = Color3.fromRGB(174, 209, 215); self.Level.Position = UDim2.fromOffset(70, 37); self.Level.Size = UDim2.new(1, -84, 0, 17)
    self.Level.AutomaticSize = Enum.AutomaticSize.None; self.Level.TextWrapped = false
    self.Hint = UI.label(hud, "Find. Restore. Make it yours.", 12, Color3.fromRGB(181, 196, 215))
    self.Hint.Position = UDim2.fromOffset(14, 56); self.Hint.Size = UDim2.new(1, -28, 0, 17)
    self.Hint.AutomaticSize = Enum.AutomaticSize.None; self.Hint.TextTruncate = Enum.TextTruncate.AtEnd; self.Hint.TextWrapped = false
    local levelTrack = Instance.new("Frame"); levelTrack.Name = "LevelProgress"; levelTrack.Position = UDim2.new(0, 14, 1, -4)
    levelTrack.Size = UDim2.new(1, -28, 0, 3); levelTrack.BackgroundColor3 = Color3.fromRGB(54, 72, 94); levelTrack.BorderSizePixel = 0; levelTrack.Parent = hud
    UI.corner(levelTrack, 3)
    local levelFill = Instance.new("Frame"); levelFill.Name = "Fill"; levelFill.Size = UDim2.fromScale(0, 1)
    levelFill.BackgroundColor3 = UI.Colors.Gold; levelFill.BorderSizePixel = 0; levelFill.Parent = levelTrack; UI.corner(levelFill, 3); self.LevelProgress = levelFill
    local nav = Instance.new("Frame"); nav.Name = "Navigation"; nav.AnchorPoint = Vector2.new(0.5, 1)
    nav.Position = UDim2.new(0.5, 0, 1, -9); nav.Size = UDim2.new(1, -24, 0, 62)
    nav.BackgroundColor3 = UI.Colors.Night; nav.BackgroundTransparency = 0.04; nav.Parent = gui; nav.ZIndex = 12; UI.corner(nav, 20); UI.padding(nav, 6, 6)
    UI.stroke(nav, UI.Colors.White, 1, 0.82)
    local navLimit = Instance.new("UISizeConstraint"); navLimit.MaxSize = Vector2.new(650, 62); navLimit.Parent = nav
    local grid = Instance.new("UIGridLayout"); grid.CellSize = UDim2.new(0.2, -4, 1, 0); grid.CellPadding = UDim2.fromOffset(5, 0)
    grid.SortOrder = Enum.SortOrder.LayoutOrder; grid.Parent = nav; self.Nav = nav; self.NavButtons = {}
    local actions = Instance.new("Frame"); actions.Name = "QuickActions"; actions.AnchorPoint = Vector2.new(1, 0.5)
    actions.Position = UDim2.new(1, -14, 0.5, 0); actions.Size = UDim2.fromOffset(116, 184)
    actions.BackgroundTransparency = 1; actions.Parent = gui; actions.ZIndex = 12; UI.list(actions, 8); self.QuickActions = actions
    local camera = workspace.CurrentCamera
    local function fitQuickActions() actions.Visible = not camera or camera.ViewportSize.X >= 700 end
    if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitQuickActions) end
    fitQuickActions()
    local overlay = Instance.new("TextButton"); overlay.Name = "ModalBackdrop"; overlay.Text = ""; overlay.AutoButtonColor = false
    overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = UI.Colors.Night; overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0; overlay.Visible = false; overlay.ZIndex = 4; overlay.Parent = gui; self.Overlay = overlay
    local panel = Instance.new("Frame"); panel.Name = "Journal"; panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, -22); panel.Size = UDim2.new(1, -24, 1, -100)
    panel.BackgroundColor3 = UI.Colors.Cream; panel.Visible = false; panel.Parent = gui; panel.ZIndex = 5
    UI.corner(panel, 24); UI.stroke(panel, UI.Colors.White, 2, 0.05)
    local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(860, 730); limit.MinSize = Vector2.new(270, 170); limit.Parent = panel
    self.Panel = panel
    local accent = Instance.new("Frame"); accent.Position = UDim2.fromOffset(17, 17); accent.Size = UDim2.fromOffset(5, 39)
    accent.BackgroundColor3 = UI.Colors.Teal; accent.Parent = panel; UI.corner(accent, 3); UI.gradient(accent, UI.Colors.Teal, Color3.fromRGB(24, 147, 222), 90)
    self.Title = UI.label(panel, "Your finds", 25); self.Title.Font = Enum.Font.GothamBold
    self.Title.Position = UDim2.fromOffset(32, 11); self.Title.Size = UDim2.new(1, -100, 0, 31); self.Title.AutomaticSize = Enum.AutomaticSize.None
    self.Title.TextTruncate = Enum.TextTruncate.AtEnd; self.Title.TextWrapped = false
    self.Subtitle = UI.label(panel, "THE THRIFT STREET JOURNAL", 11, UI.Colors.Muted)
    self.Subtitle.Font = Enum.Font.GothamBold; self.Subtitle.Position = UDim2.fromOffset(33, 43)
    self.Subtitle.Size = UDim2.new(1, -103, 0, 18); self.Subtitle.AutomaticSize = Enum.AutomaticSize.None
    self.Subtitle.TextTruncate = Enum.TextTruncate.AtEnd; self.Subtitle.TextWrapped = false
    local close = UI.button(panel, "×", function() self:hide() end, true)
    close.Size = UDim2.fromOffset(44, 44); close.Position = UDim2.new(1, -56, 0, 13); close.TextSize = 27
    local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Pages"; scroll.Position = UDim2.fromOffset(15, 74)
    scroll.Size = UDim2.new(1, -30, 1, -88); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
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
    local button = UI.button(self.QuickActions, text, callback, false)
    button.Size = UDim2.new(1, 0, 0, 56); button.TextSize = 13; button.ZIndex = 13
    for _, child in ipairs(button:GetChildren()) do if child:IsA("UIGradient") then child:Destroy() end end
    button.BackgroundColor3 = color; UI.gradient(button, color:Lerp(UI.Colors.White, 0.08), color:Lerp(UI.Colors.Night, 0.16), 15)
    return button
end
function UI:addNav(name, symbol, callback)
    local button = UI.button(self.Nav, symbol .. "\n" .. name, callback, true)
    button.TextSize = 14; button.BackgroundColor3 = UI.Colors.Night; button.TextColor3 = Color3.fromRGB(202, 215, 231); button.ZIndex = 13
    self.NavButtons[name] = button; return button
end
function UI:selectNav(name)
    for label, button in pairs(self.NavButtons) do
        local selected = label == name or (label == "Find" and name == "Source")
        button.BackgroundColor3 = if selected then UI.Colors.Teal else UI.Colors.Night
        button.TextColor3 = if selected then UI.Colors.White else Color3.fromRGB(202, 215, 231)
    end
end
function UI:setSubtitle(text) self.Subtitle.Text = string.upper(text) end
function UI:hide()
    if self.Locked then self:notice("Finish or cancel your restoration first."); return end
    self.Panel.Visible = false; self.Overlay.Visible = false; self:selectNav(nil)
end
function UI:clear(title, subtitle, preserveScroll)
    for _, connection in ipairs(self.PageConnections) do connection:Disconnect() end; self.PageConnections = {}
    local scroll = if preserveScroll then self.Content.CanvasPosition else Vector2.zero
    for _, child in ipairs(self.Content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    self.Title.Text = title; self:setSubtitle(subtitle or "THE THRIFT STREET JOURNAL")
    local opening = not self.Panel.Visible
    self.Panel.Visible = true; self.Overlay.Visible = true
    if opening and self.Effects then
        self.Overlay.BackgroundTransparency = 1; tween(self.Overlay, {BackgroundTransparency = 0.4}, 0.18)
    end
    self.Content.CanvasPosition = scroll
    if preserveScroll then task.defer(function() self.Content.CanvasPosition = scroll end) end
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
