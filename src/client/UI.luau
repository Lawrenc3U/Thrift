local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UI = {}
UI.Colors = {Cream = Color3.fromRGB(249, 242, 225), Panel = Color3.fromRGB(255, 251, 240),
    Ink = Color3.fromRGB(45, 64, 59), Teal = Color3.fromRGB(79, 139, 122),
    Muted = Color3.fromRGB(112, 126, 116), Rose = Color3.fromRGB(198, 113, 125), Gold = Color3.fromRGB(229, 178, 78)}
function UI.corner(object, radius)
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 12); corner.Parent = object
end
function UI.label(parent, text, size, color)
    local label = Instance.new("TextLabel"); label.Text = text; label.TextSize = size or 18
    label.Font = Enum.Font.GothamMedium; label.TextColor3 = color or UI.Colors.Ink
    label.TextXAlignment = Enum.TextXAlignment.Left; label.TextYAlignment = Enum.TextYAlignment.Center
    label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 0, 32); label.TextWrapped = true; label.AutomaticSize = Enum.AutomaticSize.Y
    label.Parent = parent; return label
end
function UI.button(parent, text, callback, secondary)
    local button = Instance.new("TextButton"); button.Text = text; button.Font = Enum.Font.GothamBold
    button.TextSize = 16; button.TextWrapped = true; button.TextColor3 = if secondary then UI.Colors.Ink else UI.Colors.Panel
    button.BackgroundColor3 = if secondary then Color3.fromRGB(232, 230, 211) else UI.Colors.Teal
    button.Size = UDim2.new(1, 0, 0, 48); button.AutoButtonColor = true; button.Parent = parent; UI.corner(button)
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = button
    button.Activated:Connect(callback); return button
end
function UI.list(parent, gap)
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, gap or 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = parent; return layout
end
function UI.card(parent)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, -4, 0, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = UI.Colors.Panel; frame.Parent = parent; UI.corner(frame)
    local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 12); padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12); padding.PaddingRight = UDim.new(0, 12); padding.Parent = frame
    UI.list(frame, 8); return frame
end
function UI.new()
    local self = setmetatable({}, {__index = UI})
    local gui = Instance.new("ScreenGui"); gui.Name = "ThriftFlip"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui"); self.Gui = gui
    local hud = Instance.new("Frame"); hud.Position = UDim2.fromOffset(12, 8); hud.Size = UDim2.new(1, -24, 0, 66)
    hud.BackgroundColor3 = UI.Colors.Panel; hud.Parent = gui; UI.corner(hud)
    self.Brand = UI.label(hud, "THRIFT FLIP", 20); self.Brand.Position = UDim2.fromOffset(14, 4); self.Brand.Size = UDim2.new(0.44, -14, 0, 30)
    self.Balance = UI.label(hud, "Connecting…", 18, UI.Colors.Teal); self.Balance.Position = UDim2.new(0.44, 0, 0, 4); self.Balance.Size = UDim2.new(0.56, -12, 0, 30); self.Balance.TextXAlignment = Enum.TextXAlignment.Right
    self.Hint = UI.label(hud, "Find. Restore. Make it yours.", 14, UI.Colors.Muted); self.Hint.Position = UDim2.fromOffset(14, 35); self.Hint.Size = UDim2.new(1, -28, 0, 25)
    local nav = Instance.new("Frame"); nav.AnchorPoint = Vector2.new(0.5, 1); nav.Position = UDim2.new(0.5, 0, 1, -8)
    nav.Size = UDim2.new(1, -24, 0, 56); nav.BackgroundTransparency = 1; nav.Parent = gui; self.Nav = nav
    local grid = Instance.new("UIGridLayout"); grid.CellSize = UDim2.new(0.2, -5, 1, 0); grid.CellPadding = UDim2.fromOffset(6, 0); grid.Parent = nav
    local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.new(0.5, 0, 0.5, 8)
    panel.Size = UDim2.new(0.93, 0, 0.70, 0); panel.BackgroundColor3 = UI.Colors.Cream; panel.Visible = false; panel.Parent = gui; UI.corner(panel, 18)
    local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(760, 700); limit.MinSize = Vector2.new(260, 150); limit.Parent = panel
    self.Panel = panel
    self.Title = UI.label(panel, "Your bag", 23); self.Title.Position = UDim2.fromOffset(18, 8); self.Title.Size = UDim2.new(1, -85, 0, 36)
    local close = UI.button(panel, "×", function() if self.Locked then self:notice("Finish or cancel the restoration first.") else panel.Visible = false end end, true)
    close.Size = UDim2.fromOffset(44, 40); close.Position = UDim2.new(1, -54, 0, 8)
    local scroll = Instance.new("ScrollingFrame"); scroll.Position = UDim2.fromOffset(14, 58); scroll.Size = UDim2.new(1, -28, 1, -72)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(); scroll.ScrollingDirection = Enum.ScrollingDirection.Y; scroll.Parent = panel
    UI.list(scroll, 12); self.Content = scroll
    local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.Position = UDim2.new(0.5, 0, 0, 83); toast.Size = UDim2.new(0.9, 0, 0, 54)
    toast.BackgroundColor3 = UI.Colors.Ink; toast.TextColor3 = UI.Colors.Panel; toast.TextWrapped = true
    toast.Font = Enum.Font.GothamBold; toast.TextSize = 17; toast.Visible = false; toast.ZIndex = 20
    toast.Parent = gui; UI.corner(toast); self.Toast = toast; self.ToastVersion = 0
    return self
end
function UI:clear(title)
    for _, child in ipairs(self.Content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    self.Title.Text = title; self.Content.CanvasPosition = Vector2.zero; self.Panel.Visible = true
end
function UI:notice(text)
    self.ToastVersion += 1; local version = self.ToastVersion
    self.Toast.Text = text; self.Toast.Visible = true; self.Toast.TextTransparency = 0
    task.delay(4, function()
        if self.ToastVersion == version then
            TweenService:Create(self.Toast, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
            task.wait(0.4); if self.ToastVersion == version then self.Toast.Visible = false end
        end
    end)
end
return UI
