local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))

local ZoneService = {}

local activeZoneKeys = {}
local initialized = false

local function ensureZonePart(zoneKey, zoneData)
	local zoneFolder = Workspace:FindFirstChild("Zones")
	if not zoneFolder then
		zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Zones"
		zoneFolder.Parent = Workspace
	end

	local zonePart = zoneFolder:FindFirstChild(zoneKey)
	if not zonePart then
		zonePart = Instance.new("Part")
		zonePart.Name = zoneKey
		zonePart.Size = Vector3.new(104, 4, 104)
		zonePart.Position = zoneData.SpawnPosition or Vector3.new(0, 0, 0)
		zonePart.Anchored = true
		zonePart.CanCollide = false
		zonePart.Transparency = 0.18
		zonePart.Material = Enum.Material.Slate
		zonePart.Color = Color3.fromRGB(73, 91, 82)
		zonePart.CanTouch = true
		zonePart.Parent = zoneFolder
	end
	zonePart.Size = Vector3.new(104, 4, 104)
	zonePart.Position = zoneData.SpawnPosition or Vector3.new(0, 0, 0)
	zonePart.CanCollide = true
	return zonePart
end

local function spawnZonePopulation(zoneKey, zoneData)
	local pool = zoneData.MonsterPool or {}
	for index = 1, zoneData.MonsterCount or 0 do
		local templateName = pool[((index - 1) % #pool) + 1]
		local angle = index * 2.399963
		local radius = 14 + (index % 3) * 7
		local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		MonsterService.CreateMonster(templateName, zoneData.SpawnPosition + offset + Vector3.new(0, 4, 0), {
			ZoneKey = zoneKey,
		})
	end

	for _, specialSpawn in ipairs(zoneData.SpecialSpawns or {}) do
		MonsterService.CreateMonster(specialSpawn.Template, zoneData.SpawnPosition + specialSpawn.Offset + Vector3.new(0, 4, 0), {
			ZoneKey = zoneKey,
		})
	end
end

function ZoneService.GetPlayerZone(player)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return WorldConfig.Zones.StarterVillage
	end
	return WorldConfig.GetZoneForLevel(profile.Level or 1)
end

function ZoneService.GetCurrentZoneKey(player)
	local profile = PlayerDataService.GetProfile(player)
	local activeZoneKey = activeZoneKeys[player.UserId]
	if activeZoneKey then
		local activeZone = WorldConfig.Zones[activeZoneKey]
		if activeZone and profile and (profile.Level or 1) >= (activeZone.LevelMin or 1) then
			return activeZoneKey
		end
	end
	local zone = ZoneService.GetPlayerZone(player)
	for zoneKey, zoneData in pairs(WorldConfig.Zones) do
		if zoneData == zone then
			return zoneKey
		end
	end
	return "StarterVillage"
end

function ZoneService.GetSnapshot(player)
	local profile = PlayerDataService.GetProfile(player)
	local level = profile and profile.Level or 1
	local currentZoneKey = ZoneService.GetCurrentZoneKey(player)
	local snapshot = {}
	for zoneKey, zoneData in pairs(WorldConfig.Zones) do
		table.insert(snapshot, {
			Key = zoneKey,
			Name = zoneData.Name,
			LevelMin = zoneData.LevelMin or 1,
			Unlocked = level >= (zoneData.LevelMin or 1),
			Current = zoneKey == currentZoneKey,
		})
	end
	table.sort(snapshot, function(left, right)
		return left.LevelMin < right.LevelMin
	end)
	return snapshot
end

function ZoneService.TravelToZone(player, zoneKey)
	local zoneData = WorldConfig.Zones[zoneKey]
	local profile = PlayerDataService.GetProfile(player)
	if not zoneData or not profile then
		return false, "Unknown zone"
	end
	if (profile.Level or 1) < (zoneData.LevelMin or 1) then
		return false, string.format("Requires level %d", zoneData.LevelMin or 1)
	end
	if player:GetAttribute("InDungeon") then
		return false, "Leave the dungeon before traveling"
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "Character is not ready"
	end
	activeZoneKeys[player.UserId] = zoneKey
	root.CFrame = CFrame.new(zoneData.SpawnPosition + Vector3.new(0, 4, 0))
	return true, zoneData.Name
end

function ZoneService.ApplyZone(player)
	local zoneKey = ZoneService.GetCurrentZoneKey(player)
	local zone = WorldConfig.Zones[zoneKey]
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new((zone.SpawnPosition or Vector3.new(0, 5, 0)) + Vector3.new(0, 4, 0))
	end
	activeZoneKeys[player.UserId] = zoneKey
	return zone
end

function ZoneService.Initialize()
	if initialized then
		return
	end
	initialized = true
	for zoneKey, zoneData in pairs(WorldConfig.Zones) do
		ensureZonePart(zoneKey, zoneData)
		spawnZonePopulation(zoneKey, zoneData)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local profile = PlayerDataService.GetProfile(player)
			if profile then
				if (profile.Level or 1) < 1 then
					return
				end
			end
			ZoneService.ApplyZone(player)
		end)
	end)
end

return ZoneService
