local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local attackRemote = remotesFolder:WaitForChild("AttackRequest")
local skillRemote = remotesFolder:WaitForChild("SkillRequest")
local statRemote = remotesFolder:WaitForChild("StatRequest")
local inventoryRemote = remotesFolder:WaitForChild("InventoryRequest")
local feedbackRemote = remotesFolder:WaitForChild("CombatFeedback")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KingzPathHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0.34, 0, 0.12, 0)
topBar.Position = UDim2.new(0.03, 0, 0.03, 0)
topBar.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
topBar.BackgroundTransparency = 0.12
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, 0, 0.28, 0)
headerLabel.Position = UDim2.new(0, 0, 0, 0)
headerLabel.Text = "Warrior"
headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextSize = 18
headerLabel.BackgroundTransparency = 1
headerLabel.Parent = topBar

local hpBarBackground = Instance.new("Frame")
hpBarBackground.Size = UDim2.new(0.9, 0, 0.18, 0)
hpBarBackground.Position = UDim2.new(0.05, 0, 0.38, 0)
hpBarBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hpBarBackground.BorderSizePixel = 0
hpBarBackground.Parent = topBar

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(210, 41, 52)
hpBar.BorderSizePixel = 0
hpBar.Parent = hpBarBackground

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.new(1, 0, 0.18, 0)
hpText.Position = UDim2.new(0, 0, 0.2, 0)
hpText.BackgroundTransparency = 1
hpText.Font = Enum.Font.Gotham
hpText.Text = "HP 100/100"
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextSize = 14
hpText.Parent = topBar

local expBarBackground = Instance.new("Frame")
expBarBackground.Size = UDim2.new(0.9, 0, 0.12, 0)
expBarBackground.Position = UDim2.new(0.05, 0, 0.76, 0)
expBarBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
expBarBackground.BorderSizePixel = 0
expBarBackground.Parent = topBar

local expBar = Instance.new("Frame")
expBar.Size = UDim2.new(0.15, 0, 1, 0)
expBar.BackgroundColor3 = Color3.fromRGB(90, 146, 255)
expBar.BorderSizePixel = 0
expBar.Parent = expBarBackground

local inventoryPanel = Instance.new("Frame")
inventoryPanel.Size = UDim2.new(0.28, 0, 0.18, 0)
inventoryPanel.Position = UDim2.new(0.68, 0, 0.18, 0)
inventoryPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
inventoryPanel.BackgroundTransparency = 0.18
inventoryPanel.BorderSizePixel = 0
inventoryPanel.Parent = screenGui

local inventoryLabel = Instance.new("TextLabel")
inventoryLabel.Size = UDim2.new(1, 0, 1, 0)
inventoryLabel.BackgroundTransparency = 1
inventoryLabel.Text = "Inventory: 0/24\nWeapon: None"
inventoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
inventoryLabel.Font = Enum.Font.Gotham
inventoryLabel.TextSize = 14
inventoryLabel.TextWrapped = true
inventoryLabel.Parent = inventoryPanel

local targetPanel = Instance.new("Frame")
targetPanel.Size = UDim2.new(0.25, 0, 0.1, 0)
targetPanel.Position = UDim2.new(0.72, 0, 0.05, 0)
targetPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
targetPanel.BackgroundTransparency = 0.12
targetPanel.BorderSizePixel = 0
targetPanel.Parent = screenGui

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, 0, 1, 0)
targetLabel.BackgroundTransparency = 1
targetLabel.Font = Enum.Font.GothamBold
targetLabel.Text = "Target: None"
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLabel.TextSize = 16
targetLabel.Parent = targetPanel

local floatingText = Instance.new("TextLabel")
floatingText.Size = UDim2.new(0.18, 0, 0.05, 0)
floatingText.Position = UDim2.new(0.41, 0, 0.1, 0)
floatingText.BackgroundTransparency = 1
floatingText.Text = ""
floatingText.Font = Enum.Font.GothamBold
floatingText.TextSize = 18
floatingText.TextColor3 = Color3.fromRGB(255, 100, 100)
floatingText.Parent = screenGui

local function clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

local function getNearestMonster()
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return nil
	end

	local nearestMonster = nil
	local nearestDistance = math.huge
	local monstersFolder = workspace:FindFirstChild("Monsters")
	if not monstersFolder then
		return nil
	end

	for _, monster in ipairs(monstersFolder:GetChildren()) do
		local monsterRoot = monster:FindFirstChild("HumanoidRootPart")
		if monsterRoot then
			local distance = (monsterRoot.Position - rootPart.Position).Magnitude
			if distance < nearestDistance then
				nearestMonster = monster
				nearestDistance = distance
			end
		end
	end

	return nearestMonster, nearestDistance
end

local function updateHud()
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local healthRatio = clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		hpBar.Size = UDim2.new(healthRatio, 0, 1, 0)
		hpText.Text = string.format("HP %d/%d", humanoid.Health, humanoid.MaxHealth)
	end

	local targetMonster, distance = getNearestMonster()
	if targetMonster then
		targetLabel.Text = string.format("Target: %s (%.0f)", targetMonster:GetAttribute("MonsterName") or "Slime", distance)
	else
		targetLabel.Text = "Target: None"
	end
end

local function showDamageText(value)
	local label = floatingText:Clone()
	label.Parent = screenGui
	label.Text = tostring(value)
	label.Position = UDim2.new(0.4, 0, 0.18, 0)
	label.Visible = true
	local tween = TweenService:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.4, 0, 0.08, 0),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

local function fireAttack()
	local targetMonster = getNearestMonster()
	if not targetMonster then
		return
	end
	local monsterId = targetMonster:GetAttribute("MonsterId")
	if monsterId then
		attackRemote:FireServer(monsterId)
	end
end

local function getCurrentSkillName()
	local className = player:GetAttribute("Class") or "Warrior"
	local skillMap = {
		Warrior = "ShieldBash",
		Assassin = "ShadowStrike",
		Mage = "ArcaneBurst",
		Archer = "Volley",
	}
	return skillMap[className] or "ShieldBash"
end

local function fireSkill(skillName)
	local targetMonster = getNearestMonster()
	if not targetMonster then
		return
	end
	local monsterId = targetMonster:GetAttribute("MonsterId")
	if monsterId then
		skillRemote:FireServer(skillName, monsterId)
	end
end

local function allocateStat(statName)
	statRemote:FireServer(statName)
end

local function updateInventoryDisplay(snapshot)
	if not snapshot then
		return
	end
	local itemCount = 0
	for _, _ in ipairs(snapshot.Inventory or {}) do
		itemCount = itemCount + 1
	end
	local weaponName = "None"
	if snapshot.Equipment and snapshot.Equipment.Weapon then
		weaponName = snapshot.Equipment.Weapon
	end
	inventoryLabel.Text = string.format("Inventory: %d/%d\nWeapon: %s", itemCount, snapshot.Capacity or 24, weaponName)
end

inventoryRemote:FireServer("sync")

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.F then
		fireAttack()
	elseif input.KeyCode == Enum.KeyCode.Q then
		fireSkill(getCurrentSkillName())
	elseif input.KeyCode == Enum.KeyCode.Z then
		allocateStat("STR")
	elseif input.KeyCode == Enum.KeyCode.X then
		allocateStat("VIT")
	elseif input.KeyCode == Enum.KeyCode.I then
		inventoryRemote:FireServer("sync")
	end
end)

feedbackRemote.OnClientEvent:Connect(function(messageType, payload)
	if messageType == "MonsterDamage" then
		local targetMonster = workspace:FindFirstChild("Monsters") and workspace.Monsters:FindFirstChild(string.format("Slime_%d", payload.MonsterId))
		if targetMonster then
			local healthRatio = clamp((payload.Health or 0) / (payload.MaxHealth or 1), 0, 1)
			showDamageText(tostring(payload.Damage or 0))
		end
	elseif messageType == "Reward" then
		showDamageText("+" .. tostring(payload.Exp) .. " EXP")
	elseif messageType == "InventoryUpdate" then
		updateInventoryDisplay(payload)
	end
	updateHud()
end)

player.CharacterAdded:Connect(function()
	task.wait(0.25)
	updateHud()
end)

while true do
	updateHud()
	task.wait(0.2)
end
