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
    -- Replace each zero with the creator-owned ID from Creator Dashboard. Zero-ID
    -- offers remain visible as disabled previews in Studio, but are never prompted.
    -- SuggestedPrice is planning copy only; the live button uses Roblox's price.
    Passes = {
        {
            Key = "rose_gold_boutique", Id = 0, Order = 1, Badge = "POPULAR", SuggestedPrice = 49,
            Name = "Rose Gold Boutique", Accent = "#E9949D", PreviewTheme = "RoseGold",
            Description = "A warm blush storefront made for cozy collectors.",
            Benefits = {"Exclusive Rose Gold shop theme", "Rose linen curtains + houseplants", "Rose Gold Stylist title"},
            Reward = {Themes = {"RoseGold"}, Decorations = {"Curtains", "Plant"}, Titles = {"RoseGoldStylist"}},
        },
        {
            Key = "neon_night_market", Id = 0, Order = 2, Badge = "BOLD STYLE", SuggestedPrice = 79,
            Name = "Neon Night Market", Accent = "#657FDB", PreviewTheme = "NeonNight",
            Description = "Turn your shop into a vivid after-dark treasure stop.",
            Benefits = {"Exclusive Neon Night shop theme", "Good Finds neon decoration", "Neon Curator title"},
            Reward = {Themes = {"NeonNight"}, Decorations = {"Neon"}, Titles = {"NeonCurator"}},
        },
        {
            Key = "curator_club", Id = 0, Order = 3, Badge = "BEST VALUE", SuggestedPrice = 129,
            Name = "Curator Club", Accent = "#C08A52", PreviewTheme = "Curator",
            Description = "A museum-inspired storefront bundle for serious collectors.",
            Benefits = {"Exclusive Curator's Gallery theme", "Golden sculpture + framed poster", "Curator Club title"},
            Reward = {Themes = {"Curator"}, Decorations = {"Trophy", "Poster"}, Titles = {"CuratorClub"}},
        },
    },
    Products = {
        {
            Key = "street_supporter", Id = 0, Order = 4, Badge = "SUPPORTER", SuggestedPrice = 19,
            Name = "Thrift Street Supporter", Accent = "#E8B95A",
            Description = "A small one-time thank-you bundle that supports future updates.",
            Benefits = {"Street Supporter title", "Second Chances poster", "Permanent account unlock"},
            Reward = {Decorations = {"Poster"}, Titles = {"StreetSupporter"}},
        },
    },
    ReceiptHistoryLimit = 1024,
}
return LiveConfig
