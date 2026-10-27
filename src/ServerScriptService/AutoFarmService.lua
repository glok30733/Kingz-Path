local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CombatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatUtil"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local AutoFarmService = {}
local playerStates = {}

local function ensureState(player)
	if not player then
		return nil
	end
	local userId = player.UserId
	if not playerStates[userId] then
		playerStates[userId] = {
			enabled = false,
			autoAttack = true,
			autoSkill = true,
			autoLoot = true,
			autoPotion = true,
			loop = nil,
		}
	end
	return playerStates[userId]
end

local function updatePlayerState(player)
	local state = ensureState(player)
	if not state then
		return nil
	end
	return state
end

local function attackNearestTarget(player)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return false
	end
	local classConfig = Config.GetClassConfig(profile.Class or "Warrior")
	local character = player.Character
	if not character then
		return false
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end
	local target = MonsterService.GetNearestMonster(rootPart.Position, 45, profile.Level or 1)
	if not target or not target.Model or not target.Model.Parent then
		return false
	end
	local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return false
	end
	local distance = (rootPart.Position - targetRoot.Position).Magnitude
	if distance > (classConfig.BasicAttack.Range or 18) then
		return false
	end
	local stats = profile.Stats or {}
	local damage = CombatUtil.CalculateDamage({ Stats = stats }, target.Template.Defense or 0, 0.12)
	MonsterService.DamageMonster(target.Id, player, damage)
	return true
end

local function useBestSkill(player)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return false
	end
	local classConfig = Config.GetClassConfig(profile.Class or "Warrior")
	local skills = classConfig.Skills or {}
	local skillName, skillData = nil, nil
	for name, definition in pairs(skills) do
		if (profile.Mana or 50) >= (definition.Cost or 0) then
			skillName = name
			skillData = definition
			break
		end
	end
	if not skillName or not skillData then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end
	local target = MonsterService.GetNearestMonster(rootPart.Position, 45, profile.Level or 1)
	if not target or not target.Model or not target.Model.Parent then
		return false
	end
	local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return false
	end
	local distance = (rootPart.Position - targetRoot.Position).Magnitude
	if distance > (skillData.Range or 20) then
		return false
	end
	profile.Mana = (profile.Mana or 50) - (skillData.Cost or 0)
	local stats = profile.Stats or {}
	local skillDamage = CombatUtil.CalculateDamage({ Stats = stats }, target.Template.Defense or 0, 0.18)
	local bonusDamage = math.random(skillData.MinDamage or 10, skillData.MaxDamage or 20)
	local totalDamage = skillDamage + bonusDamage
	MonsterService.DamageMonster(target.Id, player, totalDamage)
	return true
end

local function startLoop(player)
	local state = updatePlayerState(player)
	if not state or state.loop then
		return
	end
	state.loop = task.spawn(function()
		while state.enabled and player.Parent do
			if not player.Character then
				break
			end
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				state.enabled = false
				break
			end
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				if state.autoPotion and humanoid.Health / humanoid.MaxHealth <= 0.5 then
					if InventoryService.UseConsumable(player, "HealthPotion") then
						local remotes = ReplicatedStorage:FindFirstChild("Remotes")
						local feedbackRemote = remotes and remotes:FindFirstChild("CombatFeedback")
						if feedbackRemote then
							feedbackRemote:FireClient(player, "InventoryUpdate", InventoryService.GetSnapshot(player))
						end
					end
				end
				if state.autoLoot and MonsterService.CollectNearbyDrops(player, rootPart.Position, 12) > 0 then
					local remotes = ReplicatedStorage:FindFirstChild("Remotes")
					local feedbackRemote = remotes and remotes:FindFirstChild("CombatFeedback")
					if feedbackRemote then
						feedbackRemote:FireClient(player, "InventoryUpdate", InventoryService.GetSnapshot(player))
					end
				end
				local profile = PlayerDataService.GetProfile(player)
				local target = MonsterService.GetNearestMonster(rootPart.Position, 50, profile and profile.Level or 1)
				if target and target.Model and target.Model.Parent then
					local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
					if targetRoot then
						local distance = (rootPart.Position - targetRoot.Position).Magnitude
						if distance > 5 then
							local direction = (targetRoot.Position - rootPart.Position)
							if direction.Magnitude > 0 then
								direction = direction.Unit
							end
							local step = direction * math.min(distance, 8)
							rootPart.CFrame = CFrame.new(rootPart.Position + step)
						elseif state.autoSkill then
							local skillUsed = useBestSkill(player)
							if not skillUsed and state.autoAttack then
								attackNearestTarget(player)
							end
						elseif state.autoAttack then
							attackNearestTarget(player)
						end
					end
				end
			end
			task.wait(0.45)
		end
		state.loop = nil
	end)
end

function AutoFarmService.SetSettings(player, settings)
	local state = ensureState(player)
	if not state then
		return nil
	end
	if settings then
		if settings.enabled ~= nil then
			state.enabled = settings.enabled
		end
		if settings.autoAttack ~= nil then
			state.autoAttack = settings.autoAttack
		end
		if settings.autoSkill ~= nil then
			state.autoSkill = settings.autoSkill
		end
		if settings.autoLoot ~= nil then
			state.autoLoot = settings.autoLoot
		end
		if settings.autoPotion ~= nil then
			state.autoPotion = settings.autoPotion
		end
	end
	if state.enabled then
		startLoop(player)
	else
		state.loop = nil
	end
	return state
end

function AutoFarmService.Toggle(player, enabled)
	return AutoFarmService.SetSettings(player, { enabled = enabled })
end

function AutoFarmService.Stop(player)
	return AutoFarmService.SetSettings(player, { enabled = false })
end

return AutoFarmService
