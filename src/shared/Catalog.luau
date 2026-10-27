-- Fashion finds selected from Roblox's public catalog. Catalog IDs are used for
-- attribution and thumbnails; the playable 3D replicas are bundled with the game.
local Catalog = {}
local styles = {"Vintage", "Preppy", "Streetwear", "Designer", "Y2K"}
local categories = {
    {"T-Shirts", "Scrub", 18, "tshirts", {
        {"Black Logo Tee",7178736794},{"Gray Everyday Tee",9112474888},{"White Logo Tee",7178737816},
        {"Black Striped Tee",9119670803},{"White Striped Tee",9112483644},{"Golden Music Tee",9252603398},
        {"Simple Pattern Tee",3670737444},{"Pizza Graphic Tee",4047884939},{"Heart Pizza Tee",382537085},{"Teal Classic Tee",382537702},
    }},
    {"Shirts", "Polish", 24, "shirts", {
        {"Blue Plaid Shirt",398635081},{"Moto Shirt",144076358},{"Denim Layer Shirt",144076436},
        {"Pastel Layered Shirt",398634295},{"Purple Teal Top",4047886060},{"White Tie Front Top",9240752338},
        {"Blue Tie Front Top",9174384558},{"Classic Zip Shirt",607785314},{"Denim Hoodie Shirt",398633584},{"Guitar Layer Shirt",4047884046},
    }},
    {"Pants", "Assemble", 28, "pants", {
        {"Ripped Skater Pants",398635338},{"Black Wetsuit Pants",9120251003},{"Brown Cargo Pants",6984740059},
        {"White Leather Pants",7192681239},{"Brown Moto Pants",8721985925},{"Black Jeans White Shoes",398633812},
        {"Classic Blue Jeans",398634487},{"Dark Green Jeans",144076760},{"Black Sneaker Jeans",382538503},{"Everyday Black Jeans",382537569},
    }},
    {"Shorts", "Repaint", 22, "shorts", {
        {"Jean Shorts White Shoes",382537950},{"Black Bermuda Shorts",9174391966},{"Classic Jean Shorts",382537806},
        {"Light Wash Jean Shorts",7192687500},{"Light Blue Bermuda Shorts",9274782406},{"Red Basketball Shorts",7192689453},
        {"Lime Boxing Shorts",7231091126},{"Salmon Bermuda Shorts",9240765837},{"Mint Bermuda Shorts",9240767370},{"Blue Basketball Shorts",7192688494},
    }},
    {"Jackets", "Rewire", 36, "jackets", {
        {"Classic Zip Jacket",607785314},{"Denim White Hoodie",398633584},{"Pastel Star Jacket",398634295},
        {"Black Leather Jacket",7192549218},{"Light Wash Denim Jacket",8516609675},{"Gray Hooded Jacket",8516620262},
        {"White Denim Jacket",8516612751},{"Black Guitar Jacket",4047884046},{"White Collared Jacket",7192546798},{"Brown Leather Jacket",6984767443},
    }},
    {"Dresses", "Polish", 34, "dresses", {
        {"Red Evening Dress",11821648884},{"Floral Day Dress",10896900057},{"White Ruffle Dress",9240776381},
        {"Pink Chiffon Dress",9240772455},{"Red Ruffle Dress",7192696851},{"Blue Chiffon Dress",7192691582},
        {"Beige Knit Dress",6984769289},{"Pink Knit Dress",6984771334},{"Black Knit Dress",9240757332},{"Gray Knit Dress",9240758221},
    }},
    {"Shoes", "Assemble", 26, "shoes", {
        {"White Canvas Shoes",894,"BundleThumbnail"},{"Gray Canvas Shoes",905,"BundleThumbnail"},{"Black Dress Shoes",907,"BundleThumbnail"},
        {"Red Running Shoes",895,"BundleThumbnail"},{"Pink Canvas Shoes",877,"BundleThumbnail"},{"Black Running Shoes",926,"BundleThumbnail"},
        {"Blue Running Shoes",921,"BundleThumbnail"},{"Blue Canvas Shoes",881,"BundleThumbnail"},{"White Running Shoes",903,"BundleThumbnail"},{"Black Purple Canvas Shoes",931,"BundleThumbnail"},
    }},
    {"Accessories", "Repaint", 20, "accessories", {
        {"Paper Bucket Hat",10476359},{"Black Cowboy Hat",425117435},{"Umbrella Hat",10658698},
        {"Gray Winter Hat",105354517},{"Cheese Hat",1097026},{"Candy Scarf Hat",562493075},
        {"Nurse Cap",10770260},{"Ranger Hat",13335289},{"Blue Top Hat",1016145591},{"Eternal Top Hat",835066603},
    }},
}
Catalog.Items, Catalog.ById, Catalog.Categories = {}, {}, {}
for categoryIndex, group in ipairs(categories) do
    table.insert(Catalog.Categories, group[1])
    for index, choice in ipairs(group[5]) do
        local item = {Id = group[4] .. "_" .. index, Name = choice[1], Category = group[1], Minigame = group[2],
            BaseValue = group[3] + index * 4, Style = styles[(index + categoryIndex - 2) % #styles + 1],
            UnlockLevel = math.max(1, categoryIndex - 2), Variant = index,
            CatalogAssetId = choice[2], CatalogItemType = choice[3] or "Asset", CatalogCreator = "Roblox"}
        table.insert(Catalog.Items, item); Catalog.ById[item.Id] = item
    end
end
-- Alias legacy IDs for exchange recovery and old server handoff payloads.
local legacy = {lamps="tshirts", radios="shirts", clocks="pants", chairs="shorts", toys="jackets", mirrors="dresses", cameras="shoes", vases="accessories"}
for old, current in pairs(legacy) do for index = 1, 10 do Catalog.ById[old .. "_" .. index] = Catalog.ById[current .. "_" .. index] end end
return Catalog
