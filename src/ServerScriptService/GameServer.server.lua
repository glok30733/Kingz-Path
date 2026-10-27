local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CombatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatUtil"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local ZoneService = require(script.Parent:WaitForChild("ZoneService"))

local function ensureFolder(name, parent)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local remotesFolder = ensureFolder("Remotes", ReplicatedStorage)
local combatRemote = remotesFolder:FindFirstChild("AttackRequest")
if not combatRemote then
	combatRemote = Instance.new("RemoteEvent")
	combatRemote.Name = "AttackRequest"
	combatRemote.Parent = remotesFolder
end

local skillRemote = remotesFolder:FindFirstChild("SkillRequest")
if not skillRemote then
	skillRemote = Instance.new("RemoteEvent")
	skillRemote.Name = "SkillRequest"
	skillRemote.Parent = remotesFolder
end

local statRemote = remotesFolder:FindFirstChild("StatRequest")
if not statRemote then
	statRemote = Instance.new("RemoteEvent")
	statRemote.Name = "StatRequest"
	statRemote.Parent = remotesFolder
end

local inventoryRemote = remotesFolder:FindFirstChild("InventoryRequest")
if not inventoryRemote then
	inventoryRemote = Instance.new("RemoteEvent")
	inventoryRemote.Name = "InventoryRequest"
	inventoryRemote.Parent = remotesFolder
end

local feedbackRemote = remotesFolder:FindFirstChild("CombatFeedback")
if not feedbackRemote then
	feedbackRemote = Instance.new("RemoteEvent")
	feedbackRemote.Name = "CombatFeedback"
	feedbackRemote.Parent = remotesFolder
end

MonsterService.Initialize()
ZoneService.Initialize()

local function setupSpawnLocation()
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if not spawnLocation then
		spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "SpawnLocation"
		spawnLocation.Size = Vector3.new(6, 1, 6)
		spawnLocation.Position = Vector3.new(0, 2, 0)
		spawnLocation.Anchored = true
		spawnLocation.CanCollide = true
		spawnLocation.Parent = Workspace
		spawnLocation.Transparency = 0.5
		spawnLocation.Neutral = true
		spawnLocation.Color = Color3.fromRGB(154, 172, 255)
	end
end

setupSpawnLocation()

local function applyPlayerSpawn(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local root = character:WaitForChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(Vector3.new(0, 4, 0))
		end
		humanoid.WalkSpeed = 16
		if player and player.Parent then
			PlayerDataService.ApplyProfileToCharacter(player)
			ZoneService.ApplyZone(player)
		end
	end)
end

local function onPlayerAdded(player)
	PlayerDataService.LoadPlayerProfile(player)
	applyPlayerSpawn(player)
	local profile = PlayerDataService.GetProfile(player)
	if profile then
		profile.Class = "Warrior"
	end
	player.CharacterAppearanceLoaded:Connect(function()
		PlayerDataService.ApplyProfileToCharacter(player)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

combatRemote.OnServerEvent:Connect(function(player, targetMonsterId)
	if not player or not player.Character then
		return
	end

	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return
	end

	local classConfig = Config.GetClassConfig(profile.Class or "Warrior")
	local currentCharacter = player.Character
	local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local target = MonsterService.GetMonsterById(targetMonsterId)
	if not target or not target.Model or not target.Model.Parent then
		return
	end

	local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return
	end

	local distance = (rootPart.Position - targetRoot.Position).Magnitude
	if distance > (classConfig.BasicAttack.Range or 18) then
		return
	end

	local stats = profile.Stats or {}
	local damage = CombatUtil.CalculateDamage({ Stats = stats }, target.Template.Defense or 0, 0.12)
	MonsterService.DamageMonster(targetMonsterId, player, damage)
	feedbackRemote:FireClient(player, "AttackResult", {
		MonsterId = targetMonsterId,
		Damage = damage,
		TargetHealth = math.max(0, target.Humanoid and target.Humanoid.Health or 0),
	})
end)

skillRemote.OnServerEvent:Connect(function(player, skillName, targetMonsterId)
	if not player or not player.Character then
		return
	end

	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return
	end

	local classConfig = Config.GetClassConfig(profile.Class or "Warrior")
	local skillData = classConfig.Skills and classConfig.Skills[skillName]
	if not skillData then
		return
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		return
	end

	local currentMana = profile.Mana or 50
	if currentMana < (skillData.Cost or 0) then
		return
	end

	local target = MonsterService.GetMonsterById(targetMonsterId)
	if not target or not target.Model or not target.Model.Parent then
		return
	end

	local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not rootPart then
		return
	end

	local distance = (rootPart.Position - targetRoot.Position).Magnitude
	if distance > (skillData.Range or 20) then
		return
	end

	profile.Mana = currentMana - (skillData.Cost or 0)
	local stats = profile.Stats or {}
	local skillDamage = CombatUtil.CalculateDamage({ Stats = stats }, target.Template.Defense or 0, 0.18)
	local bonusDamage = math.random(skillData.MinDamage or 10, skillData.MaxDamage or 20)
	local totalDamage = skillDamage + bonusDamage
	MonsterService.DamageMonster(targetMonsterId, player, totalDamage)
	feedbackRemote:FireClient(player, "SkillResult", {
		Skill = skillName,
		MonsterId = targetMonsterId,
		Damage = totalDamage,
	})
end)

statRemote.OnServerEvent:Connect(function(player, statName)
	if not player then
		return
	end
	PlayerDataService.AllocateStat(player, statName)
end)

inventoryRemote.OnServerEvent:Connect(function(player, action, payload)
	if not player then
		return
	end
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return
	end
	if action == "equip" then
		local success = InventoryService.EquipItem(player, payload)
		if success then
			feedbackRemote:FireClient(player, "InventoryUpdate", InventoryService.GetSnapshot(player))
		end
	elseif action == "unequip" then
		local success = InventoryService.UnequipItem(player, payload)
		if success then
			feedbackRemote:FireClient(player, "InventoryUpdate", InventoryService.GetSnapshot(player))
		end
	elseif action == "addTestItem" then
		InventoryService.AddItem(player, payload or "IronSword", 1)
		feedbackRemote:FireClient(player, "InventoryUpdate", InventoryService.GetSnapshot(player))
	else
		feedbackRemote:FireClient(player, "InventoryUpdate", InventoryService.GetSnapshot(player))
	end
end)

print("Kingz-Path Phase 2 server initialized.")
