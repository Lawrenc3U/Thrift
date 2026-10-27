-- Fashion finds selected from Roblox's public catalog. Catalog IDs are used for
-- attribution and thumbnails; the playable 3D replicas are bundled with the game.
local Catalog = {}
local styles = {"Vintage", "Preppy", "Streetwear", "Designer", "Y2K"}
local categories = {
    {"T-Shirts", "Scrub", 18, "tshirts", {
        {"Black Logo Tee",7178736794,nil,"TShirt"},{"Gray Everyday Tee",9112474888,nil,"TShirt"},{"White Logo Tee",7178737816,nil,"TShirt"},
        {"Black Striped Tee",9119670803,nil,"TShirt"},{"White Striped Tee",9112483644,nil,"TShirt"},{"Golden Music Tee",9252603398,nil,"TShirt"},
        {"Simple Pattern Tee",3670737444,nil,"ClassicShirt"},{"Pizza Graphic Tee",4047884939,nil,"ClassicShirt"},{"Heart Pizza Tee",382537085,nil,"ClassicShirt"},{"Teal Classic Tee",382537702,nil,"ClassicShirt"},
    }},
    {"Shirts", "Polish", 24, "shirts", {
        {"Blue Plaid Shirt",398635081,nil,"ClassicShirt"},{"Moto Shirt",144076358,nil,"ClassicShirt"},{"Denim Layer Shirt",144076436,nil,"ClassicShirt"},
        {"Pastel Layered Shirt",398634295,nil,"ClassicShirt"},{"Purple Teal Top",4047886060,nil,"ClassicShirt"},{"White Tie Front Top",9240752338,nil,"Shirt"},
        {"Blue Tie Front Top",9174384558,nil,"Shirt"},{"Classic Zip Shirt",607785314,nil,"ClassicShirt"},{"Denim Hoodie Shirt",398633584,nil,"ClassicShirt"},{"Guitar Layer Shirt",4047884046,nil,"ClassicShirt"},
    }},
    {"Pants", "Assemble", 28, "pants", {
        {"Ripped Skater Pants",398635338,nil,"ClassicPants"},{"Black Wetsuit Pants",9120251003,nil,"Pants"},{"Brown Cargo Pants",6984740059,nil,"Pants"},
        {"White Leather Pants",7192681239,nil,"Pants"},{"Brown Moto Pants",8721985925,nil,"Pants"},{"Black Jeans White Shoes",398633812,nil,"ClassicPants"},
        {"Classic Blue Jeans",398634487,nil,"ClassicPants"},{"Dark Green Jeans",144076760,nil,"ClassicPants"},{"Black Sneaker Jeans",382538503,nil,"ClassicPants"},{"Everyday Black Jeans",382537569,nil,"ClassicPants"},
    }},
    {"Shorts", "Repaint", 22, "shorts", {
        {"Jean Shorts White Shoes",382537950,nil,"ClassicPants"},{"Black Bermuda Shorts",9174391966,nil,"Shorts"},{"Classic Jean Shorts",382537806,nil,"ClassicPants"},
        {"Light Wash Jean Shorts",7192687500,nil,"Shorts"},{"Light Blue Bermuda Shorts",9274782406,nil,"Shorts"},{"Red Basketball Shorts",7192689453,nil,"Shorts"},
        {"Lime Boxing Shorts",7231091126,nil,"ClassicPants"},{"Salmon Bermuda Shorts",9240765837,nil,"Shorts"},{"Mint Bermuda Shorts",9240767370,nil,"Shorts"},{"Blue Basketball Shorts",7192688494,nil,"Shorts"},
    }},
    {"Jackets", "Rewire", 36, "jackets", {
        {"Classic Zip Jacket",607785314,nil,"ClassicShirt"},{"Denim White Hoodie",398633584,nil,"ClassicShirt"},{"Pastel Star Jacket",398634295,nil,"ClassicShirt"},
        {"Black Leather Jacket",7192549218,nil,"Jacket"},{"Light Wash Denim Jacket",8516609675,nil,"Jacket"},{"Gray Hooded Jacket",8516620262,nil,"Jacket"},
        {"White Denim Jacket",8516612751,nil,"Jacket"},{"Black Guitar Jacket",4047884046,nil,"ClassicShirt"},{"White Collared Jacket",7192546798,nil,"Jacket"},{"Brown Leather Jacket",6984767443,nil,"Jacket"},
    }},
    {"Dresses", "Polish", 34, "dresses", {
        {"Red Evening Dress",11821648884,nil,"DressSkirt"},{"Floral Day Dress",10896900057,nil,"DressSkirt"},{"White Ruffle Dress",9240776381,nil,"DressSkirt"},
        {"Pink Chiffon Dress",9240772455,nil,"DressSkirt"},{"Red Ruffle Dress",7192696851,nil,"DressSkirt"},{"Blue Chiffon Dress",7192691582,nil,"DressSkirt"},
        {"Beige Knit Dress",6984769289,nil,"Sweater"},{"Pink Knit Dress",6984771334,nil,"Sweater"},{"Black Knit Dress",9240757332,nil,"Sweater"},{"Gray Knit Dress",9240758221,nil,"Sweater"},
    }},
    {"Shoes", "Assemble", 26, "shoes", {
        {"White Canvas Shoes",894,"BundleThumbnail","Shoes",9481782649,9481786623},{"Gray Canvas Shoes",905,"BundleThumbnail","Shoes",9483690316,9483697460},{"Black Dress Shoes",907,"BundleThumbnail","Shoes",8044843668,8044852814},
        {"Red Running Shoes",895,"BundleThumbnail","Shoes",8722108564,8722044460},{"Pink Canvas Shoes",877,"BundleThumbnail","Shoes",7192850635,7192852086},{"Black Running Shoes",926,"BundleThumbnail","Shoes",8722159299,8722157748},
        {"Blue Running Shoes",921,"BundleThumbnail","Shoes",8722154892,8722153183},{"Blue Canvas Shoes",881,"BundleThumbnail","Shoes",7192843096,7192846003},{"White Running Shoes",903,"BundleThumbnail","Shoes",8722031289,8722020587},{"Black Purple Canvas Shoes",931,"BundleThumbnail","Shoes",7650548422,7650550422},
    }},
    {"Accessories", "Repaint", 20, "accessories", {
        {"Paper Bucket Hat",10476359,nil,"Hat"},{"Black Cowboy Hat",425117435,nil,"Hat"},{"Umbrella Hat",10658698,nil,"Hat"},
        {"Gray Winter Hat",105354517,nil,"Hat"},{"Cheese Hat",1097026,nil,"Hat"},{"Candy Scarf Hat",562493075,nil,"Hat"},
        {"Nurse Cap",10770260,nil,"Hat"},{"Ranger Hat",13335289,nil,"Hat"},{"Blue Top Hat",1016145591,nil,"Hat"},{"Eternal Top Hat",835066603,nil,"Hat"},
    }},
}
Catalog.Items, Catalog.ById, Catalog.Categories = {}, {}, {}
for categoryIndex, group in ipairs(categories) do
    table.insert(Catalog.Categories, group[1])
    for index, choice in ipairs(group[5]) do
        local item = {Id = group[4] .. "_" .. index, Name = choice[1], Category = group[1], Minigame = group[2],
            BaseValue = group[3] + index * 4, Style = styles[(index + categoryIndex - 2) % #styles + 1],
            UnlockLevel = math.max(1, categoryIndex - 2), Variant = index,
            CatalogAssetId = choice[2], CatalogItemType = choice[3] or "Asset", CatalogCreator = "Roblox",
            AvatarAssetType = choice[4], CatalogComponentIds = choice[5] and {choice[5], choice[6]} or nil}
        table.insert(Catalog.Items, item); Catalog.ById[item.Id] = item
    end
end
-- Alias legacy IDs for exchange recovery and old server handoff payloads.
local legacy = {lamps="tshirts", radios="shirts", clocks="pants", chairs="shorts", toys="jackets", mirrors="dresses", cameras="shoes", vases="accessories"}
for old, current in pairs(legacy) do for index = 1, 10 do Catalog.ById[old .. "_" .. index] = Catalog.ById[current .. "_" .. index] end end
return Catalog
