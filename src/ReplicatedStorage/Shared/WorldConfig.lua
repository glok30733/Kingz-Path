local WorldConfig = {}

WorldConfig.Zones = {
	StarterVillage = {
		Name = "Starter Village",
		LevelMin = 1,
		LevelMax = 10,
		SpawnPosition = Vector3.new(0, 5, 0),
		RecommendedClass = "Warrior",
		MonsterPool = { "Slime" },
		AccessRequirement = "None",
		LootProgression = { "Common", "Uncommon" },
	},
	WhisperingForest = {
		Name = "Whispering Forest",
		LevelMin = 10,
		LevelMax = 20,
		SpawnPosition = Vector3.new(120, 5, 0),
		RecommendedClass = "Warrior",
		MonsterPool = { "Slime", "Wolf" },
		AccessRequirement = "Level 10",
		LootProgression = { "Uncommon", "Rare" },
	},
	AncientRuins = {
		Name = "Ancient Ruins",
		LevelMin = 20,
		LevelMax = 35,
		SpawnPosition = Vector3.new(240, 5, 0),
		RecommendedClass = "Assassin",
		MonsterPool = { "Wolf", "Skeleton" },
		AccessRequirement = "Level 20",
		LootProgression = { "Rare", "Epic" },
	},
	VolcanicCavern = {
		Name = "Volcanic Cavern",
		LevelMin = 35,
		LevelMax = 50,
		SpawnPosition = Vector3.new(360, 5, 0),
		RecommendedClass = "Mage",
		MonsterPool = { "Skeleton" },
		AccessRequirement = "Level 35",
		LootProgression = { "Rare", "Epic" },
	},
	ShadowDungeon = {
		Name = "Shadow Dungeon",
		LevelMin = 50,
		LevelMax = 70,
		SpawnPosition = Vector3.new(480, 5, 0),
		RecommendedClass = "Assassin",
		MonsterPool = { "Skeleton" },
		AccessRequirement = "Level 50",
		LootProgression = { "Epic", "Legendary" },
	},
	DragonsNest = {
		Name = "Dragon's Nest",
		LevelMin = 70,
		LevelMax = 999,
		SpawnPosition = Vector3.new(600, 5, 0),
		RecommendedClass = "Mage",
		MonsterPool = { "Skeleton" },
		AccessRequirement = "Level 70",
		LootProgression = { "Epic", "Legendary", "Mythic" },
	},
}

function WorldConfig.GetZoneForLevel(level)
	local zoneName = "StarterVillage"
	for name, zone in pairs(WorldConfig.Zones) do
		if level >= (zone.LevelMin or 1) and level <= (zone.LevelMax or 999) then
			zoneName = name
			break
		end
	end
	return WorldConfig.Zones[zoneName]
end

return WorldConfig
