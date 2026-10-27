local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CombatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatUtil"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local MonsterService = {}

local monsterTable = {}
local monsterIndex = 0
local lootDropIndex = 0
local lootDrops = {}
local defeatListeners = {}
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

local function attachMonsterVisuals(model, template, scale, spawnPosition)
	local root = createPart(model, "HumanoidRootPart", Vector3.new(2.4, 2.4, 2.4) * scale, template.Color, Enum.PartType.Ball, CFrame.new(spawnPosition))
	root.Transparency = 0.4

	local body = createPart(model, "Body", Vector3.new(2.2, 1.9, 1.6) * scale, template.Color, Enum.PartType.Ball, CFrame.new(spawnPosition + Vector3.new(0, 1.1 * scale, 0)))
	body.Transparency = 0.15

	local face = createPart(model, "Face", Vector3.new(1.1, 0.9, 0.2) * scale, Color3.fromRGB(25, 25, 25), Enum.PartType.Block, CFrame.new(spawnPosition + Vector3.new(0, 1.2 * scale, 0.9 * scale)))
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

function MonsterService.GetNearestMonster(position, maxDistance, playerLevel)
	local nearestMonster = nil
	local nearestDistance = maxDistance or 999999

	for _, monsterData in pairs(monsterTable) do
		if monsterData and monsterData.Model and monsterData.Model.Parent and (not playerLevel or (monsterData.Template.Level or 1) <= playerLevel) then
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

local function spawnLootDrops(monsterData)
	for _, dropDefinition in ipairs(monsterData.Template.DropTable or {}) do
		if math.random() <= (dropDefinition.Chance or 0) then
			lootDropIndex = lootDropIndex + 1
			local dropPart = Instance.new("Part")
			dropPart.Name = "LootDrop_" .. lootDropIndex
			dropPart.Shape = Enum.PartType.Ball
			dropPart.Size = Vector3.new(1.2, 1.2, 1.2)
			dropPart.Material = Enum.Material.Neon
			dropPart.Color = Color3.fromRGB(110, 220, 130)
			dropPart.Anchored = true
			dropPart.CanCollide = false
			dropPart.Position = monsterData.SpawnPosition + Vector3.new(0, 1, 0)
			dropPart:SetAttribute("ItemId", dropDefinition.ItemId)
			dropPart.Parent = getMonsterFolder()
			lootDrops[lootDropIndex] = {
				Part = dropPart,
				ItemId = dropDefinition.ItemId,
				Quantity = math.random(dropDefinition.MinQuantity or 1, dropDefinition.MaxQuantity or 1),
			}
			local dropId = lootDropIndex
			task.delay(90, function()
				local expiredDrop = lootDrops[dropId]
				if expiredDrop then
					if expiredDrop.Part then
						expiredDrop.Part:Destroy()
					end
					lootDrops[dropId] = nil
				end
			end)
		end
	end
end

local function firePlayerFeedback(player, messageType, payload)
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotesFolder and remotesFolder:FindFirstChild("CombatFeedback")
	if player and remote then
		remote:FireClient(player, messageType, payload)
	end
end

local function handleMonsterDeath(monsterData)
	if monsterData.DeathHandled then
		return
	end
	monsterData.DeathHandled = true
	monsterData.Model:SetAttribute("Health", 0)
	spawnLootDrops(monsterData)

	local killer = monsterData.LastAttacker
	local template = monsterData.Template
	if killer then
		local expReward = template.ExpReward or 0
		local goldReward = math.random(template.GoldMin or 0, template.GoldMax or 0)
		PlayerDataService.AddExperience(killer, expReward)
		PlayerDataService.AddGold(killer, goldReward)
		PlayerDataService.SavePlayerProfile(killer)
		firePlayerFeedback(killer, "Reward", {
			PlayerName = killer.Name,
			Exp = expReward,
			Gold = goldReward,
		})
	end

	fireCombatFeedback("MonsterDefeated", {
		MonsterId = monsterData.Id,
		Tier = template.Tier or "NORMAL",
		MonsterName = template.Name,
	})
	for _, listener in ipairs(defeatListeners) do
		task.spawn(function()
			local success, message = pcall(listener, monsterData, killer)
			if not success then
				warn("Monster defeat listener failed: " .. tostring(message))
			end
		end)
	end
	if monsterData.RespawnEnabled then
		task.delay(template.RespawnTime or 3, function()
			if monsterTable[monsterData.Id] == monsterData then
				MonsterService.RespawnMonster(monsterData.Id)
			end
		end)
	end
end

local function startMonsterCombat(monsterData)
	local template = monsterData.Template
	if not template.Attack or template.Attack <= 0 then
		return
	end

	local model = monsterData.Model
	local humanoid = monsterData.Humanoid
	task.spawn(function()
		local nextAttackTime = 0
		while monsterData.Model == model and model.Parent and humanoid.Health > 0 do
			local phaseRatio = template.Phase2HealthRatio
			if phaseRatio and monsterData.Phase == 1 and humanoid.Health / humanoid.MaxHealth <= phaseRatio then
				monsterData.Phase = 2
				model:SetAttribute("Phase", 2)
				local body = model:FindFirstChild("Body")
				if body then
					body.Color = Color3.fromRGB(204, 104, 78)
				end
				fireCombatFeedback("BossPhase", {
					MonsterId = monsterData.Id,
					MonsterName = template.Name,
					Phase = 2,
				})
			end

			local closestHumanoid = nil
			local closestDistance = template.AggroRange or 0
			for _, candidate in ipairs(Players:GetPlayers()) do
				local character = candidate.Character
				local candidateHumanoid = character and character:FindFirstChildOfClass("Humanoid")
				local candidateRoot = character and character:FindFirstChild("HumanoidRootPart")
				if candidateHumanoid and candidateRoot and candidateHumanoid.Health > 0 then
					local distance = (candidateRoot.Position - monsterData.RootPart.Position).Magnitude
					if distance <= closestDistance then
						closestHumanoid = candidateHumanoid
						closestDistance = distance
					end
				end
			end

			if closestHumanoid and closestDistance <= (template.AttackRange or 5) and os.clock() >= nextAttackTime then
				local attackDamage = monsterData.Phase == 2 and (template.Phase2Attack or template.Attack) or template.Attack
				closestHumanoid:TakeDamage(attackDamage)
				local cooldown = monsterData.Phase == 2 and (template.Phase2AttackCooldown or template.AttackCooldown) or template.AttackCooldown
				nextAttackTime = os.clock() + (cooldown or 2)
			end
			task.wait(0.35)
		end
	end)
end

local function createMonsterModel(monsterData)
	local template = monsterData.Template
	local monsterModel = Instance.new("Model")
	monsterModel.Name = template.Name .. "_" .. monsterData.Id
	monsterModel.Parent = getMonsterFolder()
	monsterModel:SetAttribute("MonsterId", monsterData.Id)
	monsterModel:SetAttribute("MonsterName", template.Name)
	monsterModel:SetAttribute("MonsterTier", template.Tier or "NORMAL")
	monsterModel:SetAttribute("MonsterLevel", template.Level or 1)
	monsterModel:SetAttribute("Phase", 1)
	monsterModel:SetAttribute("ZoneKey", monsterData.ZoneKey or "")
	monsterModel:SetAttribute("DungeonId", monsterData.DungeonId or "")
	monsterModel:SetAttribute("MaxHealth", template.Health)
	monsterModel:SetAttribute("Health", template.Health)

	local scale = template.Scale or 1
	local root, humanoid = attachMonsterVisuals(monsterModel, template, scale, monsterData.SpawnPosition)
	monsterModel.PrimaryPart = root
	monsterData.Model = monsterModel
	monsterData.Humanoid = humanoid
	monsterData.RootPart = root
	monsterData.Phase = 1
	monsterData.DeathHandled = false

	humanoid.Died:Connect(function()
		handleMonsterDeath(monsterData)
	end)
	startMonsterCombat(monsterData)
end

function MonsterService.CollectNearbyDrops(player, position, radius)
	if not player or not position then
		return 0
	end

	local collected = 0
	for dropId, drop in pairs(lootDrops) do
		if drop.Part and drop.Part.Parent and (drop.Part.Position - position).Magnitude <= (radius or 10) then
			if InventoryService.AddItem(player, drop.ItemId, drop.Quantity) then
				drop.Part:Destroy()
				lootDrops[dropId] = nil
				collected = collected + 1
			end
		end
	end
	return collected
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

	monsterData.LastAttacker = nil
	createMonsterModel(monsterData)
end

function MonsterService.CreateMonster(templateName, spawnPosition, options)
	monsterIndex = monsterIndex + 1
	local template = Config.GetMonsterTemplate(templateName)
	options = options or {}
	local monsterData = {
		Id = monsterIndex,
		Template = template,
		SpawnPosition = spawnPosition,
		LastAttacker = nil,
		ZoneKey = options.ZoneKey,
		DungeonId = options.DungeonId,
		RespawnEnabled = options.Respawn ~= false,
	}

	monsterTable[monsterIndex] = monsterData
	createMonsterModel(monsterData)

	return monsterData
end

function MonsterService.AddDefeatListener(listener)
	if type(listener) ~= "function" then
		return false
	end
	table.insert(defeatListeners, listener)
	return true
end

function MonsterService.RemoveMonster(monsterId)
	local monsterData = monsterTable[monsterId]
	if not monsterData then
		return false
	end
	monsterTable[monsterId] = nil
	if monsterData.Model and monsterData.Model.Parent then
		monsterData.Model:Destroy()
	end
	return true
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
		handleMonsterDeath(monsterData)
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
end

return MonsterService
