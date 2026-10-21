local Economy = {}
function Economy.level(xp)
    return math.floor(math.sqrt(math.max(0, xp) / 30)) + 1
end
function Economy.value(definition, item, rarityMultipliers, conditionMultipliers, demand, bonus)
    return math.max(1, math.floor(definition.BaseValue * rarityMultipliers[item.Rarity]
        * conditionMultipliers[item.Condition] * item.Variance * (demand or 1) * (bonus or 1)))
end
function Economy.pick(weights, randomUnit)
    local total = 0
    for _, weight in ipairs(weights) do total += weight end
    local point = math.clamp(randomUnit, 0, 0.999999999) * total
    for index, weight in ipairs(weights) do
        point -= weight
        if point < 0 then return index end
    end
    return #weights
end
function Economy.daily(now) return math.floor(now / 86400) end
function Economy.week(now) return math.floor((now + 3 * 86400) / (7 * 86400)) end
function Economy.restore(condition, score, tool)
    local gain = if score >= 0.8 then 2 else 1
    if tool >= 3 and score >= 0.6 then gain += 1 end
    return math.min(5, condition + gain)
end
function Economy.validAmount(value, minimum, maximum)
    return type(value) == "number" and value == value and value % 1 == 0
        and value >= minimum and value <= maximum
end
return Economy
