local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local ZoneService = {}

local activeZones = {}

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
		zonePart.Size = Vector3.new(80, 4, 80)
		zonePart.Position = zoneData.SpawnPosition or Vector3.new(0, 0, 0)
		zonePart.Anchored = true
		zonePart.CanCollide = false
		zonePart.Transparency = 0.6
		zonePart.Material = Enum.Material.Neon
		zonePart.Color = Color3.fromRGB(90, 150, 255)
		zonePart.Parent = zoneFolder
	end
	return zonePart
end

function ZoneService.GetPlayerZone(player)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return WorldConfig.Zones.StarterVillage
	end
	return WorldConfig.GetZoneForLevel(profile.Level or 1)
end

function ZoneService.ApplyZone(player)
	local zone = ZoneService.GetPlayerZone(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(zone.SpawnPosition or Vector3.new(0, 5, 0))
	end
	activeZones[player.UserId] = zone.Name
	return zone
end

function ZoneService.Initialize()
	for zoneKey, zoneData in pairs(WorldConfig.Zones) do
		ensureZonePart(zoneKey, zoneData)
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
