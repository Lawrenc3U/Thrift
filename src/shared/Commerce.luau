-- Pure cosmetic entitlement helpers shared by live purchase processing and tests.
local Commerce = {}

local function ensure(profile)
    profile.Themes = profile.Themes or {}
    profile.Decorations = profile.Decorations or {}
    profile.Titles = profile.Titles or {}
end

local function grant(target, single, many)
    if type(single) == "string" and single ~= "" then target[single] = true end
    if type(many) == "table" then
        for _, key in ipairs(many) do if type(key) == "string" and key ~= "" then target[key] = true end end
    end
end

local function owns(target, single, many)
    local hasReward = false
    if type(single) == "string" and single ~= "" then
        hasReward = true
        if not target[single] then return false, hasReward end
    end
    if type(many) == "table" then
        for _, key in ipairs(many) do
            if type(key) == "string" and key ~= "" then
                hasReward = true
                if not target[key] then return false, hasReward end
            end
        end
    end
    return true, hasReward
end

function Commerce.applyReward(profile, reward)
    ensure(profile); reward = reward or {}
    grant(profile.Themes, reward.Theme, reward.Themes)
    grant(profile.Decorations, reward.Decoration, reward.Decorations)
    grant(profile.Titles, reward.Title, reward.Titles)
end

function Commerce.ownsReward(profile, reward)
    ensure(profile); reward = reward or {}
    local complete, hasTheme = owns(profile.Themes, reward.Theme, reward.Themes)
    if not complete then return false end
    local decorated, hasDecoration = owns(profile.Decorations, reward.Decoration, reward.Decorations)
    if not decorated then return false end
    local titled, hasTitle = owns(profile.Titles, reward.Title, reward.Titles)
    if not titled then return false end
    return hasTheme or hasDecoration or hasTitle
end

return Commerce
