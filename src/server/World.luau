local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local World = {}
World.__index = World
local colors = {
    Cream = Color3.fromRGB(246, 233, 207), Wood = Color3.fromRGB(151, 105, 72),
    Teal = Color3.fromRGB(111, 173, 158), Rose = Color3.fromRGB(207, 146, 153),
    Gold = Color3.fromRGB(235, 190, 87), Dark = Color3.fromRGB(56, 69, 66),
}
local function part(parent, name, size, cf, color, shape)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
    p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.Material = Enum.Material.SmoothPlastic
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end
local function sign(parent, text, cf, size)
    local board = part(parent, "Sign", size or Vector3.new(16, 3, 0.3), cf, colors.Dark)
    local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 35; gui.Parent = board
    local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = colors.Cream
    label.Font = Enum.Font.GothamBold; label.TextScaled = true; label.Parent = gui
    local padding = Instance.new("UIPadding"); padding.PaddingLeft = UDim.new(0.04, 0); padding.PaddingRight = UDim.new(0.04, 0); padding.Parent = label
    return label
end
local function prompt(parent, text, action, owner, slot)
    local p = Instance.new("ProximityPrompt"); p.ActionText = text; p.ObjectText = "Thrift Flip"
    p.MaxActivationDistance = 12; p.RequiresLineOfSight = false; p.HoldDuration = 0.15
    p:SetAttribute("Action", action); p:SetAttribute("Owner", owner or 0); p:SetAttribute("Slot", slot or 0)
    CollectionService:AddTag(p, "ThriftInteractable"); p.Parent = parent
end
function World.new()
    local self = setmetatable({Plots = {}, Owners = {}, Hooks = {}}, World)
    local existing = workspace:FindFirstChild("ThriftStreet")
    if existing then existing:Destroy() end
    self.Root = Instance.new("Model"); self.Root.Name = "ThriftStreet"; self.Root.Parent = workspace
    Lighting.ClockTime = 16.2; Lighting.Brightness = 2; Lighting.Ambient = Color3.fromRGB(147, 131, 116)
    Lighting.OutdoorAmbient = Color3.fromRGB(163, 157, 142)
    local atmosphere = Instance.new("Atmosphere"); atmosphere.Density = 0.22; atmosphere.Color = colors.Cream; atmosphere.Parent = Lighting
    part(self.Root, "Meadow", Vector3.new(440, 2, 520), CFrame.new(0, -2, 0), Color3.fromRGB(134, 163, 112))
    local street = part(self.Root, "Cobblestone", Vector3.new(36, 0.5, 440), CFrame.new(0, -0.6, 0), Color3.fromRGB(181, 171, 151))
    street.Material = Enum.Material.Cobblestone
    part(self.Root, "Square", Vector3.new(100, 0.5, 70), CFrame.new(0, -0.3, -170), colors.Cream)
    for side = -1, 1, 2 do
        part(self.Root, "Walkway", Vector3.new(9, 0.5, 440), CFrame.new(side * 23, -0.1, 0), colors.Cream)
    end
    local fountain = part(self.Root, "Fountain", Vector3.new(2, 14, 14), CFrame.new(0, 1, -170), colors.Wood, Enum.PartType.Cylinder)
    fountain.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
    part(self.Root, "Water", Vector3.new(11, 0.3, 11), CFrame.new(0, 2.2, -170), Color3.fromRGB(114, 189, 209))
    part(self.Root, "FountainTop", Vector3.new(3, 4, 3), CFrame.new(0, 3, -170), colors.Cream)
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "TownSpawn"; spawn.Size = Vector3.new(8, 0.3, 8)
    spawn.CFrame = CFrame.new(0, 0.2, -145); spawn.Anchored = true; spawn.Neutral = true; spawn.Transparency = 1; spawn.Parent = self.Root
    local destinations = {
        {"DUMPSTER ALLEY", Vector3.new(-40, 2, -120), "Source", colors.Teal},
        {"ESTATE SALE", Vector3.new(42, 2, -120), "Estate", colors.Rose},
        {"AUCTION HOUSE", Vector3.new(0, 2, -211), "Auction", colors.Gold},
        {"QUESTS & SHOWCASE", Vector3.new(40, 2, -175), "Quests", colors.Teal},
        {"DAILY DELIVERY", Vector3.new(-40, 2, -175), "Delivery", colors.Rose},
        {"MARKET SQUARE", Vector3.new(0, 2, 210), "Market", colors.Teal},
    }
    self.Destinations = {}
    for _, entry in ipairs(destinations) do
        local base = part(self.Root, entry[1], Vector3.new(14, 4, 8), CFrame.new(entry[2]), entry[4])
        sign(self.Root, entry[1], CFrame.new(entry[2] + Vector3.new(0, 5, -4.2)))
        prompt(base, "Open", entry[3]); self.Destinations[entry[3]] = entry[2]
    end
    sign(self.Root, "THRIFT STREET  •  FIND SOMETHING WONDERFUL", CFrame.new(0, 13, -137), Vector3.new(35, 4, 0.5))
    for i = 1, 16 do
        local row = math.ceil(i / 2)
        local side = if i % 2 == 1 then -1 else 1
        local center = Vector3.new(side * 52, 0, -83 + (row - 1) * 35)
        local cf = CFrame.new(center) * CFrame.Angles(0, if side == -1 then -math.pi / 2 else math.pi / 2, 0)
        self:buildPlot(i, cf)
    end
    for i = 1, 18 do
        for side = -1, 1, 2 do
            local z = -220 + i * 25
            part(self.Root, "TreeTrunk", Vector3.new(2, 8, 2), CFrame.new(side * 107, 3, z), colors.Wood)
            part(self.Root, "TreeCanopy", Vector3.new(11, 12, 11), CFrame.new(side * 107, 12, z), Color3.fromRGB(96, 144, 108), Enum.PartType.Ball)
        end
    end
    for i = 1, 9 do
        local z = -170 + i * 40
        for side = -1, 1, 2 do
            part(self.Root, "StreetLamp", Vector3.new(0.6, 9, 0.6), CFrame.new(side * 24, 4.5, z), colors.Dark)
            local bulb = part(self.Root, "WarmLight", Vector3.new(2, 2, 2), CFrame.new(side * 24, 9, z), colors.Gold, Enum.PartType.Ball)
            bulb.Material = Enum.Material.Neon
            local light = Instance.new("PointLight"); light.Color = colors.Gold; light.Range = 20; light.Brightness = 0.6; light.Parent = bulb
        end
    end
    return self
end
function World:buildPlot(index, cf)
    local model = Instance.new("Model"); model.Name = "Shop" .. index; model.Parent = self.Root
    part(model, "Floor", Vector3.new(28, 1, 28), cf, colors.Wood)
    local back = part(model, "BackWall", Vector3.new(28, 12, 1), cf * CFrame.new(0, 6, 14), colors.Teal)
    part(model, "LeftWall", Vector3.new(1, 12, 28), cf * CFrame.new(-14, 6, 0), colors.Cream)
    part(model, "RightWall", Vector3.new(1, 12, 28), cf * CFrame.new(14, 6, 0), colors.Cream)
    part(model, "Awning", Vector3.new(29, 0.7, 6), cf * CFrame.new(0, 10, -13), colors.Rose)
    local label = sign(model, "SHOP AVAILABLE", cf * CFrame.new(0, 8, -14.2), Vector3.new(23, 3, 0.5))
    local bench = part(model, "Workbench", Vector3.new(9, 3, 3), cf * CFrame.new(-7, 2, 10), colors.Wood)
    prompt(bench, "Restore an item", "Workbench", 0)
    local counter = part(model, "Counter", Vector3.new(7, 3, 3), cf * CFrame.new(8, 2, -8), colors.Teal)
    prompt(counter, "Shop & upgrades", "Shop", 0)
    local slots = {}
    for slot = 1, 16 do
        local column, row = (slot - 1) % 4, math.floor((slot - 1) / 4)
        local slotCF = cf * CFrame.new(-9 + column * 6, 1.5, -4 + row * 3.5)
        local display = part(model, "Display" .. slot, Vector3.new(4, 2, 2.5), slotCF, colors.Cream)
        prompt(display, "Display slot " .. slot, "Display", 0, slot)
        slots[slot] = {Base = display, CF = slotCF * CFrame.new(0, 2.3, 0)}
    end
    self.Plots[index] = {Model = model, CF = cf, Label = label, Wall = back, Slots = slots, Items = {}, Index = index}
end
function World:assign(player)
    for index, plot in ipairs(self.Plots) do
        if not plot.Owner then
            plot.Owner = player.UserId; self.Owners[player.UserId] = plot
            for _, child in ipairs(plot.Model:GetDescendants()) do
                if child:IsA("ProximityPrompt") then child:SetAttribute("Owner", player.UserId) end
            end
            return index
        end
    end
    return nil
end
function World:release(userId)
    local plot = self.Owners[userId]
    if not plot then return end
    for _, item in pairs(plot.Items) do item:Destroy() end
    plot.Items = {}; plot.Owner = nil; plot.Label.Text = "SHOP AVAILABLE"
    for _, child in ipairs(plot.Model:GetDescendants()) do
        if child:IsA("ProximityPrompt") then child:SetAttribute("Owner", 0) end
    end
    self.Owners[userId] = nil
end
function World:near(player, action)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local target = self.Destinations[action]
    if target then return (root.Position - target).Magnitude < 25 end
    local plot = self.Owners[player.UserId]
    return plot ~= nil and (root.Position - plot.CF.Position).Magnitude < 29
end
function World:render(player, profile, catalog, config)
    local plot = self.Owners[player.UserId]
    if not plot then return end
    local tier = config.Tiers[profile.Tier]
    local average = if profile.RatingCount > 0 then string.format("%.1f", profile.RatingTotal / profile.RatingCount) else "NEW"
    plot.Label.Text = player.DisplayName .. "'s " .. tier.Name .. "  |  ★ " .. average
    for _, theme in ipairs(config.Themes) do
        if theme.Id == profile.Theme then plot.Wall.Color = Color3.new(unpack(theme.Color)) end
    end
    self:decorate(plot, profile)
    for slot, data in ipairs(plot.Slots) do
        data.Base.Transparency = if slot <= tier.Slots then 0 else 0.85
        data.Base.CanCollide = slot <= tier.Slots
    end
    for _, item in pairs(plot.Items) do item:Destroy() end
    plot.Items = {}
    for _, item in ipairs(profile.Inventory) do
        if item.Slot then
            local definition = catalog.ById[item.DefId]
            local model = self:makeItem(plot.Model, definition, item, plot.Slots[item.Slot].CF, config)
            plot.Items[item.Uid] = model
        end
    end
end
function World:decorate(plot, profile)
    local old = plot.Model:FindFirstChild("Decorations")
    if old then old:Destroy() end
    local folder = Instance.new("Folder"); folder.Name = "Decorations"; folder.Parent = plot.Model
    local cf = plot.CF
    local decor = profile.PlacedDecor
    if decor.Rug then
        part(folder, "WovenRug", Vector3.new(17, 0.08, 15), cf * CFrame.new(0, 0.56, 0), colors.Rose)
        part(folder, "RugInset", Vector3.new(15, 0.09, 13), cf * CFrame.new(0, 0.57, 0), colors.Cream)
    end
    if decor.Plant then
        for side = -1, 1, 2 do
            part(folder, "TerracottaPot", Vector3.new(2, 2, 2), cf * CFrame.new(side * 11, 1.5, -10), colors.Rose)
            part(folder, "LeafyPlant", Vector3.new(3, 4, 3), cf * CFrame.new(side * 11, 4, -10), colors.Teal, Enum.PartType.Ball)
        end
    end
    if decor.Poster then sign(folder, "SECOND CHANCES\nGOOD THINGS LIVE HERE", cf * CFrame.new(6, 7, 13.3), Vector3.new(7, 5, 0.2)) end
    if decor.Neon then
        local label = sign(folder, "GOOD FINDS ✦", cf * CFrame.new(-6, 8, 13.3), Vector3.new(10, 2.5, 0.2))
        label.TextColor3 = colors.Gold
    end
    if decor.Curtains then
        for side = -1, 1, 2 do part(folder, "LinenCurtain", Vector3.new(4, 7, 0.3), cf * CFrame.new(side * 11, 5, -13.5), colors.Rose) end
    end
    if decor.Trophy then
        part(folder, "TrophyPedestal", Vector3.new(2.5, 3, 2.5), cf * CFrame.new(0, 2, 11), colors.Dark)
        part(folder, "GoldenTreasure", Vector3.new(2, 2, 2), cf * CFrame.new(0, 4.5, 11), colors.Gold, Enum.PartType.Ball)
    end
    -- Each tier visibly adds architectural details as well as display capacity.
    if profile.Tier >= 2 then
        for side = -1, 1, 2 do part(folder, "Trim", Vector3.new(0.4, 1, 27), cf * CFrame.new(side * 13.4, 10, 0), colors.Gold) end
    end
    if profile.Tier >= 3 then sign(folder, "✦ THE BOUTIQUE COLLECTION ✦", cf * CFrame.new(0, 10.5, 13.3), Vector3.new(20, 1.5, 0.2)) end
    if profile.Tier >= 4 then
        for side = -1, 1, 2 do part(folder, "DisplayPillar", Vector3.new(1.5, 10, 1.5), cf * CFrame.new(side * 12, 5, -11), colors.Cream) end
    end
end
function World:makeItem(parent, definition, item, cf, config)
    local model = Instance.new("Model"); model.Name = definition.Name; model.Parent = parent
    local rarity = Color3.fromHex(config.RarityColors[item.Rarity])
    local color = rarity:Lerp(colors.Wood, (5 - item.Condition) / 7)
    local category = definition.Category
    if category == "Lamps" then
        part(model, "Base", Vector3.new(1.8, 0.25, 1.8), cf * CFrame.new(0, -0.7, 0), colors.Dark)
        part(model, "Stem", Vector3.new(0.25, 1.7, 0.25), cf, colors.Gold)
        part(model, "Shade", Vector3.new(2.2, 1.2, 2.2), cf * CFrame.new(0, 1, 0), color)
    elseif category == "Chairs" then
        part(model, "Seat", Vector3.new(2.3, 0.4, 2), cf, color)
        part(model, "Back", Vector3.new(2.3, 2, 0.4), cf * CFrame.new(0, 1, 0.8), color)
        for x = -1, 1, 2 do for z = -1, 1, 2 do
            part(model, "Leg", Vector3.new(0.3, 1.5, 0.3), cf * CFrame.new(x, -0.8, z * 0.8), colors.Wood)
        end end
    elseif category == "Vases" then
        part(model, "Bowl", Vector3.new(1.8, 2, 1.8), cf, color, Enum.PartType.Ball)
        part(model, "Neck", Vector3.new(0.8, 1.2, 0.8), cf * CFrame.new(0, 1, 0), color)
    elseif category == "Mirrors" then
        part(model, "Frame", Vector3.new(2.4, 3, 0.3), cf * CFrame.new(0, 0.5, 0), colors.Gold)
        local glass = part(model, "Glass", Vector3.new(2, 2.6, 0.1), cf * CFrame.new(0, 0.5, -0.2), Color3.fromRGB(185, 217, 222))
        glass.Material = Enum.Material.Glass; glass.Reflectance = 0.35
    else
        part(model, "Body", Vector3.new(2.2, 1.7, 1), cf, color)
        if category == "Clocks" then
            part(model, "Face", Vector3.new(1.4, 1.4, 0.1), cf * CFrame.new(0, 0, -0.55), colors.Cream, Enum.PartType.Ball)
            part(model, "Hand", Vector3.new(0.1, 0.6, 0.1), cf * CFrame.new(0, 0.2, -0.65), colors.Dark)
        elseif category == "Cameras" then
            part(model, "Lens", Vector3.new(1, 1, 0.6), cf * CFrame.new(0.3, 0, -0.7), colors.Dark, Enum.PartType.Ball)
        elseif category == "Radios" then
            for n = 1, 4 do part(model, "Grille", Vector3.new(0.12, 1, 0.1), cf * CFrame.new(-0.8 + n * 0.3, 0, -0.55), colors.Dark) end
        else
            part(model, "Head", Vector3.new(1.1, 1.1, 1.1), cf * CFrame.new(0, 1.2, 0), color, Enum.PartType.Ball)
        end
    end
    if item.Rarity >= 4 then
        local highlight = Instance.new("Highlight"); highlight.FillTransparency = 0.9
        highlight.OutlineColor = rarity; highlight.OutlineTransparency = 0.25; highlight.Parent = model
    end
    -- Silhouette, proportions and accents vary per catalog design without external assets.
    local scale = 0.85 + definition.Variant * 0.035
    model:ScaleTo(scale)
    return model
end
function World:customer(userId, name)
    local plot = self.Owners[userId]
    if not plot then return end
    local model = Instance.new("Model"); model.Name = name; model.Parent = self.Root
    local cf = plot.CF * CFrame.new(0, 3, -20)
    local torso = part(model, "Torso", Vector3.new(2, 2.5, 1), cf, colors.Rose)
    part(model, "Head", Vector3.new(1.3, 1.3, 1.3), cf * CFrame.new(0, 2, 0), colors.Cream, Enum.PartType.Ball)
    part(model, "LegL", Vector3.new(0.8, 2, 0.8), cf * CFrame.new(-0.5, -2, 0), colors.Dark)
    part(model, "LegR", Vector3.new(0.8, 2, 0.8), cf * CFrame.new(0.5, -2, 0), colors.Dark)
    local bill = Instance.new("BillboardGui"); bill.Size = UDim2.fromOffset(170, 35); bill.StudsOffset = Vector3.new(0, 3.5, 0); bill.Parent = torso
    local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
    label.Text = name; label.TextColor3 = colors.Dark; label.Font = Enum.Font.GothamBold; label.TextSize = 18; label.Parent = bill
    local from = cf.Position
    local target = (plot.CF * CFrame.new(0, 3, -7)).Position
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            local offset = child.Position - from
            TweenService:Create(child, TweenInfo.new(3, Enum.EasingStyle.Linear), {Position = target + offset}):Play()
            task.delay(17, function()
                if child.Parent then TweenService:Create(child, TweenInfo.new(3, Enum.EasingStyle.Linear), {Position = from + offset}):Play() end
            end)
        end
    end
    game:GetService("Debris"):AddItem(model, 21)
end
return World
