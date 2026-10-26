-- Central tuning. No paid power or randomized Robux purchases.
local Config = {
    Version = 2,
    StudioPracticeMode = true, -- Studio only; never disables live-server persistence.
    StartingCash = 75,
    InventoryLimit = 100,
    -- The town has eight claimable storefronts. Keep the server cap aligned so
    -- every player always receives a shop.
    MaxPlayers = 8,
    -- UserIds are preferred for permanent live admins. Usernames are matched
    -- against Roblox-authenticated Player.Name values and are case-insensitive.
    AdminUserIds = {},
    AdminUsernames = {"TheKaiju015"},
    AutosaveSeconds = 60,
    SessionLease = 180,
    Sources = {
        Dumpster = {Cost = 0, Level = 1, Cooldown = 15, Weights = {70, 24, 5, 0.9, 0.1}},
        Estate = {Cost = 90, Level = 3, Cooldown = 8, Weights = {30, 42, 22, 5, 1}},
        Delivery = {Cost = 0, Level = 1, Cooldown = 0, Weights = {35, 40, 20, 4, 1}},
    },
    Rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary"},
    -- ASCII badges remain readable on every Roblox font/platform. Decorative
    -- rarity effects are drawn with native UI geometry in the client.
    RarityIcons = {"C", "U", "R", "E", "L"},
    RarityColors = {"#AEB7B5", "#70C58D", "#6CABF3", "#C29AE8", "#EDC66D"},
    RarityEffectNames = {"Found", "Fresh", "Shimmer", "Enchanted", "Golden Legend"},
    RarityMultipliers = {1, 1.8, 3.5, 7, 15},
    Conditions = {"Wrecked", "Poor", "Fair", "Good", "Mint"},
    ConditionMultipliers = {0.25, 0.5, 0.85, 1.3, 2},
    Styles = {"Retro", "Cozy", "Futuristic", "Antique", "Cute"},
    Tiers = {
        {Name = "Corner Stall", Cost = 0, Slots = 4, Level = 1},
        {Name = "Small Shop", Cost = 600, Slots = 8, Level = 4},
        {Name = "Boutique", Cost = 4000, Slots = 12, Level = 9},
        {Name = "Department Store", Cost = 18000, Slots = 16, Level = 16},
    },
    ToolCosts = {150, 650, 2500},
    CustomerSeconds = 18,
    AuctionInterval = 240,
    AuctionDuration = 45,
    -- Same-server listings and trades use a durable recovery journal.
    EnablePlayerMarket = true,
    EnableTrading = true,
    Decorations = {
        {Id = "Rug", Name = "Woven welcome rug", Cost = 120},
        {Id = "Plant", Name = "Happy houseplants", Cost = 180},
        {Id = "Poster", Name = "Second chances poster", Cost = 90},
        {Id = "Neon", Name = "Good finds neon sign", Cost = 400},
        {Id = "Curtains", Name = "Rose linen curtains", Cost = 240},
        {Id = "Trophy", Name = "Golden treasure sculpture", Cost = 1200},
    },
    CosmeticPasses = {}, -- [Roblox game-pass id] = cosmetic theme key; no placeholder IDs
    Themes = {
        {Id = "Cozy", Name = "Cozy Corner", Cost = 0, Color = {0.56, 0.75, 0.68}},
        {Id = "Retro", Name = "Retro Revival", Cost = 350, Color = {0.83, 0.57, 0.47}},
        {Id = "Futuristic", Name = "Neon Tomorrow", Cost = 600, Color = {0.43, 0.56, 0.76}},
        {Id = "Antique", Name = "Antique Attic", Cost = 900, Color = {0.69, 0.56, 0.36}},
        {Id = "Cute", Name = "Rose Cottage", Cost = 450, Color = {0.85, 0.61, 0.70}},
    },
}
return Config
