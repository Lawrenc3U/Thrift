-- Pure placement geometry used by the server and optional client previews.
local Placement = {}
Placement.Bounds = {MinX = -12, MaxX = 12, MinZ = -12, MaxZ = 9}
Placement.Footprints = {Rug = {X = 14, Z = 11, Flat = true}, Plant = {X = 2.4, Z = 2.4}, Trophy = {X = 2.6, Z = 2.6}}
Placement.Defaults = {Rug = {X = 0, Z = -1, Rotation = 0}, Plant = {X = -10, Z = -9, Rotation = 0}, Trophy = {X = 10, Z = 7, Rotation = 0}}
local function finite(value) return type(value) == "number" and value == value and math.abs(value) < math.huge end
local function extent(footprint, rotation)
    if rotation == 90 or rotation == 270 then return footprint.Z / 2, footprint.X / 2 end
    return footprint.X / 2, footprint.Z / 2
end
local function overlap(a, ax, az, b, bx, bz)
    return math.abs(a.X - b.X) < ax + bx - 0.05 and math.abs(a.Z - b.Z) < az + bz - 0.05
end
function Placement.validate(id, proposed, layout, placed, slots)
    local footprint = Placement.Footprints[id]
    if not footprint then return false, "This decoration stays on its wall mount." end
    if type(proposed) ~= "table" or not finite(proposed.X) or not finite(proposed.Z) or not finite(proposed.Rotation) then return false, "Choose a position inside your shop." end
    if not table.find({0, 90, 180, 270}, proposed.Rotation) then return false, "Rotate in quarter turns." end
    local hx, hz = extent(footprint, proposed.Rotation)
    local bounds = Placement.Bounds
    if proposed.X - hx < bounds.MinX or proposed.X + hx > bounds.MaxX or proposed.Z - hz < bounds.MinZ or proposed.Z + hz > bounds.MaxZ then return false, "Keep the whole decoration inside the floor plan." end
    if not footprint.Flat then
        for slot = 1, slots do
            local col, row = (slot - 1) % 4, math.floor((slot - 1) / 4)
            if overlap(proposed, hx, hz, {X = -9 + col * 6, Z = -4 + row * 3.5}, 2.1, 1.35) then return false, "Leave room around the display furniture." end
        end
        -- Service counter; workbench is behind the editable area.
        if overlap(proposed, hx, hz, {X = 8, Z = -8}, 3.5, 1.5) then return false, "Keep the counter clear." end
        for other, otherFootprint in pairs(Placement.Footprints) do
            if other ~= id and not otherFootprint.Flat and placed[other] then
                local position = layout[other] or Placement.Defaults[other]
                local ox, oz = extent(otherFootprint, position.Rotation)
                if overlap(proposed, hx, hz, position, ox, oz) then return false, "That overlaps another decoration." end
            end
        end
    end
    return true, {X = math.round(proposed.X * 2) / 2, Z = math.round(proposed.Z * 2) / 2, Rotation = proposed.Rotation}
end
return Placement
