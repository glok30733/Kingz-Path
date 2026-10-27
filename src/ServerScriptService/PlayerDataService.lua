local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PLAYER_DATA_STORE = DataStoreService:GetDataStore("KingzPathPlayerProfilesV1")
local profiles = {}

local PlayerDataService = {}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopy(nestedValue)
	end
	return copy
end

local function mergeProfile(defaultProfile, incomingProfile)
	if type(incomingProfile) ~= "table" then
		return deepCopy(defaultProfile)
	end

	for key, defaultValue in pairs(defaultProfile) do
		if incomingProfile[key] == nil then
			incomingProfile[key] = deepCopy(defaultValue)
		end
	end

	for key, value in pairs(incomingProfile) do
		if defaultProfile[key] == nil then
			incomingProfile[key] = value
		end
	end

	return incomingProfile
end

local function refreshDerivedProfile(profile)
	if type(profile) ~= "table" then
		return profile
	end

	local stats = profile.Stats or {}
	profile.Stats = {
		STR = stats.STR or 0,
		AGI = stats.AGI or 0,
		INT = stats.INT or 0,
		VIT = stats.VIT or 0,
		DEX = stats.DEX or 0,
		LUK = stats.LUK or 0,
	}
	profile.Equipment = profile.Equipment or {}
	profile.Inventory = profile.Inventory or {}
	profile.EquipmentBonusStats = profile.EquipmentBonusStats or { STR = 0, AGI = 0, INT = 0, VIT = 0, DEX = 0, LUK = 0 }
	for statName, previousValue in pairs(profile.EquipmentBonusStats) do
		profile.Stats[statName] = (profile.Stats[statName] or 0) - (previousValue or 0)
	end

	local bonusStats = { STR = 0, AGI = 0, INT = 0, VIT = 0, DEX = 0, LUK = 0 }
	for _, slotName in pairs({ "Weapon", "Head", "Body", "Legs", "Gloves", "Boots", "Accessory1", "Accessory2" }) do
		local itemId = profile.Equipment[slotName]
		if itemId and Config.ItemDefinitions and Config.ItemDefinitions[itemId] then
			local itemStats = Config.ItemDefinitions[itemId].Stats or {}
			for statName, statValue in pairs(itemStats) do
				if type(statValue) == "number" then
					bonusStats[statName] = (bonusStats[statName] or 0) + statValue
				end
			end
		end
	end
	for statName, statValue in pairs(bonusStats) do
		profile.Stats[statName] = (profile.Stats[statName] or 0) + statValue
	end
	profile.EquipmentBonusStats = bonusStats
	profile.Health = 100 + (profile.Stats.VIT or 0) * 6
	profile.Mana = 50 + (profile.Stats.INT or 0) * 4
	profile.Level = math.max(1, profile.Level or 1)
	profile.Exp = math.max(0, profile.Exp or 0)
	profile.Gold = math.max(0, profile.Gold or 0)
	return profile
end

function PlayerDataService.GetProfile(player)
	if not player then
		return nil
	end

	return profiles[player.UserId]
end

function PlayerDataService.LoadPlayerProfile(player)
	local defaultProfile = deepCopy(Config.PlayerDataDefaults)
	local success, data = pcall(function()
		return PLAYER_DATA_STORE:GetAsync(player.UserId)
	end)

	local finalProfile = defaultProfile
	if success and type(data) == "table" then
		finalProfile = mergeProfile(defaultProfile, data)
	end

	finalProfile = refreshDerivedProfile(finalProfile)
	profiles[player.UserId] = finalProfile
	return finalProfile
end

function PlayerDataService.RefreshDerivedProfile(profile)
	if not profile then
		return nil
	end
	profile.Stats = profile.Stats or {}
	profile.Equipment = profile.Equipment or {}
	profile.Inventory = profile.Inventory or {}
	profile.EquipmentBonusStats = profile.EquipmentBonusStats or { STR = 0, AGI = 0, INT = 0, VIT = 0, DEX = 0, LUK = 0 }
	for statName, previousValue in pairs(profile.EquipmentBonusStats) do
		profile.Stats[statName] = (profile.Stats[statName] or 0) - (previousValue or 0)
	end
	local bonusStats = { STR = 0, AGI = 0, INT = 0, VIT = 0, DEX = 0, LUK = 0 }
	for _, slotName in pairs({ "Weapon", "Head", "Body", "Legs", "Gloves", "Boots", "Accessory1", "Accessory2" }) do
		local itemId = profile.Equipment[slotName]
		if itemId and Config.ItemDefinitions and Config.ItemDefinitions[itemId] then
			local itemStats = Config.ItemDefinitions[itemId].Stats or {}
			for statName, statValue in pairs(itemStats) do
				if type(statValue) == "number" then
					bonusStats[statName] = (bonusStats[statName] or 0) + statValue
				end
			end
		end
	end
	for statName, statValue in pairs(bonusStats) do
		profile.Stats[statName] = (profile.Stats[statName] or 0) + statValue
	end
	profile.EquipmentBonusStats = bonusStats
	profile.Health = 100 + (profile.Stats.VIT or 0) * 6
	profile.Mana = 50 + (profile.Stats.INT or 0) * 4
	return profile
end

function PlayerDataService.SavePlayerProfile(player)
	local profile = profiles[player.UserId]
	if not profile then
		return false
	end

	local cleanedProfile = refreshDerivedProfile(profile)
	profiles[player.UserId] = cleanedProfile

	local success, _ = pcall(function()
		PLAYER_DATA_STORE:SetAsync(player.UserId, cleanedProfile)
	end)

	return success
end

function PlayerDataService.ApplyProfileToCharacter(player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end

	player:SetAttribute("Class", profile.Class or "Warrior")
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	humanoid.MaxHealth = profile.Health
	humanoid.Health = profile.Health
	local moveSpeed = 16 + (profile.Stats.AGI or 0) * 0.28
	humanoid.WalkSpeed = moveSpeed
	rootPart.CFrame = CFrame.new(Vector3.new(0, 4, 0))
end

function PlayerDataService.AddExperience(player, amount)
	local profile = profiles[player.UserId]
	if not profile then
		return 0
	end

	profile.Exp = (profile.Exp or 0) + math.max(0, amount)
	local previousLevel = profile.Level or 1
	local newLevel = Config.GetLevelFromExp(profile.Exp)
	if newLevel > previousLevel then
		profile.Level = newLevel
		profile.StatPoints = (profile.StatPoints or 0) + (newLevel - previousLevel)
	end
	profile.Level = newLevel
	refreshDerivedProfile(profile)
	return profile.Exp
end

function PlayerDataService.AllocateStat(player, statName)
	local profile = profiles[player.UserId]
	if not profile then
		return false
	end

	local validStats = { "STR", "AGI", "INT", "VIT", "DEX", "LUK" }
	local isValid = false
	for _, stat in ipairs(validStats) do
		if stat == statName then
			isValid = true
			break
		end
	end
	if not isValid then
		return false
	end
	if (profile.StatPoints or 0) <= 0 then
		return false
	end

	profile.Stats = profile.Stats or {}
	profile.Stats[statName] = (profile.Stats[statName] or 0) + 1
	profile.StatPoints = (profile.StatPoints or 0) - 1
	refreshDerivedProfile(profile)
	return true
end

function PlayerDataService.AddGold(player, amount)
	local profile = profiles[player.UserId]
	if not profile then
		return 0
	end

	profile.Gold = (profile.Gold or 0) + math.max(0, amount)
	return profile.Gold
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.SavePlayerProfile(player)
	profiles[player.UserId] = nil
end)

return PlayerDataService
