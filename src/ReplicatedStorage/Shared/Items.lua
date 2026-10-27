local Items = {}

Items.Definitions = {
	IronSword = {
		Id = "IronSword",
		Name = "Iron Sword",
		Type = "Equipment",
		Slot = "Weapon",
		Rarity = "Uncommon",
		Description = "A sturdy iron blade suited for frontline fighters.",
		Stats = {
			STR = 4,
			VIT = 1,
		},
		Value = 25,
		Stackable = false,
	},
	WardenHelm = {
		Id = "WardenHelm",
		Name = "Warden Helm",
		Type = "Equipment",
		Slot = "Head",
		Rarity = "Rare",
		Description = "A reinforced helm protecting the head and mind.",
		Stats = {
			VIT = 3,
			DEF = 2,
		},
		Value = 42,
		Stackable = false,
	},
	MageStaff = {
		Id = "MageStaff",
		Name = "Mage Staff",
		Type = "Equipment",
		Slot = "Weapon",
		Rarity = "Rare",
		Description = "A crystal-cored staff that channels arcane energy.",
		Stats = {
			INT = 5,
			DEX = 2,
		},
		Value = 46,
		Stackable = false,
	},
	ScoutBoots = {
		Id = "ScoutBoots",
		Name = "Scout Boots",
		Type = "Equipment",
		Slot = "Boots",
		Rarity = "Common",
		Description = "Light boots used for quick movement and stable footing.",
		Stats = {
			AGI = 3,
			DEX = 1,
		},
		Value = 18,
		Stackable = false,
	},
	HealthPotion = {
		Id = "HealthPotion",
		Name = "Health Potion",
		Type = "Consumable",
		Slot = "Consumable",
		Rarity = "Common",
		Description = "Restores a small amount of health when used.",
		Stats = {},
		RestoreHealth = 40,
		Value = 10,
		Stackable = true,
	},
	Moonstone = {
		Id = "Moonstone",
		Name = "Moonstone",
		Type = "Material",
		Slot = "None",
		Rarity = "Epic",
		Description = "A rare mineral used in enchantment and crafting.",
		Stats = {},
		Value = 65,
		Stackable = true,
	},
}

Items.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(120, 210, 120),
	Rare = Color3.fromRGB(120, 150, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 180, 70),
	Mythic = Color3.fromRGB(255, 90, 90),
}

function Items.GetDefinition(itemId)
	if not itemId then
		return nil
	end
	return Items.Definitions[itemId]
end

return Items
