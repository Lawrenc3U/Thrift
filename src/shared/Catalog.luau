local Catalog = {}
local categories = {
    {"Lamps", "Scrub", 22, {"Tulip", "Banker", "Mushroom", "Arc", "Lantern", "Desk", "Lava", "Tiffany", "Studio", "Moon"}},
    {"Radios", "Rewire", 28, {"Pocket", "Bakelite", "Boombox", "Cathedral", "Transistor", "Space", "Kitchen", "Travel", "Jukebox", "Crystal"}},
    {"Clocks", "Assemble", 25, {"Cuckoo", "Mantel", "Alarm", "Sunburst", "Pendulum", "Flip", "Station", "Carriage", "Orbital", "Kitten"}},
    {"Chairs", "Repaint", 32, {"Rocking", "Windsor", "Tulip", "School", "Lounge", "Bistro", "Velvet", "Rattan", "Rocket", "Doll"}},
    {"Toys", "Assemble", 18, {"Robot", "Train", "Teddy", "Rocket", "Carousel", "Dollhouse", "Racecar", "Duck", "Airplane", "Dinosaur"}},
    {"Mirrors", "Polish", 24, {"Oval", "Sun", "Vanity", "Arch", "Pocket", "Gilded", "Cloud", "Star", "Shell", "Heart"}},
    {"Cameras", "Rewire", 30, {"Box", "Instant", "Twin Lens", "Pocket", "Bellows", "Rangefinder", "Studio", "Movie", "Underwater", "Toy"}},
    {"Vases", "Polish", 20, {"Bud", "Ginger", "Amphora", "Bubble", "Fluted", "Swan", "Geometric", "Rose", "Celadon", "Moon"}},
}
Catalog.Items = {}
Catalog.ById = {}
Catalog.Categories = {}
for categoryIndex, group in ipairs(categories) do
    table.insert(Catalog.Categories, group[1])
    for index, name in ipairs(group[4]) do
        local item = {
            Id = string.lower(group[1]) .. "_" .. index,
            Name = name .. " " .. string.sub(group[1], 1, #group[1] - 1),
            Category = group[1], Minigame = group[2],
            BaseValue = group[3] + index * 4,
            Style = ({"Retro", "Cozy", "Futuristic", "Antique", "Cute"})[(index + categoryIndex - 2) % 5 + 1],
            UnlockLevel = math.max(1, categoryIndex - 2),
            Variant = index,
        }
        table.insert(Catalog.Items, item)
        Catalog.ById[item.Id] = item
    end
end
return Catalog
