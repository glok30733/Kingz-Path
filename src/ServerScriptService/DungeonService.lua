local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local ZoneService = require(script.Parent:WaitForChild("ZoneService"))

local DungeonService = {}
local runsByUserId = {}
local nextRunId = 0
local initialized = false
local dungeonFolder = nil

local DUNGEON_LEVEL_REQUIREMENT = 25
local COMPLETION_EXPERIENCE = 500
local COMPLETION_GOLD = 250
local WAVE_TEMPLATES = {
	{ "Wolf", "Wolf", "EliteWolf" },
	{ "Skeleton", "EliteWolf", "Skeleton" },
	{ "AncientGuardian" },
}
local SPAWN_OFFSETS = {
	Vector3.new(-18, 12, -18),
	Vector3.new(0, 12, -22),
	Vector3.new(18, 12, -18),
}

local function getDungeonFolder()
	if dungeonFolder and dungeonFolder.Parent then
		return dungeonFolder
	end
	dungeonFolder = Workspace:FindFirstChild("Dungeons")
	if not dungeonFolder then
		dungeonFolder = Instance.new("Folder")
		dungeonFolder.Name = "Dungeons"
		dungeonFolder.Parent = Workspace
	end
	return dungeonFolder
end

local function getFeedbackRemote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild("CombatFeedback")
end

local function sendDungeonUpdate(player, run, message)
	local remote = getFeedbackRemote()
	if not remote then
		return
	end
	remote:FireClient(player, "DungeonUpdate", {
		Active = run ~= nil,
		Completed = run and run.Completed or false,
		Wave = run and run.Wave or 0,
		WaveCount = #WAVE_TEMPLATES,
		Message = message or "",
	})
end

local function createArena(run)
	local folder = Instance.new("Folder")
	folder.Name = "Run_" .. run.Id
	folder.Parent = getDungeonFolder()
	run.Folder = folder

	local center = run.Center
	local floor = Instance.new("Part")
	floor.Name = "ArenaFloor"
	floor.Size = Vector3.new(96, 2, 96)
	floor.Position = center + Vector3.new(0, -1, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(57, 68, 61)
	floor.Parent = folder

	local wallSpecs = {
		{ Size = Vector3.new(96, 18, 2), Offset = Vector3.new(0, 8, -48) },
		{ Size = Vector3.new(96, 18, 2), Offset = Vector3.new(0, 8, 48) },
		{ Size = Vector3.new(2, 18, 96), Offset = Vector3.new(-48, 8, 0) },
		{ Size = Vector3.new(2, 18, 96), Offset = Vector3.new(48, 8, 0) },
	}
	for index, wallSpec in ipairs(wallSpecs) do
		local wall = Instance.new("Part")
		wall.Name = "ArenaWall_" .. index
		wall.Size = wallSpec.Size
		wall.Position = center + wallSpec.Offset
		wall.Anchored = true
		wall.Material = Enum.Material.Rock
		wall.Color = Color3.fromRGB(39, 49, 45)
		wall.Parent = folder
	end
end

local function clearRunMonsters(run)
	for monsterId in pairs(run.MonsterIds) do
		MonsterService.RemoveMonster(monsterId)
		run.MonsterIds[monsterId] = nil
	end
end

local function endRun(player, message, returnToZone)
	local run = runsByUserId[player.UserId]
	if not run then
		return false
	end
	runsByUserId[player.UserId] = nil
	clearRunMonsters(run)
	if run.Folder then
		run.Folder:Destroy()
	end
	player:SetAttribute("InDungeon", false)
	player:SetAttribute("DungeonWave", 0)
	if returnToZone and player.Character then
		ZoneService.TravelToZone(player, ZoneService.GetCurrentZoneKey(player))
	end
	sendDungeonUpdate(player, nil, message)
	return true
end

local function completeRun(player, run)
	if run.Completed then
		return
	end
	run.Completed = true
	player:SetAttribute("DungeonWave", #WAVE_TEMPLATES)
	PlayerDataService.AddExperience(player, COMPLETION_EXPERIENCE)
	PlayerDataService.AddGold(player, COMPLETION_GOLD)
	PlayerDataService.SavePlayerProfile(player)
	sendDungeonUpdate(player, run, "Guardian defeated. Claim your clear and exit.")
	local remote = getFeedbackRemote()
	if remote then
		remote:FireClient(player, "Reward", {
			PlayerName = player.Name,
			Exp = COMPLETION_EXPERIENCE,
			Gold = COMPLETION_GOLD,
		})
	end
end

local function startWave(player, run)
	if runsByUserId[player.UserId] ~= run then
		return
	end
	run.Wave = run.Wave + 1
	player:SetAttribute("DungeonWave", run.Wave)
	if run.Wave > #WAVE_TEMPLATES then
		completeRun(player, run)
		return
	end

	local templates = WAVE_TEMPLATES[run.Wave]
	run.Remaining = #templates
	run.MonsterIds = {}
	sendDungeonUpdate(player, run, string.format("Wave %d: %d enemies", run.Wave, run.Remaining))
	for index, templateName in ipairs(templates) do
		local offset = SPAWN_OFFSETS[((index - 1) % #SPAWN_OFFSETS) + 1]
		local monsterData = MonsterService.CreateMonster(templateName, run.Center + offset, {
			DungeonId = run.Id,
			Respawn = false,
		})
		run.MonsterIds[monsterData.Id] = true
	end
end

local function onMonsterDefeated(monsterData, killer)
	local dungeonId = monsterData.DungeonId
	if not dungeonId or not killer then
		return
	end
	local run = runsByUserId[killer.UserId]
	if not run or run.Id ~= dungeonId or not run.MonsterIds[monsterData.Id] then
		return
	end

	run.MonsterIds[monsterData.Id] = nil
	run.Remaining = math.max(0, run.Remaining - 1)
	if run.Remaining == 0 then
		startWave(killer, run)
	else
		sendDungeonUpdate(killer, run, string.format("Wave %d: %d enemies left", run.Wave, run.Remaining))
	end
end

function DungeonService.Request(player, action)
	if action == "sync" then
		local currentRun = runsByUserId[player.UserId]
		sendDungeonUpdate(player, currentRun, currentRun and "Dungeon run in progress." or "Enter at level 25.")
		return true
	end
	if action == "exit" then
		return endRun(player, "Dungeon exited.", true)
	end
	if action ~= "enter" then
		return false
	end

	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return false
	end
	if (profile.Level or 1) < DUNGEON_LEVEL_REQUIREMENT then
		sendDungeonUpdate(player, nil, string.format("Requires level %d.", DUNGEON_LEVEL_REQUIREMENT))
		return false
	end
	if runsByUserId[player.UserId] then
		sendDungeonUpdate(player, runsByUserId[player.UserId], "You are already in the dungeon.")
		return false
	end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	nextRunId = nextRunId + 1
	local run = {
		Id = nextRunId,
		Center = Vector3.new(1400 + (nextRunId - 1) * 128, 12, 0),
		Wave = 0,
		Remaining = 0,
		MonsterIds = {},
		Completed = false,
	}
	runsByUserId[player.UserId] = run
	createArena(run)
	player:SetAttribute("InDungeon", true)
	player.Character.HumanoidRootPart.CFrame = CFrame.new(run.Center + Vector3.new(0, 5, 34))
	startWave(player, run)
	return true
end

function DungeonService.Initialize()
	if initialized then
		return
	end
	initialized = true
	MonsterService.AddDefeatListener(onMonsterDefeated)

	local function bindPlayer(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				endRun(player, "Run ended. You were defeated.", false)
			end)
		end)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		endRun(player, "Run ended.", false)
	end)
end

return DungeonService
