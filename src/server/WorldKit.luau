-- Original modular environment assets. All geometry is local, anchored and script-free.
local Kit = {}
Kit.Palette = {
    Cream = Color3.fromRGB(248, 237, 212), Paper = Color3.fromRGB(255, 250, 232),
    Wood = Color3.fromRGB(153, 108, 74), Oak = Color3.fromRGB(189, 143, 99),
    Teal = Color3.fromRGB(104, 166, 151), Rose = Color3.fromRGB(208, 146, 151),
    Gold = Color3.fromRGB(232, 185, 86), Ink = Color3.fromRGB(49, 69, 64),
    Brick = Color3.fromRGB(172, 104, 84), Leaf = Color3.fromRGB(110, 149, 101),
    Grass = Color3.fromRGB(153, 178, 121), Sky = Color3.fromRGB(186, 213, 218),
    Lavender = Color3.fromRGB(167, 156, 190), Coral = Color3.fromRGB(217, 140, 108),
}
local P = Kit.Palette
function Kit.model(parent, name)
    local model = Instance.new("Model"); model.Name = name; model.Parent = parent
    return model
end
function Kit.part(parent, name, size, cf, color, material, shape, collision)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color or P.Cream
    p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.Material = material or Enum.Material.SmoothPlastic
    p.CanCollide = collision ~= false; p.CanTouch = false
    if collision == false then p.CanQuery = false end
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end
function Kit.ball(parent, name, size, cf, color, material, collision)
    return Kit.part(parent, name, size, cf, color, material, Enum.PartType.Ball, collision)
end
function Kit.cylinder(parent, name, radius, height, cf, color, material, collision)
    return Kit.part(parent, name, Vector3.new(height, radius * 2, radius * 2),
        cf * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder, collision)
end
function Kit.beam(parent, name, from, to, width, color, material)
    local delta = to - from
    return Kit.part(parent, name, Vector3.new(width, width, delta.Magnitude),
        CFrame.lookAt((from + to) / 2, to), color, material, nil, false)
end
function Kit.sign(parent, text, cf, size, boardColor, textColor)
    local board = Kit.part(parent, "Sign", size or Vector3.new(14, 3, 0.25), cf, boardColor or P.Ink, nil, nil, false)
    local gui = Instance.new("SurfaceGui"); gui.Name = "Lettering"; gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 44
    gui.LightInfluence = 0.1; gui.Parent = board
    local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = textColor or P.Paper
    label.Font = Enum.Font.GothamBold; label.TextScaled = true; label.TextWrapped = true; label.Parent = gui
    local padding = Instance.new("UIPadding"); padding.PaddingLeft = UDim.new(0.05, 0); padding.PaddingRight = UDim.new(0.05, 0)
    padding.PaddingTop = UDim.new(0.08, 0); padding.PaddingBottom = UDim.new(0.08, 0); padding.Parent = label
    return label, board
end
function Kit.plant(parent, cf, scale, color, flowers)
    local model = Kit.model(parent, "PottedPlant")
    local s = scale or 1
    Kit.cylinder(model, "Terracotta", 0.65 * s, 1.1 * s, cf * CFrame.new(0, 0.55 * s, 0), P.Coral)
    Kit.cylinder(model, "Rim", 0.76 * s, 0.18 * s, cf * CFrame.new(0, 1.03 * s, 0), P.Cream)
    Kit.cylinder(model, "Soil", 0.60 * s, 0.06 * s, cf * CFrame.new(0, 1.13 * s, 0), P.Wood, Enum.Material.Ground, false)
    for i = 1, 4 do
        local angle = i * math.pi / 2
        local offset = Vector3.new(math.cos(angle) * 0.35 * s, 1.65 * s, math.sin(angle) * 0.35 * s)
        Kit.ball(model, "Leaf", Vector3.new(0.7, 1.5, 0.45) * s,
            cf * CFrame.new(offset) * CFrame.Angles(0, -angle, 0.35), color or P.Leaf, nil, false)
        if flowers then
            Kit.ball(model, "Blossom", Vector3.new(0.45, 0.45, 0.45) * s,
                cf * CFrame.new(offset + Vector3.new(0, 0.65 * s, 0)), P.Rose, nil, false)
        end
    end
    return model
end
function Kit.tree(parent, cf, scale, variant)
    local s = scale or 1
    local model = Kit.model(parent, "MarketTree")
    Kit.cylinder(model, "Trunk", 0.6 * s, 7 * s, cf * CFrame.new(0, 3.5 * s, 0), P.Wood, Enum.Material.Wood)
    local leafColor = if (variant or 0) % 3 == 0 then Color3.fromRGB(137, 160, 110) else P.Leaf
    Kit.ball(model, "Crown", Vector3.new(8, 8, 8) * s, cf * CFrame.new(0, 9 * s, 0), leafColor, nil, false)
    Kit.ball(model, "CrownLeft", Vector3.new(5, 5.5, 5) * s, cf * CFrame.new(-2.7 * s, 7.5 * s, 0.8 * s), leafColor, nil, false)
    Kit.ball(model, "CrownRight", Vector3.new(5, 6, 5) * s, cf * CFrame.new(2.6 * s, 8.2 * s, -0.6 * s), leafColor, nil, false)
    Kit.cylinder(model, "TreeBed", 3.2 * s, 0.2, cf * CFrame.new(0, 0.05, 0), Color3.fromRGB(125, 151, 103), Enum.Material.Grass)
    return model
end
function Kit.bench(parent, cf)
    local model = Kit.model(parent, "ParkBench")
    for x = -1, 1, 2 do
        Kit.part(model, "IronLeg", Vector3.new(0.3, 2, 1.9), cf * CFrame.new(x * 2.2, 1, 0), P.Ink, Enum.Material.Metal)
        Kit.part(model, "ArmRest", Vector3.new(0.35, 0.25, 2.1), cf * CFrame.new(x * 2.5, 2.5, 0), P.Ink, Enum.Material.Metal)
    end
    for i = 1, 4 do
        Kit.part(model, "SeatSlat", Vector3.new(5.4, 0.2, 0.4), cf * CFrame.new(0, 1.8, -1 + i * 0.45), P.Oak, Enum.Material.Wood)
    end
    for i = 1, 3 do
        Kit.part(model, "BackSlat", Vector3.new(5.4, 0.4, 0.2), cf * CFrame.new(0, 2.2 + i * 0.5, 0.9) * CFrame.Angles(-0.15, 0, 0), P.Oak, Enum.Material.Wood)
    end
    return model
end
function Kit.lamp(parent, cf)
    local model = Kit.model(parent, "StreetLantern")
    Kit.cylinder(model, "Plinth", 0.65, 0.4, cf * CFrame.new(0, 0.2, 0), P.Ink, Enum.Material.Metal)
    Kit.cylinder(model, "Post", 0.19, 8.5, cf * CFrame.new(0, 4.45, 0), P.Ink, Enum.Material.Metal)
    Kit.part(model, "LanternBase", Vector3.new(1.5, 0.2, 1.5), cf * CFrame.new(0, 8.5, 0), P.Ink)
    local glow = Kit.part(model, "WarmGlass", Vector3.new(1, 1.5, 1), cf * CFrame.new(0, 9.25, 0), P.Gold, Enum.Material.Neon, nil, false)
    glow.Transparency = 0.15
    for x = -1, 1, 2 do for z = -1, 1, 2 do
        Kit.part(model, "LanternFrame", Vector3.new(0.12, 1.7, 0.12), cf * CFrame.new(x * 0.6, 9.25, z * 0.6), P.Ink, Enum.Material.Metal, nil, false)
    end end
    Kit.part(model, "Roof", Vector3.new(1.7, 0.3, 1.7), cf * CFrame.new(0, 10.2, 0), P.Ink)
    Kit.ball(model, "Finial", Vector3.new(0.4, 0.5, 0.4), cf * CFrame.new(0, 10.6, 0), P.Gold, Enum.Material.Metal, false)
    local light = Instance.new("PointLight"); light.Color = P.Gold; light.Range = 14; light.Brightness = 0.45; light.Shadows = false; light.Parent = glow
    return model
end
function Kit.crate(parent, cf, size, open)
    local model = Kit.model(parent, "FindsCrate")
    local s = size or Vector3.new(3, 2.2, 2.5)
    Kit.part(model, "Base", Vector3.new(s.X, 0.15, s.Z), cf * CFrame.new(0, 0.1, 0), P.Oak, Enum.Material.Wood)
    for side = -1, 1, 2 do
        for row = 1, 3 do
            Kit.part(model, "Board", Vector3.new(s.X, s.Y / 3 - 0.08, 0.16), cf * CFrame.new(0, (row - 0.5) * s.Y / 3, side * (s.Z / 2 - 0.08)), P.Oak, Enum.Material.Wood)
        end
        Kit.part(model, "End", Vector3.new(0.17, s.Y, s.Z), cf * CFrame.new(side * s.X / 2, s.Y / 2, 0), P.Wood, Enum.Material.Wood)
    end
    if not open then
        Kit.part(model, "Lid", Vector3.new(s.X, 0.15, s.Z), cf * CFrame.new(0, s.Y, 0), P.Oak, Enum.Material.Wood)
    end
    return model
end
function Kit.parcel(parent, cf, size, color)
    local s = size or Vector3.new(2, 1.6, 2)
    local model = Kit.model(parent, "Parcel")
    local box = Kit.part(model, "Box", s, cf * CFrame.new(0, s.Y / 2, 0), color or P.Oak, Enum.Material.SmoothPlastic)
    Kit.part(model, "RibbonA", Vector3.new(0.25, s.Y + 0.03, s.Z + 0.03), cf * CFrame.new(0, s.Y / 2, 0), P.Cream, nil, nil, false)
    Kit.part(model, "RibbonB", Vector3.new(s.X + 0.03, s.Y + 0.03, 0.25), cf * CFrame.new(0, s.Y / 2, 0), P.Cream, nil, nil, false)
    return model, box
end
function Kit.fence(parent, cf, length, color)
    local model = Kit.model(parent, "GardenFence")
    for x = -length / 2, length / 2, 1.4 do
        Kit.part(model, "Picket", Vector3.new(0.7, 3.5, 0.2), cf * CFrame.new(x, 1.75, 0), color or P.Cream, Enum.Material.Wood)
    end
    for _, y in ipairs({0.8, 2.5}) do
        Kit.part(model, "Rail", Vector3.new(length, 0.3, 0.3), cf * CFrame.new(0, y, 0.1), color or P.Cream, Enum.Material.Wood)
    end
    return model
end
return Kit
