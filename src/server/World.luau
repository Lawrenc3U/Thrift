local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Kit = require(script.Parent.WorldKit)
local ItemModels = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemModels"))
local DecorPlacement = require(ReplicatedStorage.Shared.DecorPlacement)
local P = Kit.Palette
local E = {
    Teal = Color3.fromRGB(22, 122, 116), Cream = Color3.fromRGB(255, 246, 229), Coral = Color3.fromRGB(242, 120, 92),
    Red = Color3.fromRGB(201, 67, 45), Gold = Color3.fromRGB(242, 181, 68), Dark = Color3.fromRGB(15, 79, 75),
    Wood = Color3.fromRGB(122, 82, 48), LightWood = Color3.fromRGB(185, 129, 79), Brick = Color3.fromRGB(168, 87, 63),
    BrickDark = Color3.fromRGB(104, 70, 62), Stone = Color3.fromRGB(232, 226, 212), Road = Color3.fromRGB(190, 182, 168),
    Charcoal = Color3.fromRGB(43, 43, 51), Steel = Color3.fromRGB(138, 146, 154), Purple = Color3.fromRGB(142, 107, 191),
    Green = Color3.fromRGB(110, 170, 100), Water = Color3.fromRGB(92, 194, 209), Card = Color3.fromRGB(205, 160, 110),
    Soft = Color3.fromRGB(250, 222, 150), Blue = Color3.fromRGB(46, 90, 160), Dumpster = Color3.fromRGB(62, 142, 90),
    Terracotta = Color3.fromRGB(196, 110, 80), Grass = Color3.fromRGB(150, 205, 130), Asphalt = Color3.fromRGB(70, 72, 78),
}
local World = {}
World.__index = World
local shopColors = {P.Teal, P.Rose, P.Gold, P.Lavender, P.Coral, Color3.fromRGB(137, 166, 190)}
local catalogMetadata = {
    LargeTree = {Id = 56449188, Name = "Tree - Large"},
    ParkBench = {Id = 23153972, Name = "Park Bench"},
    Mailbox = {Id = 56449011, Name = "Mailbox"},
    PicnicTable = {Id = 23153940, Name = "Picnic Table"},
}
local function catalogAsset(parent, key, cf, scale)
    local folder = ServerStorage:FindFirstChild("CatalogAssets")
    local template = folder and folder:FindFirstChild(key)
    local metadata = catalogMetadata[key]
    if not template or not template:IsA("Model") or not metadata then return nil end
    local clone = template:Clone(); clone.Name = "Catalog" .. key
    clone:SetAttribute("CatalogAssetId", metadata.Id); clone:SetAttribute("CatalogName", metadata.Name)
    clone:SetAttribute("CatalogCreator", "Roblox"); clone:SetAttribute("CatalogScriptsReviewed", true)
    clone.Parent = parent
    if scale and scale ~= 1 and not pcall(function() clone:ScaleTo(scale) end) then clone:Destroy(); return nil end
    clone:PivotTo(cf)
    local bounds, size = clone:GetBoundingBox()
    local lift = cf.Position.Y - (bounds.Position.Y - size.Y / 2)
    clone:PivotTo(clone:GetPivot() + Vector3.new(0, lift, 0))
    for _, child in ipairs(clone:GetDescendants()) do
        if child:IsA("LuaSourceContainer") then child:Destroy()
        elseif child:IsA("BasePart") then
            child.Anchored = true; child.CanCollide = child:IsA("Seat"); child.CanTouch = child:IsA("Seat")
            child.CanQuery = false; child.CastShadow = true
        end
    end
    CollectionService:AddTag(clone, "CatalogScenery")
    return clone
end
local function prompt(parent, text, action, owner, slot, destination)
    local p = Instance.new("ProximityPrompt"); p.ActionText = text; p.ObjectText = "Thrift Flip"
    p.MaxActivationDistance = 12; p.RequiresLineOfSight = false; p.HoldDuration = 0.15
    p:SetAttribute("Action", action); p:SetAttribute("Owner", owner or 0); p:SetAttribute("Slot", slot or 0)
    if destination then p:SetAttribute("Destination", destination) end
    p.Parent = parent; CollectionService:AddTag(p, "ThriftInteractable")
    return p
end
local function window(parent, cf, width, height, color)
    local frame = Kit.part(parent, "WindowFrame", Vector3.new(width, height, 0.25), cf, P.Cream)
    local pane = Kit.part(parent, "WindowGlass", Vector3.new(width - 0.4, height - 0.4, 0.12), cf * CFrame.new(0, 0, -0.2), color or P.Sky, Enum.Material.Glass)
    pane.Transparency = 0.3; pane.Reflectance = 0.12
    Kit.part(parent, "Mullion", Vector3.new(0.15, height, 0.15), cf * CFrame.new(0, 0, -0.3), P.Cream, nil, nil, false)
    Kit.part(parent, "Mullion", Vector3.new(width, 0.15, 0.15), cf * CFrame.new(0, 0, -0.3), P.Cream, nil, nil, false)
    return frame
end
local function awning(parent, cf, width, depth, color)
    for i = 1, 8 do
        local x = -width / 2 + (i - 0.5) * width / 8
        local stripe = if i % 2 == 0 then P.Cream else color
        Kit.part(parent, "CanvasStripe", Vector3.new(width / 8 + 0.02, 0.22, depth), cf * CFrame.new(x, 0, 0) * CFrame.Angles(-0.12, 0, 0), stripe, Enum.Material.Fabric, nil, false)
        Kit.part(parent, "ScallopedValance", Vector3.new(width / 8 + 0.02, 0.65, 0.2), cf * CFrame.new(x, -0.45, -depth / 2), stripe, Enum.Material.Fabric, nil, false)
    end
end
local function exactTree(parent, x, z, scale)
    local s = scale or 1
    local model = Kit.model(parent, "PreviewTree")
    Kit.cylinder(model, "Trunk", 0.8 * s, 7 * s, CFrame.new(x, 3.5 * s, z), E.Wood, Enum.Material.Wood)
    Kit.ball(model, "Crown", Vector3.new(9, 9, 9) * s, CFrame.new(x, 9 * s, z), E.Green)
    Kit.ball(model, "CrownRight", Vector3.new(6.5, 6.5, 6.5) * s, CFrame.new(x + 2.4 * s, 7.6 * s, z + s), Color3.fromRGB(96, 158, 90), nil, false)
    Kit.ball(model, "CrownLeft", Vector3.new(6, 6, 6) * s, CFrame.new(x - 2.2 * s, 7.8 * s, z - 1.2 * s), Color3.fromRGB(120, 180, 105), nil, false)
    return model
end
local function exactPost(parent, x, z)
    local model = Kit.model(parent, "PreviewLampPost")
    Kit.cylinder(model, "Post", 0.35, 11, CFrame.new(x, 5.5, z), E.Charcoal, Enum.Material.Metal)
    Kit.cylinder(model, "Base", 0.9, 1.4, CFrame.new(x, 0.7, z), E.Charcoal, Enum.Material.Metal)
    Kit.part(model, "Arm", Vector3.new(0.4, 0.4, 2), CFrame.new(x, 11, z + 0.8), E.Charcoal, Enum.Material.Metal)
    local bulb = Kit.ball(model, "WarmLamp", Vector3.new(1.2, 1.2, 1.2), CFrame.new(x, 10.6, z + 1.6), Color3.fromRGB(255, 233, 168), Enum.Material.Neon, false)
    local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255, 233, 168); light.Brightness = 0.35; light.Range = 13; light.Parent = bulb
    return model
end
local function exactShell(parent, name, cf, width, height, depth, wall, roof, openings)
    local model = Kit.model(parent, name)
    local front = -depth / 2
    Kit.part(model, "Floor", Vector3.new(width, 0.5, depth), cf * CFrame.new(0, 0.25, 0), E.LightWood, Enum.Material.WoodPlanks)
    Kit.part(model, "BackWall", Vector3.new(width, height, 1), cf * CFrame.new(0, height / 2, depth / 2 - 0.5), wall)
    for side = -1, 1, 2 do Kit.part(model, "SideWall", Vector3.new(1, height, depth - 2), cf * CFrame.new(side * (width / 2 - 0.5), height / 2, 0), wall) end
    Kit.part(model, "Roof", Vector3.new(width + 2, 1, depth + 2), cf * CFrame.new(0, height + 0.5, 0), roof)
    local levels = {0, height}
    for _, opening in ipairs(openings) do table.insert(levels, opening[3]); table.insert(levels, opening[4]) end
    table.sort(levels)
    for level = 1, #levels - 1 do
        local low, high = levels[level], levels[level + 1]
        if high - low > 0.01 then
            local active = {}
            for _, opening in ipairs(openings) do if opening[3] <= low + 0.001 and opening[4] >= high - 0.001 then table.insert(active, opening) end end
            table.sort(active, function(a, b) return a[1] < b[1] end)
            local cursor = -width / 2
            local function segment(finish)
                if finish - cursor > 0.01 then Kit.part(model, "FrontWall", Vector3.new(finish - cursor, high - low, 1), cf * CFrame.new((cursor + finish) / 2, (low + high) / 2, front + 0.5), wall) end
                cursor = finish
            end
            for _, opening in ipairs(active) do segment(opening[1]); cursor = opening[2] end
            segment(width / 2)
        end
    end
    for _, opening in ipairs(openings) do
        if opening[3] > 0 then
            local glass = Kit.part(model, "WindowGlass", Vector3.new(opening[2] - opening[1], opening[4] - opening[3], 0.2), cf * CFrame.new((opening[1] + opening[2]) / 2, (opening[3] + opening[4]) / 2, front + 0.5), Color3.fromRGB(207, 233, 230), Enum.Material.Glass, nil, false)
            glass.Transparency = 0.45
        end
    end
    return model, front
end
function World.new()
    local self = setmetatable({Plots = {}, Owners = {}, Customers = {}, CustomerSerial = 0}, World)
    local existing = workspace:FindFirstChild("ThriftStreet")
    if existing then existing:Destroy() end
    self.Root = Kit.model(workspace, "ThriftStreet")
    self.Root:SetAttribute("AssetOrigin", "Converted from the supplied Thrift Flip town preview")
    self.Root:SetAttribute("LayoutSource", "Thrift Flip Town 3D Preview (2).html")
    self:lighting()
    self:exactLandscape()
    self:exactSquare()
    self:exactSourcing()
    self:exactDistrict()
    self:exactEnvironment()
    for i = 1, 8 do
        local left = i <= 4
        local row = if left then i - 1 else i - 5
        local center = Vector3.new(if left then -37 else 37, 0, row * 34)
        local cf = CFrame.new(center) * CFrame.Angles(0, if left then -math.pi / 2 else math.pi / 2, 0)
        self:buildPlot(i, cf)
    end
    self.CustomerHeartbeat = RunService.Heartbeat:Connect(function(delta)
        self:animateCustomers(delta)
    end)
    self.Root.Destroying:Connect(function()
        self.CustomerHeartbeat:Disconnect()
        table.clear(self.Customers)
    end)
    return self
end
function World:lighting()
    Lighting.ClockTime = 14.5; Lighting.Brightness = 2
    Lighting.GlobalShadows = true; Lighting.ShadowSoftness = 0.28; Lighting.ExposureCompensation = 0.05
    Lighting.Ambient = Color3.fromRGB(154, 165, 154); Lighting.OutdoorAmbient = Color3.fromRGB(190, 205, 195)
    Lighting.EnvironmentDiffuseScale = 0.65; Lighting.EnvironmentSpecularScale = 0.45
    for _, name in ipairs({"ThriftAtmosphere", "ThriftBloom", "ThriftColor", "ThriftSunRays"}) do
        local old = Lighting:FindFirstChild(name); if old then old:Destroy() end
    end
    local atmosphere = Instance.new("Atmosphere"); atmosphere.Name = "ThriftAtmosphere"
    atmosphere.Density = 0.16; atmosphere.Offset = 0.12; atmosphere.Color = Color3.fromRGB(191, 227, 224)
    atmosphere.Decay = Color3.fromRGB(176, 204, 193); atmosphere.Haze = 1; atmosphere.Glare = 0.06; atmosphere.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "ThriftBloom"; bloom.Intensity = 0.14; bloom.Size = 18; bloom.Threshold = 1.5; bloom.Parent = Lighting
    local grading = Instance.new("ColorCorrectionEffect"); grading.Name = "ThriftColor"; grading.Saturation = 0.06
    grading.Contrast = 0.035; grading.TintColor = Color3.fromRGB(255, 249, 239); grading.Parent = Lighting
    local rays = Instance.new("SunRaysEffect"); rays.Name = "ThriftSunRays"; rays.Intensity = 0.035; rays.Spread = 0.72; rays.Parent = Lighting
end
function World:exactLandscape()
    local ground = Kit.model(self.Root, "ExactTownGround")
    ground:SetAttribute("Source", "Thrift Flip Town 3D Preview (2).html")
    Kit.part(ground, "Grass", Vector3.new(440, 1, 480), CFrame.new(0, -0.5, 10), E.Grass, Enum.Material.Grass)
    Kit.part(ground, "ThriftStreet", Vector3.new(44, 0.2, 160), CFrame.new(0, 0, 60), E.Road, Enum.Material.Pavement)
    Kit.part(ground, "LeftCurb", Vector3.new(1.6, 0.5, 160), CFrame.new(-22.8, 0.2, 60), E.Stone, Enum.Material.Concrete)
    Kit.part(ground, "RightCurb", Vector3.new(1.6, 0.5, 160), CFrame.new(22.8, 0.2, 60), E.Stone, Enum.Material.Concrete)
    for z = -12, 132, 12 do Kit.part(ground, "RoadDash", Vector3.new(0.8, 0.05, 5), CFrame.new(0, 0.12, z), E.Cream, nil, nil, false) end
    Kit.part(ground, "Plaza", Vector3.new(100, 0.2, 70), CFrame.new(0, 0, -55), E.Road, Enum.Material.Pavement)
    Kit.cylinder(ground, "PlazaOuterRing", 23, 0.25, CFrame.new(0, 0.08, -55), E.Stone, Enum.Material.Concrete)
    Kit.cylinder(ground, "PlazaInner", 20, 0.3, CFrame.new(0, 0.1, -55), E.Road, Enum.Material.Pavement)
    Kit.part(ground, "DumpsterAlleyPaving", Vector3.new(55, 0.2, 30), CFrame.new(-77.5, 0, -53), E.Asphalt, Enum.Material.Asphalt)
    Kit.part(ground, "FleaWalk", Vector3.new(12, 0.15, 24), CFrame.new(-56, 0.02, -100), Color3.fromRGB(139, 104, 70), Enum.Material.WoodPlanks)
    Kit.cylinder(ground, "PlazaMarker", 5, 0.4, CFrame.new(0, 0.3, -84), E.Teal, Enum.Material.Neon, false)
    local arch = Kit.model(ground, "ThriftStreetArch")
    for _, x in ipairs({-24, 24}) do
        Kit.part(arch, "StonePillar", Vector3.new(3.2, 16, 3.2), CFrame.new(x, 8, -18), E.Stone, Enum.Material.Concrete)
        Kit.part(arch, "TealCap", Vector3.new(4.2, 0.8, 4.2), CFrame.new(x, 16.4, -18), E.Teal)
        Kit.part(arch, "StoneFoot", Vector3.new(4.2, 1, 4.2), CFrame.new(x, 0.5, -18), E.Stone, Enum.Material.Concrete)
    end
    Kit.sign(arch, "THRIFT STREET", CFrame.new(0, 14.5, -18), Vector3.new(44, 4.2, 0.5), E.Teal, E.Cream)
    Kit.sign(arch, "EVERY FIND HAS A STORY", CFrame.new(0, 11.6, -18.3), Vector3.new(24, 1.4, 0.2), E.Cream, E.Dark)
    for z = 17, 119, 34 do exactPost(ground, -20.5, z); exactPost(ground, 20.5, z) end
    local trees = {
        {-45,-25,1},{45,-25,1},{-60,-20,.9},{62,-15,1.1},{-110,-20,1},{110,-30,1.2},{-20,-132,1.1},{20,-132,1},
        {62,-128,1.1},{100,-112,1},{0,-138,1.3},{-62,20,1},{64,60,1},{-64,80,1.1},{64,100,1},{-62,125,1},
        {62,128,1.1},{-30,175,1.2},{30,175,1},{0,182,1.3},{-100,40,1.1},{100,20,1.2},{-110,-128,1.1},{-68,-128,.9},{-110,-96,1},
    }
    for index, tree in ipairs(trees) do
        local asset = if index % 3 == 0 then catalogAsset(ground, "LargeTree", CFrame.new(tree[1], 0, tree[2]) * CFrame.Angles(0, index * 0.71, 0), tree[3] * 0.82) else nil
        if not asset then exactTree(ground, tree[1], tree[2], tree[3]) end
    end
    for side = -1, 1, 2 do local boundary = Kit.part(ground, "TownBoundary", Vector3.new(2, 70, 480), CFrame.new(side * 220, 30, 10), E.Cream); boundary.Transparency = 1 end
    for _, z in ipairs({-230, 250}) do local boundary = Kit.part(ground, "TownBoundary", Vector3.new(440, 70, 2), CFrame.new(0, 30, z), E.Cream); boundary.Transparency = 1 end
end
function World:exactSquare()
    local square = Kit.model(self.Root, "ExactTownPlaza")
    Kit.cylinder(square, "FountainBase", 13, 2.4, CFrame.new(0, 1.2, -55), E.Stone, Enum.Material.Concrete)
    local water = Kit.cylinder(square, "FountainWater", 11, 0.2, CFrame.new(0, 2.45, -55), E.Water, Enum.Material.Glass, false); water.Transparency = 0.3
    for index = 0, 19 do
        local angle = index * math.pi / 10
        Kit.part(square, "RimStone", Vector3.new(4.2, 0.8, 1.4), CFrame.new(math.cos(angle) * 12.3, 2.7, -55 + math.sin(angle) * 12.3) * CFrame.Angles(0, -(angle + math.pi / 2), 0), E.Stone, Enum.Material.Concrete)
    end
    Kit.cylinder(square, "FountainColumn", 1.8, 7, CFrame.new(0, 5.5, -55), E.Stone, Enum.Material.Concrete)
    Kit.cylinder(square, "UpperBowl", 5, 1, CFrame.new(0, 9.5, -55), E.Stone, Enum.Material.Concrete)
    local upperWater = Kit.cylinder(square, "UpperWater", 4.3, 0.2, CFrame.new(0, 10.05, -55), E.Water, Enum.Material.Glass, false); upperWater.Transparency = 0.3
    Kit.cylinder(square, "UpperColumn", 0.6, 3, CFrame.new(0, 11.5, -55), E.Stone, Enum.Material.Concrete)
    Kit.ball(square, "GoldFinial", Vector3.new(1.6, 1.6, 1.6), CFrame.new(0, 13.3, -55), E.Gold, Enum.Material.Metal, false)
    for index = 0, 9 do
        local angle = index * math.pi / 5
        Kit.ball(square, "WaterDrop", Vector3.new(0.7, 0.7, 0.7), CFrame.new(math.cos(angle) * 2.2, 12.2 - index % 3 * 0.6, -55 + math.sin(angle) * 2.2), Color3.fromRGB(190, 232, 245), Enum.Material.Glass, false).Transparency = 0.3
    end
    for index = 0, 3 do
        local angle = index * math.pi / 2 + math.pi / 4
        exactPost(square, math.cos(angle) * 17, -55 + math.sin(angle) * 17)
    end
    for index = 0, 3 do
        local angle = index * math.pi / 2 + math.pi / 2
        local position = Vector3.new(math.cos(angle) * 21, 0, -55 + math.sin(angle) * 21)
        local facing = CFrame.lookAt(position, Vector3.new(0, 0, -55))
        if not catalogAsset(square, "ParkBench", facing, 0.72) then Kit.bench(square, facing) end
    end
    for index = 0, 7 do
        local angle = index * math.pi / 4 + math.pi / 8
        local x, z = math.cos(angle) * 30, -55 + math.sin(angle) * 26
        Kit.cylinder(square, "Planter", 1.3, 2.2, CFrame.new(x, 1.1, z), E.Terracotta)
        Kit.ball(square, "PlanterLeaf", Vector3.new(2.6, 2.6, 2.6), CFrame.new(x, 3, z), E.Green, nil, false)
        for flower = 0, 2 do Kit.ball(square, "Flower", Vector3.new(0.8, 0.8, 0.8), CFrame.new(x + math.cos(flower * 2.1), 3.9, z + math.sin(flower * 2.1)), ({E.Coral,E.Gold,E.Cream})[flower + 1], nil, false) end
    end
    for _, position in ipairs({Vector3.new(-38, 0, -79), Vector3.new(38, 0, -79)}) do
        catalogAsset(square, "PicnicTable", CFrame.lookAt(position, Vector3.new(0, 0, -55)), 0.58)
    end
    local qcf = CFrame.lookAt(Vector3.new(-26, 0, -30), Vector3.new(0, 0, -55))
    local quests = Kit.model(square, "DailyQuests")
    for _, x in ipairs({-7, 7}) do Kit.part(quests, "Post", Vector3.new(0.8, 11, 0.8), qcf * CFrame.new(x, 5.5, 0.6), E.Wood, Enum.Material.Wood) end
    Kit.part(quests, "Frame", Vector3.new(14, 8, 1), qcf * CFrame.new(0, 6.5, 0), E.Wood, Enum.Material.Wood)
    Kit.part(quests, "Cork", Vector3.new(13, 7, 0.2), qcf * CFrame.new(0, 6.5, -0.55), Color3.fromRGB(214, 170, 120))
    Kit.part(quests, "Canopy", Vector3.new(16, 0.6, 3.6), qcf * CFrame.new(0, 11.8, -0.4), E.Teal)
    local _, questBoard = Kit.sign(quests, "DAILY QUESTS", qcf * CFrame.new(0, 10.6, -0.7), Vector3.new(12, 1.8, 0.15), E.Teal, E.Cream); prompt(questBoard, "Open daily quests", "Quests")
    for index, card in ipairs({"SELL\n3 stories", "RESTORE\n3 keepsakes", "FIND\n3 treasures"}) do
        Kit.sign(quests, card, qcf * CFrame.new(-4.2 + (index - 1) * 4.2, 6.2, -0.75), Vector3.new(3.6, 4.2, 0.12), E.Cream, E.Dark)
    end
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "TownSpawn"; spawn.Size = Vector3.new(7, 0.3, 7); spawn.CFrame = CFrame.new(0, 0.5, -8)
    spawn.Anchored = true; spawn.Neutral = true; spawn.Transparency = 1; spawn.Duration = 0; spawn.Parent = square
    self.Destinations = {Source = Vector3.new(-82, 2, -60), Estate = Vector3.new(68, 2, -80),
        Delivery = Vector3.new(68, 2, -35), Quests = Vector3.new(-26, 2, -30), Flea = Vector3.new(-88, 2, -112),
        Auction = Vector3.new(0, 2, 137), Market = Vector3.new(0, 2, -90), Workbench = Vector3.new(-40, 2, -90)}
end
function World:exactSourcing()
    local sourcing = Kit.model(self.Root, "ExactSourcingDistrict")
    local alley = Kit.model(sourcing, "DumpsterAlley")
    Kit.part(alley, "NorthBrickWall", Vector3.new(55, 16, 10), CFrame.new(-77.5, 8, -33), E.BrickDark, Enum.Material.Brick)
    Kit.part(alley, "SouthBrickWall", Vector3.new(55, 16, 10), CFrame.new(-77.5, 8, -73), E.BrickDark, Enum.Material.Brick)
    Kit.part(alley, "WestBrickWall", Vector3.new(2, 16, 30), CFrame.new(-106, 8, -53), E.BrickDark, Enum.Material.Brick)
    for index = 0, 5 do for row = 0, 1 do
        local x, y = -100 + index * 9, 6 + row * 5.5
        Kit.part(alley, "Window", Vector3.new(3, 3.5, 0.2), CFrame.new(x, y, -38.05), E.Charcoal, Enum.Material.Glass, nil, false)
        Kit.part(alley, "Sill", Vector3.new(3.8, 0.4, 0.8), CFrame.new(x, y - 2, -38.3), E.Stone)
        Kit.part(alley, "Window", Vector3.new(3, 3.5, 0.2), CFrame.new(x + 4, y, -67.95), E.Charcoal, Enum.Material.Glass, nil, false)
        Kit.part(alley, "Sill", Vector3.new(3.8, 0.4, 0.8), CFrame.new(x + 4, y - 2, -67.7), E.Stone)
    end end
    Kit.cylinder(alley, "DrainPipe", 0.4, 16, CFrame.new(-60, 8, -37.5), E.Steel, Enum.Material.Metal)
    Kit.cylinder(alley, "DrainPipe", 0.4, 16, CFrame.new(-95, 8, -67.5), E.Steel, Enum.Material.Metal)
    Kit.part(alley, "FireEscape", Vector3.new(8, 0.4, 3), CFrame.new(-85, 8, -66.5), E.Charcoal, Enum.Material.Metal)
    for _, x in ipairs({-87, -85.4}) do Kit.part(alley, "LadderRail", Vector3.new(0.2, 8, 0.2), CFrame.new(x, 4, -66), E.Charcoal, Enum.Material.Metal) end
    local function dumpster(x, z, color)
        local bin = Kit.part(alley, "SalvageDumpster", Vector3.new(7, 4, 4), CFrame.new(x, 2.1, z), color, Enum.Material.Metal)
        Kit.part(alley, "DumpsterBand", Vector3.new(7.2, 0.4, 4.2), CFrame.new(x, 3.3, z), E.Charcoal, Enum.Material.Metal)
        Kit.part(alley, "OpenLid", Vector3.new(7.2, 0.4, 4.4), CFrame.new(x, 4.7, z + 1.4) * CFrame.Angles(-0.38, 0, 0), E.Charcoal, Enum.Material.Metal)
        Kit.ball(alley, "TrashBag", Vector3.new(2.2, 2.2, 2.2), CFrame.new(x - 1.5, 4.4, z - 0.4), E.Charcoal)
        Kit.ball(alley, "TrashBag", Vector3.new(1.8, 1.8, 1.8), CFrame.new(x + 1.2, 4.2, z - 0.8), Color3.fromRGB(60, 80, 70))
        prompt(bin, "Search for a treasure", "Source")
    end
    dumpster(-95, -62, E.Dumpster); dumpster(-82, -63, E.Blue); dumpster(-68, -62, E.Dumpster); dumpster(-90, -44, Color3.fromRGB(150, 60, 50))
    for _, position in ipairs({{-100,-45},{-75,-43},{-58,-66}}) do Kit.crate(alley, CFrame.new(position[1], 0.2, position[2]), Vector3.new(2.8, 2.8, 2.8), false) end
    for _, position in ipairs({{-102,-60},{-72,-44}}) do Kit.cylinder(alley, "Barrel", 1.2, 3, CFrame.new(position[1], 1.6, position[2]), E.Red, Enum.Material.Metal) end
    for index = 0, 5 do Kit.ball(alley, "LooseTrash", Vector3.new(1.6 + index % 3 * 0.4, 1.6 + index % 3 * 0.4, 1.6 + index % 3 * 0.4), CFrame.new(-98 + index * 9, 0.9, -52 + index % 2 * 4), E.Charcoal) end
    local puddle = Kit.cylinder(alley, "Puddle", 3, 0.05, CFrame.new(-72, 0.14, -52), E.Water, Enum.Material.Glass, false); puddle.Transparency = 0.5
    local smallPuddle = Kit.cylinder(alley, "Puddle", 2, 0.05, CFrame.new(-92, 0.14, -50), E.Water, Enum.Material.Glass, false); smallPuddle.Transparency = 0.5
    local alleySignCF = CFrame.lookAt(Vector3.new(-52, 0, -53), Vector3.new(0, 0, -53))
    for _, x in ipairs({-15, 15}) do Kit.part(alley, "AlleySignPost", Vector3.new(1.6, 14, 1.6), alleySignCF * CFrame.new(x, 7, 0), E.Charcoal, Enum.Material.Metal) end
    Kit.sign(alley, "DUMPSTER ALLEY", alleySignCF * CFrame.new(0, 13, 0), Vector3.new(30, 3, 0.4), E.Charcoal, E.Gold)
    Kit.sign(alley, "START HERE", alleySignCF * CFrame.new(0, 10.3, -0.3), Vector3.new(9, 1.7, 0.2), E.Red, E.Cream)
    for index = 0, 5 do for _, x in ipairs({-66,-80,-94}) do Kit.ball(alley, "AlleyLight", Vector3.new(1.2, 1.2, 1.2), CFrame.new(x, 11.5, -62 + index * 5), Color3.fromRGB(255, 233, 168), Enum.Material.Neon, false) end end
    local flea = Kit.model(sourcing, "FleaField")
    Kit.part(flea, "Field", Vector3.new(50, 0.2, 40), CFrame.new(-88, 0.05, -112), Color3.fromRGB(176, 214, 140), Enum.Material.Grass)
    local function fence(x1, z1, x2, z2)
        local dx, dz = x2 - x1, z2 - z1; local length = math.sqrt(dx * dx + dz * dz); local count = math.max(1, math.floor(length / 5))
        local cf = CFrame.lookAt(Vector3.new((x1+x2)/2, 0, (z1+z2)/2), Vector3.new(x2, 0, z2)) * CFrame.Angles(0, math.pi / 2, 0)
        for _, y in ipairs({2.8, 1.6}) do Kit.part(flea, "FenceRail", Vector3.new(length, 0.4, 0.4), cf * CFrame.new(0, y, 0), E.LightWood, Enum.Material.Wood) end
        for index = 0, count do Kit.part(flea, "FencePost", Vector3.new(0.6, 3.6, 0.6), CFrame.new(x1 + dx * index / count, 1.8, z1 + dz * index / count), E.Wood, Enum.Material.Wood) end
    end
    fence(-113,-132,-63,-132); fence(-113,-92,-63,-92); fence(-113,-132,-113,-92); fence(-63,-132,-63,-118); fence(-63,-106,-63,-92)
    for _, z in ipairs({-118,-106}) do Kit.part(flea, "GatePost", Vector3.new(1, 7, 1), CFrame.new(-63, 3.5, z), E.Wood, Enum.Material.Wood) end
    Kit.part(flea, "GateHeader", Vector3.new(0.8, 0.8, 13), CFrame.new(-63, 7, -112), E.Wood, Enum.Material.Wood)
    local fieldSignCF = CFrame.lookAt(Vector3.new(-63, 0, -112), Vector3.new(0, 0, -112))
    Kit.sign(flea, "FLEA FIELD", fieldSignCF * CFrame.new(0, 5.6, 0), Vector3.new(9, 2, 0.3), E.Coral, E.Cream)
    for _, position in ipairs({{-106,-125},{-94,-121},{-82,-126},{-72,-119},{-104,-108},{-88,-112},{-74,-106},{-98,-97}}) do
        local spot = Kit.cylinder(flea, "FindSpot", 2.5, 0.8, CFrame.new(position[1], 0.5, position[2]), Color3.fromRGB(139, 104, 70), Enum.Material.Ground)
        prompt(spot, "Search the flea field", "Source")
        for _, angle in ipairs({0.785, -0.785}) do Kit.part(flea, "DigMarker", Vector3.new(2.8, 0.1, 0.5), CFrame.new(position[1], 0.95, position[2]) * CFrame.Angles(0, angle, 0), E.Red, nil, nil, false) end
    end
    for index, x in ipairs({-106,-92,-78}) do
        local tableTop = Kit.part(flea, "FleaTable", Vector3.new(7, 0.4, 3.4), CFrame.new(x, 3.4, -97), E.LightWood, Enum.Material.Wood)
        prompt(tableTop, "Browse flea finds", "Source")
        for _, offset in ipairs({-3, 3}) do Kit.part(flea, "TableLeg", Vector3.new(0.5, 3.2, 0.5), CFrame.new(x + offset, 1.8, -97), E.Wood, Enum.Material.Wood) end
        for item = 1, 4 do Kit.part(flea, "FleaFind", Vector3.new(0.9, 0.8 + item % 3 * 0.4, 0.9), CFrame.new(x - 2.3 + item, 4.3, -97), ({E.Purple,E.Cream,E.Red,E.Dark})[item]) end
    end
    local parcelCF = CFrame.new(78, 0, -35) * CFrame.Angles(0, math.pi / 2, 0)
    local parcelPost = exactShell(sourcing, "ParcelPost", parcelCF, 24, 12, 20, E.Soft, E.Teal, {{-2.5,2.5,0,8},{-9,-5,3,8},{5,9,3,8}})
    Kit.sign(parcelPost, "PARCEL POST", parcelCF * CFrame.new(0, 10, -10.3), Vector3.new(16, 2.8, 0.25), E.Cream, E.Dark)
    Kit.part(parcelPost, "RedAwning", Vector3.new(14, 0.4, 3.4), parcelCF * CFrame.new(0, 8.9, -11.7), E.Red, Enum.Material.Fabric)
    for _, x in ipairs({-11, 11}) do
        Kit.part(parcelPost, "MailboxPost", Vector3.new(0.5, 2, 0.5), parcelCF * CFrame.new(x, 1, -13), E.Charcoal, Enum.Material.Metal)
        Kit.part(parcelPost, "StreetMailbox", Vector3.new(2.2, 2.2, 1.8), parcelCF * CFrame.new(x, 3.1, -13), E.Blue, Enum.Material.Metal)
        Kit.cylinder(parcelPost, "MailboxTop", 0.9, 2.2, parcelCF * CFrame.new(x, 4.2, -13) * CFrame.Angles(math.pi / 2, 0, 0), E.Blue, Enum.Material.Metal)
    end
    for column = 0, 1 do for row = 0, 1 do Kit.parcel(parcelPost, parcelCF * CFrame.new(7 + column * 2.6, row * 1.6, -13), Vector3.new(2.4, 1.6, 2), E.Card) end end
    for row = 0, 2 do for column = 0, 5 do Kit.part(parcelPost, "Mailbox", Vector3.new(2.6, 2, 0.6), parcelCF * CFrame.new(-7.5 + column * 3, 2.6 + row * 2.4, 8.4), E.Dark, Enum.Material.Metal) end end
    local parcelCounter = Kit.part(parcelPost, "ParcelCounter", Vector3.new(14, 3, 2.4), parcelCF * CFrame.new(0, 2, 3), E.Teal)
    Kit.part(parcelPost, "CounterTop", Vector3.new(14.4, 0.3, 2.8), parcelCF * CFrame.new(0, 3.65, 3), E.LightWood, Enum.Material.Wood)
    prompt(parcelCounter, "Open today's parcel", "Delivery")
    local sourceCF = CFrame.new(80, 0, -80) * CFrame.Angles(0, math.pi / 2, 0)
    local wholesale = exactShell(sourcing, "WholesaleSource", sourceCF, 28, 14, 24, E.Brick, E.Steel, {{-6,6,0,10},{-13,-10,5,10},{10,13,5,10}})
    Kit.cylinder(wholesale, "SteelHeader", 1, 12, sourceCF * CFrame.new(0, 10.8, -12.5) * CFrame.Angles(0, 0, math.pi / 2), E.Steel, Enum.Material.Metal)
    Kit.sign(wholesale, "SOURCE", sourceCF * CFrame.new(0, 12.4, -12.3), Vector3.new(14, 3.4, 0.3), E.Cream, E.Red)
    Kit.sign(wholesale, "WHOLESALE RESTOCK", sourceCF * CFrame.new(0, 9.6, -12.2), Vector3.new(14, 1.4, 0.2), E.Red, E.Cream)
    local sourceCrate
    for index = 0, 2 do
        sourceCrate = Kit.part(wholesale, "WholesaleCrate", Vector3.new(4, 0.5, 4), sourceCF * CFrame.new(-12 + index * 4.4, 0.35, -16), E.LightWood, Enum.Material.Wood)
        for level = 1, 2 + index % 2 do Kit.part(wholesale, "StockBox", Vector3.new(3.6, 1.6, 3.6), sourceCF * CFrame.new(-12 + index * 4.4, 0.6 + level * 1.65 - 0.8, -16), ({E.LightWood,E.Card,E.Wood})[(index + level) % 3 + 1]) end
    end
    if sourceCrate then prompt(sourceCrate, "Browse wholesale lots", "Estate") end
    Kit.cylinder(wholesale, "BlueBarrel", 1.2, 3, sourceCF * CFrame.new(12, 1.6, -15), E.Blue, Enum.Material.Metal)
    Kit.cylinder(wholesale, "RedBarrel", 1.2, 3, sourceCF * CFrame.new(14.8, 1.6, -15.6), E.Red, Enum.Material.Metal)
    Kit.part(wholesale, "ForkliftBody", Vector3.new(3, 2, 4.4), sourceCF * CFrame.new(6, 1.7, -17), Color3.fromRGB(240, 190, 40), Enum.Material.Metal)
    Kit.part(wholesale, "ForkliftSeat", Vector3.new(3, 1.6, 1.2), sourceCF * CFrame.new(6, 2.2, -14.4), E.Charcoal)
    Kit.part(wholesale, "ForkliftRoof", Vector3.new(3, 0.2, 2.8), sourceCF * CFrame.new(6, 5.8, -16.6), E.Charcoal, Enum.Material.Metal)
    for _, x in ipairs({5.1, 6.9}) do Kit.part(wholesale, "ForkliftMast", Vector3.new(0.4, 6, 0.4), sourceCF * CFrame.new(x, 3.7, -19.4), E.Charcoal, Enum.Material.Metal) end
    for level = 0, 3 do for item = 0, 6 do Kit.part(wholesale, "WholesaleStock", Vector3.new(1.3, 1.5, 1.3), sourceCF * CFrame.new(-12 + item * 2.1, 1.8 + level * 2.4, 10), ({E.Card,E.LightWood,E.Red,E.Teal})[(item + level) % 4 + 1]) end end
end
function World:exactDistrict()
    local district = Kit.model(self.Root, "ExactPublicBuildings")
    district:SetAttribute("Source", "Thrift Flip Town 3D Preview (2).html")
    local marketCF = CFrame.new(0, 0, -105) * CFrame.Angles(0, math.pi, 0)
    local market = Kit.model(district, "Market")
    Kit.part(market, "MarketFloor", Vector3.new(36, 0.4, 28), marketCF * CFrame.new(0, 0.2, 0), E.Stone, Enum.Material.Pavement)
    for stallIndex, x in ipairs({-11, 0, 11}) do
        for stripe = 1, 6 do
            local color = if stripe % 2 == 1 then ({E.Red,E.Teal,E.Gold})[stallIndex] else E.Cream
            Kit.part(market, "AwningStripe", Vector3.new(1.5, 0.4, 7.4), marketCF * CFrame.new(x - 4.5 + (stripe - 0.5) * 1.5, 8.4, -4), color, Enum.Material.Fabric)
        end
        local counter = Kit.part(market, "MarketCounter", Vector3.new(8, 2.6, 2.4), marketCF * CFrame.new(x, 1.8, -6), E.Wood, Enum.Material.Wood)
        prompt(counter, "Browse the market", "Market")
        for _, dx in ipairs({-4, 4}) do for _, dz in ipairs({-3, 3}) do Kit.part(market, "StallPost", Vector3.new(0.5, 8, 0.5), marketCF * CFrame.new(x + dx, 4.2, -4 + dz), E.Wood, Enum.Material.Wood) end end
    end
    Kit.sign(market, "MARKET", marketCF * CFrame.new(0, 11, -12), Vector3.new(20, 3, 0.4), E.Gold, Color3.fromRGB(58, 42, 0))
    for _, x in ipairs({-9, 9}) do Kit.part(market, "MarketSignPost", Vector3.new(1.2, 12, 1.2), marketCF * CFrame.new(x, 6.4, -12), E.Wood, Enum.Material.Wood) end
    local restoreCF = CFrame.new(-40, 0, -105) * CFrame.Angles(0, math.pi, 0)
    local restore = exactShell(district, "RestoreShop", restoreCF, 36, 15, 28, E.Brick, E.Charcoal, {{-3,3,0,9}})
    Kit.sign(restore, "RESTORE SHOP", restoreCF * CFrame.new(0, 13.4, -14.3), Vector3.new(20, 3, 0.3), E.Cream, Color3.fromRGB(138, 63, 43))
    local restoreTrigger = Kit.part(restore, "RestoreInteraction", Vector3.new(6, 8, 1), restoreCF * CFrame.new(0, 4, -15), E.Cream, nil, nil, false); restoreTrigger.Transparency = 1
    prompt(restoreTrigger, "Restore a treasure", "Workbench")
    local designerCF = CFrame.new(40, 0, -105) * CFrame.Angles(0, math.pi, 0)
    local designer = exactShell(district, "DesignerShowcase", designerCF, 36, 16, 28, E.Dark, E.Charcoal, {{-3,3,0,9}})
    Kit.sign(designer, "DESIGNER SHOWCASE", designerCF * CFrame.new(0, 14.4, -14.3), Vector3.new(20, 3, 0.3), E.Cream, E.Dark)
    local designerTrigger = Kit.part(designer, "ShowcaseInteraction", Vector3.new(6, 8, 1), designerCF * CFrame.new(0, 4, -15), E.Cream, nil, nil, false); designerTrigger.Transparency = 1
    prompt(designerTrigger, "Enter designer showcase", "Showcase")
    self:exactAuctionHouse(district)
end
function World:exactAuctionHouse(parent)
    local cf = CFrame.new(0, 0, 152)
    local auction = exactShell(parent, "AuctionHouse", cf, 36, 18, 32, Color3.fromRGB(245, 238, 225), E.Teal,
        {{-3.5,3.5,0,11},{-16.5,-13.5,3.5,10.5},{13.5,16.5,3.5,10.5}})
    auction:SetAttribute("PreviewLandmark", "ClockTowerAuctionHouse")
    local marble = Color3.fromRGB(245, 238, 225)
    local marbleDark = Color3.fromRGB(226, 218, 200)
    local glass = Color3.fromRGB(207, 233, 230)
    local function archedWindow(x, baseY, width, height, frontZ)
        local bodyHeight = height - width / 2
        local pane = Kit.part(auction, "ArchedGlass", Vector3.new(width, bodyHeight, 0.2),
            cf * CFrame.new(x, baseY + bodyHeight / 2, frontZ), glass, Enum.Material.Glass, nil, false)
        pane.Transparency = 0.38; pane.Reflectance = 0.12
        local crown = Kit.ball(auction, "ArchedGlassCrown", Vector3.new(width, width, 0.2),
            cf * CFrame.new(x, baseY + bodyHeight, frontZ), glass, Enum.Material.Glass, false)
        crown.Transparency = 0.38
        for _, side in ipairs({-1, 1}) do
            Kit.part(auction, "GoldWindowFrame", Vector3.new(0.55, bodyHeight + 1, 0.5),
                cf * CFrame.new(x + side * width / 2, baseY + bodyHeight / 2, frontZ - 0.15), E.Gold, Enum.Material.Metal, nil, false)
        end
        Kit.part(auction, "GoldWindowSill", Vector3.new(width + 1.6, 0.6, 1.2),
            cf * CFrame.new(x, baseY - 0.3, frontZ - 0.3), E.Gold, Enum.Material.Metal)
    end
    archedWindow(-15, 3.5, 3, 8.5, -16.15); archedWindow(15, 3.5, 3, 8.5, -16.15)
    for _, x in ipairs({-3.9, 3.9}) do
        Kit.part(auction, "DoorFrame", Vector3.new(0.6, 11, 1.2), cf * CFrame.new(x, 5.5, -16.1), E.Gold, Enum.Material.Metal)
    end
    Kit.part(auction, "DoorHeader", Vector3.new(8.2, 0.6, 1.2), cf * CFrame.new(0, 11.3, -16.1), E.Gold, Enum.Material.Metal)
    for _, side in ipairs({-1, 1}) do
        Kit.part(auction, "FrontQuoin", Vector3.new(1.4, 18, 1.6), cf * CFrame.new(side * 18, 9, -16.1), marbleDark, Enum.Material.Marble)
    end
    Kit.part(auction, "GoldCornice", Vector3.new(37.4, 1, 2), cf * CFrame.new(0, 17.5, -16.4), E.Gold, Enum.Material.Metal)
    -- Columned portico and broad entrance steps from the supplied preview.
    Kit.part(auction, "PorticoFloor", Vector3.new(34, 1, 10), cf * CFrame.new(0, 0.5, -21), marble, Enum.Material.Marble)
    Kit.part(auction, "LowerStep", Vector3.new(36, 0.5, 2.5), cf * CFrame.new(0, 0.25, -27.25), marble, Enum.Material.Marble)
    Kit.part(auction, "UpperStep", Vector3.new(35, 0.75, 1.5), cf * CFrame.new(0, 0.375, -26.25), marble, Enum.Material.Marble)
    for _, x in ipairs({-12, -4, 4, 12}) do
        Kit.part(auction, "ColumnBase", Vector3.new(3.6, 0.8, 3.6), cf * CFrame.new(x, 1.4, -23.5), marbleDark, Enum.Material.Marble)
        Kit.cylinder(auction, "PorticoColumn", 1.3, 10.4, cf * CFrame.new(x, 7.2, -23.5), marble, Enum.Material.Marble)
        Kit.part(auction, "ColumnCapital", Vector3.new(3.8, 1, 3.8), cf * CFrame.new(x, 13.1, -23.5), E.Gold, Enum.Material.Metal)
    end
    Kit.part(auction, "PorticoRoof", Vector3.new(30, 2.4, 10), cf * CFrame.new(0, 14.8, -21), marble, Enum.Material.Marble)
    Kit.part(auction, "PorticoGoldBand", Vector3.new(30.6, 0.5, 10.4), cf * CFrame.new(0, 13.45, -21), E.Gold, Enum.Material.Metal)
    Kit.sign(auction, "AUCTION HOUSE", cf * CFrame.new(0, 14.8, -26.2), Vector3.new(22, 1.8, 0.3), E.Teal, E.Cream)
    for tier, width in ipairs({30, 24, 18, 12, 6}) do
        Kit.part(auction, "SteppedPediment", Vector3.new(width, 1.1, 10), cf * CFrame.new(0, 15.45 + tier * 1.1, -21), marble, Enum.Material.Marble)
    end
    -- Side wings, window displays, event signs and planting soften the monumental facade.
    for _, side in ipairs({-1, 1}) do
        local wingX = side * 23
        Kit.part(auction, "SideWing", Vector3.new(10, 11, 26), cf * CFrame.new(wingX, 5.5, 0), marble, Enum.Material.Marble)
        Kit.part(auction, "WingRoof", Vector3.new(11, 1, 27), cf * CFrame.new(wingX, 11.5, 0), E.Teal, Enum.Material.Slate)
        Kit.part(auction, "WingGoldBand", Vector3.new(11, 0.8, 1.6), cf * CFrame.new(wingX, 10.6, -13.2), E.Gold, Enum.Material.Metal)
        archedWindow(wingX, 2.5, 4, 6, -13.2)
        Kit.part(auction, "DisplayPlinth", Vector3.new(9, 2.2, 2.6), cf * CFrame.new(wingX, 1.1, -15.2), E.Green)
        for flower = 0, 4 do
            Kit.ball(auction, "DisplayFlower", Vector3.new(0.9, 0.9, 0.9),
                cf * CFrame.new(wingX - 3.6 + flower * 1.8, 2.4, -15.2), ({E.Coral,E.Gold,E.Cream})[flower % 3 + 1], nil, false)
        end
        exactPost(auction, side * 19.2, 138.4)
    end
    Kit.sign(auction, "LIVE 5:00", cf * CFrame.new(-23, 9.3, -13.35), Vector3.new(7, 1.5, 0.2), E.Red, E.Cream)
    Kit.sign(auction, "BIDS OPEN", cf * CFrame.new(23, 9.3, -13.35), Vector3.new(7, 1.5, 0.2), E.Gold, Color3.fromRGB(58, 42, 0))
    -- Clock tower, tiered teal roof, finial and flag.
    Kit.part(auction, "ClockTower", Vector3.new(10, 9, 10), cf * CFrame.new(0, 23.5, -5), marble, Enum.Material.Marble)
    Kit.part(auction, "TowerLowerBand", Vector3.new(10.8, 0.8, 10.8), cf * CFrame.new(0, 19.4, -5), E.Teal, Enum.Material.Slate)
    Kit.part(auction, "TowerGoldBand", Vector3.new(10.8, 0.8, 10.8), cf * CFrame.new(0, 27.6, -5), E.Gold, Enum.Material.Metal)
    local clockFace = Kit.cylinder(auction, "ClockFace", 3.3, 0.3,
        cf * CFrame.new(0, 24, -10.2) * CFrame.Angles(math.pi / 2, 0, 0), E.Gold, Enum.Material.Metal, false)
    Kit.cylinder(auction, "ClockInset", 2.9, 0.32,
        cf * CFrame.new(0, 24, -10.4) * CFrame.Angles(math.pi / 2, 0, 0), E.Cream, Enum.Material.SmoothPlastic, false)
    Kit.part(auction, "MinuteHand", Vector3.new(0.28, 1.8, 0.18), cf * CFrame.new(0, 24.8, -10.65), E.Charcoal, Enum.Material.Metal, nil, false)
    Kit.part(auction, "HourHand", Vector3.new(2.2, 0.28, 0.18), cf * CFrame.new(1, 24, -10.65), E.Charcoal, Enum.Material.Metal, nil, false)
    for tier = 0, 4 do
        local width = 11 - tier * 2
        Kit.part(auction, "TowerRoofTier", Vector3.new(width, 1.3, width), cf * CFrame.new(0, 28.65 + tier * 1.3, -5), E.Teal, Enum.Material.Slate)
    end
    Kit.ball(auction, "TowerFinial", Vector3.new(2, 2, 2), cf * CFrame.new(0, 35.4, -5), E.Gold, Enum.Material.Metal, false)
    Kit.part(auction, "FlagPole", Vector3.new(0.2, 5, 0.2), cf * CFrame.new(0, 38, -5), E.Steel, Enum.Material.Metal, nil, false)
    Kit.part(auction, "AuctionFlag", Vector3.new(3, 1.8, 0.15), cf * CFrame.new(1.6, 39.4, -5), E.Coral, Enum.Material.Fabric, nil, false)
    local trigger = Kit.part(auction, "AuctionInteraction", Vector3.new(8, 8, 1), cf * CFrame.new(0, 4, -28), E.Cream, nil, nil, false)
    trigger.Transparency = 1; prompt(trigger, "Join the auction", "Auction")
    local podium = Kit.part(auction, "AuctionPodium", Vector3.new(3.5, 4.2, 2.5), cf * CFrame.new(7, 3, 9), E.Wood, Enum.Material.Wood)
    prompt(podium, "View the current lot", "Auction")
    return auction, clockFace
end
function World:exactEnvironment()
    local environment = Kit.model(self.Root, "PreviewEnvironment")
    environment:SetAttribute("Source", "Thrift Flip Town 3D Preview (2).html")
    environment:SetAttribute("Purpose", "Hills, skyline, street dressing, cafe and Riverside Park")
    Kit.part(environment, "OuterGround", Vector3.new(1600, 1, 1600), CFrame.new(0, -0.9, 10), Color3.fromRGB(134, 194, 117), Enum.Material.Grass)
    local seed = 7
    local function random()
        seed = seed * 16807 % 2147483647
        return seed / 2147483647
    end
    -- Layered horizon from the preview: soft green foothills, pale mountains and clouds.
    for index = 0, 23 do
        local angle = index / 24 * math.pi * 2 + (random() - 0.5) * 0.2
        local distance, radius, height = 285 + random() * 55, 55 + random() * 40, 18 + random() * 22
        Kit.ball(environment, "HorizonHill", Vector3.new(radius * 2, radius * 2, radius * 2),
            CFrame.new(math.cos(angle) * distance, height - radius, 10 + math.sin(angle) * distance),
            if index % 3 == 0 then Color3.fromRGB(143, 197, 122) else Color3.fromRGB(125, 186, 110), Enum.Material.Grass, false)
    end
    for index = 0, 13 do
        local angle = index / 14 * math.pi * 2 + (random() - 0.5) * 0.3
        local distance, radius, height = 430 + random() * 35, 110 + random() * 50, 90 + random() * 60
        local x, z = math.cos(angle) * distance, 10 + math.sin(angle) * distance
        Kit.ball(environment, "Mountain", Vector3.new(radius * 2, radius * 2, radius * 2), CFrame.new(x, height - radius, z), Color3.fromRGB(139, 152, 163), Enum.Material.Slate, false)
        Kit.ball(environment, "SnowCap", Vector3.new(radius, radius * 0.55, radius), CFrame.new(x, height - radius * 0.275, z), Color3.fromRGB(244, 248, 250), Enum.Material.Snow, false)
    end
    for cloud = 1, 9 do
        local angle, distance = random() * math.pi * 2, 250 + random() * 200
        local x, z, y = math.cos(angle) * distance, 10 + math.sin(angle) * distance, 130 + random() * 50
        for puff = 0, 3 do
            local diameter = 26 + random() * 16
            local part = Kit.ball(environment, "Cloud", Vector3.new(diameter, diameter * 0.45, diameter),
                CFrame.new(x + puff * 14 - 20, y + puff % 2 * 4, z + (random() - 0.5) * 10), E.Cream, Enum.Material.SmoothPlastic, false)
            part.Transparency = 0.12; part.CastShadow = false
        end
    end
    local function backdropTree(x, z, scale, pine)
        if pine then
            Kit.cylinder(environment, "PineTrunk", 0.6 * scale, 5 * scale, CFrame.new(x, 2.5 * scale, z), E.Wood, Enum.Material.Wood, false)
            for tier = 0, 3 do
                Kit.cylinder(environment, "PineTier", (5 - tier * 1.2) * scale, 3.4 * scale,
                    CFrame.new(x, (3.5 + tier * 2.8) * scale, z), Color3.fromRGB(58 + tier * 8, 120 + tier * 6, 80), Enum.Material.Grass, false)
            end
        else
            local trunk = Kit.cylinder(environment, "TreeLineTrunk", 0.8 * scale, 7 * scale, CFrame.new(x, 3.5 * scale, z), E.Wood, Enum.Material.Wood, false); trunk.CastShadow = false
            Kit.ball(environment, "TreeLineCrown", Vector3.new(9, 9, 9) * scale, CFrame.new(x, 9 * scale, z), E.Green, Enum.Material.Grass, false)
        end
    end
    for index = 1, 110 do
        local angle, distance, scale = random() * math.pi * 2, 240 + random() * 45, 0.9 + random() * 0.8
        backdropTree(math.cos(angle) * distance, 10 + math.sin(angle) * distance, scale, random() < 0.6)
    end
    local flowerColors = {E.Coral,E.Gold,E.Cream,Color3.fromRGB(240,150,180),E.Purple}
    for index = 1, 160 do
        local x, z = (random() - 0.5) * 430, -225 + random() * 470
        local centralTown = x > -130 and x < 130 and z > -155 and z < 200
        local eastDistrict = x > 100 and x < 205 and z > -130 and z < -10
        if not centralTown and not eastDistrict then
            for blossom = 0, 2 do
                Kit.ball(environment, "Wildflower", Vector3.new(0.9, 0.9, 0.9),
                    CFrame.new(x + random() * 3, 1.2, z + random() * 3), flowerColors[(index + blossom - 1) % #flowerColors + 1], nil, false)
            end
        end
    end
    -- Sidewalk furniture, banners and warm overhead string lights along Thrift Street.
    for _, side in ipairs({-1, 1}) do
        Kit.part(environment, "Sidewalk", Vector3.new(6, 0.12, 160), CFrame.new(side * 19, 0.08, 60), Color3.fromRGB(214, 206, 190), Enum.Material.Pavement)
        Kit.part(environment, "SidewalkEdge", Vector3.new(0.6, 0.25, 160), CFrame.new(side * 15.7, 0.125, 60), E.Stone, Enum.Material.Concrete)
    end
    for row, z in ipairs({17,51,85,119}) do
        for sideIndex, side in ipairs({-1,1}) do
            local benchCF = CFrame.new(side * 18, 0, z) * CFrame.Angles(0, if side < 0 then math.pi / 2 else -math.pi / 2, 0)
            if not catalogAsset(environment, "ParkBench", benchCF, 0.58) then Kit.bench(environment, benchCF) end
            Kit.cylinder(environment, "StreetBin", 0.9, 2.4, CFrame.new(side * 18, 1.2, z + 5), Color3.fromRGB(52,100,80), Enum.Material.Metal)
            Kit.part(environment, "StreetBanner", Vector3.new(2.2, 5, 0.3), CFrame.new(side * 19.2, 7.2, z), if (row + sideIndex) % 2 == 0 then E.Coral else E.Teal, Enum.Material.Fabric, nil, false)
            Kit.cylinder(environment, "BannerFinial", 0.8, 0.2, CFrame.new(side * 19.2, 7.6, z - 0.25) * CFrame.Angles(math.pi / 2, 0, 0), E.Gold, Enum.Material.Metal, false)
        end
        local previous
        for point = 0, 20 do
            local x = -20.5 + point * 2.05
            local y = 11.2 - 1.6 * (1 - (x / 20.5) ^ 2)
            local current = Vector3.new(x, y, z)
            if previous then Kit.beam(environment, "StringLightCable", previous, current, 0.08, E.Charcoal, Enum.Material.Metal) end
            if point % 2 == 1 then
                local bulb = Kit.ball(environment, "StringLightBulb", Vector3.new(0.45,0.55,0.45), CFrame.new(x,y-0.7,z), Color3.fromRGB(255,233,168), Enum.Material.Neon, false)
                bulb.CastShadow = false
            end
            previous = current
        end
    end
    local signpost = Kit.model(environment, "TownSignpost")
    Kit.cylinder(signpost, "Post", 0.45, 12, CFrame.new(10, 6, -74), E.Wood, Enum.Material.Wood)
    Kit.ball(signpost, "Finial", Vector3.new(1.4,1.4,1.4), CFrame.new(10,12.2,-74), E.Gold, Enum.Material.Metal, false)
    local directions = {{"↑ THRIFT STREET",E.Teal,E.Cream},{"DUMPSTER ALLEY →",E.Charcoal,E.Gold},{"← PARCEL POST",E.Gold,Color3.fromRGB(58,42,0)},{"← SOURCE",E.Red,E.Cream},{"FLEA FIELD →",E.Coral,E.Cream}}
    for index, direction in ipairs(directions) do
        Kit.sign(signpost, direction[1], CFrame.new(10, 12.55 - index * 1.55, -74.7), Vector3.new(8,1.3,0.2), direction[2], direction[3])
    end
    local cafe = Kit.model(environment, "PlazaCafe")
    for _, location in ipairs({{33,-34},{43,-34},{38,-43}}) do
        local x, z = location[1], location[2]
        Kit.cylinder(cafe, "CafeTable", 2, 0.3, CFrame.new(x, 3.2, z), E.Cream, Enum.Material.Marble)
        Kit.cylinder(cafe, "TablePost", 0.25, 3, CFrame.new(x, 1.6, z), E.Charcoal, Enum.Material.Metal)
        Kit.cylinder(cafe, "Umbrella", 4.5, 0.4, CFrame.new(x, 8.3, z), E.Coral, Enum.Material.Fabric, false)
        Kit.cylinder(cafe, "UmbrellaPole", 0.15, 8, CFrame.new(x, 4.2, z), E.Steel, Enum.Material.Metal)
        for _, offset in ipairs({{3,0},{-3,0},{0,3},{0,-3}}) do
            Kit.part(cafe, "CafeChair", Vector3.new(1.8,1.8,1.8), CFrame.new(x+offset[1],1.4,z+offset[2]), E.LightWood, Enum.Material.Wood)
        end
    end
    -- Riverside Park occupies the east side exactly as shown in the preview.
    local park = Kit.model(environment, "RiversidePark")
    local px, pz = 158, -56.5
    Kit.part(park, "ParkWalk", Vector3.new(72,0.15,8), CFrame.new(86,0.04,pz), E.Stone, Enum.Material.Pavement)
    Kit.cylinder(park, "OuterPark", 33, 0.12, CFrame.new(px,0.08,pz), E.Stone, Enum.Material.Concrete)
    Kit.cylinder(park, "ParkLawn", 29, 0.14, CFrame.new(px,0.09,pz), Color3.fromRGB(176,214,140), Enum.Material.Grass)
    Kit.cylinder(park, "PondEdge", 25.5, 0.3, CFrame.new(px,0.1,pz), E.Stone, Enum.Material.Concrete)
    local pond = Kit.cylinder(park, "PondWater", 24, 0.2, CFrame.new(px,0.16,pz), E.Water, Enum.Material.Glass, false); pond.Transparency = 0.2
    for _, offset in ipairs({-5.2,5.2}) do
        Kit.part(park, "ParkGate", Vector3.new(1.6,8,1.6), CFrame.new(122,4,pz+offset), E.Stone, Enum.Material.Concrete)
        Kit.part(park, "ParkGateCap", Vector3.new(2.2,0.6,2.2), CFrame.new(122,8.3,pz+offset), E.Teal)
    end
    local parkSignCF = CFrame.lookAt(Vector3.new(122,0,pz), Vector3.new(0,0,pz))
    Kit.sign(park, "RIVERSIDE PARK", parkSignCF * CFrame.new(0,7,0), Vector3.new(11,2,0.25), E.Teal, E.Cream)
    for index = 0, 24 do
        Kit.part(park, "BridgeSlat", Vector3.new(1.9,0.3,5.5), CFrame.new(px-25+index*2.08,1.4+0.5*math.sin(index/24*math.pi),pz), E.LightWood, Enum.Material.Wood)
    end
    for _, offset in ipairs({-2.6,2.6}) do
        Kit.part(park, "BridgeRail", Vector3.new(52,0.3,0.3), CFrame.new(px,3.3,pz+offset), E.Wood, Enum.Material.Wood)
        for index = 0, 10 do Kit.part(park, "BridgePost", Vector3.new(0.4,2.2,0.4), CFrame.new(px-25+index*5,2.4,pz+offset), E.Wood, Enum.Material.Wood) end
    end
    for _, offset in ipairs({{-10,10},{8,-12},{12,9},{-14,-8}}) do
        Kit.part(park, "DuckBody", Vector3.new(2,1,1.4), CFrame.new(px+offset[1],0.8,pz+offset[2]), Color3.fromRGB(245,245,245), nil, nil, false)
        Kit.ball(park, "DuckHead", Vector3.new(1,1,1), CFrame.new(px+offset[1]+1,1.6,pz+offset[2]), Color3.fromRGB(245,245,245), nil, false)
        Kit.part(park, "DuckBill", Vector3.new(0.6,0.25,0.5), CFrame.new(px+offset[1]+1.6,1.5,pz+offset[2]), Color3.fromRGB(240,150,50), nil, nil, false)
    end
    for index = 1, 14 do
        local angle, radius = random()*math.pi*2, 6+random()*13
        Kit.cylinder(park, "PondReed", 0.9+random()*0.6, 0.1, CFrame.new(px+math.cos(angle)*radius,0.3,pz+math.sin(angle)*radius), Color3.fromRGB(70,150,80), nil, false)
        if index % 3 == 0 then Kit.ball(park, "WaterFlower", Vector3.new(0.8,0.8,0.8), CFrame.new(px+math.cos(angle)*radius,0.5,pz+math.sin(angle)*radius), Color3.fromRGB(240,150,180), nil, false) end
    end
    for index = 0, 27 do
        local angle = index/28*math.pi*2
        Kit.cylinder(park, "PondStone", 0.125, 3+random()*2, CFrame.new(px+math.cos(angle)*25.5,2,pz+math.sin(angle)*25.5), Color3.fromRGB(110,150,70), Enum.Material.Rock)
    end
    for index = 0, 3 do
        local angle = index*math.pi/2+math.pi/4
        local benchCF = CFrame.lookAt(Vector3.new(px+math.cos(angle)*32,0,pz+math.sin(angle)*32), Vector3.new(px,0,pz))
        if not catalogAsset(park, "ParkBench", benchCF, 0.65) then Kit.bench(park, benchCF) end
        exactPost(park, px+math.cos(angle+math.pi/4)*33, pz+math.sin(angle+math.pi/4)*33)
    end
    local willowX, willowZ = px+20, pz-30
    Kit.cylinder(park, "WillowTrunk", 1.2, 9, CFrame.new(willowX,4.5,willowZ), E.Wood, Enum.Material.Wood)
    Kit.ball(park, "WillowCrown", Vector3.new(12,12,12), CFrame.new(willowX,11,willowZ), Color3.fromRGB(110,170,90), Enum.Material.Grass, false)
    for strand = 0, 27 do
        local angle, length = strand/28*math.pi*2, 5+random()*3
        Kit.part(park, "WillowBranch", Vector3.new(0.3,length,0.3), CFrame.new(willowX+math.cos(angle)*5.2,11-length/2,willowZ+math.sin(angle)*5.2), Color3.fromRGB(120,180,100), Enum.Material.Grass, nil, false)
    end
    local parkTrees = {{8,22},{-6,30},{24,22},{36,-8},{38,18}}
    for index, offset in ipairs(parkTrees) do exactTree(park, px+offset[1]+20, pz+offset[2], 1.1 + index%2*0.08) end
end
function World:previewLandscape()
    local world = Kit.model(self.Root, "ThriftStreetWorldPreview")
    world:SetAttribute("Source", "Thrift_Street_World_3D.html")
    local paving = Color3.fromRGB(217, 213, 199)
    local asphalt = Color3.fromRGB(109, 112, 114)
    local stone = Color3.fromRGB(201, 196, 175)
    local waterColor = Color3.fromRGB(119, 184, 197)
    local steel = Color3.fromRGB(97, 114, 119)
    Kit.part(world, "TownGround", Vector3.new(450, 1.2, 470), CFrame.new(0, -1, -20), Color3.fromRGB(145, 185, 140), Enum.Material.Grass)
    Kit.part(world, "CommunityPlaza", Vector3.new(255, 0.35, 108), CFrame.new(0, -0.2, -37), paving, Enum.Material.Pavement)
    for x = -124, 124, 6 do Kit.part(world, "PlazaSeam", Vector3.new(0.08, 0.03, 107), CFrame.new(x, 0.01, -37), stone, nil, nil, false) end
    for z = -90, 28, 6 do Kit.part(world, "PlazaSeam", Vector3.new(254, 0.03, 0.08), CFrame.new(0, 0.01, z), stone, nil, nil, false) end
    Kit.part(world, "MainStreet", Vector3.new(300, 0.45, 40), CFrame.new(0, -0.22, 54), asphalt, Enum.Material.Asphalt)
    Kit.part(world, "PlazaCurb", Vector3.new(300, 0.55, 1.8), CFrame.new(0, 0.06, 33), stone, Enum.Material.Concrete)
    Kit.part(world, "SouthCurb", Vector3.new(300, 0.55, 1.8), CFrame.new(0, 0.06, 74), stone, Enum.Material.Concrete)
    Kit.part(world, "SouthWalk", Vector3.new(300, 0.25, 11), CFrame.new(0, -0.02, 80), paving, Enum.Material.Pavement)
    for x = -120, 120, 15 do Kit.part(world, "LaneDash", Vector3.new(7.5, 0.08, 0.28), CFrame.new(x, 0.08, 54), P.Gold, Enum.Material.Neon, nil, false) end
    for z = 36, 71, 3.7 do Kit.part(world, "Crosswalk", Vector3.new(10.2, 0.08, 2.35), CFrame.new(0, 0.1, z), P.Paper, nil, nil, false) end
    for x = 38, 105, 15 do Kit.part(world, "ParkingBay", Vector3.new(0.2, 0.08, 21), CFrame.new(x, 0.1, 54), P.Paper, nil, nil, false) end
    -- Extra multiplayer shops use their own clear side streets, outside the authored five-shop block.
    for side = -1, 1, 2 do
        Kit.part(world, "MerchantLane", Vector3.new(15, 0.45, 380), CFrame.new(side * 126, -0.22, 15), asphalt, Enum.Material.Asphalt)
        Kit.part(world, "MerchantWalk", Vector3.new(10, 0.25, 380), CFrame.new(side * 141, 0, 15), paving, Enum.Material.Pavement)
        Kit.part(world, "MerchantCurb", Vector3.new(0.6, 0.6, 380), CFrame.new(side * 136, 0.05, 15), stone, Enum.Material.Concrete)
        for z = -160, 190, 50 do Kit.lamp(world, CFrame.new(side * 135, 0.2, z + 22)) end
    end
    Kit.part(world, "Waterfront", Vector3.new(310, 0.22, 56), CFrame.new(0, -0.25, -145), waterColor, Enum.Material.Glass, nil, false).Transparency = 0.12
    Kit.part(world, "HarborWall", Vector3.new(310, 1.5, 3), CFrame.new(0, 0.5, -113), P.Cream, Enum.Material.Concrete)
    for x = -145, 145, 11 do Kit.part(world, "HarborRail", Vector3.new(0.45, 3, 0.45), CFrame.new(x, 2.1, -112), steel, Enum.Material.Metal) end
    Kit.part(world, "HarborTopRail", Vector3.new(300, 0.35, 0.35), CFrame.new(0, 3.5, -112), steel, Enum.Material.Metal, nil, false)
    for _, x in ipairs({-91, -52, -13, 26, 65}) do Kit.part(world, "BridgePier", Vector3.new(5, 15, 4), CFrame.new(x, 6.5, -161), stone, Enum.Material.Concrete) end
    Kit.part(world, "DistantBridge", Vector3.new(195, 2.6, 8), CFrame.new(-12, 15, -161), stone, Enum.Material.Concrete)
    for x = -101, 70, 11 do Kit.part(world, "BridgeRail", Vector3.new(0.5, 3, 0.45), CFrame.new(x, 18, -161), steel, Enum.Material.Metal, nil, false) end
    local lighthouse = Kit.model(world, "Lighthouse")
    Kit.cylinder(lighthouse, "Tower", 6.2, 26, CFrame.new(118, 13, -166), P.Cream, Enum.Material.Concrete)
    for _, y in ipairs({7, 14, 21}) do Kit.cylinder(lighthouse, "CoralBand", 4.7, 2.2, CFrame.new(118, y, -166), P.Coral) end
    Kit.cylinder(lighthouse, "Gallery", 5.7, 1.5, CFrame.new(118, 26, -166), P.Ink, Enum.Material.Metal)
    local lantern = Kit.cylinder(lighthouse, "LanternRoom", 3.8, 5.4, CFrame.new(118, 29.5, -166), P.Paper, Enum.Material.Glass, false)
    lantern.Transparency = 0.25
    Kit.cylinder(lighthouse, "RedRoof", 6.5, 2, CFrame.new(118, 34, -166), P.Coral, Enum.Material.Metal)
    local beacon = Kit.ball(lighthouse, "Beacon", Vector3.new(2.8, 2.8, 2.8), CFrame.new(118, 30, -162), P.Gold, Enum.Material.Neon, false)
    local light = Instance.new("PointLight"); light.Color = P.Gold; light.Brightness = 1.2; light.Range = 35; light.Parent = beacon
    local truck = Kit.model(world, "ParcelTruck")
    Kit.part(truck, "CargoBody", Vector3.new(21, 9, 9.3), CFrame.new(83, 5.7, 56), Color3.fromRGB(193, 223, 215), Enum.Material.Metal)
    Kit.part(truck, "Cab", Vector3.new(6, 6.3, 9.1), CFrame.new(95.8, 4.5, 56), Color3.fromRGB(189, 215, 208), Enum.Material.Metal)
    Kit.part(truck, "Chassis", Vector3.new(30.4, 1.4, 9.8), CFrame.new(87, 2.2, 56), P.Ink, Enum.Material.Metal)
    Kit.sign(truck, "THRIFT STREET\nGOOD FINDS • BRIGHTER DAYS", CFrame.new(83, 6.2, 60.72), Vector3.new(17.5, 5.4, 0.15), Color3.fromRGB(193, 223, 215), P.Teal)
    for _, x in ipairs({75.5, 96.2}) do for side = -1, 1, 2 do
        Kit.cylinder(truck, "Wheel", 2, 1.05, CFrame.new(x, 2, 56 + side * 5.05) * CFrame.Angles(math.pi / 2, 0, 0), Color3.fromRGB(51, 54, 57), Enum.Material.Metal)
    end end
    for index, position in ipairs({{-110,-3},{-99,-83},{-20,-105},{28,-105},{105,-12},{116,-74},{-110,-95},{94,-94}}) do
        Kit.tree(world, CFrame.new(position[1], 0, position[2]), 0.75 + index % 3 * 0.12, index)
    end
    for _, position in ipairs({{-92,24},{-68,23},{-40,24},{38,23},{83,24},{111,20},{-104,-30},{109,-36}}) do Kit.lamp(world, CFrame.new(position[1], 0.2, position[2])) end
    for _, position in ipairs({{-87,14},{-48,17},{36,18},{91,17},{-96,-58},{99,-69}}) do Kit.bench(world, CFrame.new(position[1], 0.2, position[2])) end
    local function stringLights(from, to, count)
        Kit.beam(world, "LightCable", from, to, 0.08, P.Ink, Enum.Material.Metal)
        for index = 0, count do
            local alpha = index / count
            local point = from:Lerp(to, alpha) - Vector3.new(0, math.sin(alpha * math.pi) * 1.8, 0)
            Kit.beam(world, "LightDrop", point + Vector3.new(0, 0.4, 0), point, 0.04, P.Ink, Enum.Material.Metal)
            local bulb = Kit.ball(world, "FestivalBulb", Vector3.new(0.5, 0.5, 0.5), CFrame.new(point), P.Gold, Enum.Material.Neon, false)
            bulb.Transparency = 0.05
        end
    end
    stringLights(Vector3.new(-105, 13, -12), Vector3.new(-65, 13, -12), 10)
    stringLights(Vector3.new(-33, 14, -43), Vector3.new(28, 16, -43), 14)
    stringLights(Vector3.new(32, 17, -43), Vector3.new(98, 16, -43), 12)
    stringLights(Vector3.new(-36, 16, 21), Vector3.new(38, 17, 21), 15)
    for _, x in ipairs({-100, -70, -36, 36, 72, 106}) do
        Kit.part(world, "BannerPost", Vector3.new(0.25, 12, 0.25), CFrame.new(x, 6, 32), steel, Enum.Material.Metal)
        Kit.part(world, "StreetBanner", Vector3.new(1.6, 3.8, 0.12), CFrame.new(x, 9.5, 33), P.Teal, Enum.Material.Fabric, nil, false)
    end
    for x = -115, 115, 17 do Kit.tree(world, CFrame.new(x, 0, -191), 0.45, x) end
    for side = -1, 1, 2 do
        local wall = Kit.part(world, "TownBoundary", Vector3.new(2, 80, 470), CFrame.new(side * 220, 30, -20), P.Cream); wall.Transparency = 1
    end
    for _, z in ipairs({-218, 215}) do local wall = Kit.part(world, "TownBoundary", Vector3.new(440, 80, 2), CFrame.new(0, 30, z), P.Cream); wall.Transparency = 1 end
end
function World:previewSquare()
    local square = Kit.model(self.Root, "PreviewCommunityPlaza")
    local fountainCF = CFrame.new(-30, 0, -57)
    Kit.cylinder(square, "FountainBase", 8.7, 1.5, fountainCF * CFrame.new(0, 0.85, 0), P.Cream, Enum.Material.Marble)
    local lowerWater = Kit.cylinder(square, "LowerWater", 7.15, 0.35, fountainCF * CFrame.new(0, 1.65, 0), Color3.fromRGB(119, 184, 197), Enum.Material.Glass, false)
    lowerWater.Transparency = 0.18
    Kit.cylinder(square, "FountainColumn", 1.35, 6.4, fountainCF * CFrame.new(0, 4.3, 0), P.Paper, Enum.Material.Marble)
    Kit.cylinder(square, "MiddleBowl", 4.5, 0.9, fountainCF * CFrame.new(0, 5.5, 0), P.Cream, Enum.Material.Marble)
    Kit.cylinder(square, "UpperColumn", 0.65, 3.4, fountainCF * CFrame.new(0, 7, 0), P.Cream, Enum.Material.Marble)
    Kit.cylinder(square, "UpperBowl", 2.7, 0.7, fountainCF * CFrame.new(0, 8.7, 0), P.Cream, Enum.Material.Marble)
    Kit.ball(square, "GoldenFinial", Vector3.new(1.2, 1.2, 1.2), fountainCF * CFrame.new(0, 10, 0), P.Gold, Enum.Material.Metal, false)
    for i = 1, 10 do
        local angle = i * math.pi / 5
        local from = fountainCF.Position + Vector3.new(math.cos(angle) * 2.2, 8.8, math.sin(angle) * 2.2)
        local to = fountainCF.Position + Vector3.new(math.cos(angle) * 5.7, 2, math.sin(angle) * 5.7)
        local ribbon = Kit.beam(square, "WaterArc", from, to, 0.13, Color3.fromRGB(174, 226, 229), Enum.Material.Glass); ribbon.Transparency = 0.35
    end
    local archCF = CFrame.new(-102, 0, 19)
    for side = -1, 1, 2 do
        Kit.part(square, "ArchPillar", Vector3.new(4.2, 12.5, 4.2), archCF * CFrame.new(side * 10, 6.3, 0), Color3.fromRGB(229, 214, 187), Enum.Material.Brick)
        Kit.part(square, "ArchCap", Vector3.new(4.8, 1.2, 4.8), archCF * CFrame.new(side * 10, 12.8, 0), P.Cream, Enum.Material.Marble)
    end
    Kit.part(square, "ArchHeader", Vector3.new(24, 2, 1.8), archCF * CFrame.new(0, 13.8, 0), P.Ink, Enum.Material.Metal)
    Kit.sign(square, "THRIFT STREET\nSHOP • EXPLORE • REIMAGINE", archCF * CFrame.new(0, 13.8, -1), Vector3.new(23.3, 3.1, 0.2), P.Ink, P.Cream)
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "TownSpawn"; spawn.Size = Vector3.new(7, 0.3, 7)
    spawn.CFrame = CFrame.new(-102, 0.5, 26); spawn.Anchored = true; spawn.Neutral = true; spawn.Transparency = 1; spawn.Duration = 0; spawn.Parent = square
    local notice = Kit.model(square, "CommunityNoticeboard")
    local noticeCF = CFrame.new(-87, 0, 14)
    for side = -1, 1, 2 do Kit.part(notice, "Post", Vector3.new(0.6, 8, 0.6), noticeCF * CFrame.new(side * 5.6, 4, 0), P.Wood, Enum.Material.Wood) end
    local label, board = Kit.sign(notice, "THE DAILY FIND\nQUESTS & DESIGNER SHOWCASE", noticeCF * CFrame.new(0, 6, 0), Vector3.new(12, 5, 0.5), P.Teal)
    label.TextColor3 = P.Paper; prompt(board, "Quests & showcase", "Quests")
    Kit.part(notice, "RainCover", Vector3.new(14, 0.35, 3), noticeCF * CFrame.new(0, 9.2, 0), P.Wood, Enum.Material.Wood)
    self.Destinations = {Source = Vector3.new(-108, 2, -67), Estate = Vector3.new(-18, 2, -86),
        Delivery = Vector3.new(100, 2, 40), Quests = Vector3.new(-87, 2, 14), Flea = Vector3.new(-18, 2, -86),
        Auction = Vector3.new(-72, 2, 4), Market = Vector3.new(-72, 2, 4), Workbench = Vector3.new(69, 2, -53)}
    local travel = Kit.model(square, "FastTravelHub")
    local stops = {{"FINDS","Source",-60,P.Coral},{"ESTATE","Estate",-50,P.Gold},{"MARKET","Market",-40,P.Lavender},{"RESTORE","Workbench",-30,P.Teal}}
    for _, stop in ipairs(stops) do
        local pad = Kit.cylinder(travel, stop[1] .. "TravelPad", 3, 0.3, CFrame.new(stop[3], 0.35, 24), stop[4], Enum.Material.Neon)
        prompt(pad, "Fast travel", "Teleport", 0, 0, stop[2])
        Kit.sign(travel, stop[1], CFrame.new(stop[3], 3.2, 27), Vector3.new(7, 1.4, 0.2), P.Ink, P.Paper)
    end
    local delivery = Kit.model(square, "ParcelPost")
    local dcf = CFrame.new(100, 0.2, 40)
    Kit.part(delivery, "PostalCabinet", Vector3.new(9, 5, 4), dcf * CFrame.new(0, 2.5, 0), P.Teal)
    Kit.sign(delivery, "PARCEL POST", dcf * CFrame.new(0, 6.7, -2.1), Vector3.new(10, 2, 0.3), P.Cream, P.Ink)
    local _, parcel = Kit.parcel(delivery, dcf * CFrame.new(0, 5.2, 0), Vector3.new(2.5, 1.8, 2), P.Rose)
    prompt(parcel, "Open daily delivery", "Delivery")
    for i = 1, 4 do Kit.parcel(delivery, dcf * CFrame.new(-8 + i * 3.2, 0, 4), Vector3.new(2.2, 1.5 + i % 2, 2), if i % 2 == 0 then P.Oak else P.Rose) end
end
function World:landscape()
    local terrain = Kit.model(self.Root, "VillageLandscape")
    Kit.part(terrain, "Meadow", Vector3.new(520, 2, 650), CFrame.new(0, -1.5, -15), P.Grass, Enum.Material.Grass)
    Kit.part(terrain, "CobblestoneHighStreet", Vector3.new(34, 0.5, 410), CFrame.new(0, -0.3, 20), Color3.fromRGB(185, 178, 158), Enum.Material.Cobblestone)
    Kit.part(terrain, "FeaturedShopWalk", Vector3.new(9, 0.25, 12), CFrame.new(-32, 0.2, -25), Color3.fromRGB(214, 195, 162), Enum.Material.Pavement)
    Kit.part(terrain, "MerchantCrossStreet", Vector3.new(182, 0.5, 14), CFrame.new(0, -0.3, 75), Color3.fromRGB(185, 178, 158), Enum.Material.Cobblestone)
    for z = -170, 210, 18 do
        Kit.part(terrain, "RoadMarker", Vector3.new(0.45, 0.08, 8), CFrame.new(0, 0.01, z), P.Gold, Enum.Material.Neon, nil, false)
    end
    for side = -1, 1, 2 do
        Kit.part(terrain, "PavedWalkway", Vector3.new(11, 0.5, 410), CFrame.new(side * 22.5, 0, 20), P.Cream, Enum.Material.Pavement)
        Kit.part(terrain, "Curb", Vector3.new(0.6, 0.8, 410), CFrame.new(side * 17.4, 0.1, 20), Color3.fromRGB(213, 205, 180))
        Kit.part(terrain, "MerchantRowRoad", Vector3.new(14, 0.5, 340), CFrame.new(side * 90, -0.3, 35), Color3.fromRGB(185, 178, 158), Enum.Material.Cobblestone)
        Kit.part(terrain, "MerchantRowWalkway", Vector3.new(8, 0.5, 340), CFrame.new(side * 101, 0, 35), P.Cream, Enum.Material.Pavement)
        Kit.part(terrain, "MerchantRowCurb", Vector3.new(0.6, 0.8, 340), CFrame.new(side * 97.2, 0.1, 35), Color3.fromRGB(213, 205, 180))
        for row = 1, 8 do
            local z = -105 + (row - 1) * 40
            if row % 2 == 1 then Kit.bench(terrain, CFrame.new(side * 96, 0.3, z + 17) * CFrame.Angles(0, if side == -1 then -math.pi / 2 else math.pi / 2, 0)) end
        end
        for i = 1, 10 do Kit.lamp(terrain, CFrame.new(side * 18.8, 0.3, -120 + i * 34)) end
        for i = 1, 14 do Kit.tree(terrain, CFrame.new(side * (108 + i % 3 * 5), 0, -230 + i * 34), 0.9 + (i % 3) * 0.15, i) end
        for i = 1, 6 do
            local x = side * (177 + (i % 2) * 35)
            Kit.ball(terrain, "DistantHill", Vector3.new(130, 70 + i % 3 * 20, 150), CFrame.new(x, 6, -270 + i * 100), Color3.fromRGB(131, 160, 116), Enum.Material.Grass, false)
        end
    end
    for i = 1, 8 do
        local x = -100 + i * 25
        Kit.tree(terrain, CFrame.new(x, 0, 245 + i % 2 * 10), 1.3, i)
    end
    -- Invisible edges keep avatars inside the authored landscape without a box-like skyline.
    for side = -1, 1, 2 do
        local wall = Kit.part(terrain, "TownBoundary", Vector3.new(2, 80, 650), CFrame.new(side * 180, 30, -15), P.Cream)
        wall.Transparency = 1
    end
    for _, z in ipairs({-302, 288}) do
        local wall = Kit.part(terrain, "TownBoundary", Vector3.new(360, 80, 2), CFrame.new(0, 30, z), P.Cream); wall.Transparency = 1
    end
end
function World:square()
    local square = Kit.model(self.Root, "WelcomeSquare")
    Kit.part(square, "PlazaPaving", Vector3.new(112, 0.4, 96), CFrame.new(0, 0, -165), Color3.fromRGB(227, 216, 189), Enum.Material.Pavement)
    Kit.cylinder(square, "FountainSteps", 11, 0.5, CFrame.new(0, 0.4, -170), P.Cream, Enum.Material.Marble)
    Kit.cylinder(square, "FountainBasin", 8.8, 1.7, CFrame.new(0, 1.2, -170), Color3.fromRGB(192, 180, 154), Enum.Material.Marble)
    local water = Kit.cylinder(square, "TurquoiseWater", 7.9, 0.2, CFrame.new(0, 2.1, -170), Color3.fromRGB(109, 181, 187), Enum.Material.Glass, false)
    water.Transparency = 0.2; water.Reflectance = 0.1
    Kit.cylinder(square, "FountainColumn", 1.4, 5, CFrame.new(0, 3.9, -170), P.Cream, Enum.Material.Marble)
    Kit.cylinder(square, "UpperBowl", 3, 0.5, CFrame.new(0, 6.5, -170), P.Cream, Enum.Material.Marble)
    Kit.ball(square, "GoldenFinial", Vector3.new(1.3, 1.5, 1.3), CFrame.new(0, 7.4, -170), P.Gold, Enum.Material.Metal, false)
    for i = 1, 8 do
        local angle = i * math.pi / 4
        local start = Vector3.new(math.cos(angle) * 2.6, 6.4, -170 + math.sin(angle) * 2.6)
        local finish = Vector3.new(math.cos(angle) * 3.5, 2.3, -170 + math.sin(angle) * 3.5)
        local flow = Kit.beam(square, "WaterRibbon", start, finish, 0.17, Color3.fromRGB(163, 222, 222), Enum.Material.Glass)
        flow.Transparency = 0.35
    end
    for _, x in ipairs({-23, 23}) do
        Kit.bench(square, CFrame.new(x, 0.2, -169) * CFrame.Angles(0, if x < 0 then -math.pi / 2 else math.pi / 2, 0))
        Kit.plant(square, CFrame.new(x, 0.2, -160), 1.6, nil, true)
        Kit.plant(square, CFrame.new(x, 0.2, -180), 1.6, nil, true)
    end
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "TownSpawn"; spawn.Size = Vector3.new(8, 0.3, 8)
    spawn.CFrame = CFrame.new(0, 0.5, -145); spawn.Anchored = true; spawn.Neutral = true; spawn.Transparency = 1; spawn.Duration = 0; spawn.Parent = square
    for side = -1, 1, 2 do Kit.part(square, "EntrancePost", Vector3.new(1.2, 16, 1.2), CFrame.new(side * 17, 8, -129), P.Teal) end
    Kit.sign(square, "THRIFT STREET", CFrame.new(0, 15, -129), Vector3.new(34, 4.3, 0.6), P.Teal)
    Kit.sign(square, "SECOND CHANCES. EXTRAORDINARY FINDS.", CFrame.new(0, 11.8, -129.2), Vector3.new(29, 1.1, 0.2), P.Cream, P.Ink)
    local notice = Kit.model(square, "CommunityNoticeboard")
    local noticeCF = CFrame.new(-24, 0, -145)
    for side = -1, 1, 2 do Kit.part(notice, "Post", Vector3.new(0.6, 8, 0.6), noticeCF * CFrame.new(side * 5.6, 4, 0), P.Wood, Enum.Material.Wood) end
    local label, board = Kit.sign(notice, "THE DAILY FIND\nQUESTS & DESIGNER SHOWCASE", noticeCF * CFrame.new(0, 6, 0), Vector3.new(12, 5, 0.5), P.Teal)
    label.TextColor3 = P.Paper; prompt(board, "Quests & showcase", "Quests")
    Kit.part(notice, "RainCover", Vector3.new(14, 0.35, 3), noticeCF * CFrame.new(0, 9.2, 0), P.Wood, Enum.Material.Wood)
    for i = 1, 3 do Kit.sign(notice, ({"FIND\n3 treasures", "RESTORE\n3 keepsakes", "SELL\n3 stories"})[i], noticeCF * CFrame.new(-3.6 + (i - 1) * 3.6, 2.2, -0.4) * CFrame.Angles(0, 0, (i - 2) * 0.06), Vector3.new(3, 2.4, 0.1), P.Paper, P.Ink) end
    self.Destinations = {Source = Vector3.new(-46, 2, -165), Estate = Vector3.new(48, 2, -165),
        Delivery = Vector3.new(46, 2, -185), Quests = Vector3.new(-24, 2, -145), Flea = Vector3.new(-78, 2, -215),
        Auction = Vector3.new(-48, 2, 28), Market = Vector3.new(-48, 2, -80), Workbench = Vector3.new(48, 2, 25)}
    local travel = Kit.model(square, "FastTravelHub")
    local stops = {
        {"FINDS", "Source", -16, -147, P.Coral}, {"ESTATE", "Estate", -8, -147, P.Gold},
        {"AUCTION", "Auction", 8, -147, P.Rose}, {"MARKET", "Market", 16, -147, P.Lavender},
    }
    for _, stop in ipairs(stops) do
        local pad = Kit.cylinder(travel, stop[1] .. "TravelPad", 3.1, 0.35, CFrame.new(stop[3], 0.42, stop[4]), stop[5], Enum.Material.Neon)
        pad.Transparency = 0.08
        Kit.cylinder(travel, "PadRing", 3.75, 0.16, CFrame.new(stop[3], 0.25, stop[4]), P.Ink, Enum.Material.Metal)
        Kit.sign(travel, stop[1], CFrame.new(stop[3], 3.4, stop[4] + 2.8), Vector3.new(6.5, 1.5, 0.18), P.Ink, P.Paper)
        local beacon = Kit.part(travel, "TravelBeacon", Vector3.new(0.35, 8, 0.35), CFrame.new(stop[3], 4.3, stop[4]), stop[5], Enum.Material.Neon, nil, false)
        beacon.Transparency = 0.32
        prompt(pad, "Fast travel", "Teleport", 0, 0, stop[2])
    end
    Kit.sign(travel, "FAST TRAVEL", CFrame.new(0, 5.8, -144.2), Vector3.new(14, 2.1, 0.3), P.Teal, P.Paper)
    local delivery = Kit.model(square, "ParcelPost")
    local dcf = CFrame.new(46, 0.2, -185)
    Kit.part(delivery, "PostalCabinet", Vector3.new(9, 5, 4), dcf * CFrame.new(0, 2.5, 0), P.Teal)
    Kit.part(delivery, "PostalTop", Vector3.new(9.5, 0.4, 4.5), dcf * CFrame.new(0, 5.2, 0), P.Oak, Enum.Material.Wood)
    Kit.sign(delivery, "PARCEL POST", dcf * CFrame.new(0, 7, 0.1), Vector3.new(10, 2, 0.3), P.Cream, P.Ink)
    local _, parcel = Kit.parcel(delivery, dcf * CFrame.new(0, 5.4, 0), Vector3.new(2.5, 1.8, 2), P.Rose)
    prompt(parcel, "Open daily delivery", "Delivery")
    for i = 1, 3 do
        Kit.sign(delivery, "✉", dcf * CFrame.new(-3 + (i - 1) * 3, 2.8, -2.1), Vector3.new(2.6, 2.1, 0.1), P.Cream, P.Teal)
    end
    Kit.parcel(delivery, dcf * CFrame.new(-6, 0, 1), Vector3.new(2, 2.5, 2), P.Oak)
    Kit.parcel(delivery, dcf * CFrame.new(-6.2, 2.6, 1), Vector3.new(1.8, 1.2, 1.8), P.Rose)
end
function World:sourcing()
    local alley = Kit.model(self.Root, "SecondChanceAlley")
    local cf = CFrame.new(-108, 0, -67)
    Kit.part(alley, "AlleyPavers", Vector3.new(30, 0.3, 24), cf, Color3.fromRGB(162, 160, 145), Enum.Material.Cobblestone)
    Kit.part(alley, "BrickWall", Vector3.new(29, 9, 1), cf * CFrame.new(0, 4.5, -10), P.Brick, Enum.Material.Brick)
    Kit.sign(alley, "START HERE\nDUMPSTER ALLEY", cf * CFrame.new(0, 7, -9.4) * CFrame.Angles(0, math.pi, 0), Vector3.new(22, 4.3, 0.2), P.Teal)
    for _, x in ipairs({-7, 2}) do
        local binCF = cf * CFrame.new(x, 0.3, -4)
        local bin = Kit.part(alley, "SalvageBin", Vector3.new(6.8, 3.9, 4.3), binCF * CFrame.new(0, 2.1, 0), if x < 0 then P.Teal else P.Ink, Enum.Material.Metal)
        Kit.part(alley, "HingedLid", Vector3.new(7.2, 0.35, 4.6), binCF * CFrame.new(0, 4.4, 0.9) * CFrame.Angles(-0.35, 0, 0), P.Ink, Enum.Material.Metal)
        for side = -1, 1, 2 do
            Kit.part(alley, "Handle", Vector3.new(1.6, 0.18, 0.25), binCF * CFrame.new(side * 1.8, 3.2, 2.3), P.Cream, Enum.Material.Metal, nil, false)
            Kit.ball(alley, "Wheel", Vector3.new(0.7, 0.7, 0.5), binCF * CFrame.new(side * 2.5, 0.3, 1.6), P.Ink)
        end
        prompt(bin, "Search for a treasure", "Source")
        Kit.sign(alley, "FIND • RESTORE • REPEAT", binCF * CFrame.new(0, 2.2, 2.24) * CFrame.Angles(0, math.pi, 0), Vector3.new(5.3, 1.4, 0.1), P.Cream, P.Ink)
    end
    Kit.crate(alley, cf * CFrame.new(10, 0.3, -5), Vector3.new(4, 2.5, 3), true)
    Kit.crate(alley, cf * CFrame.new(9, 0.3, 1), Vector3.new(3, 2, 3), false)
    Kit.parcel(alley, cf * CFrame.new(9, 2.4, 1), Vector3.new(2, 1.5, 2), P.Oak)
    Kit.plant(alley, cf * CFrame.new(-12, 0.3, 7), 1, nil, true)
    Kit.sign(alley, "FREE FINDS\nA little dusty. A lot of possibility.", cf * CFrame.new(0, 1.8, 7) * CFrame.Angles(0, math.pi, 0), Vector3.new(10, 2.5, 0.3), P.Cream, P.Ink)
    local estate = Kit.model(self.Root, "SundayEstateSale")
    local ecf = CFrame.new(-18, 0, -86)
    Kit.part(estate, "GardenPath", Vector3.new(27, 0.3, 26), ecf, Color3.fromRGB(210, 194, 160), Enum.Material.Pavement)
    Kit.fence(estate, ecf * CFrame.new(14, 0.2, -1) * CFrame.Angles(0, math.pi / 2, 0), 28)
    Kit.fence(estate, ecf * CFrame.new(0, 0.2, -13), 28)
    local tableTop = Kit.part(estate, "SaleTable", Vector3.new(12, 0.4, 5), ecf * CFrame.new(-2, 3, 0), P.Oak, Enum.Material.Wood)
    for x = -1, 1, 2 do for z = -1, 1, 2 do
        Kit.part(estate, "TableLeg", Vector3.new(0.4, 2.8, 0.4), ecf * CFrame.new(-2 + x * 5.2, 1.4, z * 2), P.Wood, Enum.Material.Wood)
    end end
    awning(estate, ecf * CFrame.new(-2, 8.5, 0), 16, 8, P.Rose)
    for x = -1, 1, 2 do Kit.part(estate, "CanopyPole", Vector3.new(0.25, 8.4, 0.25), ecf * CFrame.new(-2 + x * 7.4, 4.2, 2.9), P.Cream, Enum.Material.Metal) end
    prompt(tableTop, "Browse mystery lots", "Estate")
    Kit.sign(estate, "WHOLESALE SOURCE", ecf * CFrame.new(-2, 6.5, 4) * CFrame.Angles(0, math.pi, 0), Vector3.new(14, 2.2, 0.3), P.Rose)
    Kit.parcel(estate, ecf * CFrame.new(-5, 3.2, 0), Vector3.new(2.6, 1.8, 2.5), P.Cream)
    Kit.parcel(estate, ecf * CFrame.new(0, 3.2, 0), Vector3.new(2.5, 2.3, 2.5), P.Teal)
    Kit.parcel(estate, ecf * CFrame.new(3, 3.2, 0), Vector3.new(2.2, 1.4, 2.2), P.Rose)
    Kit.plant(estate, ecf * CFrame.new(11, 0.3, 8), 1.5, nil, true)
    Kit.crate(estate, ecf * CFrame.new(8, 0.3, -6), Vector3.new(3, 3, 3), false)
end
function World:auctionHouse()
    local model = Kit.model(self.Root, "TheGavelAuctionHouse")
    local cf = CFrame.new(-52, 0, 55) * CFrame.Angles(0, -math.pi / 2, 0)
    Kit.part(model, "Foundation", Vector3.new(58, 1, 46), cf * CFrame.new(0, 0.25, 0), P.Cream, Enum.Material.Marble)
    Kit.part(model, "TimberFloor", Vector3.new(52, 0.2, 40), cf * CFrame.new(0, 0.85, 0), P.Wood, Enum.Material.WoodPlanks)
    Kit.part(model, "BackWall", Vector3.new(56, 20, 1.3), cf * CFrame.new(0, 10, 22), P.Brick, Enum.Material.Brick)
    for side = -1, 1, 2 do
        Kit.part(model, "WingWall", Vector3.new(1.3, 20, 44), cf * CFrame.new(side * 28, 10, 0), P.Brick, Enum.Material.Brick)
        Kit.part(model, "EntranceWall", Vector3.new(15, 20, 1.3), cf * CFrame.new(side * 20.5, 10, -22), P.Brick, Enum.Material.Brick)
        window(model, cf * CFrame.new(side * 20.5, 8, -22.7), 8, 10)
        Kit.part(model, "EntryColumn", Vector3.new(2, 17, 2), cf * CFrame.new(side * 12, 8.5, -23), P.Cream, Enum.Material.Marble)
        Kit.cylinder(model, "ColumnCap", 1.7, 0.8, cf * CFrame.new(side * 12, 16.8, -23), P.Cream, Enum.Material.Marble)
    end
    Kit.part(model, "Entablature", Vector3.new(58, 2, 3), cf * CFrame.new(0, 18.5, -22.5), P.Cream)
    Kit.sign(model, "THE GAVEL", cf * CFrame.new(0, 15.5, -23.7), Vector3.new(20, 3, 0.3), P.Brick, P.Paper)
    Kit.sign(model, "RARE FINDS • REAL EXCITEMENT", cf * CFrame.new(0, 12.8, -23.8), Vector3.new(20, 1.3, 0.2), P.Brick, P.Gold)
    Kit.part(model, "Stage", Vector3.new(40, 2, 11), cf * CFrame.new(0, 1.7, 14), P.Ink)
    Kit.part(model, "CurtainRod", Vector3.new(42, 0.5, 0.5), cf * CFrame.new(0, 17, 20), P.Gold, Enum.Material.Metal)
    for side = -1, 1, 2 do for i = 1, 5 do
        Kit.part(model, "VelvetCurtain", Vector3.new(1.6, 14, 1), cf * CFrame.new(side * (13 + i * 1.5), 10, 19.5), P.Rose, Enum.Material.Fabric, nil, false)
    end end
    Kit.sign(model, "A NEW STORY STARTS HERE", cf * CFrame.new(0, 12, 20.8), Vector3.new(25, 4, 0.2), P.Ink, P.Gold)
    local podium = Kit.part(model, "BiddingPodium", Vector3.new(4, 4.5, 3), cf * CFrame.new(9, 4.7, 13), P.Wood, Enum.Material.Wood)
    Kit.part(model, "PodiumTop", Vector3.new(4.6, 0.4, 3.6), cf * CFrame.new(9, 7.1, 13), P.Oak, Enum.Material.Wood)
    prompt(podium, "Join the auction", "Auction")
    Kit.cylinder(model, "GavelBlock", 0.8, 0.2, cf * CFrame.new(9, 7.4, 13), P.Ink)
    Kit.part(model, "GavelHandle", Vector3.new(0.18, 0.18, 1.8), cf * CFrame.new(9, 7.7, 12.5), P.Oak, Enum.Material.Wood, nil, false)
    Kit.cylinder(model, "GavelHead", 0.3, 0.9, cf * CFrame.new(9, 7.7, 13.3) * CFrame.Angles(0, 0, math.pi / 2), P.Wood, Enum.Material.Wood, false)
    local plinth = Kit.part(model, "AuctionDisplay", Vector3.new(5, 4, 5), cf * CFrame.new(-3, 4.5, 13), P.Cream, Enum.Material.Marble)
    prompt(plinth, "View the current lot", "Auction")
    Kit.sign(model, "✦  THE NEXT GREAT FIND  ✦", cf * CFrame.new(-3, 8, 13), Vector3.new(11, 1.2, 0.2), P.Ink, P.Gold)
    for row = 1, 3 do
        for column = 1, 4 do
            local x = (column - 2.5) * 8
            local seatCF = cf * CFrame.new(x, 0.95, -15 + row * 6)
            Kit.part(model, "Seat", Vector3.new(3, 0.5, 3), seatCF * CFrame.new(0, 1.8, 0), P.Rose, Enum.Material.Fabric)
            Kit.part(model, "SeatBack", Vector3.new(3, 3, 0.4), seatCF * CFrame.new(0, 3.1, -1.3), P.Rose, Enum.Material.Fabric)
            for side = -1, 1, 2 do Kit.part(model, "SeatLeg", Vector3.new(0.25, 1.7, 2.5), seatCF * CFrame.new(side * 1.2, 0.85, 0), P.Wood, Enum.Material.Wood) end
        end
    end
    -- Ceiling beams leave the central camera view open in the authored building.
    for i = 1, 5 do Kit.part(model, "RoofBeam", Vector3.new(56, 1, 1.2), cf * CFrame.new(0, 20, -20 + i * 8), P.Wood, Enum.Material.Wood) end
    local welcome = Kit.sign(model, "AUCTION HOUSE\nStep inside to bid", cf * CFrame.new(0, 2.5, -24.6), Vector3.new(9, 2.5, 0.25), P.Cream, P.Ink)
    welcome.Parent.Parent.CanCollide = false
end
function World:market()
    local market = Kit.model(self.Root, "MakersMarket")
    Kit.part(market, "MarketPaving", Vector3.new(90, 0.3, 48), CFrame.new(0, 0.1, 211), P.Cream, Enum.Material.Pavement)
    Kit.sign(market, "THE MAKERS' MARKET", CFrame.new(0, 11, 233), Vector3.new(34, 4, 0.6), P.Teal)
    for side = -1, 1, 2 do
        for row = 1, 2 do
            local cf = CFrame.new(side * 23, 0.3, 198 + row * 12) * CFrame.Angles(0, if side == -1 then -math.pi / 2 else math.pi / 2, 0)
            local tableTop = Kit.part(market, "MarketCounter", Vector3.new(9, 0.4, 4), cf * CFrame.new(0, 3, 0), P.Oak, Enum.Material.Wood)
            Kit.part(market, "StallFront", Vector3.new(9, 2.8, 0.2), cf * CFrame.new(0, 1.5, -1.8), if row == 1 then P.Teal else P.Rose, Enum.Material.Wood)
            for x = -1, 1, 2 do Kit.part(market, "StallPost", Vector3.new(0.4, 8, 0.4), cf * CFrame.new(x * 4.2, 4, 1.8), P.Wood, Enum.Material.Wood) end
            awning(market, cf * CFrame.new(0, 8, 0), 10, 6, if row == 1 then P.Teal else P.Rose)
            prompt(tableTop, "Browse the player market", "Market")
            Kit.crate(market, cf * CFrame.new(5.8, 0, 0), Vector3.new(2.8, 2.5, 2.8), true)
        end
    end
    local kiosk = Kit.part(market, "MarketGuide", Vector3.new(5, 3, 3), CFrame.new(0, 1.8, 210), P.Teal)
    prompt(kiosk, "Open the market", "Market")
    Kit.sign(market, "TRADE STORIES\nFIND SOMETHING YOU LOVE", CFrame.new(0, 4.8, 208.4), Vector3.new(10, 3, 0.25), P.Cream, P.Ink)
    for _, x in ipairs({-38, 38}) do Kit.tree(market, CFrame.new(x, 0.2, 213), 1.2, 1) end
    local pivot = market:GetPivot()
    local transform = CFrame.new(-52, 0, -95) * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(0, 0, -211)
    market:PivotTo(transform * pivot)
end
function World:districtLandmarks()
    local district = Kit.model(self.Root, "HTMLPreviewDistrict")
    district:SetAttribute("Source", "Thrift Street 3D Preview.html")
    local glassColor = Color3.fromRGB(207, 233, 230)
    local stone = Color3.fromRGB(232, 226, 212)
    local charcoal = Color3.fromRGB(43, 43, 51)
    local steel = Color3.fromRGB(138, 146, 154)
    local function building(name, position, side, width, height, depth, wall, floor, roof)
        local cf = CFrame.new(position) * CFrame.Angles(0, if side < 0 then -math.pi / 2 else math.pi / 2, 0)
        local model = Kit.model(district, name)
        Kit.part(model, "Floor", Vector3.new(width, 0.5, depth), cf * CFrame.new(0, 0.25, 0), floor, Enum.Material.WoodPlanks)
        Kit.part(model, "BackWall", Vector3.new(width, height, 1), cf * CFrame.new(0, height / 2, depth / 2 - 0.5), wall, Enum.Material.Brick)
        for x = -1, 1, 2 do Kit.part(model, "SideWall", Vector3.new(1, height, depth - 2), cf * CFrame.new(x * (width / 2 - 0.5), height / 2, 0), wall, Enum.Material.Brick) end
        Kit.part(model, "Roof", Vector3.new(width + 2, 1, depth + 2), cf * CFrame.new(0, height + 0.5, 0), roof, Enum.Material.Slate)
        return model, cf
    end
    local function displayWindow(model, cf, x, y, width, height, frameColor)
        local pane = Kit.part(model, "DisplayGlass", Vector3.new(width, height, 0.18), cf * CFrame.new(x, y, -14.05), glassColor, Enum.Material.Glass, nil, false)
        pane.Transparency = 0.35; pane.Reflectance = 0.12
        for side = -1, 1, 2 do Kit.part(model, "WindowPost", Vector3.new(0.45, height + 0.8, 0.55), cf * CFrame.new(x + side * width / 2, y, -14.2), frameColor, Enum.Material.Metal) end
        Kit.part(model, "WindowTop", Vector3.new(width + 0.8, 0.45, 0.55), cf * CFrame.new(x, y + height / 2, -14.2), frameColor, Enum.Material.Metal)
        Kit.part(model, "WindowBase", Vector3.new(width + 1.4, 0.6, 1.2), cf * CFrame.new(x, y - height / 2, -14.5), frameColor)
    end
    local function shelf(model, cf, x, z, width, levels, colors)
        for level = 0, levels do Kit.part(model, "Shelf", Vector3.new(width, 0.22, 1.8), cf * CFrame.new(x, 0.6 + level * 2.35, z), P.Oak, Enum.Material.Wood) end
        for side = -1, 1, 2 do Kit.part(model, "ShelfSide", Vector3.new(0.25, levels * 2.4, 1.8), cf * CFrame.new(x + side * width / 2, levels * 1.2 + 0.5, z), P.Wood, Enum.Material.Wood) end
        for level = 1, levels do for item = 1, math.floor(width / 1.6) do
            local h = 0.8 + ((item + level) % 3) * 0.35
            Kit.part(model, "ShelfFind", Vector3.new(0.9, h, 0.9), cf * CFrame.new(x - width / 2 + item * 1.6 - 0.7, 0.75 + (level - 1) * 2.35 + h / 2, z), colors[(item + level) % #colors + 1])
        end end
    end
    local colors = {P.Coral, P.Gold, P.Teal, P.Lavender, P.Cream}
    -- Port of market(): three open striped stalls with counters and visible stock.
    local market = Kit.model(district, "Market")
    local mcf = CFrame.new(-52, 0, -80) * CFrame.Angles(0, -math.pi / 2, 0)
    Kit.part(market, "MarketFloor", Vector3.new(36, 0.4, 28), mcf * CFrame.new(0, 0.2, 0), stone, Enum.Material.Pavement)
    for stallIndex, stall in ipairs({{"ANTIQUES", P.Rose}, {"CLOTHES", P.Teal}, {"COLLECTIBLES", P.Gold}}) do
        local x = -11 + (stallIndex - 1) * 11
        for sx = -1, 1, 2 do for sz = -1, 1, 2 do Kit.part(market, "StallPost", Vector3.new(0.45, 8, 0.45), mcf * CFrame.new(x + sx * 4, 4.2, -4 + sz * 3), P.Wood, Enum.Material.Wood) end end
        awning(market, mcf * CFrame.new(x, 8.4, -4), 9, 7.4, stall[2])
        local counter = Kit.part(market, "MarketCounter", Vector3.new(8, 2.6, 2.4), mcf * CFrame.new(x, 1.8, -6), P.Wood, Enum.Material.Wood)
        prompt(counter, "Browse " .. string.lower(stall[1]), "Market")
        Kit.sign(market, stall[1], mcf * CFrame.new(x, 6.6, -7.5), Vector3.new(8, 1.6, 0.25), stall[2], P.Cream)
        for item = 1, 6 do Kit.part(market, "MarketFind", Vector3.new(0.8, 0.8 + item % 3 * 0.35, 0.8), mcf * CFrame.new(x - 3.5 + (item - 1) * 1.4, 4, -6.4), colors[item % #colors + 1]) end
    end
    Kit.sign(market, "MARKET", mcf * CFrame.new(0, 11, -12), Vector3.new(20, 3, 0.4), P.Gold, P.Ink)
    -- Port of designer(): charcoal shell, gold framing, runway and mannequins.
    local designer, dcf = building("DesignerShowcase", Vector3.new(52, 0, -80), 1, 36, 16, 28, P.Ink, P.Cream, charcoal)
    Kit.part(designer, "FrontFascia", Vector3.new(36, 4.5, 1), dcf * CFrame.new(0, 13.75, -13.5), P.Ink)
    displayWindow(designer, dcf, -11, 6.5, 9, 8, P.Gold); displayWindow(designer, dcf, 11, 6.5, 9, 8, P.Gold)
    Kit.part(designer, "GoldDoor", Vector3.new(6, 9.5, 0.7), dcf * CFrame.new(0, 4.75, -14), P.Gold)
    Kit.sign(designer, "DESIGNER SHOWCASE", dcf * CFrame.new(0, 13.4, -14.2), Vector3.new(24, 3, 0.4), P.Cream, P.Ink)
    Kit.part(designer, "Runway", Vector3.new(6, 0.15, 20), dcf * CFrame.new(0, 0.58, -3), P.Rose, Enum.Material.Fabric)
    for x = -1, 1, 2 do
        Kit.cylinder(designer, "MannequinStand", 1.25, 0.3, dcf * CFrame.new(x * 11, 0.8, -10), steel, Enum.Material.Metal)
        Kit.part(designer, "MannequinDress", Vector3.new(3, 3.8, 1.8), dcf * CFrame.new(x * 11, 4.3, -10), if x < 0 then P.Coral else P.Gold, Enum.Material.Fabric)
        Kit.ball(designer, "MannequinHead", Vector3.new(1.4, 1.4, 1.4), dcf * CFrame.new(x * 11, 7.7, -10), P.Cream)
    end
    local showcaseDoor = designer:FindFirstChild("GoldDoor"); prompt(showcaseDoor, "Open designer showcase", "Showcase")
    -- Antique Corner complements the supplied five models in the map's sixth lot.
    local antique, acf = building("AntiqueCorner", Vector3.new(52, 0, -27), 1, 36, 14, 28, P.Wood, P.Oak, P.Ink)
    Kit.part(antique, "FrontFascia", Vector3.new(36, 5, 1), acf * CFrame.new(0, 11.5, -13.5), P.Wood)
    displayWindow(antique, acf, -10, 6, 9, 7, P.Gold); displayWindow(antique, acf, 10, 6, 9, 7, P.Gold)
    Kit.sign(antique, "ANTIQUE CORNER", acf * CFrame.new(0, 12.5, -14.2), Vector3.new(23, 3, 0.35), P.Gold, P.Ink)
    shelf(antique, acf, -9, 10.5, 13, 3, {P.Gold, P.Wood, P.Rose}); shelf(antique, acf, 9, 10.5, 13, 3, {P.Oak, P.Teal, P.Cream})
    local antiqueDesk = Kit.part(antique, "EstateDesk", Vector3.new(8, 3, 3), acf * CFrame.new(0, 2, -8), P.Oak, Enum.Material.Wood); prompt(antiqueDesk, "Open collector journal", "Collection")
    -- Port of restore(): brick workshop, open bay, steel header, tool wall and two benches.
    local workshop, wcf = building("RestoreWorkshop", Vector3.new(52, 0, 25), 1, 36, 15, 28, P.Brick, charcoal, charcoal)
    Kit.part(workshop, "BrickFascia", Vector3.new(36, 5, 1), wcf * CFrame.new(0, 12.5, -13.5), P.Brick, Enum.Material.Brick)
    Kit.part(workshop, "OpenBay", Vector3.new(17, 9.5, 0.25), wcf * CFrame.new(0, 4.75, -14), charcoal, Enum.Material.Metal, nil, false)
    Kit.cylinder(workshop, "SteelHeader", 1.1, 16, wcf * CFrame.new(0, 10.2, -14.5) * CFrame.Angles(0, 0, math.pi / 2), steel, Enum.Material.Metal)
    Kit.sign(workshop, "RESTORE SHOP", wcf * CFrame.new(0, 13, -14.2), Vector3.new(18, 3, 0.4), P.Cream, P.Brick)
    for x = -1, 1, 2 do
        local bench = Kit.part(workshop, "RestoreBench", Vector3.new(12, 0.45, 3.2), wcf * CFrame.new(x * 9, 3.6, -2), P.Oak, Enum.Material.Wood)
        prompt(bench, "Restore a treasure", "Workbench")
        for lx = -1, 1, 2 do for lz = -1, 1, 2 do Kit.part(workshop, "BenchLeg", Vector3.new(0.5, 3.1, 0.5), wcf * CFrame.new(x * 9 + lx * 5.5, 2, -2 + lz * 1.3), P.Wood, Enum.Material.Wood) end end
    end
    shelf(workshop, wcf, 10, 11.5, 12, 3, {P.Rose, steel, P.Gold, P.Teal})
    Kit.part(workshop, "ToolBoard", Vector3.new(15, 7, 0.3), wcf * CFrame.new(-9, 6, 12.7), P.Oak, Enum.Material.Wood)
    for tool = 1, 7 do Kit.part(workshop, "HangingTool", Vector3.new(0.25, 2.2, 0.25), wcf * CFrame.new(-15.5 + tool * 2.1, 6 + tool % 2, 12.4), steel, Enum.Material.Metal, nil, false) end
    -- Port of auction(): stone frontage, six columns, stepped roof, clock and seating.
    local auction, ucf = building("AuctionHouse", Vector3.new(-52, 0, 28), -1, 36, 18, 32, stone, P.Wood, charcoal)
    Kit.part(auction, "FrontFascia", Vector3.new(36, 7, 1), ucf * CFrame.new(0, 14.5, -15.5), stone, Enum.Material.Marble)
    for column = 1, 6 do
        local x = -12.5 + (column - 1) * 5
        Kit.cylinder(auction, "MarbleColumn", 1.1, 11, ucf * CFrame.new(x, 7.1, -23.5), P.Cream, Enum.Material.Marble)
        Kit.part(auction, "ColumnCap", Vector3.new(3.2, 0.8, 3.2), ucf * CFrame.new(x, 13.1, -23.5), stone, Enum.Material.Marble)
    end
    for tier, width in ipairs({33, 27, 21, 15, 9}) do Kit.part(auction, "SteppedRoof", Vector3.new(width, 1.2, 9.6), ucf * CFrame.new(0, 15.5 + tier * 1.2, -20.5), stone, Enum.Material.Marble) end
    Kit.sign(auction, "AUCTION HOUSE", ucf * CFrame.new(0, 14.8, -25.8), Vector3.new(26, 2.2, 0.4), P.Teal, P.Cream)
    Kit.cylinder(auction, "ClockFace", 1.7, 0.35, ucf * CFrame.new(0, 18.4, -25.9) * CFrame.Angles(math.pi / 2, 0, 0), P.Gold, Enum.Material.Metal)
    local podium = Kit.part(auction, "AuctionPodium", Vector3.new(3, 4.5, 2), ucf * CFrame.new(0, 3.4, 11), P.Wood, Enum.Material.Wood); prompt(podium, "Join the auction", "Auction")
    Kit.sign(auction, "NOW BIDDING", ucf * CFrame.new(0, 10.5, 14.7), Vector3.new(14, 4, 0.3), charcoal, P.Gold)
    for row = 1, 5 do for side = -1, 1, 2 do for seat = 1, 4 do
        local x = side * (4.5 + (seat - 1) * 2.8); local z = -9 + (row - 1) * 3.2
        Kit.part(auction, "BidderSeat", Vector3.new(2.4, 1.2, 1.8), ucf * CFrame.new(x, 1.1, z), P.Cream)
        Kit.part(auction, "SeatBack", Vector3.new(2.4, 2.2, 0.4), ucf * CFrame.new(x, 2.5, z - 0.8), P.Teal)
    end end end
    local flea = Kit.model(district, "FleaField")
    local fcf = CFrame.new(-78, 0, -215)
    Kit.part(flea, "Field", Vector3.new(58, 0.3, 42), fcf, Color3.fromRGB(148, 174, 113), Enum.Material.Grass)
    Kit.sign(flea, "FLEA FIELD\nDIG • DISCOVER • RESTORE", fcf * CFrame.new(0, 7, -19), Vector3.new(27, 4, 0.4), P.Coral, P.Paper)
    for i = 1, 6 do
        local x, z = -20 + (i - 1) % 3 * 20, -8 + math.floor((i - 1) / 3) * 17
        local spot = Kit.cylinder(flea, "FindSpot", 3, 0.18, fcf * CFrame.new(x, 0.25, z), if i % 2 == 0 then P.Gold else P.Rose, Enum.Material.Sand)
        prompt(spot, "Search the flea field", "Source")
        Kit.crate(flea, fcf * CFrame.new(x + 4, 0.2, z + 2), Vector3.new(2.5, 1.7, 2.2), i % 2 == 0)
    end
end
function World:wayfinding()
    local route = Kit.model(self.Root, "NewPlayerRoute")
    local stops = {
        {1, "SPAWN", Vector3.new(0, 0.5, -145)}, {2, "QUESTS", Vector3.new(-24, 0.5, -145)},
        {3, "DIG", Vector3.new(-46, 0.5, -165)}, {4, "RESTORE", Vector3.new(35, 0.5, 25)},
        {5, "SELL", Vector3.new(-35, 0.5, -80)},
    }
    for index, stop in ipairs(stops) do
        local pad = Kit.cylinder(route, "Stop" .. stop[1], 2.1, 0.16, CFrame.new(stop[3]), P.Teal, Enum.Material.Neon, false)
        Kit.sign(route, tostring(stop[1]), CFrame.new(stop[3] + Vector3.new(0, 0.25, 0)), Vector3.new(2.2, 2.2, 0.08), P.Teal, P.Paper)
        if index < #stops then
            local a, b = stop[3], stops[index + 1][3]; local delta = b - a; local length = delta.Magnitude
            for distance = 5, length - 3, 6 do
                local point = a + delta.Unit * distance
                Kit.part(route, "RouteDash", Vector3.new(0.45, 0.08, 3.2), CFrame.lookAt(point, point + delta.Unit), P.Gold, Enum.Material.Neon, nil, false)
            end
        end
    end
    local legendCF = CFrame.new(75, 5, -145) * CFrame.Angles(0, math.pi, 0)
    Kit.sign(route, "NEW PLAYER ROUTE\n1  SPAWN\n2  DAILY QUESTS\n3  DIG THE ALLEY\n4  RESTORE AT WORKSHOP\n5  SELL AT MARKET", legendCF, Vector3.new(24, 11, 0.5), P.Ink, P.Paper)
end
function World:previewDistrict()
    local district = Kit.model(self.Root, "AttachedPreviewShops")
    district:SetAttribute("Source", "Thrift_Street_World_3D.html")
    local glassColor = Color3.fromRGB(181, 226, 223)
    local steel = Color3.fromRGB(97, 114, 119)
    local brick2 = Color3.fromRGB(209, 142, 115)
    local beige = Color3.fromRGB(233, 212, 189)
    local purple = Color3.fromRGB(169, 147, 199)
    local function shell(name, center, width, depth, height, wall, trim, roof)
        local cf = CFrame.new(center) * CFrame.Angles(0, math.pi, 0)
        local model = Kit.model(district, name)
        local front = -depth / 2
        Kit.part(model, "Floor", Vector3.new(width, 0.7, depth), cf * CFrame.new(0, 0.35, 0), Color3.fromRGB(217, 213, 199), Enum.Material.Pavement)
        Kit.part(model, "BackWall", Vector3.new(width, height, 0.65), cf * CFrame.new(0, height / 2, depth / 2), wall, Enum.Material.Brick)
        for side = -1, 1, 2 do Kit.part(model, "SideWall", Vector3.new(0.7, height, depth), cf * CFrame.new(side * (width / 2 - 0.35), height / 2, 0), wall, Enum.Material.Brick) end
        Kit.part(model, "Roof", Vector3.new(width + 1, 0.8, depth + 1), cf * CFrame.new(0, height + 0.35, 0), roof, Enum.Material.Slate)
        Kit.part(model, "RoofCornice", Vector3.new(width + 1.5, 1.4, 1.8), cf * CFrame.new(0, height, front - 0.3), trim)
        return model, cf, front
    end
    local function facadeWindow(model, cf, front, x, width, height, frameColor)
        local pane = Kit.part(model, "DisplayGlass", Vector3.new(width, height, 0.16), cf * CFrame.new(x, 7, front - 0.45), glassColor, Enum.Material.Glass, nil, false)
        pane.Transparency = 0.38; pane.Reflectance = 0.1
        for side = -1, 1, 2 do Kit.part(model, "WindowPost", Vector3.new(0.35, height + 0.6, 0.5), cf * CFrame.new(x + side * width / 2, 7, front - 0.55), frameColor, Enum.Material.Metal) end
        Kit.part(model, "WindowTop", Vector3.new(width + 0.7, 0.35, 0.5), cf * CFrame.new(x, 7 + height / 2, front - 0.55), frameColor, Enum.Material.Metal)
        Kit.part(model, "WindowBase", Vector3.new(width + 1, 0.55, 1), cf * CFrame.new(x, 7 - height / 2, front - 0.65), P.Cream)
        Kit.part(model, "WindowMullion", Vector3.new(0.16, height, 0.2), cf * CFrame.new(x, 7, front - 0.7), frameColor, Enum.Material.Metal, nil, false)
    end
    local function stockShelf(model, cf, x, z, width, colors)
        for level = 0, 3 do Kit.part(model, "Shelf", Vector3.new(width, 0.25, 2), cf * CFrame.new(x, 0.8 + level * 2.4, z), P.Oak, Enum.Material.Wood) end
        for side = -1, 1, 2 do Kit.part(model, "ShelfSide", Vector3.new(0.3, 7.5, 2), cf * CFrame.new(x + side * width / 2, 4, z), P.Wood, Enum.Material.Wood) end
        for level = 1, 3 do for item = 1, math.floor(width / 1.7) do
            local height = 0.8 + (item + level) % 3 * 0.3
            Kit.part(model, "ShelfFind", Vector3.new(0.95, height, 0.8), cf * CFrame.new(x - width / 2 + item * 1.7 - 0.8, 1.1 + (level - 1) * 2.4 + height / 2, z), colors[(item + level) % #colors + 1])
        end end
    end
    local colors = {P.Coral, P.Gold, P.Teal, P.Lavender, P.Cream}
    -- Vintage Market: the neighborhood's sale and auction destination.
    local vintage, vcf, vf = shell("VintageMarket", Vector3.new(-72, 0, -13), 43, 32, 22, P.Brick, P.Wood, brick2)
    Kit.part(vintage, "FrontFascia", Vector3.new(43, 4, 0.8), vcf * CFrame.new(0, 19, vf), P.Brick, Enum.Material.Brick)
    facadeWindow(vintage, vcf, vf, -12, 12, 8.2, P.Wood); facadeWindow(vintage, vcf, vf, 12, 12, 8.2, P.Wood)
    Kit.part(vintage, "MarketDoor", Vector3.new(6, 10, 0.7), vcf * CFrame.new(0, 5, vf - 0.5), P.Wood, Enum.Material.Wood)
    awning(vintage, vcf * CFrame.new(-12, 12.4, vf - 2), 13, 3.4, P.Rose); awning(vintage, vcf * CFrame.new(12, 12.4, vf - 2), 13, 3.4, P.Rose)
    Kit.sign(vintage, "VINTAGE MARKET\nANTIQUES • DECOR • CURIOS", vcf * CFrame.new(0, 18.5, vf - 0.6), Vector3.new(35, 3.5, 0.3), P.Wood, P.Gold)
    stockShelf(vintage, vcf, -12, 7, 13, colors); stockShelf(vintage, vcf, 12, 7, 13, colors)
    local marketCounter = Kit.part(vintage, "MarketCounter", Vector3.new(10, 3, 3), vcf * CFrame.new(-7, 2, vf - 5), P.Teal)
    prompt(marketCounter, "Browse the vintage market", "Market")
    local auctionPodium = Kit.part(vintage, "AuctionPodium", Vector3.new(5, 4, 3), vcf * CFrame.new(9, 2.5, vf - 5), P.Wood, Enum.Material.Wood)
    prompt(auctionPodium, "Join the vintage auction", "Auction")
    for i = 1, 4 do Kit.crate(vintage, vcf * CFrame.new(-15 + (i - 1) * 10, 0.4, vf - 5), Vector3.new(3, 2, 2.5), i % 2 == 0) end
    -- Collectibles: toys, games, curios, and the collection journal.
    local collectible, ccf, cfz = shell("Collectibles", Vector3.new(-73, 0, -67), 39, 29, 20, brick2, P.Cream, P.Wood)
    Kit.part(collectible, "FrontFascia", Vector3.new(39, 4, 0.8), ccf * CFrame.new(0, 17, cfz), brick2)
    facadeWindow(collectible, ccf, cfz, -11, 11, 8, P.Cream); facadeWindow(collectible, ccf, cfz, 11, 11, 8, P.Cream)
    Kit.part(collectible, "CollectorDoor", Vector3.new(6, 9.5, 0.7), ccf * CFrame.new(0, 4.75, cfz - 0.5), P.Teal)
    awning(collectible, ccf * CFrame.new(0, 13, cfz - 2), 30, 3, purple)
    Kit.sign(collectible, "COLLECTIBLES\nTOYS • GAMES • MORE", ccf * CFrame.new(0, 16.6, cfz - 0.6), Vector3.new(31, 3.4, 0.3), P.Wood, P.Gold)
    stockShelf(collectible, ccf, -9, 5, 12, {P.Teal, P.Rose, P.Gold}); stockShelf(collectible, ccf, 9, 5, 12, {P.Lavender, P.Coral, P.Cream})
    local journalDesk = Kit.part(collectible, "CollectionDesk", Vector3.new(8, 3, 3), ccf * CFrame.new(0, 2, cfz - 5), P.Oak, Enum.Material.Wood)
    prompt(journalDesk, "Open collector journal", "Collection")
    -- Designer Showcase: tall windows, gold trim, display runway, and mannequins.
    local designer, dcf, df = shell("DesignerShowcase", Vector3.new(71, 0, -13), 42, 33, 24, beige, P.Gold, P.Cream)
    Kit.part(designer, "FrontFascia", Vector3.new(42, 5, 0.8), dcf * CFrame.new(0, 20.5, df), beige)
    facadeWindow(designer, dcf, df, -12, 12, 9, P.Gold); facadeWindow(designer, dcf, df, 12, 12, 9, P.Gold)
    local designerDoor = Kit.part(designer, "DesignerDoor", Vector3.new(6, 10, 0.7), dcf * CFrame.new(0, 5, df - 0.5), P.Gold, Enum.Material.Metal)
    prompt(designerDoor, "Enter designer showcase", "Showcase")
    Kit.sign(designer, "DESIGNER\nSHOWCASE & SECOND CHANCES", dcf * CFrame.new(0, 20, df - 0.6), Vector3.new(34, 3.7, 0.3), P.Ink, P.Gold)
    Kit.part(designer, "Runway", Vector3.new(9, 0.15, 20), dcf * CFrame.new(0, 0.55, -1), P.Coral, Enum.Material.Fabric)
    for side = -1, 1, 2 do
        Kit.cylinder(designer, "MannequinStand", 1.1, 0.25, dcf * CFrame.new(side * 11, 0.7, df - 4), steel, Enum.Material.Metal)
        Kit.part(designer, "MannequinSkirt", Vector3.new(3, 3.2, 1.8), dcf * CFrame.new(side * 11, 2.5, df - 4), if side < 0 then P.Rose else P.Gold, Enum.Material.Fabric)
        Kit.part(designer, "MannequinTop", Vector3.new(2.2, 2.6, 1.4), dcf * CFrame.new(side * 11, 5.2, df - 4), if side < 0 then P.Rose else P.Gold, Enum.Material.Fabric)
        Kit.ball(designer, "MannequinHead", Vector3.new(1.5, 1.5, 1.5), dcf * CFrame.new(side * 11, 7.2, df - 4), P.Cream)
    end
    for side = -1, 1, 2 do Kit.plant(designer, dcf * CFrame.new(side * 18, 0.4, df - 4), 1.2, nil, true) end
    -- Restore Workshop: visible tools, roll-up bay, stocked shelves, and playable benches.
    local restore, rcf, rf = shell("RestoreWorkshop", Vector3.new(69, 0, -66), 43, 32, 20, P.Oak, P.Ink, Color3.fromRGB(86, 115, 108))
    Kit.part(restore, "FrontFascia", Vector3.new(43, 4, 0.8), rcf * CFrame.new(0, 17, rf), P.Oak, Enum.Material.Wood)
    facadeWindow(restore, rcf, rf, -13, 11, 8, P.Ink)
    Kit.part(restore, "OpenWorkshopBay", Vector3.new(17, 10, 0.3), rcf * CFrame.new(10, 6.8, rf - 0.35), Color3.fromRGB(65, 73, 75), Enum.Material.Metal, nil, false)
    for line = 1, 7 do Kit.part(restore, "BaySlat", Vector3.new(17, 0.16, 0.55), rcf * CFrame.new(10, 3 + line * 1.3, rf - 0.65), steel, Enum.Material.Metal, nil, false) end
    Kit.sign(restore, "RESTORE\nFIX • UPCYCLE • CREATE", rcf * CFrame.new(0, 16.6, rf - 0.6), Vector3.new(34, 3.5, 0.3), P.Wood, P.Gold)
    stockShelf(restore, rcf, -12, 7, 12, {P.Rose, steel, P.Gold, P.Teal})
    for side = -1, 1, 2 do
        local bench = Kit.part(restore, "RestoreBench", Vector3.new(10, 0.45, 3.2), rcf * CFrame.new(side * 8, 3.5, rf - 6), P.Oak, Enum.Material.Wood)
        prompt(bench, "Restore a treasure", "Workbench")
        for leg = -1, 1, 2 do Kit.part(restore, "BenchLeg", Vector3.new(0.45, 3, 2.5), rcf * CFrame.new(side * 8 + leg * 4, 1.8, rf - 6), P.Ink, Enum.Material.Metal) end
    end
    Kit.part(restore, "ToolBoard", Vector3.new(15, 7, 0.3), rcf * CFrame.new(-10, 6, 15), P.Wood, Enum.Material.Wood)
    for tool = 1, 7 do Kit.part(restore, "HangingTool", Vector3.new(0.25, 2.2, 0.25), rcf * CFrame.new(-16.5 + tool * 2, 6 + tool % 2, 14.7), steel, Enum.Material.Metal, nil, false) end
    -- Patio details from the supplied world make the plaza feel inhabited.
    for _, position in ipairs({{-118,24},{-83,10},{-44,9},{42,8},{91,10},{116,28},{-39,-85},{33,-75}}) do Kit.plant(district, CFrame.new(position[1], 0, position[2]), 1.15, nil, true) end
    for _, data in ipairs({{-37,12,P.Rose},{40,9,P.Gold}}) do
        local x, z, color = data[1], data[2], data[3]
        Kit.cylinder(district, "CafePole", 0.12, 5, CFrame.new(x, 2.5, z), P.Oak, Enum.Material.Wood)
        Kit.cylinder(district, "CafeCanopy", 4, 0.3, CFrame.new(x, 5.4, z), color, Enum.Material.Fabric)
        Kit.cylinder(district, "CafeTable", 2, 0.2, CFrame.new(x, 2.1, z), P.Cream)
    end
end
function World:previewWayfinding()
    local route = Kit.model(self.Root, "PreviewNewPlayerRoute")
    local stops = {
        {1, "SPAWN", Vector3.new(-102, 0.5, 26)}, {2, "QUESTS", Vector3.new(-87, 0.5, 14)},
        {3, "DIG", Vector3.new(-108, 0.5, -67)}, {4, "RESTORE", Vector3.new(69, 0.5, -53)},
        {5, "SELL", Vector3.new(-72, 0.5, 4)},
    }
    for index, stop in ipairs(stops) do
        Kit.cylinder(route, "Stop" .. stop[1], 2.1, 0.16, CFrame.new(stop[3]), P.Teal, Enum.Material.Neon, false)
        Kit.sign(route, tostring(stop[1]), CFrame.new(stop[3] + Vector3.new(0, 0.25, 0)), Vector3.new(2.2, 2.2, 0.08), P.Teal, P.Paper)
        if index < #stops then
            local a, b = stop[3], stops[index + 1][3]; local delta = b - a
            for distance = 5, delta.Magnitude - 3, 7 do
                local point = a + delta.Unit * distance
                Kit.part(route, "RouteDash", Vector3.new(0.45, 0.08, 3.2), CFrame.lookAt(point, point + delta.Unit), P.Gold, Enum.Material.Neon, nil, false)
            end
        end
    end
    Kit.sign(route, "NEW PLAYER ROUTE\n1 SPAWN  •  2 QUESTS  •  3 DIG\n4 RESTORE  •  5 SELL", CFrame.new(-4, 5, 25), Vector3.new(32, 7, 0.5), P.Ink, P.Paper)
end
function World:buildPlot(index, cf)
    local model = Kit.model(self.Root, "Shop" .. index)
    model:SetAttribute("Role", "PlayerThriftShop")
    local styles = {{Color3.fromRGB(244,227,193),E.Teal},{Color3.fromRGB(214,238,226),E.Coral},{Color3.fromRGB(250,222,226),E.Gold},{Color3.fromRGB(220,230,248),E.Purple}}
    local style = styles[(index - 1) % 4 + 1]
    local wallColor, color = style[1], style[2]
    local front = Kit.model(model, "Storefront")
    local zone = Kit.part(front, "OwnedPlot", Vector3.new(32, 0.16, 28), cf * CFrame.new(0, 0.35, 0), color, Enum.Material.SmoothPlastic, nil, false)
    zone.Transparency = 0.76
    -- Exact 30 x 12 x 26 shell front with the three openings from the supplied model.
    for side = -1, 1, 2 do
        Kit.part(front, "LowerFront", Vector3.new(12.5, 3, 1), cf * CFrame.new(side * 8.75, 1.5, -12.5), wallColor)
        Kit.part(front, "OuterFront", Vector3.new(3, 6, 1), cf * CFrame.new(side * 13.5, 6, -12.5), wallColor)
        Kit.part(front, "InnerFront", Vector3.new(3.5, 6, 1), cf * CFrame.new(side * 4.25, 6, -12.5), wallColor)
        window(front, cf * CFrame.new(side * 9, 6, -13.1), 5.7, 5.7, Color3.fromRGB(207, 233, 230))
        Kit.part(front, "FlowerBox", Vector3.new(6.4, 1.2, 1.2), cf * CFrame.new(side * 9, 2.1, -13.9), E.Wood, Enum.Material.Wood)
        Kit.part(front, "FlowerGreenery", Vector3.new(6, 0.6, 0.9), cf * CFrame.new(side * 9, 2.9, -13.9), E.Green, Enum.Material.Grass, nil, false)
    end
    Kit.part(front, "TopFront", Vector3.new(30, 3, 1), cf * CFrame.new(0, 10.5, -12.5), wallColor)
    Kit.part(front, "DoorHeader", Vector3.new(5, 1, 1), cf * CFrame.new(0, 8.5, -12.5), wallColor)
    for stripe = 1, 10 do
        local stripeColor = if stripe % 2 == 1 then color else E.Cream
        local x = -15 + (stripe - 0.5) * 3
        Kit.part(front, "AwningStripe", Vector3.new(3, 0.4, 3.6), cf * CFrame.new(x, 10.2, -14.8), stripeColor, Enum.Material.Fabric)
        Kit.part(front, "AwningValance", Vector3.new(3, 1.2, 0.3), cf * CFrame.new(x, 9.6, -16.6), stripeColor, Enum.Material.Fabric, nil, false)
    end
    for _, x in ipairs({-7, 7}) do Kit.part(front, "SignPost", Vector3.new(0.5, 3.2, 0.5), cf * CFrame.new(x, 14.6, -11.5), E.Charcoal, Enum.Material.Metal) end
    local label = Kit.sign(front, "SHOP " .. index, cf * CFrame.new(0, 14.8, -11.5), Vector3.new(18, 3, 0.5), color, E.Cream)
    Kit.part(front, "FrontStep", Vector3.new(5, 0.12, 6), cf * CFrame.new(0, 0.07, -16.3), E.Stone, Enum.Material.Pavement)
    catalogAsset(front, "Mailbox", cf * CFrame.new(11.2, 0, -17.3), 0.72)
    local forSale = Kit.model(front, "ForSale")
    for _, x in ipairs({-9.6, -4.4}) do Kit.part(forSale, "SalePost", Vector3.new(0.4, 3.4, 0.4), cf * CFrame.new(x, 1.7, -17.5), E.Wood, Enum.Material.Wood) end
    Kit.sign(forSale, "FOR SALE", cf * CFrame.new(-7, 3.6, -17.6), Vector3.new(6.6, 2.4, 0.3), E.Cream, E.Dark)
    for side = -1, 1, 2 do
        local rackX = side * 9
        Kit.part(front, "RackBar", Vector3.new(7, 0.3, 0.3), cf * CFrame.new(rackX, 4.5, -10.2), E.Steel, Enum.Material.Metal)
        for item = 0, 5 do Kit.part(front, "RackClothing", Vector3.new(0.8, 2.4 + item % 2 * 0.6, 0.4), cf * CFrame.new(rackX - 3 + item * 1.1, 3, -10.2), ({E.Coral,E.Gold,E.Teal,E.Purple,E.Cream})[item % 5 + 1], Enum.Material.Fabric, nil, false) end
    end
    Kit.part(front, "ShowroomRug", Vector3.new(12, 0.1, 10), cf * CFrame.new(0, 0.55, 2), color, Enum.Material.Fabric, nil, false)
    local plot = {Model = model, Storefront = front, ForSale = forSale, CF = cf, Label = label, Slots = {}, Items = {}, Index = index,
        Color = color, WallColor = wallColor, Tier = 0, Depth = 28, HalfWidth = 15, RenderKeys = {}, DecorKey = "", Owner = nil}
    self.Plots[index] = plot
    self:buildInterior(plot, 1)
end
function World:buildInterior(plot, tier)
    local previous = plot.Model:FindFirstChild("Interior")
    if previous then previous:Destroy() end
    for _, item in pairs(plot.Items) do item:Destroy() end
    plot.Items = {}; plot.RenderKeys = {}; plot.Slots = {}; plot.DecorKey = ""
    local model = Kit.model(plot.Model, "Interior")
    local cf = plot.CF
    local backZ = ({14, 20, 27, 34})[tier]
    local depth = backZ + 14
    plot.Tier = tier; plot.Depth = depth; plot.BackZ = backZ
    Kit.part(model, "OakFloor", Vector3.new(30, 0.5, depth), cf * CFrame.new(0, 0.25, (backZ - 14) / 2), E.LightWood, Enum.Material.WoodPlanks)
    plot.Wall = Kit.part(model, "FeatureWall", Vector3.new(30, 12, 1), cf * CFrame.new(0, 6, backZ - 0.5), plot.WallColor or plot.Color)
    for side = -1, 1, 2 do
        Kit.part(model, "SideWall", Vector3.new(1, 12, depth - 2), cf * CFrame.new(side * 14.5, 6, (backZ - 14) / 2), plot.WallColor or E.Cream)
        Kit.part(model, "Wainscot", Vector3.new(0.15, 3, depth - 2), cf * CFrame.new(side * 13.9, 1.8, (backZ - 14) / 2), E.LightWood, Enum.Material.WoodPlanks)
        Kit.part(model, "PictureRail", Vector3.new(0.2, 0.25, depth - 2), cf * CFrame.new(side * 13.8, 8.8, (backZ - 14) / 2), E.Gold, nil, nil, false)
        Kit.part(model, "Skirting", Vector3.new(0.25, 0.4, depth - 2), cf * CFrame.new(side * 13.8, 0.7, (backZ - 14) / 2), E.Cream)
    end
    Kit.part(model, "RearSkirting", Vector3.new(29, 0.4, 0.2), cf * CFrame.new(0, 0.7, backZ - 1), E.Cream)
    Kit.part(model, "RearCornice", Vector3.new(30, 0.6, 1), cf * CFrame.new(0, 12.2, backZ - 0.5), E.Cream)
    Kit.part(model, "Roof", Vector3.new(32, 1, depth + 2), cf * CFrame.new(0, 12.5, (backZ - 14) / 2), E.Charcoal)
    local workZ = backZ - 3.5
    local bench = Kit.part(model, "RestorationBench", Vector3.new(9, 0.5, 3.4), cf * CFrame.new(-7.5, 3.1, workZ), P.Wood, Enum.Material.Wood)
    for x = -1, 1, 2 do Kit.part(model, "BenchLeg", Vector3.new(0.5, 2.5, 2.7), cf * CFrame.new(-7.5 + x * 3.8, 1.7, workZ), P.Ink, Enum.Material.Metal) end
    Kit.part(model, "WorkbenchMat", Vector3.new(4.6, 0.05, 2.6), cf * CFrame.new(-7.5, 3.38, workZ), P.Teal, Enum.Material.Fabric, nil, false)
    prompt(bench, "Restore your find", "Workbench", plot.Owner)
    Kit.sign(model, "THE RESTORATION STATION", cf * CFrame.new(-7, 8, backZ - 0.55), Vector3.new(11, 1.5, 0.15), P.Ink)
    Kit.part(model, "ToolBoard", Vector3.new(8.5, 3.2, 0.2), cf * CFrame.new(-7.5, 5.6, backZ - 0.6), P.Oak, Enum.Material.Wood)
    for tool = 1, 5 do
        local x = -11 + tool * 1.25
        Kit.part(model, "ToolHandle", Vector3.new(0.25, 1, 0.3), cf * CFrame.new(x, 5.1, backZ - 0.8), if tool % 2 == 0 then P.Rose else P.Teal, nil, nil, false)
        Kit.part(model, "ToolHead", Vector3.new(if tool % 2 == 0 then 0.6 else 0.2, 0.6, 0.18), cf * CFrame.new(x, 5.8, backZ - 0.8), P.Cream, Enum.Material.Metal, nil, false)
    end
    Kit.cylinder(model, "PaintPot", 0.45, 0.8, cf * CFrame.new(-11, 3.8, workZ), P.Rose)
    Kit.cylinder(model, "BrushCup", 0.35, 0.8, cf * CFrame.new(-3.7, 3.8, workZ), P.Cream)
    for i = 1, 3 do Kit.part(model, "Brush", Vector3.new(0.09, 1, 0.09), cf * CFrame.new(-3.9 + i * 0.12, 4.6, workZ), P.Wood, nil, nil, false) end
    local counter = Kit.part(model, "SalesCounter", Vector3.new(8, 3, 2.4), cf * CFrame.new(9, 2, -3), plot.Color)
    Kit.part(model, "CounterTop", Vector3.new(8.4, 0.3, 2.8), cf * CFrame.new(9, 3.65, -3), E.LightWood, Enum.Material.Wood)
    Kit.part(model, "TillBase", Vector3.new(1.8, 0.55, 1.4), cf * CFrame.new(10.3, 4, -3), E.Cream)
    Kit.part(model, "TillDisplay", Vector3.new(1.3, 0.75, 0.3), cf * CFrame.new(10.3, 4.6, -2.5), E.Dark)
    Kit.sign(model, "THANK YOU", cf * CFrame.new(7.8, 4.1, -3.4), Vector3.new(2.3, 0.8, 0.1), E.Cream, E.Dark)
    prompt(counter, "Manage displays & decor", "Shop", plot.Owner)
    for slot = 1, 16 do
        local position, surface, shelf
        if slot <= 4 then
            local side = if slot % 2 == 1 then -1 else 1
            local row = math.ceil(slot / 2)
            position = Vector3.new(side * 5, 0, -5 + row * 5.5); surface = 2.9; shelf = false
        elseif slot <= 12 then
            local offset = slot - 5
            local side = if offset % 2 == 0 then -1 else 1
            local row = math.floor(offset / 2) % 2
            local upper = offset >= 4
            position = Vector3.new(side * 10.7, 0, -0.5 + row * 6.5)
            surface = if upper then 7.1 else 2.9; shelf = true
        else
            local side = if slot % 2 == 1 then -1 else 1
            local row = math.ceil((slot - 12) / 2)
            position = Vector3.new(side * 5, 0, 13 + row * 6); surface = 2.9; shelf = false
        end
        local furniture = Kit.model(model, "DisplayFurniture" .. slot)
        local top = Kit.part(furniture, "Display" .. slot, Vector3.new(4.4, 0.3, 3.6), cf * CFrame.new(position + Vector3.new(0, surface - 0.15, 0)), P.Cream)
        if shelf then
            for side = -1, 1, 2 do Kit.part(furniture, "ShelfBracket", Vector3.new(0.15, 0.8, 1.8), cf * CFrame.new(position + Vector3.new(side * 1.5, surface - 0.6, 0.7)), P.Gold, Enum.Material.Metal, nil, false) end
        else
            for x = -1, 1, 2 do for z = -1, 1, 2 do
                Kit.part(furniture, "TurnedLeg", Vector3.new(0.28, surface - 0.8, 0.28), cf * CFrame.new(position + Vector3.new(x * 1.8, (surface - 0.3) / 2, z * 1.3)), P.Wood, Enum.Material.Wood)
            end end
            Kit.part(furniture, "LowerShelf", Vector3.new(4, 0.18, 3), cf * CFrame.new(position + Vector3.new(0, 0.9, 0)), P.Oak, Enum.Material.Wood)
        end
        local plate = Kit.sign(furniture, string.format("%02d", slot), cf * CFrame.new(position + Vector3.new(0, surface - 0.3, -1.86)), Vector3.new(0.9, 0.45, 0.07), P.Gold, P.Ink)
        plate.TextScaled = true
        local interaction = prompt(top, "Display slot " .. slot, "Display", plot.Owner, slot)
        plot.Slots[slot] = {Base = top, Model = furniture, Prompt = interaction, CF = cf * CFrame.new(position + Vector3.new(0, surface + 0.02, 0))}
    end
    if tier >= 2 then
        Kit.sign(model, "EVERY OBJECT HAS A STORY", cf * CFrame.new(6.5, 8, backZ - 0.55), Vector3.new(10, 2.7, 0.2), P.Cream, P.Ink)
        window(model, cf * CFrame.new(7.2, 5.3, backZ - 0.55), 7, 4)
    end
    if tier >= 3 then
        Kit.part(model, "ShowroomArch", Vector3.new(27, 1, 1), cf * CFrame.new(0, 10, 12), E.Gold)
        for side = -1, 1, 2 do Kit.part(model, "ArchPillar", Vector3.new(1, 10, 1), cf * CFrame.new(side * 12.8, 5, 12), E.Cream) end
        Kit.sign(model, "THE CURATED COLLECTION", cf * CFrame.new(0, 9.8, 11.4), Vector3.new(18, 1.3, 0.15), E.Gold, E.Dark)
    end
    if tier >= 4 then
        Kit.part(model, "ShowroomCarpet", Vector3.new(11, 0.03, 17), cf * CFrame.new(0, 0.52, 21), P.Rose, Enum.Material.Fabric, nil, false)
        for side = -1, 1, 2 do Kit.plant(model, cf * CFrame.new(side * 11.5, 0.5, 25), 1.6) end
    end
    self:setSlotCapacity(plot, ({4, 8, 12, 16})[tier])
end
function World:setSlotCapacity(plot, capacity)
    for slot, data in ipairs(plot.Slots) do
        local enabled = slot <= capacity
        data.Prompt.Enabled = enabled and plot.Owner ~= nil
        for _, child in ipairs(data.Model:GetDescendants()) do
            if child:IsA("BasePart") then child.Transparency = if enabled then 0 else 1; child.CanCollide = enabled and child == data.Base
            elseif child:IsA("SurfaceGui") then child.Enabled = enabled end
        end
    end
end
function World:assign(player)
    for index, plot in ipairs(self.Plots) do
        if not plot.Owner then
            plot.Owner = player.UserId; self.Owners[player.UserId] = plot
            plot.ForSale.Parent = nil
            for _, child in ipairs(plot.Model:GetDescendants()) do if child:IsA("ProximityPrompt") then child:SetAttribute("Owner", player.UserId) end end
            return index
        end
    end
    return nil
end
function World:release(userId)
    local plot = self.Owners[userId]; if not plot then return end
    for _, item in pairs(plot.Items) do item:Destroy() end
    plot.Items = {}; plot.RenderKeys = {}; plot.Owner = nil; plot.Label.Text = "SHOP " .. plot.Index
    plot.ForSale.Parent = plot.Storefront
    self:buildInterior(plot, 1)
    local decor = plot.Model:FindFirstChild("Decorations"); if decor then decor:Destroy() end
    for _, child in ipairs(plot.Model:GetDescendants()) do if child:IsA("ProximityPrompt") then child:SetAttribute("Owner", 0) end end
    self.Owners[userId] = nil
    for _, npc in pairs(self.Customers) do if npc.Owner == userId then npc.Model:Destroy() end end
end
function World:near(player, action)
    local character = player.Character; local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local target = self.Destinations[action]
    if target and (root.Position - target).Magnitude < 25 then return true end
    if action == "Source" and (root.Position - self.Destinations.Flea).Magnitude < 38 then return true end
    local plot = self.Owners[player.UserId]; if not plot then return false end
    local position = plot.CF:PointToObjectSpace(root.Position)
    return math.abs(position.X) < (plot.HalfWidth or 15.5) and position.Z > -19 and position.Z < plot.BackZ + 1 and position.Y > -3 and position.Y < 14
end
function World:teleportCFrame(player, destination)
    local target = self.Destinations[destination]
    if target then
        local offset = if destination == "Estate" or destination == "Delivery" then Vector3.new(-7, 3.5, 0)
            elseif destination == "Auction" then Vector3.new(0, 3.5, -9)
            else Vector3.new(0, 3.5, 6)
        return CFrame.new(target + offset, target)
    end
    if destination ~= "Shop" then return nil end
    local plot = self.Owners[player.UserId]
    if not plot then return nil end
    local localPosition = Vector3.new(0, 4, -8)
    local position = plot.CF:PointToWorldSpace(localPosition)
    local lookAt = plot.CF:PointToWorldSpace(Vector3.new(0, 3, 0))
    return CFrame.lookAt(position, lookAt)
end
function World:render(player, profile, catalog, config)
    local plot = self.Owners[player.UserId]; if not plot then return end
    if plot.Tier ~= profile.Tier then self:buildInterior(plot, profile.Tier) end
    local tier = config.Tiers[profile.Tier]
    plot.Label.Text = string.upper(player.DisplayName) .. "'S SHOP"
    for _, theme in ipairs(config.Themes) do if theme.Id == profile.Theme then plot.Wall.Color = Color3.new(unpack(theme.Color)) end end
    self:decorate(plot, profile)
    self:setSlotCapacity(plot, tier.Slots)
    local present = {}
    for _, item in ipairs(profile.Inventory) do
        if item.Slot and plot.Slots[item.Slot] then
            local key = table.concat({item.DefId, item.Slot, item.Rarity, item.Condition, item.Style or ""}, ":")
            present[item.Uid] = true
            if plot.RenderKeys[item.Uid] ~= key then
                if plot.Items[item.Uid] then plot.Items[item.Uid]:Destroy() end
                local model = self:makeItem(plot.Model, catalog.ById[item.DefId], item, plot.Slots[item.Slot].CF, config)
                plot.Items[item.Uid] = model; plot.RenderKeys[item.Uid] = key
            end
        end
    end
    for uid, model in pairs(plot.Items) do
        if not present[uid] then model:Destroy(); plot.Items[uid] = nil; plot.RenderKeys[uid] = nil end
    end
end
function World:decorate(plot, profile)
    local decor = profile.PlacedDecor or {}
    local layout = profile.DecorLayout or {}
    local keys = {}; for key, enabled in pairs(decor) do if enabled then table.insert(keys, key) end end; table.sort(keys)
    local positions = {}
    for _, key in ipairs(keys) do
        local value = layout[key]
        if value then table.insert(positions, key .. ":" .. tostring(value.X) .. ":" .. tostring(value.Z) .. ":" .. tostring(value.Rotation)) end
    end
    local signature = table.concat(keys, ":") .. ":" .. table.concat(positions, "|") .. ":" .. tostring(profile.Tier)
    if signature == plot.DecorKey then return end
    plot.DecorKey = signature
    local old = plot.Model:FindFirstChild("Decorations"); if old then old:Destroy() end
    local folder = Kit.model(plot.Model, "Decorations"); local cf = plot.CF
    if decor.Rug then
        local at = layout.Rug or DecorPlacement.Defaults.Rug
        local rugCF = cf * CFrame.new(at.X, 0.53, at.Z) * CFrame.Angles(0, math.rad(at.Rotation), 0)
        Kit.part(folder, "WovenRug", Vector3.new(14, 0.035, 11), rugCF, P.Teal, Enum.Material.Fabric, nil, false)
        for side = -1, 1, 2 do
            Kit.part(folder, "WovenBorder", Vector3.new(13.5, 0.04, 0.15), rugCF * CFrame.new(0, 0.02, side * 5.1), P.Cream, Enum.Material.Fabric, nil, false)
            for i = 1, 14 do Kit.part(folder, "RugFringe", Vector3.new(0.45, 0.025, 0.15), rugCF * CFrame.new(-6.7 + i * 0.9, 0.01, side * 5.6), P.Cream, Enum.Material.Fabric, nil, false) end
        end
    end
    if decor.Plant then
        local at = layout.Plant or DecorPlacement.Defaults.Plant
        Kit.plant(folder, cf * CFrame.new(at.X, 0.5, at.Z) * CFrame.Angles(0, math.rad(at.Rotation), 0), 1.25, nil, true)
    end
    if decor.Poster then
        Kit.part(folder, "PosterFrame", Vector3.new(5.3, 6.3, 0.2), cf * CFrame.new(5.2, 6.8, plot.BackZ - 0.55), P.Wood, Enum.Material.Wood, nil, false)
        Kit.sign(folder, "SECOND\nCHANCES\nGOOD THINGS LIVE HERE", cf * CFrame.new(5.2, 6.8, plot.BackZ - 0.7), Vector3.new(4.8, 5.8, 0.1), P.Paper, P.Teal)
    end
    if decor.Neon then
        local label, board = Kit.sign(folder, "good finds ✦", cf * CFrame.new(0, 10.5, plot.BackZ - 0.7), Vector3.new(12, 1.8, 0.2), P.Ink, P.Gold)
        label.Font = Enum.Font.GothamBold
        local glow = Instance.new("PointLight"); glow.Color = P.Gold; glow.Brightness = 0.3; glow.Range = 7; glow.Parent = board
    end
    if decor.Curtains then for side = -1, 1, 2 do
        Kit.part(folder, "CurtainRod", Vector3.new(5.5, 0.12, 0.12), cf * CFrame.new(side * 11, 9, -13.4), P.Gold, Enum.Material.Metal, nil, false)
        for fold = 1, 4 do Kit.part(folder, "LinenPleat", Vector3.new(0.45, 5.5, 0.35), cf * CFrame.new(side * (12.1 - fold * 0.35), 6.2, -13.3), P.Rose, Enum.Material.Fabric, nil, false) end
    end end
    if decor.Trophy then
        local at = layout.Trophy or DecorPlacement.Defaults.Trophy
        local trophyCF = cf * CFrame.new(at.X, 0.5, at.Z) * CFrame.Angles(0, math.rad(at.Rotation), 0)
        Kit.part(folder, "TrophyPlinth", Vector3.new(2, 2.5, 2), trophyCF * CFrame.new(0, 1.25, 0), P.Cream, Enum.Material.Marble)
        Kit.cylinder(folder, "TrophyFoot", 0.7, 0.2, trophyCF * CFrame.new(0, 2.6, 0), P.Gold, Enum.Material.Metal, false)
        Kit.cylinder(folder, "TrophyStem", 0.18, 1, trophyCF * CFrame.new(0, 3.2, 0), P.Gold, Enum.Material.Metal, false)
        Kit.ball(folder, "GoldenTreasure", Vector3.new(1.3, 1.6, 1.3), trophyCF * CFrame.new(0, 4.1, 0), P.Gold, Enum.Material.Metal, false)
    end
end
function World:makeItem(parent, definition, item, cf, config)
    local model = ItemModels.create(parent, definition, item, cf, config)
    local anchor = model:FindFirstChildWhichIsA("BasePart", true)
    if anchor then
        local light = Instance.new("PointLight"); light.Name = "DisplayLight"; light.Color = Color3.fromRGB(255, 224, 177)
        light.Brightness = 0.22; light.Range = 6; light.Shadows = false; light.Parent = anchor
    end
    return model
end
function World:clearHeld(player)
    local character = player and player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, child in ipairs(humanoid:GetChildren()) do
            if child:GetAttribute("ThriftCarryIK") then child:Destroy() end
        end
    end
    local torso = character:FindFirstChild("Torso")
    if torso then
        for _, name in ipairs({"Left Shoulder", "Right Shoulder"}) do
            local shoulder = torso:FindFirstChild(name)
            local original = shoulder and shoulder:GetAttribute("ThriftOriginalC0")
            if shoulder and typeof(original) == "CFrame" then
                shoulder.C0 = original; shoulder:SetAttribute("ThriftOriginalC0", nil)
            end
        end
    end
    for _, child in ipairs(character:GetChildren()) do
        if child:GetAttribute("ThriftHeldItem") then child:Destroy() end
    end
end
function World:holdItem(player, definition, item, config)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or humanoid.Health <= 0 or not root then return false end
    self:clearHeld(player)

    local model = ItemModels.create(character, definition, item, CFrame.new(), config)
    model.Name = "Held " .. definition.Name; model:SetAttribute("ThriftHeldItem", true); model:SetAttribute("Uid", item.Uid)
    local _, initialSize = model:GetBoundingBox()
    local largest = math.max(initialSize.X, initialSize.Y, initialSize.Z, 0.01)
    model:ScaleTo(math.min(1.1, 2.35 / largest))
    local boxCF, carrySize = model:GetBoundingBox()
    -- ItemModels face -Z, the same direction as the avatar. Keeping that
    -- orientation lets nearby players see the front of the treasure.
    local target = root.CFrame * CFrame.new(0, 0.22, -1.45)
    model:PivotTo(target * boxCF:Inverse() * model:GetPivot())

    local holder = Instance.new("Part"); holder.Name = "CarryGrip"; holder.Size = Vector3.new(0.2, 0.2, 0.2)
    holder.CFrame = target; holder.Transparency = 1; holder.Anchored = true; holder.Massless = true
    holder.CanCollide = false; holder.CanTouch = false; holder.CanQuery = false; holder.Parent = model
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= holder then
            part.Anchored = false; part.Massless = true; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
            local weld = Instance.new("WeldConstraint"); weld.Part0 = holder; weld.Part1 = part; weld.Parent = holder
        end
    end
    local rootWeld = Instance.new("WeldConstraint"); rootWeld.Name = "CarryWeld"
    rootWeld.Part0 = root; rootWeld.Part1 = holder; rootWeld.Parent = holder; holder.Anchored = false

    local gripX = math.clamp(carrySize.X * 0.42, 0.32, 0.92)
    local gripY = -math.clamp(carrySize.Y * 0.12, 0.08, 0.24)
    local gripZ = -math.clamp(carrySize.Z * 0.08, 0.04, 0.18)
    local function gripTarget(name, x)
        local grip = Instance.new("Part"); grip.Name = name; grip.Size = Vector3.new(0.12, 0.12, 0.12)
        grip.CFrame = target * CFrame.new(x, gripY, gripZ); grip.Transparency = 1; grip.Massless = true
        grip.CanCollide = false; grip.CanTouch = false; grip.CanQuery = false; grip.Parent = model
        local weld = Instance.new("WeldConstraint"); weld.Part0 = holder; weld.Part1 = grip; weld.Parent = grip
        local attachment = Instance.new("Attachment"); attachment.Name = name .. "Attachment"; attachment.Parent = grip
        return attachment
    end
    local leftTarget = gripTarget("LeftCarryTarget", -gripX)
    local rightTarget = gripTarget("RightCarryTarget", gripX)

    local leftUpper, rightUpper = character:FindFirstChild("LeftUpperArm"), character:FindFirstChild("RightUpperArm")
    local leftHand, rightHand = character:FindFirstChild("LeftHand"), character:FindFirstChild("RightHand")
    if leftUpper and rightUpper and leftHand and rightHand then
        local function addIK(name, chainRoot, endEffector, targetAttachment)
            local control = Instance.new("IKControl"); control.Name = name; control.Type = Enum.IKControlType.Position
            control.ChainRoot = chainRoot; control.EndEffector = endEffector; control.Target = targetAttachment
            control.Weight = 1; control.SmoothTime = 0.06; control.Enabled = true
            control:SetAttribute("ThriftCarryIK", true); control.Parent = humanoid
        end
        addIK("LeftThriftCarry", leftUpper, leftHand, leftTarget)
        addIK("RightThriftCarry", rightUpper, rightHand, rightTarget)
    else
        -- R6 has no elbow chain for IK, so rotate both shoulder bases into a
        -- stable two-arm carry pose. C0 is restored when the item is put away.
        local torso = character:FindFirstChild("Torso")
        if torso then
            for _, data in ipairs({{"Left Shoulder", 1}, {"Right Shoulder", -1}}) do
                local shoulder = torso:FindFirstChild(data[1])
                if shoulder and shoulder:IsA("Motor6D") then
                    shoulder:SetAttribute("ThriftOriginalC0", shoulder.C0)
                    shoulder.C0 = shoulder.C0 * CFrame.Angles(math.rad(58), 0, math.rad(data[2] * 18))
                end
            end
        end
    end
    return true
end
function World:customer(userId, name)
    local plot = self.Owners[userId]; if not plot then return end
    self.CustomerSerial += 1
    local id = self.CustomerSerial
    local model = Kit.model(self.Root, "Customer_" .. id)
    local paletteIndex = (id - 1) % #shopColors + 1
    local shirt = shopColors[paletteIndex]
    local skin = ({Color3.fromRGB(237, 194, 153), Color3.fromRGB(180, 126, 88), Color3.fromRGB(121, 80, 58), Color3.fromRGB(225, 171, 128)})[(id - 1) % 4 + 1]
    local npc = {Model = model, Owner = userId, CF = plot.CF, Age = 0, Parts = {}, Id = id}
    local function limb(name_, size, offset, color, shape)
        local part = Kit.part(model, name_, size, plot.CF * CFrame.new(offset), color, nil, shape, false)
        npc.Parts[name_] = {Part = part, Offset = CFrame.new(offset)}; return part
    end
    limb("Torso", Vector3.new(1.7, 1.8, 0.9), Vector3.new(0, 3.25, 0), shirt)
    limb("Apron", Vector3.new(1.4, 1.4, 0.1), Vector3.new(0, 3, -0.51), if id % 2 == 0 then P.Cream else shirt:Lerp(P.Cream, 0.3))
    local head = limb("Head", Vector3.new(1.35, 1.4, 1.2), Vector3.new(0, 4.8, 0), skin, Enum.PartType.Ball)
    limb("Hair", Vector3.new(1.4, 0.6, 1.25), Vector3.new(0, 5.25, 0.05), if id % 3 == 0 then P.Cream else P.Wood, Enum.PartType.Ball)
    limb("LeftArm", Vector3.new(0.55, 1.85, 0.65), Vector3.new(-1.15, 3.25, 0), shirt)
    limb("RightArm", Vector3.new(0.55, 1.85, 0.65), Vector3.new(1.15, 3.25, 0), shirt)
    limb("LeftHand", Vector3.new(0.52, 0.5, 0.58), Vector3.new(-1.15, 2.25, 0), skin, Enum.PartType.Ball)
    limb("RightHand", Vector3.new(0.52, 0.5, 0.58), Vector3.new(1.15, 2.25, 0), skin, Enum.PartType.Ball)
    limb("LeftLeg", Vector3.new(0.7, 1.8, 0.7), Vector3.new(-0.47, 1.45, 0), P.Ink)
    limb("RightLeg", Vector3.new(0.7, 1.8, 0.7), Vector3.new(0.47, 1.45, 0), P.Ink)
    limb("LeftShoe", Vector3.new(0.78, 0.35, 1.1), Vector3.new(-0.47, 0.45, -0.13), P.Wood)
    limb("RightShoe", Vector3.new(0.78, 0.35, 1.1), Vector3.new(0.47, 0.45, -0.13), P.Wood)
    if id % 2 == 0 then
        limb("HatBrim", Vector3.new(1.9, 0.15, 1.6), Vector3.new(0, 5.4, 0), P.Gold)
        limb("HatCrown", Vector3.new(1.2, 0.6, 1), Vector3.new(0, 5.7, 0), P.Gold)
    end
    local face = Instance.new("SurfaceGui"); face.Face = Enum.NormalId.Front; face.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; face.PixelsPerStud = 100; face.Parent = head
    local smile = Instance.new("TextLabel"); smile.Size = UDim2.fromScale(1, 1); smile.BackgroundTransparency = 1; smile.Text = "• ᴗ •"
    smile.TextScaled = true; smile.Font = Enum.Font.GothamBold; smile.TextColor3 = P.Ink; smile.Parent = face
    local bill = Instance.new("BillboardGui"); bill.Size = UDim2.fromOffset(190, 42); bill.StudsOffset = Vector3.new(0, 1.4, 0); bill.MaxDistance = 45; bill.Parent = head
    local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 0.12; label.BackgroundColor3 = P.Paper
    label.Text = name; label.TextColor3 = P.Ink; label.TextSize = 14; label.TextWrapped = true; label.Font = Enum.Font.GothamBold; label.Parent = bill
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = label
    self.Customers[id] = npc
end
function World:animateCustomers(delta)
    for id, npc in pairs(self.Customers) do
        if not npc.Model.Parent then self.Customers[id] = nil
        else
            npc.Age += delta
            local age = npc.Age
            if age >= 21 then npc.Model:Destroy(); self.Customers[id] = nil
            else
                local moving = age < 4 or age > 17
                local z, x = -6, 0
                if age < 4 then z = -23 + age / 4 * 17
                elseif age > 17 then z = -6 - (age - 17) / 4 * 17
                else x = math.sin((age - 4) / 13 * math.pi) * 1.5 end
                local face = if age > 17 then math.pi else 0
                local base = npc.CF * CFrame.new(x, if moving then math.abs(math.sin(age * 8)) * 0.08 else 0, z) * CFrame.Angles(0, face, 0)
                for name, entry in pairs(npc.Parts) do
                    local swing = 0
                    if moving then
                        if name == "LeftLeg" or name == "LeftShoe" or name == "RightArm" or name == "RightHand" then swing = math.sin(age * 8) * 0.3
                        elseif name == "RightLeg" or name == "RightShoe" or name == "LeftArm" or name == "LeftHand" then swing = -math.sin(age * 8) * 0.3 end
                    end
                    entry.Part.CFrame = base * entry.Offset * CFrame.Angles(swing, 0, 0)
                end
            end
        end
    end
end
return World
