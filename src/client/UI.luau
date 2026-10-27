-- Shared visual language for the Thrift Flip client. All art here is vector UI or
-- an in-game model, so menus work without third-party image dependencies.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = {}
UI.Colors = {
    Cream = Color3.fromRGB(255, 246, 229), Panel = Color3.fromRGB(255, 250, 241),
    Ink = Color3.fromRGB(15, 79, 75), Teal = Color3.fromRGB(22, 122, 116),
    Muted = Color3.fromRGB(83, 108, 104), Rose = Color3.fromRGB(242, 120, 92),
    Gold = Color3.fromRGB(242, 181, 68), Line = Color3.fromRGB(203, 213, 201),
    Light = Color3.fromRGB(236, 244, 234), White = Color3.fromRGB(255, 255, 255),
    Wood = Color3.fromRGB(146, 103, 72), Night = Color3.fromRGB(31, 39, 42),
    Red = Color3.fromRGB(210, 64, 43),
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
function UI.vectorIcon(parent, kind, color, position, size, zIndex)
    -- HUD icons are drawn from Roblox Frames instead of Unicode glyphs or
    -- uploaded images. They therefore render identically on every platform.
    local ink = color or UI.Colors.Ink
    local canvas = Instance.new("Frame"); canvas.Name = "VectorIcon"; canvas.AnchorPoint = Vector2.new(0.5, 0)
    canvas.Position = position or UDim2.new(0.5, 0, 0, 3); canvas.Size = UDim2.fromOffset(size or 24, size or 24)
    canvas.BackgroundTransparency = 1; canvas.ZIndex = zIndex or ((parent.ZIndex or 1) + 1); canvas.Parent = parent
    local z = canvas.ZIndex
    local function line(x, y, width, height, rotation)
        local part = Instance.new("Frame"); part.Name = "IconPart"; part.AnchorPoint = Vector2.new(0.5, 0.5)
        part.Position = UDim2.fromOffset(x, y); part.Size = UDim2.fromOffset(width, height); part.Rotation = rotation or 0
        part.BackgroundColor3 = ink; part.BorderSizePixel = 0; part.ZIndex = z; part.Parent = canvas; UI.corner(part, math.min(width, height) / 2)
        return part
    end
    local function outline(x, y, width, height, radius)
        local part = Instance.new("Frame"); part.Name = "IconOutline"; part.Position = UDim2.fromOffset(x, y)
        part.Size = UDim2.fromOffset(width, height); part.BackgroundTransparency = 1; part.ZIndex = z; part.Parent = canvas
        UI.corner(part, radius or 2); local stroke = UI.stroke(part, ink, 2, 0); stroke.Name = "IconStroke"
        return part
    end
    local function dot(x, y, diameter)
        local part = line(x, y, diameter, diameter); UI.corner(part, diameter / 2); return part
    end

    if kind == "home" then
        outline(5, 10, 14, 11, 2); line(8, 8, 11, 2, -38); line(16, 8, 11, 2, 38); line(12, 17, 2, 8)
    elseif kind == "bag" then
        outline(4, 8, 16, 13, 3); outline(8, 3, 8, 8, 4)
    elseif kind == "shop" then
        outline(5, 9, 14, 12, 1); line(12, 7, 18, 3); line(8, 7, 2, 5); line(12, 7, 2, 5); line(16, 7, 2, 5); line(12, 17, 14, 2)
    elseif kind == "search" then
        outline(3, 3, 13, 13, 7); line(18, 18, 8, 2, 45)
    elseif kind == "quests" then
        outline(4, 3, 16, 19, 3); line(8, 9, 3, 2, 42); line(10, 8, 5, 2, -45); line(15, 9, 6, 2)
        line(8, 15, 3, 2, 42); line(10, 14, 5, 2, -45); line(15, 15, 6, 2)
    elseif kind == "travel" then
        line(14, 5, 10, 3, -54); line(10, 11, 11, 3, 0); line(11, 17, 10, 3, -54)
    elseif kind == "gift" then
        outline(4, 9, 16, 12, 2); line(12, 15, 2, 12); line(12, 9, 18, 3)
        outline(6, 4, 6, 5, 3); outline(12, 4, 6, 5, 3)
    elseif kind == "store" then
        outline(4, 7, 16, 13, 3); line(8, 7, 2, 5); line(12, 7, 2, 5); line(16, 7, 2, 5); line(12, 5, 16, 2)
    elseif kind == "more" then
        dot(6, 12, 4); dot(12, 12, 4); dot(18, 12, 4)
    elseif kind == "style" then
        outline(3, 4, 18, 16, 8); dot(8, 9, 3); dot(13, 7, 3); dot(17, 11, 3); line(17, 18, 8, 5, -18)
    elseif kind == "tools" then
        line(8, 12, 17, 3, 45); line(16, 12, 17, 3, -45); line(5, 5, 6, 3, 0); line(19, 5, 6, 3, 0)
    elseif kind == "expand" then
        line(12, 13, 15, 3, -90); line(8, 7, 8, 3, -45); line(16, 7, 8, 3, 45); line(12, 21, 16, 2)
    elseif kind == "admin" then
        outline(5, 3, 14, 17, 6); line(12, 11, 10, 2, -90); line(12, 11, 8, 2)
    elseif kind == "settings" then
        line(7, 12, 6, 7); line(11, 9, 7, 2, -38); line(11, 15, 7, 2, 38)
        line(17, 8, 6, 2, 48); line(19, 12, 8, 2, 0); line(17, 16, 6, 2, -48)
    elseif kind == "chevron" then
        line(9, 11, 9, 2, 42); line(15, 11, 9, 2, -42); line(9, 16, 9, 2, 42); line(15, 16, 9, 2, -42)
    elseif kind == "arrow" then
        line(11, 12, 15, 3); line(17, 9, 9, 3, 45); line(17, 15, 9, 3, -45)
    elseif kind == "rank" then
        local diamond = line(12, 12, 12, 12, 45); UI.corner(diamond, 3); line(12, 12, 5, 5, 45).BackgroundColor3 = UI.Colors.Gold
    elseif kind == "gavel" then
        line(10, 8, 11, 5, 35); line(14, 14, 13, 3, -55); line(17, 20, 11, 3)
    end
    return canvas
end
function UI.tintIcon(parent, color)
    for _, child in ipairs(parent:GetDescendants()) do
        if child.Name == "IconPart" then child.BackgroundColor3 = color
        elseif child.Name == "IconStroke" and child:IsA("UIStroke") then child.Color = color end
    end
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
    button.BackgroundColor3 = if secondary then UI.Colors.Light else UI.Colors.Red
    button.Size = UDim2.new(1, 0, 0, 50); button.AutoButtonColor = false; button.Parent = parent
    UI.corner(button, 14); UI.padding(button, 10, 3)
    UI.stroke(button, if secondary then UI.Colors.Line else UI.Colors.White, 1, if secondary then 0.15 else 0.72)
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
    if definition and definition.CatalogAssetId then
        local catalog = Instance.new("ImageLabel"); catalog.Name = "CatalogReference"
        catalog.AnchorPoint = Vector2.new(1, 0); catalog.Position = UDim2.new(1, -8, 0, 8)
        catalog.Size = UDim2.fromOffset(94, 94); catalog.BackgroundColor3 = UI.Colors.Panel
        catalog.BackgroundTransparency = 0.08; catalog.BorderSizePixel = 0; catalog.ZIndex = 4
        catalog.Image = "rbxthumb://type=" .. (definition.CatalogItemType or "Asset") .. "&id=" .. definition.CatalogAssetId .. "&w=150&h=150"
        catalog.ScaleType = Enum.ScaleType.Crop; catalog.Parent = viewport; UI.corner(catalog, 9); UI.stroke(catalog, UI.Colors.White, 1, 0.2)
        local tag = UI.label(viewport, "ROBLOX CATALOG", 8, UI.Colors.White); tag.ZIndex = 5
        tag.AnchorPoint = Vector2.new(1, 0); tag.Position = UDim2.new(1, -8, 0, 102); tag.Size = UDim2.fromOffset(94, 14)
        tag.AutomaticSize = Enum.AutomaticSize.None; tag.TextXAlignment = Enum.TextXAlignment.Center
        tag.BackgroundColor3 = UI.Colors.Teal; tag.BackgroundTransparency = 0.05; UI.corner(tag, 5)
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
    local splashTag = UI.label(splash, "FIND  |  RESTORE  |  BUILD YOUR DREAM SHOP", 13, UI.Colors.Gold)
    splashTag.AnchorPoint = Vector2.new(0.5, 0); splashTag.Position = UDim2.fromScale(0.5, 0.51)
    splashTag.Size = UDim2.new(0.9, 0, 0, 30); splashTag.AutomaticSize = Enum.AutomaticSize.None; splashTag.TextXAlignment = Enum.TextXAlignment.Center; splashTag.ZIndex = 101
    task.delay(1.1, function()
        tween(splash, {BackgroundTransparency = 1}, 0.35); tween(splashTitle, {TextTransparency = 1}, 0.25); tween(splashTag, {TextTransparency = 1}, 0.25)
        task.wait(0.38); if splash.Parent then splash:Destroy() end
    end)
    local hud = Instance.new("Frame"); hud.Name = "TownHUD"; hud.Position = UDim2.fromOffset(10, 10)
    hud.Size = UDim2.new(1, -20, 0, 112); hud.BackgroundTransparency = 1; hud.Parent = gui
    local brand = Instance.new("Frame"); brand.Name = "BrandPill"; brand.Size = UDim2.fromOffset(190, 42)
    brand.BackgroundColor3 = Color3.fromRGB(255, 248, 232); brand.Parent = hud; UI.corner(brand, 23); UI.stroke(brand, UI.Colors.White, 2, 0.15)
    local badge = Instance.new("Frame"); badge.Size = UDim2.fromOffset(32, 32); badge.Position = UDim2.fromOffset(5, 5)
    badge.BackgroundColor3 = Color3.fromRGB(23, 132, 124); badge.Parent = brand; UI.corner(badge, 16)
    UI.vectorIcon(badge, "chevron", UI.Colors.White, UDim2.new(0.5, 0, 0, 4), 24, 3)
    self.Brand = UI.label(brand, "Thrift Flip", 16, Color3.fromRGB(8, 91, 84)); self.Brand.Font = Enum.Font.GothamBold
    self.Brand.Position = UDim2.fromOffset(43, 3); self.Brand.Size = UDim2.new(1, -49, 0, 20); self.Brand.AutomaticSize = Enum.AutomaticSize.None
    local tagline = UI.label(brand, "Every find has a story", 10, Color3.fromRGB(67, 86, 83))
    tagline.Position = UDim2.fromOffset(43, 21); tagline.Size = UDim2.new(1, -49, 0, 15); tagline.AutomaticSize = Enum.AutomaticSize.None
    local objective = Instance.new("Frame"); objective.Name = "Objective"; objective.Position = UDim2.fromOffset(0, 49)
    objective.Size = UDim2.fromOffset(210, 56); objective.BackgroundColor3 = Color3.fromRGB(20, 132, 124); objective.Parent = hud; UI.corner(objective, 14)
    UI.stroke(objective, Color3.fromRGB(8, 107, 101), 1, 0.25)
    UI.vectorIcon(objective, "arrow", UI.Colors.White, UDim2.fromOffset(23, 16), 24, 3)
    local objectiveTitle = UI.label(objective, "OBJECTIVE | 0/1", 9, Color3.fromRGB(187, 235, 226)); objectiveTitle.Font = Enum.Font.GothamBold; self.ObjectiveTitle = objectiveTitle
    objectiveTitle.Position = UDim2.fromOffset(36, 6); objectiveTitle.Size = UDim2.new(1, -45, 0, 14); objectiveTitle.AutomaticSize = Enum.AutomaticSize.None
    self.Hint = UI.label(objective, "Thrift your first fashion find", 12, UI.Colors.White); self.Hint.Font = Enum.Font.GothamBold
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
    local rankBadge = Instance.new("Frame"); rankBadge.Size = UDim2.fromOffset(27, 27); rankBadge.Position = UDim2.fromOffset(5, 5)
    rankBadge.BackgroundColor3 = Color3.fromRGB(20, 132, 124); rankBadge.BorderSizePixel = 0; rankBadge.Parent = levelPill; UI.corner(rankBadge, 14)
    UI.vectorIcon(rankBadge, "rank", UI.Colors.White, UDim2.new(0.5, 0, 0, 2), 23, 3)
    self.Level = UI.label(levelPill, "LV 1", 15, Color3.fromRGB(20, 75, 70)); self.Level.Font = Enum.Font.GothamBold
    self.Level.Position = UDim2.fromOffset(36, 5); self.Level.Size = UDim2.new(1, -40, 0, 28); self.Level.AutomaticSize = Enum.AutomaticSize.None
    local levelTrack = Instance.new("Frame"); levelTrack.Name = "LevelProgress"; levelTrack.Position = UDim2.new(0, 36, 1, -5)
    levelTrack.Size = UDim2.new(1, -48, 0, 3); levelTrack.BackgroundColor3 = Color3.fromRGB(31, 111, 104); levelTrack.BorderSizePixel = 0; levelTrack.Parent = objective; UI.corner(levelTrack, 3)
    local levelFill = Instance.new("Frame"); levelFill.Name = "Fill"; levelFill.Size = UDim2.fromScale(0, 1)
    levelFill.BackgroundColor3 = UI.Colors.Gold; levelFill.BorderSizePixel = 0; levelFill.Parent = levelTrack; UI.corner(levelFill, 3); self.LevelProgress = levelFill
    local auctionBar = Instance.new("TextButton"); auctionBar.Name = "AuctionBossBar"; auctionBar.Text = ""; auctionBar.AutoButtonColor = false; auctionBar.AnchorPoint = Vector2.new(0.5, 0)
    auctionBar.Position = UDim2.new(0.5, 0, 0, 10); auctionBar.Size = UDim2.new(0.46, 0, 0, 58)
    auctionBar.BackgroundColor3 = UI.Colors.Ink; auctionBar.BorderSizePixel = 0; auctionBar.Visible = false; auctionBar.ZIndex = 20; auctionBar.Parent = gui
    UI.corner(auctionBar, 15); UI.stroke(auctionBar, UI.Colors.Gold, 2, 0.08)
    local auctionLimit = Instance.new("UISizeConstraint"); auctionLimit.MaxSize = Vector2.new(520, 58); auctionLimit.MinSize = Vector2.new(260, 58); auctionLimit.Parent = auctionBar
    UI.vectorIcon(auctionBar, "gavel", UI.Colors.Gold, UDim2.fromOffset(25, 7), 25, 21)
    self.AuctionTitle = UI.label(auctionBar, "LIVE AUCTION", 11, UI.Colors.Cream); self.AuctionTitle.Font = Enum.Font.GothamBold
    self.AuctionTitle.Position = UDim2.fromOffset(42, 5); self.AuctionTitle.Size = UDim2.new(1, -116, 0, 20); self.AuctionTitle.AutomaticSize = Enum.AutomaticSize.None
    self.AuctionTitle.TextTruncate = Enum.TextTruncate.AtEnd; self.AuctionTitle.TextWrapped = false; self.AuctionTitle.ZIndex = 21
    self.AuctionBid = UI.label(auctionBar, "Opening bid | $0", 12, UI.Colors.White); self.AuctionBid.Font = Enum.Font.GothamBold
    self.AuctionBid.Position = UDim2.fromOffset(42, 23); self.AuctionBid.Size = UDim2.new(1, -116, 0, 21); self.AuctionBid.AutomaticSize = Enum.AutomaticSize.None
    self.AuctionBid.TextTruncate = Enum.TextTruncate.AtEnd; self.AuctionBid.TextWrapped = false; self.AuctionBid.ZIndex = 21
    self.AuctionTime = UI.label(auctionBar, "0:00", 16, UI.Colors.Gold); self.AuctionTime.Font = Enum.Font.GothamBold
    self.AuctionTime.Position = UDim2.new(1, -72, 0, 14); self.AuctionTime.Size = UDim2.fromOffset(60, 24); self.AuctionTime.AutomaticSize = Enum.AutomaticSize.None
    self.AuctionTime.TextXAlignment = Enum.TextXAlignment.Right; self.AuctionTime.ZIndex = 21
    local auctionTrack = Instance.new("Frame"); auctionTrack.Position = UDim2.new(0, 13, 1, -8); auctionTrack.Size = UDim2.new(1, -26, 0, 4)
    auctionTrack.BackgroundColor3 = Color3.fromRGB(64, 112, 106); auctionTrack.BorderSizePixel = 0; auctionTrack.ZIndex = 21; auctionTrack.Parent = auctionBar; UI.corner(auctionTrack, 3)
    self.AuctionProgress = Instance.new("Frame"); self.AuctionProgress.Size = UDim2.fromScale(1, 1); self.AuctionProgress.BackgroundColor3 = UI.Colors.Gold
    self.AuctionProgress.BorderSizePixel = 0; self.AuctionProgress.ZIndex = 22; self.AuctionProgress.Parent = auctionTrack; UI.corner(self.AuctionProgress, 3)
    self.AuctionBar = auctionBar
    local nav = Instance.new("Frame"); nav.Name = "Navigation"; nav.AnchorPoint = Vector2.new(0.5, 1)
    nav.Position = UDim2.new(0.5, 0, 1, -12); nav.Size = UDim2.new(1, -24, 0, 62)
    nav.BackgroundColor3 = Color3.fromRGB(255, 248, 232); nav.Parent = gui; nav.ZIndex = 12; UI.corner(nav, 22); UI.padding(nav, 6, 6)
    UI.stroke(nav, Color3.fromRGB(122, 143, 135), 1, 0.45)
    local navLimit = Instance.new("UISizeConstraint"); navLimit.MaxSize = Vector2.new(360, 62); navLimit.Parent = nav
    local grid = Instance.new("UIGridLayout"); grid.CellSize = UDim2.new(0.2, -4, 1, 0); grid.CellPadding = UDim2.fromOffset(5, 0)
    grid.SortOrder = Enum.SortOrder.LayoutOrder; grid.Parent = nav; self.Nav = nav; self.NavButtons = {}
    local actions = Instance.new("Frame"); actions.Name = "QuickActions"; actions.AnchorPoint = Vector2.new(1, 0.5)
    actions.Position = UDim2.new(1, -14, 0.5, 0); actions.Size = UDim2.fromOffset(60, 48)
    actions.BackgroundTransparency = 1; actions.Parent = gui; actions.ZIndex = 12; UI.list(actions, 6)
    self.QuickActions = actions; self.QuickActionCount = 0; self.QuickButtons = {}
    local moreMenu = Instance.new("Frame"); moreMenu.Name = "MoreMenu"; moreMenu.AnchorPoint = Vector2.new(1, 0.5)
    moreMenu.Position = UDim2.new(1, -82, 0.5, 25); moreMenu.Size = UDim2.fromOffset(104, 0)
    moreMenu.BackgroundColor3 = UI.Colors.Cream; moreMenu.BorderSizePixel = 0; moreMenu.Visible = false; moreMenu.ZIndex = 14; moreMenu.Parent = gui
    UI.corner(moreMenu, 15); UI.stroke(moreMenu, Color3.fromRGB(122,143,135), 1, 0.38); UI.padding(moreMenu, 7, 7); UI.list(moreMenu, 2)
    self.MoreMenu = moreMenu; self.MoreActionCount = 0
    local moreButton = UI.button(actions, "More", function() moreMenu.Visible = not moreMenu.Visible end, true)
    moreButton.LayoutOrder = 100; moreButton.Size = UDim2.new(1, 0, 0, 48); moreButton.TextSize = 10; moreButton.ZIndex = 13
    moreButton.TextYAlignment = Enum.TextYAlignment.Bottom; moreButton.BackgroundColor3 = UI.Colors.Teal; moreButton.TextColor3 = UI.Colors.White
    UI.vectorIcon(moreButton, "more", UI.Colors.White, UDim2.new(0.5, 0, 0, 2), 23, 14); self.MoreButton = moreButton
    local camera = workspace.CurrentCamera
    local function fitQuickActions()
        local narrow = camera and camera.ViewportSize.X < 900
        actions.Visible = true
        auctionBar.Position = if narrow then UDim2.new(0.5, 0, 0, 122) else UDim2.new(0.5, 0, 0, 10)
        auctionBar.Size = if narrow then UDim2.new(1, -190, 0, 58) else UDim2.new(0.46, 0, 0, 58)
    end
    if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitQuickActions) end
    fitQuickActions()
    local overlay = Instance.new("TextButton"); overlay.Name = "ModalBackdrop"; overlay.Text = ""; overlay.AutoButtonColor = false
    overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = Color3.fromRGB(31, 79, 74); overlay.BackgroundTransparency = 0.46
    overlay.BorderSizePixel = 0; overlay.Visible = false; overlay.ZIndex = 4; overlay.Parent = gui; self.Overlay = overlay
    local shadow = Instance.new("Frame"); shadow.Name = "ModalShadow"; shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 4, 0.5, -16); shadow.Size = UDim2.new(1, -24, 1, -100)
    shadow.BackgroundColor3 = Color3.fromRGB(12, 52, 48); shadow.BackgroundTransparency = 0.62; shadow.Visible = false; shadow.ZIndex = 5; shadow.Parent = gui
    UI.corner(shadow, 26); local shadowLimit = Instance.new("UISizeConstraint"); shadowLimit.MaxSize = Vector2.new(780, 730); shadowLimit.MinSize = Vector2.new(270, 170); shadowLimit.Parent = shadow; self.PanelShadow = shadow; self.ShadowLimit = shadowLimit
    local panel = Instance.new("Frame"); panel.Name = "Journal"; panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, -22); panel.Size = UDim2.new(1, -24, 1, -100)
    panel.BackgroundColor3 = UI.Colors.Cream; panel.Visible = false; panel.Parent = gui; panel.ZIndex = 6
    UI.corner(panel, 26); UI.stroke(panel, UI.Colors.White, 2, 0.12)
    local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(780, 730); limit.MinSize = Vector2.new(270, 170); limit.Parent = panel; self.PanelLimit = limit
    local panelScale = Instance.new("UIScale"); panelScale.Parent = panel; self.PanelScale = panelScale; self.Panel = panel
    local header = Instance.new("Frame"); header.Name = "ModalHeader"; header.Size = UDim2.new(1, 0, 0, 58)
    header.BackgroundColor3 = Color3.fromRGB(20, 132, 124); header.BorderSizePixel = 0; header.Parent = panel; header.ZIndex = 7; UI.corner(header, 25)
    local headerMask = Instance.new("Frame"); headerMask.Position = UDim2.new(0, 0, 1, -20); headerMask.Size = UDim2.new(1, 0, 0, 20)
    headerMask.BackgroundColor3 = header.BackgroundColor3; headerMask.BorderSizePixel = 0; headerMask.Parent = header; headerMask.ZIndex = 7
    self.Title = UI.label(header, "Your finds", 20, UI.Colors.White); self.Title.Font = Enum.Font.GothamBold; self.Title.ZIndex = 8
    self.Title.Position = UDim2.fromOffset(17, 5); self.Title.Size = UDim2.new(1, -72, 0, 26); self.Title.AutomaticSize = Enum.AutomaticSize.None
    self.Title.TextTruncate = Enum.TextTruncate.AtEnd; self.Title.TextWrapped = false
    self.Subtitle = UI.label(header, "THRIFT STREET", 10, Color3.fromRGB(191, 237, 229)); self.Subtitle.ZIndex = 8
    self.Subtitle.Font = Enum.Font.GothamBold; self.Subtitle.Position = UDim2.fromOffset(18, 31)
    self.Subtitle.Size = UDim2.new(1, -74, 0, 16); self.Subtitle.AutomaticSize = Enum.AutomaticSize.None
    self.Subtitle.TextTruncate = Enum.TextTruncate.AtEnd; self.Subtitle.TextWrapped = false
    local close = UI.button(header, "X", function() self:hide() end, true)
    close.Size = UDim2.fromOffset(36, 36); close.Position = UDim2.new(1, -46, 0, 10); close.TextSize = 22; close.ZIndex = 9; close.BackgroundColor3 = UI.Colors.Cream
    local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Pages"; scroll.Position = UDim2.fromOffset(13, 70)
    scroll.Size = UDim2.new(1, -26, 1, -82); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
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
function UI:addQuickAction(label, iconKind, color, callback)
    local button = UI.button(self.QuickActions, label, callback, true)
    self.QuickActionCount += 1
    button.LayoutOrder = self.QuickActionCount
    button.Size = UDim2.new(1, 0, 0, 48); button.TextSize = 10; button.TextYAlignment = Enum.TextYAlignment.Bottom; button.ZIndex = 13
    for _, child in ipairs(button:GetChildren()) do if child:IsA("UIGradient") then child:Destroy() end end
    button.BackgroundColor3 = Color3.fromRGB(255, 248, 232); button.TextColor3 = Color3.fromRGB(8, 91, 84)
    UI.corner(button, 15)
    self.QuickActions.Size = UDim2.fromOffset(60, (self.QuickActionCount + 1) * 48 + self.QuickActionCount * 6)
    UI.vectorIcon(button, iconKind, Color3.fromRGB(8, 91, 84), UDim2.new(0.5, 0, 0, 2), 23, 14)
    self.QuickButtons[label] = button
    return button
end
function UI:addMoreAction(label, iconKind, callback)
    self.MoreActionCount += 1
    local button = UI.button(self.MoreMenu, "      " .. label, function() self.MoreMenu.Visible = false; callback() end, true)
    button.LayoutOrder = self.MoreActionCount; button.Size = UDim2.new(1, 0, 0, 34); button.TextSize = 11; button.ZIndex = 15
    button.BackgroundTransparency = 1; button.TextColor3 = UI.Colors.Ink; button.TextXAlignment = Enum.TextXAlignment.Left
    UI.padding(button, 8, 2)
    UI.vectorIcon(button, iconKind, UI.Colors.Ink, UDim2.fromOffset(16, 4), 24, 16)
    self.MoreMenu.Size = UDim2.fromOffset(104, self.MoreActionCount * 36 + 14)
    return button
end
function UI:setActionBadge(button, visible)
    if not button then return end
    local badge = button:FindFirstChild("NotificationBadge")
    if visible and not badge then
        badge = Instance.new("Frame"); badge.Name = "NotificationBadge"; badge.Size = UDim2.fromOffset(11, 11)
        badge.Position = UDim2.new(1, -10, 0, -2); badge.BackgroundColor3 = UI.Colors.Red; badge.BorderSizePixel = 0; badge.ZIndex = 16; badge.Parent = button
        UI.corner(badge, 6); UI.stroke(badge, UI.Colors.Cream, 2, 0)
    elseif badge then badge.Visible = visible end
end
function UI:updateAuction(auction, itemName, serverTime)
    if not auction then
        self.AuctionBar.Visible = false; self.AuctionEnds = nil
        return
    end
    self.AuctionBar.Visible = true
    self.AuctionTitle.Text = "LIVE AUCTION  |  " .. string.upper(itemName or "MYSTERY LOT")
    self.AuctionBid.Text = (auction.BidderName and ("Latest: " .. auction.BidderName) or "Opening bid") .. "  |  $" .. tostring(math.floor(auction.Bid or 0))
    self.AuctionEnds = auction.Ends; self.AuctionClockOffset = (serverTime or os.time()) - os.time()
    if not self.AuctionHeartbeat then
        local last = 0
        self.AuctionHeartbeat = RunService.Heartbeat:Connect(function()
            if not self.AuctionBar.Visible or not self.AuctionEnds or os.clock() - last < 0.1 then return end
            last = os.clock()
            if not SharedConfig then SharedConfig = require(ReplicatedStorage.Shared.Config) end
            local left = math.max(0, self.AuctionEnds - (os.time() + (self.AuctionClockOffset or 0)))
            self.AuctionTime.Text = string.format("%d:%02d", math.floor(left / 60), left % 60)
            self.AuctionProgress.Size = UDim2.fromScale(math.clamp(left / math.max(1, SharedConfig.AuctionDuration or 45), 0, 1), 1)
        end)
    end
end
function UI:addNav(name, symbol, callback)
    local button = UI.button(self.Nav, name, callback, true)
    button.TextSize = 11; button.TextYAlignment = Enum.TextYAlignment.Bottom; button.BackgroundColor3 = Color3.fromRGB(255, 248, 232); button.TextColor3 = Color3.fromRGB(8, 91, 84); button.ZIndex = 13
    UI.vectorIcon(button, symbol, button.TextColor3, UDim2.new(0.5, 0, 0, 1), 25, 14)
    self.NavButtons[name] = button; return button
end
function UI:selectNav(name)
    for label, button in pairs(self.NavButtons) do
        local selected = label == name or (label == "Find" and name == "Source")
        button.BackgroundColor3 = if selected then Color3.fromRGB(20, 132, 124) else Color3.fromRGB(255, 248, 232)
        button.TextColor3 = if selected then UI.Colors.White else Color3.fromRGB(8, 91, 84)
        UI.tintIcon(button, button.TextColor3)
    end
end
function UI:setSubtitle(text) self.Subtitle.Text = string.upper(text) end
function UI:setPanelMode(compact)
    local size = if compact then UDim2.new(0.9, 0, 0.82, 0) else UDim2.new(1, -24, 1, -100)
    local maximum = if compact then Vector2.new(390, 650) else Vector2.new(780, 730)
    self.Panel.Size = size; self.PanelShadow.Size = size
    self.PanelLimit.MaxSize = maximum; self.ShadowLimit.MaxSize = maximum
end
function UI:hide()
    if self.Locked then self:notice("Finish or cancel your restoration first."); return end
    self.Panel.Visible = false; self.PanelShadow.Visible = false; self.Overlay.Visible = false; self.MoreMenu.Visible = false; self:selectNav(nil)
end
function UI:clear(title, subtitle, preserveScroll)
    for _, connection in ipairs(self.PageConnections) do connection:Disconnect() end; self.PageConnections = {}
    local scroll = if preserveScroll then self.Content.CanvasPosition else Vector2.zero
    for _, child in ipairs(self.Content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    self.Title.Text = title; self:setSubtitle(subtitle or "THE THRIFT STREET JOURNAL")
    local opening = not self.Panel.Visible
    self.Panel.Visible = true; self.PanelShadow.Visible = true; self.Overlay.Visible = true
    if opening and self.Effects then
        self.Overlay.BackgroundTransparency = 1; tween(self.Overlay, {BackgroundTransparency = 0.46}, 0.18)
        self.PanelScale.Scale = 0.94; tween(self.PanelScale, {Scale = 1}, 0.2)
    end
    self.Content.CanvasPosition = scroll
    if preserveScroll then task.defer(function() self.Content.CanvasPosition = scroll end) end
end
function UI:searchTreasure(source, callback)
    if self.Searching then return end
    self.Searching = true
    local baseZ = 40
    local function block(parent, name, size, position, color, z)
        local frame = Instance.new("Frame"); frame.Name = name; frame.Size = size; frame.Position = position
        frame.BackgroundColor3 = color; frame.BorderSizePixel = 0; frame.ZIndex = z or baseZ + 2; frame.Parent = parent
        return frame
    end

    local layer = block(self.Gui, "TreasureSearch", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), UI.Colors.Night, baseZ)
    layer.BackgroundTransparency = 0.18; layer.Active = true
    local panel = block(layer, "SearchPanel", UDim2.new(0.92, 0, 0, 400), UDim2.fromScale(0.5, 0.5), UI.Colors.Cream, baseZ + 1)
    panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.ClipsDescendants = true; UI.corner(panel, 26); UI.stroke(panel, UI.Colors.White, 2, 0.12)
    local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(520, 400); limit.MinSize = Vector2.new(300, 360); limit.Parent = panel
    local panelScale = Instance.new("UIScale"); panelScale.Scale = 0.92; panelScale.Parent = panel
    if self.Effects then tween(panelScale, {Scale = 1}, 0.22) else panelScale.Scale = 1 end

    local header = block(panel, "Header", UDim2.new(1, 0, 0, 66), UDim2.fromOffset(0, 0), UI.Colors.Teal, baseZ + 2)
    local heading = UI.label(header, "Source", 25, UI.Colors.Cream); heading.Font = Enum.Font.GothamBold
    heading.Position = UDim2.fromOffset(20, 8); heading.Size = UDim2.new(1, -40, 0, 30); heading.AutomaticSize = Enum.AutomaticSize.None; heading.ZIndex = baseZ + 3
    local sourceCopy = if source == "Delivery" then "DONATION DROP | DAILY BAG" elseif source == "Estate" then "CURATED RACK | PREMIUM FINDS" else "THRIFT OUTLET | $25 PER FIND"
    local eyebrow = UI.label(header, sourceCopy, 11, UI.Colors.Cream); eyebrow.Font = Enum.Font.GothamBold
    eyebrow.TextTransparency = 0.08; eyebrow.Position = UDim2.fromOffset(20, 38); eyebrow.Size = UDim2.new(1, -40, 0, 17); eyebrow.AutomaticSize = Enum.AutomaticSize.None; eyebrow.ZIndex = baseZ + 3

    local stage = block(panel, "SearchStage", UDim2.new(1, 0, 0, 270), UDim2.fromOffset(0, 66), Color3.fromRGB(74, 86, 84), baseZ + 2)
    stage.ClipsDescendants = true
    local wall = block(stage, "BrickWall", UDim2.new(1, 0, 0, 202), UDim2.fromOffset(0, 0), Color3.fromRGB(104, 70, 62), baseZ + 2)
    for row = 1, 8 do
        local mortar = block(wall, "Mortar", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, row * 24), Color3.fromRGB(65, 55, 52), baseZ + 3)
        mortar.BackgroundTransparency = 0.55
    end
    local ground = block(stage, "Ground", UDim2.new(1, 0, 0, 70), UDim2.new(0, 0, 1, -70), Color3.fromRGB(58, 68, 66), baseZ + 3)

    local lamp = block(stage, "Lamp", UDim2.fromOffset(17, 17), UDim2.new(1, -64, 0, 27), Color3.fromRGB(255, 233, 168), baseZ + 4)
    UI.corner(lamp, 9)
    local lampGlow = block(stage, "LampGlow", UDim2.fromOffset(58, 58), UDim2.new(1, -84, 0, 6), Color3.fromRGB(255, 233, 168), baseZ + 3)
    lampGlow.BackgroundTransparency = 0.76; UI.corner(lampGlow, 29)

    local dumpster = Instance.new("Frame"); dumpster.Name = "ClothingBin"; dumpster.AnchorPoint = Vector2.new(0.5, 1)
    dumpster.Position = UDim2.new(0.5, 0, 1, -48); dumpster.Size = UDim2.fromOffset(190, 128)
    dumpster.BackgroundTransparency = 1; dumpster.ZIndex = baseZ + 5; dumpster.Parent = stage
    local body = block(dumpster, "Body", UDim2.fromOffset(190, 92), UDim2.fromOffset(0, 36), Color3.fromRGB(62, 142, 90), baseZ + 6)
    UI.corner(body, 9); UI.gradient(body, Color3.fromRGB(71, 157, 99), Color3.fromRGB(45, 110, 68), 90)
    local band = block(body, "Band", UDim2.new(1, 0, 0, 10), UDim2.fromOffset(0, 34), Color3.fromRGB(46, 110, 68), baseZ + 7)
    local lid = block(dumpster, "Lid", UDim2.fromOffset(198, 17), UDim2.fromOffset(-4, 29), Color3.fromRGB(43, 43, 51), baseZ + 9)
    lid.AnchorPoint = Vector2.new(0, 1); UI.corner(lid, 6)
    for _, x in ipairs({14, 158}) do
        local wheel = block(dumpster, "Wheel", UDim2.fromOffset(19, 19), UDim2.fromOffset(x, 116), Color3.fromRGB(43, 43, 51), baseZ + 8); UI.corner(wheel, 10)
    end
    local props = {
        {26, 14, 22, 47, Color3.fromRGB(127, 200, 232), -8},
        {83, 22, 51, 27, UI.Colors.Red, 6},
        {140, 17, 31, 35, UI.Colors.Gold, -5},
    }
    local finds = {}
    for index, data in ipairs(props) do
        local prop = block(dumpster, "PeekFind" .. index, UDim2.fromOffset(data[3], data[4]), UDim2.fromOffset(data[1], data[2]), data[5], baseZ + 5)
        prop.Rotation = data[6]; UI.corner(prop, if index == 3 then 14 else 7); table.insert(finds, {Frame = prop, Y = data[2], Rotation = data[6]})
    end

    local flash = block(stage, "RevealFlash", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), UI.Colors.White, baseZ + 18)
    flash.BackgroundTransparency = 1
    local status = UI.label(panel, "Checking labels and sorting the rack...", 17, UI.Colors.Ink); status.Font = Enum.Font.GothamBold
    status.Position = UDim2.new(0, 18, 1, -56); status.Size = UDim2.new(1, -36, 0, 26); status.AutomaticSize = Enum.AutomaticSize.None
    status.TextXAlignment = Enum.TextXAlignment.Center; status.ZIndex = baseZ + 4
    local track = block(panel, "SearchProgress", UDim2.new(1, -40, 0, 7), UDim2.new(0, 20, 1, -18), Color3.fromRGB(218, 225, 211), baseZ + 3); UI.corner(track, 5)
    local fill = block(track, "Fill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), UI.Colors.Red, baseZ + 4); UI.corner(fill, 5)
    TweenService:Create(fill, TweenInfo.new(2.3, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1, 1)}):Play()

    local function dust(step)
        if not self.Effects or not stage.Parent then return end
        local puff = block(stage, "Dust", UDim2.fromOffset(8 + step % 3 * 3, 8 + step % 3 * 3), UDim2.new(0.5, -72 + (step * 29) % 144, 1, -126), Color3.fromRGB(232, 226, 212), baseZ + 11)
        puff.BackgroundTransparency = 0.28; UI.corner(puff, 12)
        local drift = -22 + (step * 17) % 45
        TweenService:Create(puff, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = puff.Position + UDim2.fromOffset(drift, -68), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
        }):Play(); task.delay(0.9, function() if puff.Parent then puff:Destroy() end end)
    end
    local function burst()
        if not self.Effects then return end
        local colors = {UI.Colors.Gold, UI.Colors.Rose, UI.Colors.Cream, UI.Colors.Teal, Color3.fromRGB(91, 133, 240)}
        for index = 1, 18 do
            local angle = index / 18 * math.pi * 2 + (index % 3) * 0.12
            local distance = 75 + (index * 23) % 105
            local spark = UI.label(stage, if index % 3 == 0 then "+" else "*", 14 + index % 4 * 3, colors[index % #colors + 1])
            spark.AnchorPoint = Vector2.new(0.5, 0.5); spark.Position = UDim2.fromScale(0.5, 0.56); spark.Size = UDim2.fromOffset(28, 28)
            spark.AutomaticSize = Enum.AutomaticSize.None; spark.TextXAlignment = Enum.TextXAlignment.Center; spark.ZIndex = baseZ + 17; spark.Rotation = index * 21
            tween(spark, {Position = spark.Position + UDim2.fromOffset(math.cos(angle) * distance, math.sin(angle) * distance - 32), TextTransparency = 1, Rotation = spark.Rotation + 180}, 0.9)
            task.delay(0.95, function() if spark.Parent then spark:Destroy() end end)
        end
    end

    task.spawn(function()
        local messages = {"Sorting through the rack...", "Checking size and condition...", "This label looks special..."}
        for step = 1, 21 do
            if not layer.Parent then self.Searching = false; return end
            if step == 8 then status.Text = messages[2] elseif step == 15 then status.Text = messages[3] end
            if self.Effects then
                dumpster.Rotation = if step % 2 == 0 then 1.2 else -1.2
                dumpster.Position = UDim2.new(0.5, if step % 2 == 0 then 2 else -3, 1, -48 + step % 3 - 1)
                lid.Rotation = if step % 2 == 0 then -4 else -19
                for index, entry in ipairs(finds) do
                    entry.Frame.Position = UDim2.fromOffset(props[index][1], entry.Y - (step + index * 2) % 5 * 3)
                    entry.Frame.Rotation = if step % 2 == 0 then -entry.Rotation else entry.Rotation
                end
                if step % 2 == 0 then dust(step) end
            end
            task.wait(0.11)
        end
        dumpster.Rotation = 0; dumpster.Position = UDim2.new(0.5, 0, 1, -48); lid.Rotation = -58
        status.Text = "You thrifted a fashion find!"; fill.BackgroundColor3 = UI.Colors.Gold
        if self.Effects then
            flash.BackgroundTransparency = 0.12; tween(flash, {BackgroundTransparency = 1}, 0.42); burst()
            tween(dumpster, {Position = UDim2.new(0.5, 0, 1, -12)}, 0.42)
        end
        task.wait(if self.Effects then 0.42 else 0.06)
        self.Searching = false
        local ok, message = pcall(callback)
        if not ok then warn("Thrift search callback failed: " .. tostring(message)) end
        if layer.Parent then
            tween(layer, {BackgroundTransparency = 1}, 0.16); tween(panelScale, {Scale = 0.96}, 0.16)
            task.wait(0.16); layer:Destroy()
        end
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
            local symbol = UI.label(layer, if index % 3 == 0 then SharedConfig.RarityIcons[rarity] else "+", 16 + index % 4 * 5, color)
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
    local detail = UI.label(card, SharedConfig.Conditions[item.Condition] .. " | " .. (item.Style or definition.Style) .. " | $" .. tostring(math.floor(item.Value or 0)), 15, UI.Colors.Muted)
    detail.Position = UDim2.fromOffset(18, 394); detail.Size = UDim2.new(1, -36, 0, 28); detail.AutomaticSize = Enum.AutomaticSize.None
    detail.TextXAlignment = Enum.TextXAlignment.Center; detail.ZIndex = 53
    local button = UI.button(card, if rarity >= 5 then "LEGENDARY | Keep this find" else "Add to my collection", function()
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
    local targetY = if self.AuctionBar.Visible then 190 else 96
    if self.Effects then
        self.Toast.Position = UDim2.new(0.5, 0, 0, targetY - 10); tween(self.Toast, {Position = UDim2.new(0.5, 0, 0, targetY)}, 0.18)
    else self.Toast.Position = UDim2.new(0.5, 0, 0, targetY)
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
