local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.WorldKit)
local ItemModels = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemModels"))
local DecorPlacement = require(ReplicatedStorage.Shared.DecorPlacement)
local P = Kit.Palette
local World = {}
World.__index = World
local shopColors = {P.Teal, P.Rose, P.Gold, P.Lavender, P.Coral, Color3.fromRGB(137, 166, 190)}
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
function World.new()
    local self = setmetatable({Plots = {}, Owners = {}, Customers = {}, CustomerSerial = 0}, World)
    local existing = workspace:FindFirstChild("ThriftStreet")
    if existing then existing:Destroy() end
    self.Root = Kit.model(workspace, "ThriftStreet")
    self.Root:SetAttribute("AssetOrigin", "Original Thrift Flip modular environment")
    self:lighting()
    self:landscape()
    self:square()
    self:sourcing()
    self:auctionHouse()
    self:market()
    for i = 1, 16 do
        local row = math.ceil(i / 2)
        local side = if i % 2 == 1 then -1 else 1
        local center = Vector3.new(side * 52, 0, -83 + (row - 1) * 35)
        local cf = CFrame.new(center) * CFrame.Angles(0, if side == -1 then -math.pi / 2 else math.pi / 2, 0)
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
    Lighting.ClockTime = 16.1; Lighting.Brightness = 2.2
    Lighting.Ambient = Color3.fromRGB(132, 121, 110); Lighting.OutdoorAmbient = Color3.fromRGB(160, 157, 137)
    Lighting.EnvironmentDiffuseScale = 0.65; Lighting.EnvironmentSpecularScale = 0.45
    for _, name in ipairs({"ThriftAtmosphere", "ThriftBloom", "ThriftColor"}) do
        local old = Lighting:FindFirstChild(name); if old then old:Destroy() end
    end
    local atmosphere = Instance.new("Atmosphere"); atmosphere.Name = "ThriftAtmosphere"
    atmosphere.Density = 0.25; atmosphere.Offset = 0.18; atmosphere.Color = P.Cream
    atmosphere.Decay = Color3.fromRGB(176, 192, 187); atmosphere.Haze = 1.5; atmosphere.Glare = 0.1; atmosphere.Parent = Lighting
    local bloom = Instance.new("BloomEffect"); bloom.Name = "ThriftBloom"; bloom.Intensity = 0.14; bloom.Size = 18; bloom.Threshold = 1.5; bloom.Parent = Lighting
    local grading = Instance.new("ColorCorrectionEffect"); grading.Name = "ThriftColor"; grading.Saturation = 0.06
    grading.Contrast = 0.035; grading.TintColor = Color3.fromRGB(255, 249, 239); grading.Parent = Lighting
end
function World:landscape()
    local terrain = Kit.model(self.Root, "VillageLandscape")
    Kit.part(terrain, "Meadow", Vector3.new(520, 2, 650), CFrame.new(0, -1.5, -15), P.Grass, Enum.Material.Grass)
    Kit.part(terrain, "CobblestoneHighStreet", Vector3.new(34, 0.5, 410), CFrame.new(0, -0.3, 20), Color3.fromRGB(185, 178, 158), Enum.Material.Cobblestone)
    for z = -170, 210, 18 do
        Kit.part(terrain, "RoadMarker", Vector3.new(0.45, 0.08, 8), CFrame.new(0, 0.01, z), P.Gold, Enum.Material.Neon, nil, false)
    end
    for side = -1, 1, 2 do
        Kit.part(terrain, "PavedWalkway", Vector3.new(11, 0.5, 410), CFrame.new(side * 22.5, 0, 20), P.Cream, Enum.Material.Pavement)
        Kit.part(terrain, "Curb", Vector3.new(0.6, 0.8, 410), CFrame.new(side * 17.4, 0.1, 20), Color3.fromRGB(213, 205, 180))
        for row = 1, 8 do
            local z = -83 + (row - 1) * 35
            Kit.part(terrain, "ShopPath", Vector3.new(14, 0.25, 10), CFrame.new(side * 33, 0.2, z), Color3.fromRGB(214, 195, 162), Enum.Material.Pavement)
            if row % 2 == 1 then Kit.bench(terrain, CFrame.new(side * 24.5, 0.3, z + 14) * CFrame.Angles(0, if side == -1 then -math.pi / 2 else math.pi / 2, 0)) end
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
    local noticeCF = CFrame.new(40, 0, -175)
    for side = -1, 1, 2 do Kit.part(notice, "Post", Vector3.new(0.6, 8, 0.6), noticeCF * CFrame.new(side * 5.6, 4, 0), P.Wood, Enum.Material.Wood) end
    local label, board = Kit.sign(notice, "THE DAILY FIND\nQUESTS & DESIGNER SHOWCASE", noticeCF * CFrame.new(0, 6, 0), Vector3.new(12, 5, 0.5), P.Teal)
    label.TextColor3 = P.Paper; prompt(board, "Quests & showcase", "Quests")
    Kit.part(notice, "RainCover", Vector3.new(14, 0.35, 3), noticeCF * CFrame.new(0, 9.2, 0), P.Wood, Enum.Material.Wood)
    for i = 1, 3 do Kit.sign(notice, ({"FIND\n3 treasures", "RESTORE\n3 keepsakes", "SELL\n3 stories"})[i], noticeCF * CFrame.new(-3.6 + (i - 1) * 3.6, 2.2, -0.4) * CFrame.Angles(0, 0, (i - 2) * 0.06), Vector3.new(3, 2.4, 0.1), P.Paper, P.Ink) end
    self.Destinations = {Source = Vector3.new(-40, 2, -120), Estate = Vector3.new(42, 2, -120),
        Delivery = Vector3.new(-40, 2, -175), Quests = Vector3.new(40, 2, -175),
        Auction = Vector3.new(0, 2, -233), Market = Vector3.new(0, 2, 210)}
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
    local dcf = CFrame.new(-40, 0.2, -175)
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
    local cf = CFrame.new(-42, 0, -120)
    Kit.part(alley, "AlleyPavers", Vector3.new(30, 0.3, 24), cf, Color3.fromRGB(162, 160, 145), Enum.Material.Cobblestone)
    Kit.part(alley, "BrickWall", Vector3.new(29, 9, 1), cf * CFrame.new(0, 4.5, -10), P.Brick, Enum.Material.Brick)
    Kit.sign(alley, "SECOND CHANCE ALLEY", cf * CFrame.new(0, 7, -9.4) * CFrame.Angles(0, math.pi, 0), Vector3.new(22, 2.6, 0.2), P.Teal)
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
    local ecf = CFrame.new(46, 0, -120)
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
    Kit.sign(estate, "THE SUNDAY SALE", ecf * CFrame.new(-2, 6.5, 4) * CFrame.Angles(0, math.pi, 0), Vector3.new(14, 2.2, 0.3), P.Rose)
    Kit.parcel(estate, ecf * CFrame.new(-5, 3.2, 0), Vector3.new(2.6, 1.8, 2.5), P.Cream)
    Kit.parcel(estate, ecf * CFrame.new(0, 3.2, 0), Vector3.new(2.5, 2.3, 2.5), P.Teal)
    Kit.parcel(estate, ecf * CFrame.new(3, 3.2, 0), Vector3.new(2.2, 1.4, 2.2), P.Rose)
    Kit.plant(estate, ecf * CFrame.new(11, 0.3, 8), 1.5, nil, true)
    Kit.crate(estate, ecf * CFrame.new(8, 0.3, -6), Vector3.new(3, 3, 3), false)
end
function World:auctionHouse()
    local model = Kit.model(self.Root, "TheGavelAuctionHouse")
    local cf = CFrame.new(0, 0, -237) * CFrame.Angles(0, math.pi, 0)
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
end
function World:buildPlot(index, cf)
    local model = Kit.model(self.Root, "Shop" .. index)
    local color = shopColors[(index - 1) % #shopColors + 1]
    local front = Kit.model(model, "Storefront")
    local zone = Kit.part(front, "OwnedPlot", Vector3.new(32, 0.16, 33), cf * CFrame.new(0, 0.35, 0), color, Enum.Material.SmoothPlastic, nil, false)
    zone.Transparency = 0.76
    for side = -1, 1, 2 do
        Kit.part(front, "PlotRail", Vector3.new(0.24, 0.2, 33), cf * CFrame.new(side * 15.8, 0.48, 0), color, Enum.Material.Neon, nil, false)
    end
    Kit.part(front, "FrontStep", Vector3.new(29, 0.6, 5), cf * CFrame.new(0, 0, -15), P.Cream, Enum.Material.Pavement)
    for side = -1, 1, 2 do
        Kit.part(front, "FrontPanel", Vector3.new(6, 12, 0.7), cf * CFrame.new(side * 11, 6, -14), color)
        window(front, cf * CFrame.new(side * 11, 6, -14.45), 4.8, 5.5)
        Kit.part(front, "DoorPost", Vector3.new(0.5, 9, 0.9), cf * CFrame.new(side * 7.9, 4.5, -14), P.Cream)
        Kit.plant(front, cf * CFrame.new(side * 11.4, 0.35, -17.1), 1.2, nil, true)
    end
    Kit.part(front, "SignFascia", Vector3.new(29, 3.5, 1), cf * CFrame.new(0, 11.2, -14), color)
    Kit.part(front, "Cornice", Vector3.new(30, 0.6, 1.8), cf * CFrame.new(0, 13.2, -14), P.Cream)
    for side = -1, 1, 2 do
        local lightBar = Kit.part(front, "StorefrontGlow", Vector3.new(0.22, 9.5, 0.25), cf * CFrame.new(side * 14.15, 6.2, -14.7), color, Enum.Material.Neon, nil, false)
        lightBar.Transparency = 0.1
    end
    local label = Kit.sign(front, "YOUR NEXT CHAPTER", cf * CFrame.new(0, 11.2, -14.6), Vector3.new(26, 2.6, 0.15), color)
    for side = -1, 1, 2 do
        Kit.part(front, "BrandPylon", Vector3.new(0.7, 15, 0.7), cf * CFrame.new(side * 15, 7.5, -13.8), P.Ink, Enum.Material.Metal)
    end
    Kit.part(front, "BrandArch", Vector3.new(30.7, 0.7, 0.7), cf * CFrame.new(0, 14.7, -13.8), P.Ink, Enum.Material.Metal)
    awning(front, cf * CFrame.new(0, 8.8, -15.4), 17, 4.5, color)
    Kit.sign(front, string.format("%02d", index), cf * CFrame.new(-8.2, 5.8, -14.6), Vector3.new(1.4, 1.8, 0.12), P.Ink)
    local plot = {Model = model, CF = cf, Label = label, Slots = {}, Items = {}, Index = index,
        Color = color, Tier = 0, Depth = 28, RenderKeys = {}, DecorKey = "", Owner = nil}
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
    Kit.part(model, "OakFloor", Vector3.new(28, 0.8, depth), cf * CFrame.new(0, 0.1, (backZ - 14) / 2), P.Oak, Enum.Material.WoodPlanks)
    plot.Wall = Kit.part(model, "FeatureWall", Vector3.new(28, 12, 0.8), cf * CFrame.new(0, 6, backZ), plot.Color)
    for side = -1, 1, 2 do
        Kit.part(model, "SideWall", Vector3.new(0.8, 12, depth), cf * CFrame.new(side * 14, 6, (backZ - 14) / 2), P.Cream)
        Kit.part(model, "Wainscot", Vector3.new(0.15, 3, depth), cf * CFrame.new(side * 13.5, 1.8, (backZ - 14) / 2), P.Oak, Enum.Material.WoodPlanks)
        Kit.part(model, "PictureRail", Vector3.new(0.2, 0.25, depth), cf * CFrame.new(side * 13.4, 8.8, (backZ - 14) / 2), P.Gold, nil, nil, false)
        Kit.part(model, "Skirting", Vector3.new(0.25, 0.4, depth), cf * CFrame.new(side * 13.4, 0.7, (backZ - 14) / 2), P.Cream)
    end
    Kit.part(model, "RearSkirting", Vector3.new(27, 0.4, 0.2), cf * CFrame.new(0, 0.7, backZ - 0.5), P.Cream)
    Kit.part(model, "RearCornice", Vector3.new(28, 0.6, 1), cf * CFrame.new(0, 12.2, backZ), P.Cream)
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
    local counter = Kit.part(model, "SalesCounter", Vector3.new(6, 3, 3), cf * CFrame.new(8, 2, -9), plot.Color)
    Kit.part(model, "CounterTop", Vector3.new(6.5, 0.35, 3.5), cf * CFrame.new(8, 3.6, -9), P.Wood, Enum.Material.Wood)
    Kit.part(model, "TillBase", Vector3.new(1.8, 0.55, 1.4), cf * CFrame.new(9.3, 4, -8.8), P.Cream)
    Kit.part(model, "TillDisplay", Vector3.new(1.3, 0.75, 0.3), cf * CFrame.new(9.3, 4.6, -8.3), P.Ink)
    Kit.sign(model, "THANK YOU", cf * CFrame.new(6.8, 4.1, -9.3), Vector3.new(2.3, 0.8, 0.1), P.Cream, P.Ink)
    prompt(counter, "Sales, decor & upgrades", "Shop", plot.Owner)
    local upgradePads = {{"EXPAND", 4.5, P.Teal}, {"TOOLS", 8, P.Gold}, {"STYLE", 11.5, P.Rose}}
    for _, upgrade in ipairs(upgradePads) do
        local managementPad = Kit.cylinder(model, upgrade[1] .. "Pad", 1.45, 0.24, cf * CFrame.new(upgrade[2], 0.62, -4.5), upgrade[3], Enum.Material.Neon)
        managementPad.Transparency = 0.08
        Kit.cylinder(model, "ManagementPadRing", 1.72, 0.12, cf * CFrame.new(upgrade[2], 0.5, -4.5), P.Ink, Enum.Material.Metal)
        prompt(managementPad, "Open " .. string.lower(upgrade[1]), "Shop", plot.Owner)
        local padLabel = Kit.sign(model, upgrade[1], cf * CFrame.new(upgrade[2], 1.05, -2.95), Vector3.new(3.1, 0.72, 0.1), P.Ink, P.Paper)
        padLabel.TextScaled = true
    end
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
        Kit.part(model, "ShowroomArch", Vector3.new(27, 1, 1), cf * CFrame.new(0, 10, 12), P.Gold)
        for side = -1, 1, 2 do Kit.part(model, "ArchPillar", Vector3.new(1, 10, 1), cf * CFrame.new(side * 12.8, 5, 12), P.Cream) end
        Kit.sign(model, "THE CURATED COLLECTION", cf * CFrame.new(0, 9.8, 11.4), Vector3.new(18, 1.3, 0.15), P.Gold, P.Ink)
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
            for _, child in ipairs(plot.Model:GetDescendants()) do if child:IsA("ProximityPrompt") then child:SetAttribute("Owner", player.UserId) end end
            return index
        end
    end
    return nil
end
function World:release(userId)
    local plot = self.Owners[userId]; if not plot then return end
    for _, item in pairs(plot.Items) do item:Destroy() end
    plot.Items = {}; plot.RenderKeys = {}; plot.Owner = nil; plot.Label.Text = "YOUR NEXT CHAPTER"
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
    if target then return (root.Position - target).Magnitude < 25 end
    local plot = self.Owners[player.UserId]; if not plot then return false end
    local position = plot.CF:PointToObjectSpace(root.Position)
    return math.abs(position.X) < 15.5 and position.Z > -18 and position.Z < plot.BackZ + 1 and position.Y > -3 and position.Y < 14
end
function World:teleportCFrame(player, destination)
    local target = self.Destinations[destination]
    if target then return CFrame.new(target + Vector3.new(0, 3.5, 6), target) end
    if destination ~= "Shop" and destination ~= "Workbench" then return nil end
    local plot = self.Owners[player.UserId]
    if not plot then return nil end
    local localPosition = if destination == "Workbench"
        then Vector3.new(-7.5, 4, plot.BackZ - 8)
        else Vector3.new(0, 4, -8)
    local position = plot.CF:PointToWorldSpace(localPosition)
    local lookAt = plot.CF:PointToWorldSpace(if destination == "Workbench" then Vector3.new(-7.5, 3, plot.BackZ - 3.5) else Vector3.new(0, 3, 0))
    return CFrame.lookAt(position, lookAt)
end
function World:render(player, profile, catalog, config)
    local plot = self.Owners[player.UserId]; if not plot then return end
    if plot.Tier ~= profile.Tier then self:buildInterior(plot, profile.Tier) end
    local tier = config.Tiers[profile.Tier]
    local average = if profile.RatingCount > 0 then string.format("%.1f", profile.RatingTotal / profile.RatingCount) else "NEW"
    plot.Label.Text = player.DisplayName .. "'s " .. tier.Name .. "  •  ★ " .. average
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
    return ItemModels.create(parent, definition, item, cf, config)
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
