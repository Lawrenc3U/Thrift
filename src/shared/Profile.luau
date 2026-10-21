local Profile = {}
function Profile.new()
    return {
        Version = 1, Cash = 75, XP = 0, Tier = 1, Tool = 0,
        Inventory = {}, Collection = {}, Themes = {Cozy = true}, Theme = "Cozy",
        Stats = {Found = 0, Restored = 0, Sold = 0, Earned = 0},
        Tutorial = 0, LastDelivery = -1, Daily = {Day = -1, Claimed = {}},
        Weekly = {Week = -1, Restored = 0, Sold = 0, Claimed = false},
        Decorations = {}, PlacedDecor = {}, Reputation = 0, RatingTotal = 0, RatingCount = 0, Rated = {},
        Settings = {Music = true, Effects = true}, Titles = {},
    }
end
function Profile.reconcile(data)
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
    return data
end
return Profile
