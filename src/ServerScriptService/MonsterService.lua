local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CombatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatUtil"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local MonsterService = {}

local monsterTable = {}
local monsterIndex = 0
local monstersFolder = nil
local initialized = false

local function getMonsterFolder()
	if monstersFolder and monstersFolder.Parent then
		return monstersFolder
	end

	local workspaceMonsters = Workspace:FindFirstChild("Monsters")
	if not workspaceMonsters then
		workspaceMonsters = Instance.new("Folder")
		workspaceMonsters.Name = "Monsters"
		workspaceMonsters.Parent = Workspace
	end

	monstersFolder = workspaceMonsters
	return monstersFolder
end

local function createPart(model, name, size, color, shape, cframe)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = cframe
	part.Parent = model
	return part
end

local function attachMonsterVisuals(model, template)
	local root = createPart(model, "HumanoidRootPart", Vector3.new(2.4, 2.4, 2.4), template.Color, Enum.PartType.Ball, CFrame.new(0, 1.2, 0))
	root.Transparency = 0.4

	local body = createPart(model, "Body", Vector3.new(2.2, 1.9, 1.6), template.Color, Enum.PartType.Ball, CFrame.new(0, 2.4, 0))
	body.Transparency = 0.15

	local face = createPart(model, "Face", Vector3.new(1.1, 0.9, 0.2), Color3.fromRGB(25, 25, 25), Enum.PartType.Block, CFrame.new(0, 2.5, 0.9))
	face.Transparency = 0.1

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = template.Health
	humanoid.Health = template.Health
	humanoid.Name = "Humanoid"
	humanoid.WalkSpeed = template.MoveSpeed
	humanoid.Parent = model

	return root, humanoid
end

function MonsterService.GetMonsterById(monsterId)
	return monsterTable[monsterId]
end

function MonsterService.GetNearestMonster(position, maxDistance)
	local nearestMonster = nil
	local nearestDistance = maxDistance or 999999

	for _, monsterData in pairs(monsterTable) do
		if monsterData and monsterData.Model and monsterData.Model.Parent then
			local humanoid = monsterData.Model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local root = monsterData.Model:FindFirstChild("HumanoidRootPart")
				if root then
					local distance = (root.Position - position).Magnitude
					if distance < nearestDistance then
						nearestMonster = monsterData
						nearestDistance = distance
					end
				end
			end
		end
	end

	return nearestMonster
end

local function fireCombatFeedback(messageType, payload)
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotesFolder and remotesFolder:FindFirstChild("CombatFeedback")
	if remote then
		remote:FireAllClients(messageType, payload)
	end
end

local function rewardPlayerForKill(player, template)
	if not player then
		return
	end

	local expGained = template.ExpReward or 0
	local goldGained = math.random(template.GoldMin or 0, template.GoldMax or 0)
	PlayerDataService.AddExperience(player, expGained)
	PlayerDataService.AddGold(player, goldGained)
	fireCombatFeedback("Reward", {
		PlayerName = player.Name,
		Exp = expGained,
		Gold = goldGained,
	})
end

function MonsterService.RespawnMonster(monsterId)
	local monsterData = monsterTable[monsterId]
	if not monsterData then
		return
	end

	local model = monsterData.Model
	if model and model.Parent then
		model:Destroy()
	end

	local template = monsterData.Template
	local monsterModel = Instance.new("Model")
	monsterModel.Name = template.Name .. "_" .. monsterId
	monsterModel.Parent = getMonsterFolder()
	monsterModel:SetAttribute("MonsterId", monsterId)
	monsterModel:SetAttribute("MonsterName", template.Name)
	monsterModel:SetAttribute("MaxHealth", template.Health)
	monsterModel:SetAttribute("Health", template.Health)

	local root, humanoid = attachMonsterVisuals(monsterModel, template)
	root.Position = monsterData.SpawnPosition
	monsterData.Model = monsterModel
	monsterData.Humanoid = humanoid
	monsterData.RootPart = root

	humanoid.Died:Connect(function()
		local killer = monsterData.LastAttacker
		if killer then
			rewardPlayerForKill(killer, template)
		end
		task.delay(3, function()
			MonsterService.RespawnMonster(monsterId)
		end)
	end)
end

function MonsterService.CreateMonster(templateName, spawnPosition)
	monsterIndex = monsterIndex + 1
	local template = Config.GetMonsterTemplate(templateName)
	local monsterModel = Instance.new("Model")
	monsterModel.Name = template.Name .. "_" .. monsterIndex
	monsterModel.Parent = getMonsterFolder()
	monsterModel:SetAttribute("MonsterId", monsterIndex)
	monsterModel:SetAttribute("MonsterName", template.Name)
	monsterModel:SetAttribute("MaxHealth", template.Health)
	monsterModel:SetAttribute("Health", template.Health)

	local root, humanoid = attachMonsterVisuals(monsterModel, template)
	root.Position = spawnPosition

	local monsterData = {
		Id = monsterIndex,
		Template = template,
		Model = monsterModel,
		Humanoid = humanoid,
		RootPart = root,
		SpawnPosition = spawnPosition,
		LastAttacker = nil,
	}

	monsterTable[monsterIndex] = monsterData
	monsterModel.PrimaryPart = root

	humanoid.Died:Connect(function()
		monsterModel:SetAttribute("Health", 0)
		local killer = monsterData.LastAttacker
		if killer then
			rewardPlayerForKill(killer, template)
		end
		task.delay(3, function()
			MonsterService.RespawnMonster(monsterIndex)
		end)
	end)

	return monsterData
end

function MonsterService.DamageMonster(monsterId, attackerPlayer, amount)
	local monsterData = monsterTable[monsterId]
	if not monsterData then
		return false
	end

	local humanoid = monsterData.Humanoid
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	monsterData.LastAttacker = attackerPlayer
	humanoid:TakeDamage(amount)
	monsterData.Model:SetAttribute("Health", math.max(0, humanoid.Health))
	fireCombatFeedback("MonsterDamage", {
		MonsterId = monsterId,
		Health = math.max(0, humanoid.Health),
		MaxHealth = humanoid.MaxHealth,
		Damage = amount,
	})

	if humanoid.Health <= 0 then
		monsterData.Model:SetAttribute("Health", 0)
		local template = monsterData.Template
		local rewardExp = template.ExpReward or 0
		local rewardGold = math.random(template.GoldMin or 0, template.GoldMax or 0)
		if attackerPlayer then
			local profile = PlayerDataService.GetProfile(attackerPlayer)
			if profile then
				profile.Exp = (profile.Exp or 0) + rewardExp
				profile.Gold = (profile.Gold or 0) + rewardGold
				local levelBefore = profile.Level or 1
				local levelAfter = Config.GetLevelFromExp(profile.Exp)
				if levelAfter > levelBefore then
					profile.Level = levelAfter
					profile.StatPoints = (profile.StatPoints or 0) + (levelAfter - levelBefore)
				end
				profile.Level = levelAfter
				PlayerDataService.SavePlayerProfile(attackerPlayer)
			end
		end
		fireCombatFeedback("Reward", {
			PlayerName = attackerPlayer and attackerPlayer.Name or "Unknown",
			Exp = rewardExp,
			Gold = rewardGold,
		})
		return true
	end

	return true
end

function MonsterService.Initialize()
	if initialized then
		return
	end

	initialized = true
	getMonsterFolder()
	local monsterSpawns = {
		{ "Slime", Vector3.new(0, 4, 24) },
		{ "Slime", Vector3.new(18, 4, 18) },
		{ "Wolf", Vector3.new(-18, 4, 18) },
		{ "Skeleton", Vector3.new(24, 4, 0) },
		{ "Slime", Vector3.new(-24, 4, 0) },
	}

	for _, entry in ipairs(monsterSpawns) do
		MonsterService.CreateMonster(entry[1], entry[2])
	end
end

return MonsterService
