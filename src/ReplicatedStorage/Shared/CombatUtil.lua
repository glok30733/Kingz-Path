local CombatUtil = {}

function CombatUtil.Clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

function CombatUtil.RandomInt(minValue, maxValue)
	return math.random(minValue, maxValue)
end

function CombatUtil.CalculateDamage(playerProfile, targetDefense, critChance)
	local classStats = playerProfile.Stats or {}
	local strength = classStats.STR or 0
	local dexterity = classStats.DEX or 0
	local luck = classStats.LUK or 0
	local baseDamage = 10 + strength * 1.6 + dexterity * 0.8
	local critRoll = math.random()
	local critMultiplier = 1
	if critRoll <= (critChance or 0.1) + (luck / 200) then
		critMultiplier = 1.75 + (luck / 100)
	end
	local finalDamage = baseDamage * critMultiplier - (targetDefense or 0)
	return math.max(5, math.floor(finalDamage))
end

function CombatUtil.GetPlayerLevel(exp)
	local level = 1
	while (60 * ((level + 1) ^ 1.8)) <= exp do
		level = level + 1
	end
	return level
end

return CombatUtil
