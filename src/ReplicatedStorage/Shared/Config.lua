local Config = {}

Config.Classes = {
	Warrior = {
		Name = "Warrior",
		BaseStats = {
			STR = 12,
			AGI = 5,
			INT = 3,
			VIT = 10,
			DEX = 5,
			LUK = 4,
		},
		Growth = {
			STR = 2.4,
			AGI = 1.2,
			INT = 0.8,
			VIT = 2.0,
			DEX = 1.1,
			LUK = 0.9,
		},
		WeaponRestrictions = { "Sword", "Axe", "Mace" },
		BasicAttack = {
			Name = "Heavy Slash",
			Range = 18,
			Cooldown = 0.75,
			MinDamage = 12,
			MaxDamage = 18,
			Type = "Melee",
		},
		Skills = {
			ShieldBash = {
				Name = "Shield Bash",
				Range = 18,
				Cooldown = 3,
				Cost = 8,
				MinDamage = 20,
				MaxDamage = 30,
				Type = "Melee",
			},
		},
	},
	Assassin = {
		Name = "Assassin",
		BaseStats = {
			STR = 8,
			AGI = 12,
			INT = 4,
			VIT = 7,
			DEX = 11,
			LUK = 9,
		},
		Growth = {
			STR = 1.8,
			AGI = 2.5,
			INT = 1.0,
			VIT = 1.4,
			DEX = 2.2,
			LUK = 1.6,
		},
		WeaponRestrictions = { "Dagger", "Sword" },
		BasicAttack = {
			Name = "Quick Strike",
			Range = 16,
			Cooldown = 0.45,
			MinDamage = 12,
			MaxDamage = 20,
			Type = "Melee",
		},
		Skills = {
			ShadowStrike = {
				Name = "Shadow Strike",
				Range = 22,
				Cooldown = 2.3,
				Cost = 10,
				MinDamage = 24,
				MaxDamage = 35,
				Type = "Melee",
			},
		},
	},
	Mage = {
		Name = "Mage",
		BaseStats = {
			STR = 5,
			AGI = 6,
			INT = 15,
			VIT = 8,
			DEX = 7,
			LUK = 6,
		},
		Growth = {
			STR = 1.0,
			AGI = 1.2,
			INT = 3.0,
			VIT = 1.6,
			DEX = 1.4,
			LUK = 1.1,
		},
		WeaponRestrictions = { "Staff", "Wand" },
		BasicAttack = {
			Name = "Arcane Bolt",
			Range = 28,
			Cooldown = 0.7,
			MinDamage = 10,
			MaxDamage = 18,
			Type = "Ranged",
		},
		Skills = {
			ArcaneBurst = {
				Name = "Arcane Burst",
				Range = 28,
				Cooldown = 2.8,
				Cost = 12,
				MinDamage = 22,
				MaxDamage = 32,
				Type = "Ranged",
			},
		},
	},
	Archer = {
		Name = "Archer",
		BaseStats = {
			STR = 7,
			AGI = 10,
			INT = 5,
			VIT = 7,
			DEX = 13,
			LUK = 8,
		},
		Growth = {
			STR = 1.5,
			AGI = 2.2,
			INT = 1.1,
			VIT = 1.4,
			DEX = 2.8,
			LUK = 1.5,
		},
		WeaponRestrictions = { "Bow", "Crossbow" },
		BasicAttack = {
			Name = "Twin Shot",
			Range = 30,
			Cooldown = 0.55,
			MinDamage = 11,
			MaxDamage = 19,
			Type = "Ranged",
		},
		Skills = {
			Volley = {
				Name = "Volley",
				Range = 30,
				Cooldown = 2.6,
				Cost = 10,
				MinDamage = 18,
				MaxDamage = 28,
				Type = "Ranged",
			},
		},
	},
}

Config.Monsters = {
	Slime = {
		Name = "Slime",
		Level = 1,
		Health = 50,
		Attack = 8,
		Defense = 2,
		MoveSpeed = 7,
		AggroRange = 24,
		AttackRange = 4,
		AttackCooldown = 1.5,
		ExpReward = 15,
		GoldMin = 8,
		GoldMax = 18,
		Color = Color3.fromRGB(120, 220, 120),
	},
	Wolf = {
		Name = "Wolf",
		Level = 4,
		Health = 68,
		Attack = 12,
		Defense = 4,
		MoveSpeed = 9,
		AggroRange = 26,
		AttackRange = 5,
		AttackCooldown = 1.3,
		ExpReward = 22,
		GoldMin = 12,
		GoldMax = 22,
		Color = Color3.fromRGB(175, 130, 88),
	},
	Skeleton = {
		Name = "Skeleton",
		Level = 7,
		Health = 90,
		Attack = 16,
		Defense = 5,
		MoveSpeed = 8,
		AggroRange = 28,
		AttackRange = 5,
		AttackCooldown = 1.25,
		ExpReward = 30,
		GoldMin = 15,
		GoldMax = 30,
		Color = Color3.fromRGB(200, 200, 210),
	},
}

Config.PlayerDataDefaults = {
	Class = "Warrior",
	Level = 1,
	Exp = 0,
	Gold = 0,
	Health = 100,
	Mana = 50,
	Stats = {
		STR = 0,
		AGI = 0,
		INT = 0,
		VIT = 0,
		DEX = 0,
		LUK = 0,
	},
	StatPoints = 0,
	Inventory = {},
	Equipment = {
		Weapon = nil,
		Head = nil,
		Body = nil,
		Legs = nil,
		Gloves = nil,
		Boots = nil,
		Accessory1 = nil,
		Accessory2 = nil,
	},
	EquipmentBonusStats = {
		STR = 0,
		AGI = 0,
		INT = 0,
		VIT = 0,
		DEX = 0,
		LUK = 0,
	},
	Position = Vector3.new(0, 4, 0),
}

Config.InventoryCapacity = 24

Config.ItemDefinitions = {
	IronSword = {
		Id = "IronSword",
		Name = "Iron Sword",
		Type = "Equipment",
		Slot = "Weapon",
		Rarity = "Uncommon",
		Stats = { STR = 4, VIT = 1 },
	},
	WardenHelm = {
		Id = "WardenHelm",
		Name = "Warden Helm",
		Type = "Equipment",
		Slot = "Head",
		Rarity = "Rare",
		Stats = { VIT = 3 },
	},
	MageStaff = {
		Id = "MageStaff",
		Name = "Mage Staff",
		Type = "Equipment",
		Slot = "Weapon",
		Rarity = "Rare",
		Stats = { INT = 5, DEX = 2 },
	},
	ScoutBoots = {
		Id = "ScoutBoots",
		Name = "Scout Boots",
		Type = "Equipment",
		Slot = "Boots",
		Rarity = "Common",
		Stats = { AGI = 3 },
	},
	HealthPotion = {
		Id = "HealthPotion",
		Name = "Health Potion",
		Type = "Consumable",
		Slot = "None",
		Rarity = "Common",
		Stats = {},
	},
}

Config.XPTable = {}
for level = 1, 100 do
	if level == 1 then
		Config.XPTable[level] = 0
	else
		Config.XPTable[level] = math.floor(60 * (level ^ 1.8))
	end
end

function Config.GetXpForLevel(level)
	local xp = Config.XPTable[level] or 0
	return xp
end

function Config.GetLevelFromExp(exp)
	local currentLevel = 1
	while Config.GetXpForLevel(currentLevel + 1) <= exp do
		currentLevel = currentLevel + 1
	end
	return currentLevel
end

function Config.GetClassConfig(className)
	local normalized = className or "Warrior"
	return Config.Classes[normalized] or Config.Classes.Warrior
end

function Config.GetMonsterTemplate(monsterName)
	local normalized = monsterName or "Slime"
	return Config.Monsters[normalized] or Config.Monsters.Slime
end

return Config
