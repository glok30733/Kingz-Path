local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))

local QuestService = {}
local QUEST_ID = "SlimeHunt"
local QUEST_TARGET = 3
local QUEST_EXP_REWARD = 120
local QUEST_GOLD_REWARD = 80
local initialized = false

local function getQuestSnapshot(player)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return nil
	end
	return {
		Id = QUEST_ID,
		Title = "Village Pest Control",
		Description = "Defeat 3 Slimes near the village.",
		Progress = math.min(profile.QuestProgress or 0, QUEST_TARGET),
		Target = QUEST_TARGET,
		Complete = (profile.QuestProgress or 0) >= QUEST_TARGET,
		Claimed = profile.QuestClaimed == true,
		RewardExp = QUEST_EXP_REWARD,
		RewardGold = QUEST_GOLD_REWARD,
	}
end

local function sendQuestUpdate(player, message)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local feedbackRemote = remotes and remotes:FindFirstChild("CombatFeedback")
	local snapshot = getQuestSnapshot(player)
	if feedbackRemote and snapshot then
		snapshot.Message = message or ""
		feedbackRemote:FireClient(player, "QuestUpdate", snapshot)
	end
end

local function onMonsterDefeated(monsterData, killer)
	if not killer or monsterData.Template.Name ~= "Slime" then
		return
	end
	local profile = PlayerDataService.GetProfile(killer)
	if not profile or profile.QuestClaimed or (profile.QuestProgress or 0) >= QUEST_TARGET then
		return
	end

	profile.QuestProgress = (profile.QuestProgress or 0) + 1
	PlayerDataService.SavePlayerProfile(killer)
	sendQuestUpdate(killer, profile.QuestProgress >= QUEST_TARGET and "Quest complete. Claim your reward." or "Slime defeated.")
end

function QuestService.Request(player, action)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return false
	end

	if action == "sync" then
		sendQuestUpdate(player)
		return true
	end
	if action ~= "claim" then
		return false
	end
	if profile.QuestClaimed or (profile.QuestProgress or 0) < QUEST_TARGET then
		sendQuestUpdate(player, "Defeat 3 Slimes to complete this quest.")
		return false
	end

	profile.QuestClaimed = true
	PlayerDataService.AddExperience(player, QUEST_EXP_REWARD)
	PlayerDataService.AddGold(player, QUEST_GOLD_REWARD)
	PlayerDataService.SavePlayerProfile(player)
	sendQuestUpdate(player, "Reward claimed.")
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local feedbackRemote = remotes and remotes:FindFirstChild("CombatFeedback")
	if feedbackRemote then
		feedbackRemote:FireClient(player, "Reward", {
			PlayerName = player.Name,
			Exp = QUEST_EXP_REWARD,
			Gold = QUEST_GOLD_REWARD,
		})
	end
	return true
end

function QuestService.Initialize()
	if initialized then
		return
	end
	initialized = true
	MonsterService.AddDefeatListener(onMonsterDefeated)
	Players.PlayerAdded:Connect(function(player)
		player:WaitForChild("PlayerGui", 5)
		task.delay(2, function()
			if player.Parent then
				sendQuestUpdate(player)
			end
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.delay(2, function()
			if player.Parent then
				sendQuestUpdate(player)
			end
		end)
	end
end

return QuestService
