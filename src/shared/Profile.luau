local Profile = {}
function Profile.new()
    return {
        Version = 3, Cash = 500, XP = 0, Tier = 1, Tool = 0,
        Inventory = {}, Collection = {}, Themes = {Cozy = true}, Theme = "Cozy",
        Stats = {Found = 0, Restored = 0, Sold = 0, Earned = 0},
        Tutorial = 0, LastDelivery = -1, Daily = {Day = -1, Claimed = {}},
        Login = {Day = -2, Streak = 0, ClaimedDay = -2},
        Weekly = {Week = -1, Restored = 0, Sold = 0, Claimed = false},
        Decorations = {}, PlacedDecor = {}, DecorLayout = {}, Reputation = 0, RatingTotal = 0, RatingCount = 0, Rated = {},
        Settings = {Music = true, TownMusic = true, AuctionMusic = true, Effects = true}, Titles = {},
        AppliedReceipts = {}, Exchange = {Pending = false},
    }
end
function Profile.reconcile(data)
    assert(type(data) == "table", "Profile data is not a table")
    local version = data.Version or 1
    assert(type(version) == "number" and version >= 1 and version <= 3, "Unsupported profile schema version")
    if data.Cash ~= nil then
        assert(type(data.Cash) == "number" and data.Cash == data.Cash and data.Cash >= 0 and data.Cash < math.huge, "Invalid saved cash")
    end
    if data.Inventory ~= nil then assert(type(data.Inventory) == "table", "Invalid saved inventory") end
    local defaults = Profile.new()
    local function merge(target, template)
        for key, value in pairs(template) do
            if target[key] == nil then
                target[key] = if type(value) == "table" then table.clone(value) else value
            elseif type(value) == "table" and type(target[key]) == "table" then
                merge(target[key], value)
            end
        end
    end
    merge(data, defaults)
    if version < 3 then
        local prefixes = {lamps = "tshirts", radios = "shirts", clocks = "pants", chairs = "shorts",
            toys = "jackets", mirrors = "dresses", cameras = "shoes", vases = "accessories"}
        local styles = {Retro = "Vintage", Cozy = "Preppy", Futuristic = "Streetwear", Antique = "Designer", Cute = "Y2K"}
        local function fashionId(id)
            if type(id) ~= "string" then return id end
            local prefix, number = string.match(id, "^(%a+)_(%d+)$")
            return (prefixes[prefix] and number) and (prefixes[prefix] .. "_" .. number) or id
        end
        for _, item in ipairs(data.Inventory or {}) do
            item.DefId = fashionId(item.DefId)
            item.Style = styles[item.Style] or item.Style
        end
        local migrated = {}
        for key, owned in pairs(data.Collection or {}) do
            local id, rarity = string.match(key, "^(.+):(%d+)$")
            migrated[id and (fashionId(id) .. ":" .. rarity) or key] = owned
        end
        data.Collection = migrated
    end
    data.Version = 3
    return data
end
return Profile
