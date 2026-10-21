-- UTC dates are explicit so events can be reviewed and scheduled before release.
-- Cosmetic rewards never change rarity, cash earning, restoration scores or capacity.
local LiveConfig = {
    Showcase = {
        Neighborhoods = 32,
        MaxEntries = 128,
        MaxVoters = 5000,
        CacheSeconds = 45,
        HistoryWeeks = 4,
        MinimumVotes = 1,
        WinnerCount = 3,
        Themes = {"Cozy", "Retro", "Antique", "Cute", "Futuristic"},
        Rewards = {
            {Title = "ShowcaseChampion", Decoration = "Trophy"},
            {Title = "ShowcaseSilver", Decoration = "Poster"},
            {Title = "ShowcaseBronze", Decoration = "Plant"},
        },
    },
    Events = {
        {
            Id = "harvest_2026", Name = "Harvest of Second Chances",
            Description = "Bring forgotten treasures back to life for a warm autumn window display.",
            Starts = 1792108800, Ends = 1794182400, -- Oct 16 through Nov 8, 2026 UTC
            Goal = {Restored = 15, Sold = 8},
            Reward = {Title = "HarvestCurator", Theme = "Retro", Decoration = "Plant"},
            RewardName = "Harvest Curator title + Retro theme + houseplants",
            Accent = "#D69D52",
        },
        {
            Id = "winter_2026", Name = "Winter Window Festival",
            Description = "Fill Thrift Street with gifts that already have a story.",
            Starts = 1796083200, Ends = 1799107200, -- Dec 1, 2026 through Jan 4, 2027 UTC
            Goal = {Restored = 20, Sold = 12},
            Reward = {Title = "WinterWonder", Theme = "Cute", Decoration = "Trophy"},
            RewardName = "Winter Wonder title + Rose Cottage theme + golden sculpture",
            Accent = "#8ABEBB",
        },
        {
            Id = "spring_2027", Name = "Fresh Start Market",
            Description = "Restore, reuse and restyle. A brighter season starts with a second chance.",
            Starts = 1803859200, Ends = 1806537600, -- March 2027 UTC
            Goal = {Found = 20, Restored = 12, Sold = 8},
            Reward = {Title = "SpringStylist", Theme = "Cozy", Decoration = "Curtains"},
            RewardName = "Spring Stylist title + rose linen curtains",
            Accent = "#A3BD7C",
        },
    },
    -- Configure real creator-owned IDs after creating products in Creator Dashboard.
    -- Entries without positive integer IDs are never displayed or prompted.
    -- Example schema (not an enabled product):
    -- Passes = {{Id = YOUR_ID, Name = "Rose Cottage", Description = "A permanent cosmetic theme", Reward = {Theme = "Cute"}}}
    -- Products grant permanent cosmetics only; replays cannot create cash/items.
    Passes = {},
    Products = {},
    ReceiptHistoryLimit = 1024,
}
return LiveConfig
