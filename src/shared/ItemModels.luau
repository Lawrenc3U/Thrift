-- Original Thrift Flip model library. No catalog meshes or externally owned assets.
-- describe() is pure data so the same authored assets can be exported or previewed.
-- Model origin: bottom-center; presentation/front: -Z. All parts are anchored.
local ItemModels = {}
local pi = math.pi
local palette = {
    Cream = {0.96, 0.89, 0.73}, Ivory = {0.98, 0.96, 0.87},
    Teal = {0.28, 0.58, 0.54}, Mint = {0.58, 0.77, 0.65},
    Coral = {0.84, 0.43, 0.34}, Rose = {0.80, 0.51, 0.57},
    Mustard = {0.89, 0.67, 0.27}, Gold = {0.74, 0.55, 0.25},
    Brass = {0.60, 0.43, 0.23}, Copper = {0.68, 0.36, 0.24},
    Walnut = {0.29, 0.17, 0.11}, Wood = {0.57, 0.36, 0.20},
    Dark = {0.13, 0.18, 0.19}, Black = {0.075, 0.10, 0.11},
    Silver = {0.64, 0.70, 0.69}, Blue = {0.28, 0.48, 0.65},
    Lilac = {0.61, 0.49, 0.73}, Glass = {0.62, 0.82, 0.83},
    Dirt = {0.39, 0.34, 0.24}, White = {0.96, 0.96, 0.92},
}
local styleColors = {Retro = "Coral", Cozy = "Mint", Futuristic = "Blue", Antique = "Wood", Cute = "Rose"}
local function clone3(value) return {value[1], value[2], value[3]} end
local function blend(a, b, t)
    return {a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t}
end
local function builder(definition, item)
    local parts = {}
    local theme = palette[styleColors[item.Style or definition.Style] or "Teal"]
    local condition = math.clamp(item.Condition or 5, 1, 5)
    local wear = (5 - condition) * 0.075
    local function p(name, size, pos, color, shape, rotation, material, transparency)
        local original = if type(color) == "table" then color else palette[color or "Cream"]
        local entry = {Name = name, Class = "Part", Size = clone3(size), Position = clone3(pos),
            Color = blend(original, palette.Dirt, wear), Shape = shape or "Block",
            Rotation = rotation or {0, 0, 0}, Material = material or "SmoothPlastic",
            Transparency = transparency or 0, Reflectance = 0}
        table.insert(parts, entry)
        return entry
    end
    local function box(name, size, pos, color, rot, mat)
        return p(name, size, pos, color, "Block", rot, mat)
    end
    local function ball(name, size, pos, color, mat)
        return p(name, size, pos, color, "Ball", nil, mat)
    end
    local function cyl(name, diameter, height, pos, color, mat)
        return p(name, {height, diameter, diameter}, pos, color, "Cylinder", {0, 0, pi / 2}, mat)
    end
    local function disc(name, diameter, depth, pos, color, mat)
        return p(name, {depth, diameter, diameter}, pos, color, "Cylinder", {0, pi / 2, 0}, mat)
    end
    local function wedge(name, size, pos, color, rot)
        local part = box(name, size, pos, color, rot); part.Class = "WedgePart"; part.Shape = nil; return part
    end
    local function rod(name, a, b, thickness, color, mat)
        local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
        local len = math.sqrt(dx * dx + dy * dy + dz * dz)
        return box(name, {thickness, len, thickness}, {(a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2}, color,
            {math.atan2(dz, dy), 0, -math.atan2(dx, math.sqrt(dy * dy + dz * dz))}, mat)
    end
    local function face(name, width, height, depth, pos, color)
        box(name, {width, height, depth}, pos, color)
        for side = -1, 1, 2 do
            ball(name .. "Corner", {height, height, depth}, {pos[1] + side * width / 2, pos[2], pos[3]}, color)
        end
    end
    local function knobs(y, z, count, spacing, color)
        for i = 1, count do disc("Knob", 0.19, 0.11, {(i - (count + 1) / 2) * spacing, y, z}, color or "Gold", "Metal") end
    end
    local function feet(width, depth, y, height, color)
        for x = -1, 1, 2 do for z = -1, 1, 2 do
            box("Foot", {0.18, height, 0.18}, {x * width / 2, y, z * depth / 2}, color or "Walnut")
        end end
    end
    return parts, {p = p, box = box, ball = ball, cyl = cyl, disc = disc, wedge = wedge, rod = rod,
        face = face, knobs = knobs, feet = feet, Theme = theme, Variant = definition.Variant or 1, Condition = condition}
end
local function lamps(g)
    local v, tint = g.Variant, g.Theme
    if v == 1 then -- Tulip: curved stalk and five cupped glass petals.
        g.cyl("Pedestal", 1.35, 0.18, {0, 0.09, 0}, "Brass", "Metal")
        g.rod("Stem", {0, 0.18, 0}, {0.18, 2.15, 0}, 0.14, "Gold", "Metal")
        g.ball("WarmBulb", {0.58, 0.72, 0.58}, {0.18, 2.17, 0}, "Cream", "Neon")
        for i = 1, 5 do
            local a = i * 2 * pi / 5
            local petal = g.ball("TulipPetal", {0.55, 1.05, 0.38}, {0.18 + math.cos(a) * 0.38, 2.3, math.sin(a) * 0.38}, tint)
            petal.Rotation = {0, -a, 0.2}; petal.Transparency = 0.12
        end
        g.ball("Leaf", {0.7, 0.16, 0.3}, {-0.22, 1.3, 0}, "Mint").Rotation = {0, 0, -0.5}
    elseif v == 2 then -- Brass banker desk lamp.
        g.cyl("WeightedFoot", 1.55, 0.2, {0, 0.1, 0}, "Brass", "Metal")
        g.cyl("FootInset", 1.1, 0.08, {0, 0.24, 0}, "Gold", "Metal")
        g.rod("CurvedNeck", {0, 0.25, 0.2}, {0, 1.95, 0.2}, 0.18, "Brass", "Metal")
        g.rod("ShadeSupport", {-0.65, 1.9, 0.2}, {0.65, 1.9, 0.2}, 0.14, "Brass", "Metal")
        g.ball("EmeraldShade", {2.1, 0.75, 1.05}, {0, 2.05, -0.14}, "Teal")
        g.box("CreamDiffuser", {1.72, 0.12, 0.82}, {0, 1.79, -0.14}, "Cream", nil, "Neon")
        g.rod("PullChain", {0.72, 1.8, -0.25}, {0.72, 1.16, -0.25}, 0.035, "Gold", "Metal")
        g.ball("ChainBead", {0.13, 0.13, 0.13}, {0.72, 1.1, -0.25}, "Gold", "Metal")
    elseif v == 3 then
        g.cyl("SoftFoot", 1.1, 0.15, {0, 0.075, 0}, "Ivory")
        g.ball("MushroomStem", {0.68, 1.75, 0.68}, {0, 0.95, 0}, "Ivory")
        g.ball("MushroomCap", {2.35, 1.02, 2.35}, {0, 1.9, 0}, tint)
        g.cyl("CapRim", 2.1, 0.09, {0, 1.59, 0}, "Cream")
        for i = 1, 5 do
            local a = i * 2 * pi / 5
            g.ball("GlazedSpot", {0.28, 0.05, 0.28}, {math.cos(a) * 0.6, 2.37, math.sin(a) * 0.6}, "Ivory")
        end
    elseif v == 4 then
        g.cyl("StoneBase", 1.5, 0.25, {-0.4, 0.125, 0}, "Dark", "Marble")
        g.rod("ArcStem", {-0.4, 0.2, 0}, {-0.4, 2.7, 0}, 0.12, "Silver", "Metal")
        g.rod("ArcShoulder", {-0.4, 2.7, 0}, {0.6, 3.25, 0}, 0.12, "Silver", "Metal")
        g.rod("ArcTip", {0.6, 3.25, 0}, {1.1, 2.8, 0}, 0.12, "Silver", "Metal")
        g.ball("SteelShade", {1.15, 0.65, 1.15}, {1.08, 2.65, 0}, tint)
        g.cyl("WarmUnderside", 0.85, 0.08, {1.08, 2.41, 0}, "Cream", "Neon")
    elseif v == 5 then
        g.cyl("LanternBase", 1.35, 0.25, {0, 0.125, 0}, "Dark", "Metal")
        g.cyl("GlassChamber", 0.95, 1.55, {0, 1, 0}, "Cream", "Glass").Transparency = 0.35
        g.cyl("Candle", 0.25, 0.65, {0, 0.65, 0}, "Ivory")
        g.ball("Flame", {0.16, 0.35, 0.16}, {0, 1.1, 0}, "Mustard", "Neon")
        for x = -1, 1, 2 do for z = -1, 1, 2 do
            g.box("LanternFrame", {0.09, 1.7, 0.09}, {x * 0.45, 1.1, z * 0.45}, "Dark", nil, "Metal")
        end end
        g.cyl("LanternRoof", 1.5, 0.18, {0, 1.95, 0}, "Dark", "Metal")
        g.ball("RoofCap", {0.85, 0.48, 0.85}, {0, 2.13, 0}, "Dark")
        g.rod("HandleL", {-0.4, 2.2, 0}, {-0.4, 2.65, 0}, 0.1, "Brass")
        g.rod("HandleR", {0.4, 2.2, 0}, {0.4, 2.65, 0}, 0.1, "Brass")
        g.rod("CarryHandle", {-0.4, 2.65, 0}, {0.4, 2.65, 0}, 0.1, "Brass")
    elseif v == 6 then
        g.cyl("DeskBase", 1.4, 0.17, {0, 0.085, 0}, tint)
        g.rod("LowerArm", {0, 0.18, 0}, {-0.5, 1.3, 0}, 0.13, tint)
        g.disc("ElbowBolt", 0.26, 0.3, {-0.5, 1.3, 0}, "Gold", "Metal")
        g.rod("UpperArm", {-0.5, 1.3, 0}, {0.5, 2.15, 0}, 0.13, tint)
        g.disc("HeadPivot", 0.24, 0.3, {0.5, 2.15, 0}, "Gold", "Metal")
        g.ball("TaskShade", {0.95, 0.6, 0.95}, {0.7, 1.98, -0.1}, tint)
        g.cyl("TaskLight", 0.7, 0.09, {0.7, 1.78, -0.1}, "Cream", "Neon")
    elseif v == 7 then
        g.cyl("LavaFoot", 1.15, 0.2, {0, 0.1, 0}, "Silver", "Metal")
        g.ball("LavaBase", {1.1, 0.7, 1.1}, {0, 0.45, 0}, "Silver", "Metal")
        local glass = g.ball("LavaGlass", {0.95, 2.2, 0.95}, {0, 1.65, 0}, "Lilac", "Glass"); glass.Transparency = 0.5
        g.ball("WaxLower", {0.65, 0.8, 0.65}, {0, 0.95, 0}, "Coral", "Neon")
        g.ball("WaxMiddle", {0.35, 0.55, 0.35}, {0.12, 1.85, 0}, "Coral", "Neon")
        g.ball("WaxUpper", {0.5, 0.55, 0.5}, {-0.06, 2.35, 0}, "Coral", "Neon")
        g.ball("MetalCap", {0.55, 0.5, 0.55}, {0, 2.8, 0}, "Silver", "Metal")
    elseif v == 8 then
        g.cyl("OrnateFoot", 1.35, 0.16, {0, 0.08, 0}, "Brass", "Metal")
        g.cyl("TiffanyStem", 0.15, 1.8, {0, 1.05, 0}, "Brass", "Metal")
        g.ball("ShadeCore", {2.2, 0.95, 2.2}, {0, 2.16, 0}, "Gold")
        for i = 1, 8 do
            local a = i * pi / 4
            local petal = g.ball("StainedGlassPanel", {0.68, 0.74, 0.35}, {math.cos(a) * 0.77, 2.18, math.sin(a) * 0.77}, if i % 2 == 0 then "Teal" else "Mustard", "Glass")
            petal.Rotation = {0, -a + pi / 2, 0}; petal.Transparency = 0.1
        end
        g.ball("Finial", {0.19, 0.25, 0.19}, {0, 2.72, 0}, "Brass")
    elseif v == 9 then
        for i = 1, 3 do
            local a = i * 2 * pi / 3
            g.rod("TripodLeg", {0, 1.8, 0}, {math.cos(a) * 0.95, 0.08, math.sin(a) * 0.95}, 0.14, "Wood", "Wood")
        end
        g.cyl("TripodCollar", 0.25, 0.35, {0, 1.85, 0}, "Silver", "Metal")
        g.disc("SpotHousing", 1.2, 0.7, {0, 2.4, 0}, "Dark", "Metal")
        g.disc("Reflector", 0.95, 0.05, {0, 2.4, -0.38}, "Silver", "Metal")
        g.disc("SpotLamp", 0.7, 0.06, {0, 2.4, -0.43}, "Cream", "Neon")
        for x = -1, 1, 2 do g.box("BarnDoor", {0.35, 1.15, 0.1}, {x * 0.72, 2.4, -0.5}, "Dark", {0, x * 0.25, 0}) end
    else
        g.cyl("MoonFoot", 1.45, 0.15, {0, 0.075, 0}, "Wood", "Wood")
        g.cyl("MoonCradle", 0.24, 0.5, {0, 0.4, 0}, "Gold", "Metal")
        g.ball("MoonOrb", {1.85, 1.85, 1.85}, {0, 1.5, 0}, "Cream", "Neon")
        for _, spot in ipairs({{-0.5, 1.6, -0.72, 0.28}, {0.35, 1.9, -0.7, 0.4}, {0.1, 1.05, -0.76, 0.26}, {-0.2, 2.12, -0.6, 0.2}}) do
            g.ball("LunarCrater", {spot[4], spot[4], 0.07}, {spot[1], spot[2], spot[3]}, "Ivory")
        end
    end
end
local function radios(g)
    local v, tint = g.Variant, g.Theme
    if v == 1 or v == 5 or v == 8 then
        local w, h = if v == 1 then 1.25 else 1.9, if v == 1 then 1.9 else 1.35
        g.box("PortableCase", {w, h, 0.65}, {0, h / 2 + 0.1, 0}, tint)
        g.box("SpeakerFabric", {w * 0.7, h * 0.48, 0.04}, {-w * 0.08, h * 0.37, -0.35}, "Cream", nil, "Fabric")
        for i = 1, 4 do g.box("SpeakerSlot", {w * 0.53, 0.035, 0.03}, {-w * 0.08, h * 0.23 + i * h * 0.07, -0.38}, "Wood") end
        g.box("TunerGlass", {w * 0.72, 0.2, 0.05}, {0, h * 0.83, -0.36}, "Dark")
        g.box("TuningNeedle", {0.035, 0.14, 0.04}, {0.2, h * 0.83, -0.40}, "Coral")
        g.knobs(h * 0.11, -0.38, 2, w * 0.6, "Silver")
        g.rod("Antenna", {w * 0.3, h, 0}, {w * 0.52, h + 0.75, 0}, 0.045, "Silver", "Metal")
        if v == 8 then
            g.box("SuitcaseHandle", {0.85, 0.12, 0.24}, {0, h + 0.42, 0}, "Walnut")
            for x = -1, 1, 2 do g.box("HandleRiser", {0.12, 0.32, 0.24}, {x * 0.4, h + 0.26, 0}, "Walnut") end
            g.feet(w * 0.75, 0.45, 0.06, 0.12, "Dark")
        elseif v == 5 then
            g.disc("LargeTuner", 0.5, 0.12, {0.59, 0.6, -0.39}, "Silver", "Metal")
            g.box("LeatherStrap", {0.13, 0.8, 0.2}, {-w / 2 - 0.12, 1.15, 0}, "Walnut", {0, 0, 0.15})
        end
    elseif v == 2 then
        g.face("BakeliteCabinet", 1.55, 1.5, 0.85, {0, 0.9, 0}, "Walnut")
        g.box("GoldTrim", {2.1, 0.08, 0.9}, {0, 0.22, 0}, "Brass")
        g.disc("TuningDial", 0.78, 0.08, {-0.5, 1, -0.47}, "Cream")
        g.rod("DialPointer", {-0.5, 1, -0.53}, {-0.35, 1.27, -0.53}, 0.04, "Dark")
        for i = 1, 5 do g.box("VerticalGrille", {0.08, 0.85, 0.04}, {0.15 + i * 0.18, 1, -0.48}, "Cream") end
        g.knobs(0.4, -0.51, 2, 1.25)
    elseif v == 3 then
        g.box("BoomboxBody", {2.85, 1.55, 0.8}, {0, 0.92, 0}, "Silver", nil, "Metal")
        for x = -1, 1, 2 do
            g.disc("SpeakerRim", 1.05, 0.09, {x * 0.88, 0.9, -0.47}, "Dark")
            g.disc("SpeakerCone", 0.78, 0.07, {x * 0.88, 0.9, -0.54}, "Black")
            g.disc("SpeakerCap", 0.28, 0.06, {x * 0.88, 0.9, -0.6}, "Silver", "Metal")
        end
        g.box("CassetteWindow", {0.64, 0.58, 0.05}, {0, 0.8, -0.46}, "Dark")
        g.box("CassetteLabel", {0.49, 0.16, 0.03}, {0, 0.9, -0.5}, "Coral")
        g.box("TunerStrip", {2.5, 0.16, 0.06}, {0, 1.52, -0.46}, "Dark")
        g.box("Handle", {1.75, 0.15, 0.24}, {0, 2.1, 0}, "Dark")
        for x = -1, 1, 2 do g.box("HandlePost", {0.15, 0.37, 0.24}, {x * 0.8, 1.92, 0}, "Dark") end
        for i = 1, 4 do g.box("TapeButton", {0.16, 0.07, 0.25}, {-0.3 + i * 0.18, 1.72, -0.15}, if i == 1 then "Coral" else "Dark") end
        g.rod("TelescopicAntenna", {1.15, 1.7, 0.1}, {1.5, 2.65, 0.1}, 0.04, "Silver", "Metal")
    elseif v == 4 then
        g.box("CathedralCabinet", {1.8, 1.8, 0.85}, {0, 1.1, 0}, "Walnut", nil, "Wood")
        g.ball("ArchedCrown", {1.8, 1.55, 0.85}, {0, 1.95, 0}, "Walnut", "Wood")
        g.box("CabinetFoot", {2.05, 0.22, 1}, {0, 0.11, 0}, "Wood", nil, "Wood")
        for i = -2, 2 do g.box("CathedralGrille", {0.14, 1.25 - math.abs(i) * 0.13, 0.04}, {i * 0.26, 1.72, -0.46}, "Cream") end
        g.disc("FrequencyDial", 0.45, 0.06, {0, 0.68, -0.48}, "Gold")
        g.knobs(0.4, -0.48, 2, 1.15)
    elseif v == 6 then
        g.ball("SpaceCabinet", {2.35, 1.7, 1.1}, {0, 1.15, 0}, tint)
        g.face("Visor", 1.3, 0.7, 0.08, {0, 1.3, -0.52}, "Dark")
        for i = 1, 4 do g.box("FrequencyLight", {0.16, 0.25, 0.03}, {-0.5 + i * 0.22, 1.3, -0.59}, if i % 2 == 0 then "Mustard" else "Teal", nil, "Neon") end
        for x = -1, 1, 2 do
            g.rod("SplayedFoot", {x * 0.6, 0.6, 0}, {x * 0.85, 0.1, 0}, 0.16, "Silver", "Metal")
            g.rod("RabbitAerial", {x * 0.2, 1.95, 0}, {x * 0.75, 2.65, 0}, 0.05, "Silver", "Metal")
        end
        g.knobs(0.75, -0.55, 3, 0.45)
    elseif v == 7 then
        g.box("KitchenRadio", {2.2, 1.35, 0.8}, {0, 0.8, 0}, "Ivory")
        g.box("PastelFace", {2.02, 1.15, 0.05}, {0, 0.8, -0.43}, tint)
        g.disc("KitchenSpeaker", 0.9, 0.08, {-0.48, 0.85, -0.48}, "Cream")
        for i = -2, 2 do g.box("GrilleBar", {0.04, 0.6, 0.04}, {-0.48 + i * 0.14, 0.85, -0.54}, "Gold") end
        g.box("LCDClock", {0.7, 0.25, 0.06}, {0.65, 1.08, -0.49}, "Dark")
        g.disc("Tuner", 0.34, 0.14, {0.65, 0.62, -0.5}, "Silver", "Metal")
        g.feet(1.75, 0.5, 0.08, 0.16, "Dark")
    elseif v == 9 then
        g.box("JukeboxBase", {2.1, 2.5, 0.95}, {0, 1.35, 0}, "Wood", nil, "Wood")
        g.ball("JukeboxArch", {2.1, 1.6, 0.95}, {0, 2.55, 0}, "Coral")
        g.box("GoldenFront", {1.8, 1.8, 0.07}, {0, 1.7, -0.51}, "Gold", nil, "Metal")
        g.ball("RecordWindow", {1.4, 1.4, 0.08}, {0, 2.4, -0.55}, "Dark")
        for x = -1, 1, 2 do g.box("NeonPillar", {0.12, 2.25, 0.08}, {x * 0.87, 1.55, -0.59}, "Mint", nil, "Neon") end
        g.disc("VinylRecord", 0.82, 0.06, {0, 2.4, -0.63}, "Black")
        g.disc("RecordLabel", 0.28, 0.04, {0, 2.4, -0.68}, "Rose")
        for i = 1, 4 do g.box("SongSelection", {1.15, 0.12, 0.06}, {0, 1.25 + i * 0.17, -0.58}, "Ivory") end
        for i = 1, 4 do g.box("SpeakerGrille", {1.45, 0.07, 0.06}, {0, 0.35 + i * 0.16, -0.55}, "Dark") end
    else
        g.box("CrystalRadioBase", {2.15, 0.25, 1.4}, {0, 0.125, 0}, "Walnut", nil, "Wood")
        g.cyl("CoilSpool", 0.8, 0.85, {-0.5, 0.72, 0}, "Copper", "Metal")
        for i = 1, 5 do g.cyl("CoilWinding", 0.88, 0.035, {-0.5, 0.3 + i * 0.14, 0}, "Gold", "Metal") end
        g.box("CrystalMount", {0.45, 0.2, 0.5}, {0.6, 0.38, 0}, "Brass", nil, "Metal")
        g.ball("Crystal", {0.45, 0.5, 0.45}, {0.6, 0.66, 0}, "Lilac", "Glass")
        g.rod("CatsWhisker", {0.94, 0.3, 0}, {0.6, 0.85, 0}, 0.035, "Silver", "Metal")
        g.rod("Aerial", {-0.75, 1.2, 0}, {-0.75, 2, 0}, 0.04, "Silver", "Metal")
        g.knobs(0.3, -0.75, 2, 1.25)
    end
end
local function clockFace(g, x, y, z, diameter, trim)
    g.disc("ClockBezel", diameter + 0.18, 0.12, {x, y, z}, trim or "Gold", "Metal")
    g.disc("ClockDial", diameter, 0.06, {x, y, z - 0.08}, "Ivory")
    for i = 0, 3 do
        local a = i * pi / 2
        g.box("HourMarker", {0.06, 0.13, 0.04}, {x + math.sin(a) * diameter * 0.37, y + math.cos(a) * diameter * 0.37, z - 0.13}, "Dark", {0, 0, -a})
    end
    g.rod("HourHand", {x, y, z - 0.17}, {x - diameter * 0.21, y + diameter * 0.13, z - 0.17}, 0.06, "Dark")
    g.rod("MinuteHand", {x, y, z - 0.18}, {x + diameter * 0.13, y + diameter * 0.32, z - 0.18}, 0.04, "Dark")
    g.disc("HandPin", 0.12, 0.04, {x, y, z - 0.2}, "Gold")
end
local function clocks(g)
    local v, tint = g.Variant, g.Theme
    if v == 1 then
        g.box("CuckooHouse", {1.9, 2, 0.9}, {0, 1.8, 0}, "Wood", nil, "Wood")
        g.box("RoofL", {1.45, 0.2, 1.2}, {-0.54, 3, 0}, "Walnut", {0, 0, 0.55}, "Wood")
        g.box("RoofR", {1.45, 0.2, 1.2}, {0.54, 3, 0}, "Walnut", {0, 0, -0.55}, "Wood")
        clockFace(g, 0, 1.8, -0.5, 1.05, "Gold")
        g.disc("CuckooDoor", 0.34, 0.05, {0, 2.65, -0.5}, "Dark")
        g.ball("Bird", {0.2, 0.16, 0.29}, {0, 2.6, -0.68}, "Coral")
        for x = -1, 1, 2 do g.rod("Chain", {x * 0.5, 0.8, 0}, {x * 0.5, 0.18, 0}, 0.04, "Gold"); g.ball("PineconeWeight", {0.22, 0.4, 0.22}, {x * 0.5, 0.25, 0}, "Brass") end
    elseif v == 2 then
        g.box("MantelPlinth", {2.5, 0.24, 0.9}, {0, 0.12, 0}, "Walnut", nil, "Wood")
        g.face("TambourCase", 1.35, 1.6, 0.8, {0, 1.02, 0}, "Wood")
        clockFace(g, 0, 1.12, -0.46, 1.2)
        g.box("BaseMolding", {2.3, 0.12, 0.87}, {0, 0.3, 0}, "Gold")
    elseif v == 3 then
        g.disc("AlarmCase", 1.85, 0.65, {0, 1.24, 0}, tint)
        clockFace(g, 0, 1.24, -0.37, 1.5, "Silver")
        for x = -1, 1, 2 do
            g.rod("AlarmFoot", {x * 0.5, 0.6, 0}, {x * 0.7, 0.08, 0}, 0.14, "Gold")
            g.ball("AlarmBell", {0.75, 0.35, 0.65}, {x * 0.65, 2.26, 0}, "Silver", "Metal")
        end
        g.box("BellHammer", {0.7, 0.08, 0.08}, {0, 2.42, 0}, "Dark")
        g.box("CarryLoop", {0.5, 0.1, 0.15}, {0, 2.65, 0}, "Gold")
    elseif v == 4 then
        for i = 1, 12 do
            local a = i * pi / 6
            g.rod("SunburstRay", {math.sin(a) * 0.65, 1.7 + math.cos(a) * 0.65, 0}, {math.sin(a) * 1.5, 1.7 + math.cos(a) * 1.5, 0}, if i % 2 == 0 then 0.13 else 0.07, "Gold", "Metal")
        end
        clockFace(g, 0, 1.7, -0.1, 1.25, "Brass")
    elseif v == 5 then
        g.box("PendulumCase", {1.45, 3.5, 0.7}, {0, 1.8, 0}, "Walnut", nil, "Wood")
        g.box("PendulumWindow", {1.02, 1.3, 0.05}, {0, 1.05, -0.39}, "Dark")
        g.rod("PendulumRod", {0, 1.75, -0.44}, {0.18, 0.68, -0.44}, 0.06, "Gold", "Metal")
        g.disc("PendulumBob", 0.56, 0.08, {0.18, 0.65, -0.45}, "Gold", "Metal")
        clockFace(g, 0, 2.7, -0.41, 1.06)
        g.box("Crown", {1.7, 0.17, 0.83}, {0, 3.6, 0}, "Wood")
        g.box("Foot", {1.75, 0.17, 0.85}, {0, 0.085, 0}, "Wood")
    elseif v == 6 then
        g.face("FlipClockShell", 1.9, 1.15, 0.9, {0, 0.95, 0}, tint)
        for x = -1, 1, 2 do
            g.box("FlipPanel", {0.78, 0.82, 0.05}, {x * 0.43, 0.95, -0.49}, "Dark")
            g.box("PanelSplit", {0.75, 0.025, 0.03}, {x * 0.43, 0.95, -0.53}, "Silver")
            for _, dy in ipairs({-0.23, 0.23}) do g.box("DigitStroke", {0.3, 0.06, 0.025}, {x * 0.43, 0.95 + dy, -0.55}, "Ivory") end
            g.box("DigitSide", {0.06, 0.5, 0.025}, {x * 0.43 + 0.15, 0.95, -0.56}, "Ivory")
        end
        g.cyl("Pedestal", 0.22, 0.35, {0, 0.28, 0}, "Silver", "Metal")
        g.cyl("Stand", 1.55, 0.12, {0, 0.06, 0}, "Silver", "Metal")
    elseif v == 7 then
        g.disc("StationHousing", 2.65, 0.45, {0, 1.5, 0}, "Dark", "Metal")
        clockFace(g, 0, 1.5, -0.28, 2.3, "Dark")
        for i = 1, 8 do
            local a = i * pi / 4
            g.box("MinuteTick", {0.035, 0.13, 0.03}, {math.sin(a) * 0.96, 1.5 + math.cos(a) * 0.96, -0.44}, "Dark", {0, 0, -a})
        end
    elseif v == 8 then
        g.box("CarriageBody", {1.45, 2, 0.8}, {0, 1.2, 0}, "Brass", nil, "Metal")
        g.box("EnamelFront", {1.2, 1.65, 0.05}, {0, 1.22, -0.45}, "Ivory")
        clockFace(g, 0, 1.35, -0.49, 0.96, "Gold")
        g.feet(1.1, 0.5, 0.11, 0.22, "Gold")
        for x = -1, 1, 2 do g.box("HandleArm", {0.12, 0.4, 0.15}, {x * 0.44, 2.38, 0}, "Gold") end
        g.box("CarryHandle", {0.98, 0.12, 0.16}, {0, 2.58, 0}, "Gold")
    elseif v == 9 then
        g.cyl("OrbitalBase", 1.3, 0.15, {0, 0.075, 0}, "Dark")
        g.rod("OrbitalStem", {0, 0.15, 0}, {0, 1.45, 0}, 0.13, "Silver", "Metal")
        clockFace(g, 0, 1.7, -0.15, 1.4, "Silver")
        for i = 1, 8 do
            local a = i * pi / 4
            g.ball("OrbitMarker", {0.18, 0.18, 0.18}, {math.sin(a) * 1.15, 1.7 + math.cos(a) * 0.85, 0}, if i % 2 == 0 then "Coral" else "Mustard")
            local b = a + pi / 4
            g.rod("OrbitRing", {math.sin(a) * 1.15, 1.7 + math.cos(a) * 0.85, 0}, {math.sin(b) * 1.15, 1.7 + math.cos(b) * 0.85, 0}, 0.045, "Silver")
        end
    else
        g.ball("KittenBody", {1.55, 2.4, 0.65}, {0, 1.4, 0}, "Dark")
        g.ball("KittenHead", {1.45, 1.15, 0.7}, {0, 2.6, 0}, "Dark")
        for x = -1, 1, 2 do
            g.wedge("PointedEar", {0.45, 0.65, 0.5}, {x * 0.5, 3.12, 0}, "Dark", {0, if x == 1 then pi else 0, x * -0.15})
            g.ball("Eye", {0.3, 0.42, 0.06}, {x * 0.31, 2.72, -0.37}, "Ivory")
            g.ball("Pupil", {0.12, 0.25, 0.05}, {x * 0.31, 2.72, -0.42}, "Dark")
        end
        clockFace(g, 0, 1.42, -0.37, 1.18, "Silver")
        g.ball("Nose", {0.14, 0.12, 0.08}, {0, 2.45, -0.4}, "Rose")
        g.rod("SwingTail", {0.35, 0.7, 0.1}, {0.85, 0.15, 0.1}, 0.19, "Dark")
    end
end
local function chairs(g)
    local v, tint = g.Variant, g.Theme
    if v == 1 then
        for x = -1, 1, 2 do
            g.box("RockerRunner", {0.15, 0.18, 2.85}, {x * 0.83, 0.2, 0.08}, "Walnut", {0.08, 0, 0}, "Wood")
            g.rod("FrontLeg", {x * 0.83, 0.25, -0.78}, {x * 0.83, 1.45, -0.68}, 0.15, "Wood")
            g.rod("RearLeg", {x * 0.83, 0.25, 0.9}, {x * 0.83, 2.95, 0.75}, 0.15, "Wood")
            g.box("ArmRest", {0.22, 0.13, 1.65}, {x * 0.92, 2.05, -0.05}, "Wood", nil, "Wood")
            g.box("ArmSpindle", {0.1, 0.7, 0.1}, {x * 0.92, 1.72, -0.55}, "Wood")
        end
        g.box("WovenSeat", {1.8, 0.22, 1.65}, {0, 1.4, 0}, "Cream", nil, "Fabric")
        g.box("CrestRail", {1.95, 0.35, 0.17}, {0, 2.98, 0.77}, "Wood", nil, "Wood")
        for i = -2, 2 do g.rod("BackSpindle", {i * 0.32, 1.5, 0.7}, {i * 0.32, 2.8, 0.77}, 0.07, "Wood") end
    elseif v == 2 then
        g.box("SaddleSeat", {2.05, 0.22, 1.7}, {0, 1.4, 0}, "Wood", nil, "Wood")
        for x = -1, 1, 2 do for z = -1, 1, 2 do
            g.rod("SplayedLeg", {x * 0.65, 1.3, z * 0.6}, {x * 0.9, 0.05, z * 0.8}, 0.16, "Walnut")
        end end
        for i = -3, 3 do
            g.rod("WindsorSpindle", {i * 0.29, 1.5, 0.6}, {i * 0.29, 3.15 - math.abs(i) * 0.12, 0.8}, 0.075, "Wood")
        end
        g.face("HoopBack", 1.3, 0.22, 0.22, {0, 3.13, 0.8}, "Wood")
        g.rod("LegStretcher", {-0.75, 0.6, 0}, {0.75, 0.6, 0}, 0.12, "Walnut")
    elseif v == 3 then
        g.cyl("TulipFoot", 1.6, 0.15, {0, 0.075, 0}, "Ivory")
        g.cyl("Pedestal", 0.2, 1.1, {0, 0.7, 0}, "Ivory")
        g.ball("TulipShell", {2.15, 0.55, 1.95}, {0, 1.45, 0}, "Ivory")
        g.ball("ShellBack", {2.05, 1.65, 0.4}, {0, 2.13, 0.7}, "Ivory")
        g.ball("SoftSeat", {1.72, 0.25, 1.55}, {0, 1.64, -0.07}, tint, "Fabric")
        g.ball("BackPad", {1.65, 1.15, 0.18}, {0, 2.12, 0.46}, tint, "Fabric")
    elseif v == 4 then
        g.box("SchoolSeat", {1.95, 0.2, 1.7}, {0, 1.4, 0}, "Wood", nil, "Wood")
        g.box("PlywoodBack", {2.05, 0.8, 0.18}, {0, 2.55, 0.8}, "Wood", {0.08, 0, 0}, "Wood")
        for x = -1, 1, 2 do
            g.rod("FrontSteelLeg", {x * 0.78, 1.35, -0.6}, {x * 0.92, 0.07, -0.75}, 0.13, tint, "Metal")
            g.rod("RearSteelUpright", {x * 0.92, 0.07, 0.9}, {x * 0.78, 2.8, 0.8}, 0.13, tint, "Metal")
            g.ball("BackRivet", {0.075, 0.075, 0.06}, {x * 0.77, 2.55, 0.68}, "Silver")
        end
        g.rod("FrontBrace", {-0.8, 0.7, -0.65}, {0.8, 0.7, -0.65}, 0.1, tint)
    elseif v == 5 then
        g.box("LoungeSeatFrame", {2.4, 0.35, 2.2}, {0, 1.2, 0}, "Walnut", nil, "Wood")
        g.box("SeatCushion", {2.2, 0.42, 1.9}, {0, 1.5, -0.1}, tint, nil, "Fabric")
        g.box("ReclinedBack", {2.3, 1.7, 0.4}, {0, 2.15, 0.87}, "Walnut", {-0.22, 0, 0}, "Wood")
        g.box("LoungeBackCushion", {2.1, 1.5, 0.35}, {0, 2.2, 0.6}, tint, {-0.22, 0, 0}, "Fabric")
        for x = -1, 1, 2 do
            g.box("WideArm", {0.25, 0.22, 2}, {x * 1.25, 1.9, 0}, "Walnut", nil, "Wood")
            g.rod("AngledFrontLeg", {x * 1.05, 1.3, -0.7}, {x * 1.3, 0.08, -0.9}, 0.17, "Walnut")
            g.rod("AngledRearLeg", {x * 1.05, 1.2, 0.6}, {x * 1.3, 0.08, 1}, 0.17, "Walnut")
        end
        for x = -1, 1, 2 do g.ball("TuftButton", {0.12, 0.12, 0.05}, {x * 0.45, 2.3, 0.37}, tint) end
    elseif v == 6 then
        g.cyl("BistroSeat", 1.85, 0.17, {0, 1.45, 0}, tint)
        for x = -1, 1, 2 do
            g.rod("FrontLeg", {x * 0.5, 1.4, -0.45}, {x * 0.8, 0.06, -0.7}, 0.1, "Dark", "Metal")
            g.rod("BentwoodBack", {x * 0.7, 0.06, 0.75}, {x * 0.7, 2.95, 0.65}, 0.12, "Dark", "Metal")
        end
        g.face("BistroHoop", 0.9, 0.18, 0.17, {0, 2.97, 0.65}, "Dark")
        g.box("BistroBackSlat", {1.45, 0.32, 0.12}, {0, 2.4, 0.63}, tint)
        g.rod("CrossBraceA", {-0.65, 0.65, -0.5}, {0.65, 0.65, 0.6}, 0.09, "Dark")
        g.rod("CrossBraceB", {0.65, 0.65, -0.5}, {-0.65, 0.65, 0.6}, 0.09, "Dark")
    elseif v == 7 then
        g.box("VelvetSeat", {2.3, 0.5, 2}, {0, 1.3, 0}, tint, nil, "Fabric")
        g.ball("WingBack", {2.3, 2.3, 0.65}, {0, 2.3, 0.75}, tint, "Fabric")
        for x = -1, 1, 2 do
            g.ball("RolledArm", {0.55, 0.65, 1.95}, {x * 1.05, 1.8, 0}, tint, "Fabric")
            for z = -1, 1, 2 do g.rod("TaperedLeg", {x * 0.85, 1.1, z * 0.7}, {x * 1, 0.06, z * 0.85}, 0.14, "Gold", "Metal") end
        end
        for y = 1, 2 do for x = -1, 1, 2 do g.ball("UpholsteryButton", {0.12, 0.12, 0.05}, {x * 0.45, 1.7 + y * 0.5, 0.43}, "Gold") end end
    elseif v == 8 then
        g.cyl("RattanSeat", 2.05, 0.2, {0, 1.3, 0}, "Wood", "Wood")
        for x = -1, 1, 2 do
            g.rod("RattanRearLeg", {x * 0.78, 0.06, 0.7}, {x * 0.78, 3.05, 0.6}, 0.12, "Wood")
            g.rod("RattanFrontLeg", {x * 0.78, 0.06, -0.7}, {x * 0.78, 1.5, -0.7}, 0.12, "Wood")
        end
        g.face("ArchedCaneBack", 1.1, 0.22, 0.15, {0, 3.08, 0.6}, "Wood")
        for i = -2, 2 do g.rod("CaneSpoke", {i * 0.24, 1.45, 0.6}, {i * 0.33, 2.95, 0.6}, 0.045, "Cream") end
        for y = 1, 4 do g.box("WovenCane", {1.5, 0.035, 0.07}, {0, 1.55 + y * 0.27, 0.57}, "Cream") end
        g.ball("LinenCushion", {1.6, 0.22, 1.5}, {0, 1.48, -0.07}, "Ivory", "Fabric")
    elseif v == 9 then
        g.cyl("RocketFoot", 1.9, 0.18, {0, 0.09, 0}, "Silver", "Metal")
        g.cyl("ChromeLift", 0.26, 1.15, {0, 0.75, 0}, "Silver", "Metal")
        g.ball("SpaceSeat", {2.15, 0.58, 1.9}, {0, 1.45, 0}, tint)
        g.ball("RocketBack", {1.95, 2.2, 0.7}, {0, 2.3, 0.7}, tint)
        g.ball("VisorCushion", {1.45, 1.35, 0.17}, {0, 2.3, 0.34}, "Dark")
        for x = -1, 1, 2 do
            g.wedge("WingArm", {0.6, 0.85, 1.5}, {x * 1.15, 1.75, 0}, "Silver", {0, if x == -1 then pi else 0, 0})
            g.disc("ArmSignal", 0.2, 0.07, {x * 1.13, 1.65, -0.76}, "Coral", "Neon")
        end
    else
        g.box("DollSeat", {1.65, 0.2, 1.4}, {0, 1, 0}, "Rose")
        g.box("DollBack", {1.7, 1.3, 0.2}, {0, 1.8, 0.6}, "Rose")
        g.feet(1.3, 1, 0.46, 0.92, "Ivory")
        g.ball("HeartLobeL", {0.42, 0.45, 0.06}, {-0.15, 1.92, 0.47}, "Ivory")
        g.ball("HeartLobeR", {0.42, 0.45, 0.06}, {0.15, 1.92, 0.47}, "Ivory")
        g.box("HeartPoint", {0.4, 0.4, 0.06}, {0, 1.75, 0.47}, "Ivory", {0, 0, pi / 4})
        g.ball("FlowerCushion", {1.25, 0.18, 1}, {0, 1.16, -0.05}, "Cream", "Fabric")
    end
end
local function toys(g)
    local v, tint = g.Variant, g.Theme
    if v == 1 then
        g.box("TinTorso", {1.35, 1.25, 0.8}, {0, 1.25, 0}, tint, nil, "Metal")
        g.box("RobotHead", {1.1, 0.8, 0.8}, {0, 2.32, 0}, "Silver", nil, "Metal")
        for x = -1, 1, 2 do
            g.disc("RobotEye", 0.24, 0.06, {x * 0.28, 2.42, -0.44}, "Mustard", "Neon")
            g.box("Arm", {0.32, 1.12, 0.4}, {x * 0.91, 1.27, 0}, "Silver", {0, 0, -x * 0.12}, "Metal")
            g.ball("Claw", {0.4, 0.4, 0.4}, {x * 0.99, 0.75, 0}, "Dark")
            g.box("Leg", {0.3, 0.6, 0.37}, {x * 0.38, 0.45, 0}, "Silver", nil, "Metal")
            g.box("Boot", {0.58, 0.25, 0.75}, {x * 0.38, 0.13, -0.12}, "Dark")
        end
        g.box("MouthGrille", {0.6, 0.12, 0.05}, {0, 2.12, -0.44}, "Dark")
        g.box("ChestPanel", {0.85, 0.65, 0.06}, {0, 1.3, -0.44}, "Dark")
        g.knobs(1.3, -0.5, 3, 0.24, "Coral")
        g.rod("Aerial", {0, 2.7, 0}, {0, 3.05, 0}, 0.06, "Silver")
        g.ball("AerialTip", {0.18, 0.18, 0.18}, {0, 3.09, 0}, "Coral")
    elseif v == 2 then
        g.box("TrainChassis", {2.65, 0.25, 1.05}, {0, 0.52, 0}, "Dark")
        g.box("EngineBoiler", {1.5, 0.75, 0.85}, {-0.38, 1.02, 0}, tint)
        g.box("Cab", {0.85, 1.15, 1.05}, {0.87, 1.35, 0}, "Coral")
        g.box("CabRoof", {1.02, 0.15, 1.25}, {0.87, 1.98, 0}, "Dark")
        g.box("CabWindow", {0.53, 0.48, 0.05}, {0.87, 1.47, -0.56}, "Glass")
        g.cyl("Chimney", 0.3, 0.5, {-0.78, 1.65, 0}, "Dark")
        g.cyl("ChimneyLip", 0.43, 0.13, {-0.78, 1.91, 0}, "Gold")
        for z = -1, 1, 2 do for i = -1, 1 do g.disc("TrainWheel", 0.65, 0.12, {i * 0.85, 0.36, z * 0.62}, "Gold"); g.disc("WheelHub", 0.2, 0.14, {i * 0.85, 0.36, z * 0.66}, "Dark") end end
        g.box("Coupler", {0.3, 0.13, 0.24}, {-1.55, 0.52, 0}, "Silver")
    elseif v == 3 then
        g.ball("TeddyBody", {1.35, 1.6, 0.95}, {0, 1.03, 0}, "Wood", "Fabric")
        g.ball("TeddyHead", {1.42, 1.22, 1.1}, {0, 2.05, 0}, "Wood", "Fabric")
        g.ball("BellyPatch", {0.85, 1, 0.15}, {0, 1, -0.46}, "Cream", "Fabric")
        g.ball("Muzzle", {0.73, 0.5, 0.28}, {0, 1.92, -0.55}, "Cream", "Fabric")
        for x = -1, 1, 2 do
            g.ball("RoundEar", {0.52, 0.52, 0.35}, {x * 0.57, 2.55, 0}, "Wood", "Fabric")
            g.ball("EarInner", {0.3, 0.3, 0.08}, {x * 0.57, 2.56, -0.18}, "Cream")
            g.ball("ButtonEye", {0.13, 0.15, 0.1}, {x * 0.28, 2.21, -0.51}, "Dark")
            g.ball("Arm", {0.5, 1.15, 0.5}, {x * 0.77, 1.12, 0}, "Wood", "Fabric").Rotation = {0, 0, -x * 0.25}
            g.ball("Foot", {0.6, 0.65, 0.85}, {x * 0.45, 0.33, -0.15}, "Wood", "Fabric")
        end
        g.ball("ButtonNose", {0.21, 0.16, 0.13}, {0, 2, -0.73}, "Dark")
        g.box("BowTie", {0.65, 0.21, 0.12}, {0, 1.55, -0.45}, "Coral")
    elseif v == 4 then
        g.cyl("RocketBody", 0.96, 1.85, {0, 1.55, 0}, "Ivory")
        g.ball("PointedNose", {0.96, 1.2, 0.96}, {0, 2.57, 0}, "Coral")
        g.cyl("AccentBand", 1.02, 0.16, {0, 2.12, 0}, tint)
        g.disc("PortholeRim", 0.52, 0.08, {0, 1.7, -0.48}, "Gold")
        g.disc("PortholeGlass", 0.36, 0.05, {0, 1.7, -0.54}, "Blue", "Glass")
        for i = 1, 3 do
            local a = i * 2 * pi / 3
            g.wedge("RocketFin", {0.14, 1.1, 0.85}, {math.sin(a) * 0.55, 0.66, math.cos(a) * 0.55}, tint, {0, a, 0})
        end
        g.cyl("EngineNozzle", 0.65, 0.35, {0, 0.45, 0}, "Dark")
    elseif v == 5 then
        g.cyl("CarouselBase", 2.45, 0.28, {0, 0.14, 0}, tint)
        g.cyl("GildedPlatform", 2.25, 0.13, {0, 0.35, 0}, "Gold")
        g.cyl("CenterPole", 0.22, 2.05, {0, 1.4, 0}, "Gold")
        g.ball("StripedCanopy", {2.65, 0.75, 2.65}, {0, 2.55, 0}, "Coral")
        g.cyl("CanopyFringe", 2.45, 0.18, {0, 2.35, 0}, "Cream")
        g.ball("CrownFinial", {0.22, 0.35, 0.22}, {0, 3.05, 0}, "Gold")
        for i = 1, 3 do
            local a = i * 2 * pi / 3
            local x, z = math.cos(a) * 0.78, math.sin(a) * 0.78
            g.cyl("HorsePole", 0.06, 1.85, {x, 1.4, z}, "Gold")
            g.ball("PonyBody", {0.55, 0.3, 0.25}, {x, 1.15, z}, "Ivory")
            g.ball("PonyHead", {0.23, 0.4, 0.22}, {x - 0.23, 1.38, z}, "Ivory")
            g.box("Saddle", {0.26, 0.08, 0.28}, {x, 1.32, z}, tint)
            for dx = -1, 1, 2 do g.box("PonyLeg", {0.08, 0.3, 0.1}, {x + dx * 0.17, 0.94, z}, "Ivory") end
        end
    elseif v == 6 then
        g.box("DollhouseBody", {2.25, 2.25, 1.1}, {0, 1.25, 0}, "Rose")
        g.box("RoofL", {1.65, 0.18, 1.35}, {-0.61, 2.7, 0}, "Teal", {0, 0, 0.5})
        g.box("RoofR", {1.65, 0.18, 1.35}, {0.61, 2.7, 0}, "Teal", {0, 0, -0.5})
        for x = -1, 1, 2 do for y = 1, 2 do
            g.box("WindowFrame", {0.63, 0.67, 0.08}, {x * 0.62, y * 0.95, -0.59}, "Ivory")
            g.box("WindowPane", {0.43, 0.48, 0.05}, {x * 0.62, y * 0.95, -0.65}, "Blue")
            g.box("WindowMullion", {0.04, 0.48, 0.04}, {x * 0.62, y * 0.95, -0.69}, "Ivory")
        end end
        g.box("FrontDoor", {0.43, 0.77, 0.06}, {0, 0.55, -0.6}, "Teal")
        g.ball("DoorKnob", {0.08, 0.08, 0.08}, {0.1, 0.55, -0.66}, "Gold")
        g.box("Chimney", {0.3, 0.7, 0.35}, {0.75, 3, 0.2}, "Cream")
        g.box("Porch", {2.55, 0.15, 1.5}, {0, 0.075, 0}, "Ivory")
    elseif v == 7 then
        g.ball("RacecarBody", {2.75, 0.7, 1.15}, {0, 0.65, 0}, "Coral")
        g.box("RacingStripe", {2.2, 0.035, 0.2}, {0, 0.98, 0}, "Ivory")
        g.ball("Cockpit", {0.85, 0.55, 0.75}, {0.3, 1, 0}, "Dark")
        g.ball("Windscreen", {0.35, 0.35, 0.7}, {-0.05, 1.1, 0}, "Glass", "Glass").Transparency = 0.3
        for x = -1, 1, 2 do for z = -1, 1, 2 do
            g.disc("Tire", 0.67, 0.2, {x * 0.87, 0.36, z * 0.65}, "Dark")
            g.disc("SpokeHub", 0.36, 0.22, {x * 0.87, 0.36, z * 0.67}, "Silver", "Metal")
        end end
        g.box("RearSpoiler", {0.12, 0.12, 1.65}, {1.1, 1.2, 0}, "Ivory")
        g.box("SpoilerSupport", {0.12, 0.4, 0.16}, {1.1, 1, 0}, "Dark")
    elseif v == 8 then
        g.ball("DuckBody", {1.8, 1.25, 1.5}, {0, 0.88, 0}, "Mustard")
        g.ball("DuckHead", {1.05, 1.05, 1.05}, {-0.4, 1.75, -0.1}, "Mustard")
        g.ball("DuckBill", {0.75, 0.27, 0.5}, {-0.85, 1.6, -0.17}, "Coral")
        g.ball("Wing", {0.9, 0.7, 0.15}, {0.25, 0.95, -0.72}, "Cream")
        for z = -1, 1, 2 do g.ball("DuckEye", {0.13, 0.16, 0.1}, {-0.65, 1.91, z * 0.42}, "Dark") end
        g.box("PullCart", {2.05, 0.15, 1.2}, {0, 0.26, 0}, "Teal")
        for x = -1, 1, 2 do for z = -1, 1, 2 do g.disc("WoodenWheel", 0.4, 0.15, {x * 0.65, 0.22, z * 0.65}, "Coral") end end
        g.rod("PullString", {-1, 0.35, 0}, {-1.6, 0.12, 0}, 0.025, "Ivory")
    elseif v == 9 then
        g.ball("Fuselage", {2.8, 0.65, 0.65}, {0, 0.94, 0}, tint)
        g.box("MainWing", {1.02, 0.11, 2.9}, {-0.2, 1.03, 0}, "Cream")
        g.box("UpperWing", {0.95, 0.11, 2.7}, {-0.2, 1.58, 0}, "Cream")
        for z = -1, 1, 2 do g.rod("WingStrut", {-0.25, 1.05, z * 0.95}, {-0.25, 1.55, z * 0.95}, 0.055, "Gold") end
        g.box("TailWing", {0.5, 0.08, 1.15}, {1.13, 1, 0}, "Coral")
        g.wedge("TailFin", {0.08, 0.65, 0.6}, {1.05, 1.23, 0}, "Coral", {0, pi / 2, 0})
        g.box("Propeller", {0.08, 1.05, 0.13}, {-1.42, 0.94, 0}, "Dark", {0.3, 0, 0})
        g.ball("Spinner", {0.24, 0.24, 0.24}, {-1.46, 0.94, 0}, "Gold")
        for z = -1, 1, 2 do g.disc("LandingWheel", 0.48, 0.14, {-0.6, 0.28, z * 0.45}, "Dark"); g.rod("LandingStrut", {-0.4, 0.85, 0}, {-0.6, 0.3, z * 0.45}, 0.07, "Silver") end
    else
        g.ball("DinosaurBody", {1.6, 1.15, 1}, {0, 1.15, 0}, "Mint")
        g.ball("LongNeck", {0.55, 1.5, 0.55}, {-0.68, 2, 0}, "Mint").Rotation = {0, 0, -0.15}
        g.ball("DinosaurHead", {0.85, 0.5, 0.65}, {-0.9, 2.77, 0}, "Mint")
        for x = -1, 1, 2 do for z = -1, 1, 2 do g.ball("StumpyLeg", {0.38, 0.9, 0.38}, {x * 0.52, 0.49, z * 0.36}, "Teal") end end
        g.rod("Tail", {0.55, 1.15, 0}, {1.55, 0.7, 0}, 0.27, "Mint")
        for i = 1, 4 do g.wedge("BackPlate", {0.16, 0.32, 0.3}, {-0.55 + i * 0.34, 1.85, 0}, "Mustard", {0, pi / 2, 0}) end
        for z = -1, 1, 2 do g.ball("FriendlyEye", {0.12, 0.15, 0.08}, {-1.02, 2.85, z * 0.29}, "Dark") end
    end
end
local function mirrorInset(g, x, y, z, w, h, shape)
    local pane = if shape == "Oval" then g.ball("SilveredMirror", {w, h, 0.06}, {x, y, z}, "Glass", "Glass")
        else g.box("SilveredMirror", {w, h, 0.06}, {x, y, z}, "Glass", nil, "Glass")
    pane.Reflectance = 0.38
    -- Reflection streaks stay readable in a thumbnail and work in ViewportFrames.
    g.box("MirrorGlint", {0.045, h * 0.38, 0.025}, {x - w * 0.19, y + h * 0.12, z - 0.055}, "Ivory", {0, 0, -0.32})
    g.box("MirrorGlintShort", {0.035, h * 0.16, 0.025}, {x - w * 0.05, y + h * 0.24, z - 0.055}, "Ivory", {0, 0, -0.32})
end
local function mirrors(g)
    local v, tint = g.Variant, g.Theme
    if v == 1 then
        g.ball("OvalFrame", {2.1, 3.1, 0.2}, {0, 1.65, 0}, "Wood", "Wood")
        mirrorInset(g, 0, 1.65, -0.14, 1.78, 2.76, "Oval")
        for y = -1, 1, 2 do g.ball("FrameRosette", {0.26, 0.26, 0.14}, {0, 1.65 + y * 1.45, -0.08}, "Gold") end
    elseif v == 2 then
        for i = 1, 16 do
            local a = i * pi / 8
            g.rod("SunRay", {math.sin(a) * 0.8, 1.65 + math.cos(a) * 0.8, 0}, {math.sin(a) * (if i % 2 == 0 then 1.5 else 1.25), 1.65 + math.cos(a) * (if i % 2 == 0 then 1.5 else 1.25), 0}, 0.09, "Gold", "Metal")
        end
        g.disc("SunBezel", 1.72, 0.15, {0, 1.65, -0.03}, "Gold")
        mirrorInset(g, 0, 1.65, -0.15, 1.48, 1.48, "Oval")
    elseif v == 3 then
        g.cyl("VanityBase", 1.65, 0.18, {0, 0.09, 0}, "Brass", "Metal")
        g.cyl("VanityStem", 0.12, 0.6, {0, 0.47, 0}, "Brass", "Metal")
        g.disc("RoundVanityFrame", 1.9, 0.2, {0, 1.8, 0}, "Gold", "Metal")
        mirrorInset(g, 0, 1.8, -0.14, 1.63, 1.63, "Oval")
        for x = -1, 1, 2 do
            g.rod("TiltArm", {x * 0.55, 0.45, 0}, {x * 1.05, 1.8, 0}, 0.09, "Gold")
            g.ball("TiltPivot", {0.2, 0.2, 0.22}, {x * 1.03, 1.8, 0}, "Brass")
        end
    elseif v == 4 then
        g.box("ArchLower", {2, 2.2, 0.22}, {0, 1.16, 0}, "Dark")
        g.ball("ArchCrown", {2, 1.7, 0.22}, {0, 2.26, 0}, "Dark")
        mirrorInset(g, 0, 1.26, -0.15, 1.72, 2.12)
        mirrorInset(g, 0, 2.28, -0.15, 1.72, 1.4, "Oval")
        g.box("Crossbar", {1.76, 0.06, 0.07}, {0, 1.5, -0.23}, "Dark")
        g.box("Mullion", {0.06, 2.6, 0.07}, {0, 1.6, -0.23}, "Dark")
    elseif v == 5 then
        g.disc("PocketCompact", 1.55, 0.2, {0, 1.35, 0}, "Rose")
        mirrorInset(g, 0, 1.35, -0.14, 1.3, 1.3, "Oval")
        g.box("EngravedHandle", {0.29, 0.8, 0.17}, {0, 0.41, 0}, "Gold", {0, 0, 0.06}, "Metal")
        g.ball("HandleJewel", {0.18, 0.26, 0.1}, {0, 0.35, -0.12}, tint)
        g.ball("CrownBowL", {0.5, 0.25, 0.17}, {-0.2, 2.1, 0}, "Gold")
        g.ball("CrownBowR", {0.5, 0.25, 0.17}, {0.2, 2.1, 0}, "Gold")
    elseif v == 6 then
        g.box("GildedFrame", {2.2, 2.85, 0.23}, {0, 1.55, 0}, "Gold", nil, "Metal")
        mirrorInset(g, 0, 1.55, -0.15, 1.76, 2.38)
        for x = -1, 1, 2 do for y = -1, 1, 2 do
            g.ball("CornerScroll", {0.4, 0.48, 0.2}, {x * 0.98, 1.55 + y * 1.3, -0.07}, "Brass")
            g.ball("ScrollPearl", {0.18, 0.18, 0.17}, {x * 0.93, 1.55 + y * 1.25, -0.18}, "Cream")
        end end
        for x = -1, 1, 2 do g.box("InnerGilt", {0.055, 2.55, 0.05}, {x * 0.93, 1.55, -0.19}, "Mustard") end
    elseif v == 7 then
        for _, data in ipairs({{-0.78, 1.6, 1.1}, {-0.25, 2.1, 1.35}, {0.48, 2.06, 1.4}, {1, 1.55, 0.9}}) do
            g.ball("CloudFrame", {data[3], data[3], 0.25}, {data[1], data[2], 0}, "Ivory")
            mirrorInset(g, data[1], data[2], -0.16, data[3] - 0.17, data[3] - 0.17, "Oval")
        end
        g.box("CloudBottom", {2.2, 0.45, 0.25}, {0.02, 1.25, 0}, "Ivory")
        g.box("MirrorBottom", {1.95, 0.3, 0.06}, {0.02, 1.3, -0.16}, "Glass", nil, "Glass").Reflectance = 0.38
    elseif v == 8 then
        for i = 1, 5 do
            local a = i * 2 * pi / 5
            g.box("StarPoint", {0.65, 1.5, 0.2}, {math.sin(a) * 0.62, 1.65 + math.cos(a) * 0.62, 0}, "Gold", {0, 0, -a})
        end
        g.disc("StarCenter", 1.8, 0.23, {0, 1.65, 0}, "Gold")
        mirrorInset(g, 0, 1.65, -0.16, 1.4, 1.4, "Oval")
    elseif v == 9 then
        g.ball("ShellFrame", {2.6, 2.4, 0.28}, {0, 1.45, 0}, "Rose")
        for i = -3, 3 do
            local a = i * 0.26
            g.rod("ShellRib", {0, 0.42, -0.17}, {math.sin(a) * 1.3, 1.45 + math.cos(a) * 1.15, -0.17}, 0.065, "Cream")
        end
        mirrorInset(g, 0, 1.55, -0.24, 1.65, 1.65, "Oval")
        g.ball("ShellFoot", {0.8, 0.37, 0.4}, {0, 0.2, 0}, "Cream")
    else
        g.ball("HeartFrameL", {1.4, 1.5, 0.25}, {-0.52, 2.03, 0}, "Rose")
        g.ball("HeartFrameR", {1.4, 1.5, 0.25}, {0.52, 2.03, 0}, "Rose")
        g.box("HeartFramePoint", {1.55, 1.55, 0.25}, {0, 1.4, 0}, "Rose", {0, 0, pi / 4})
        g.ball("HeartMirrorL", {1.12, 1.24, 0.06}, {-0.46, 2.03, -0.16}, "Glass", "Glass").Reflectance = 0.38
        g.ball("HeartMirrorR", {1.12, 1.24, 0.06}, {0.46, 2.03, -0.16}, "Glass", "Glass").Reflectance = 0.38
        g.box("HeartMirrorPoint", {1.26, 1.26, 0.06}, {0, 1.45, -0.16}, "Glass", {0, 0, pi / 4}, "Glass").Reflectance = 0.38
        g.box("HeartGlint", {0.05, 0.65, 0.03}, {-0.45, 2.05, -0.22}, "Ivory", {0, 0, -0.3})
    end
end
