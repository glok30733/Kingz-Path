local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local attackRemote = remotesFolder:WaitForChild("AttackRequest")
local skillRemote = remotesFolder:WaitForChild("SkillRequest")
local statRemote = remotesFolder:WaitForChild("StatRequest")
local inventoryRemote = remotesFolder:WaitForChild("InventoryRequest")
local autoFarmRemote = remotesFolder:WaitForChild("AutoFarmRequest")
local profileRemote = remotesFolder:WaitForChild("ProfileRequest")
local zoneRemote = remotesFolder:WaitForChild("ZoneRequest")
local dungeonRemote = remotesFolder:WaitForChild("DungeonRequest")
local questRemote = remotesFolder:WaitForChild("QuestRequest")
local feedbackRemote = remotesFolder:WaitForChild("CombatFeedback")
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local palette = {
	Panel = Color3.fromRGB(20, 25, 30),
	Raised = Color3.fromRGB(31, 39, 43),
	Muted = Color3.fromRGB(145, 158, 158),
	Text = Color3.fromRGB(239, 242, 232),
	Mint = Color3.fromRGB(122, 211, 165),
	Red = Color3.fromRGB(222, 93, 88),
	Blue = Color3.fromRGB(97, 185, 218),
	Gold = Color3.fromRGB(231, 184, 91),
}

local oldGui = playerGui:FindFirstChild("KingzPathHUD")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KingzPathHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

local guiScale = Instance.new("UIScale")
guiScale.Parent = screenGui

local function create(className, parent, properties)
	local object = Instance.new(className)
	for property, value in pairs(properties or {}) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

local function addCorner(object, radius)
	create("UICorner", object, { CornerRadius = UDim.new(0, radius or 6) })
end

local function addStroke(object, color, transparency)
	create("UIStroke", object, {
		Color = color or Color3.fromRGB(73, 87, 86),
		Transparency = transparency or 0.35,
		Thickness = 1,
	})
end

local function makeLabel(parent, text, size, position, options)
	options = options or {}
	return create("TextLabel", parent, {
		BackgroundTransparency = 1,
		Font = options.Font or Enum.Font.Gotham,
		Text = text,
		TextColor3 = options.Color or palette.Text,
		TextSize = options.TextSize or 14,
		TextXAlignment = options.Alignment or Enum.TextXAlignment.Left,
		TextYAlignment = options.VerticalAlignment or Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = size,
		Position = position,
		ZIndex = options.ZIndex or 2,
	})
end

local function makeButton(parent, text, size, position, callback, options)
	options = options or {}
	local button = create("TextButton", parent, {
		AutoButtonColor = true,
		BackgroundColor3 = options.Background or palette.Raised,
		BorderSizePixel = 0,
		Font = options.Font or Enum.Font.GothamBold,
		Text = text,
		TextColor3 = options.Color or palette.Text,
		TextSize = options.TextSize or 13,
		Size = size,
		Position = position,
		ZIndex = options.ZIndex or 3,
	})
	addCorner(button, options.Radius or 5)
	if options.Stroke then
		addStroke(button, options.Stroke, 0.45)
	end
	button.Activated:Connect(callback)
	return button
end

local function makePanel(parent, size, position, anchorPoint)
	local panel = create("Frame", parent, {
		AnchorPoint = anchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = palette.Panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Size = size,
		Position = position,
		ZIndex = 1,
	})
	addCorner(panel, 8)
	addStroke(panel, Color3.fromRGB(98, 120, 111), 0.45)
	return panel
end

local function makeBar(parent, yPosition, color, caption)
	local background = create("Frame", parent, {
		BackgroundColor3 = Color3.fromRGB(44, 52, 53),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, yPosition),
		Size = UDim2.new(1, -24, 0, 19),
		ZIndex = 2,
	})
	addCorner(background, 4)
	local fill = create("Frame", background, {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
	})
	addCorner(fill, 4)
	local label = makeLabel(background, caption, UDim2.new(1, -12, 1, 0), UDim2.new(0, 6, 0, 0), {
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Alignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})
	return { Fill = fill, Label = label }
end

local hudPanel = makePanel(screenGui, UDim2.fromOffset(330, 154), UDim2.fromOffset(18, 18))
local headerLabel = makeLabel(hudPanel, "WARRIOR  /  LEVEL 1", UDim2.new(1, -110, 0, 27), UDim2.fromOffset(13, 7), {
	Font = Enum.Font.GothamBlack,
	TextSize = 16,
})
local goldLabel = makeLabel(hudPanel, "0 G", UDim2.fromOffset(90, 27), UDim2.new(1, -102, 0, 7), {
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	Color = palette.Gold,
	Alignment = Enum.TextXAlignment.Right,
})
local hpBar = makeBar(hudPanel, 42, palette.Red, "HP 100 / 100")
local manaBar = makeBar(hudPanel, 68, palette.Blue, "MP 50 / 50")
local expBar = makeBar(hudPanel, 94, palette.Gold, "EXP 0 / 0")
local statsSummary = makeLabel(hudPanel, "STR 0   AGI 0   INT 0   VIT 0", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 124), {
	Color = palette.Muted,
	TextSize = 11,
})

local targetPanel = makePanel(screenGui, UDim2.fromOffset(286, 84), UDim2.new(1, -18, 0, 18), Vector2.new(1, 0))
local targetLabel = makeLabel(targetPanel, "NO TARGET", UDim2.new(1, -24, 0, 25), UDim2.fromOffset(12, 8), {
	Font = Enum.Font.GothamBlack,
	TextSize = 15,
})
local targetDistance = makeLabel(targetPanel, "Find a nearby creature", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 32), {
	Color = palette.Muted,
	TextSize = 11,
})
local targetHealth = makeBar(targetPanel, 56, palette.Mint, "")

local inventoryPanel = makePanel(screenGui, UDim2.fromOffset(410, 590), UDim2.new(1, -18, 0.5, 0), Vector2.new(1, 0.5))
inventoryPanel.Visible = false
local inventoryTitle = makeLabel(inventoryPanel, "INVENTORY", UDim2.new(1, -75, 0, 32), UDim2.fromOffset(14, 8), {
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
})
local closeInventoryButton
closeInventoryButton = makeButton(inventoryPanel, "X", UDim2.fromOffset(34, 30), UDim2.new(1, -44, 0, 8), function()
	inventoryPanel.Visible = false
end, { Background = Color3.fromRGB(72, 48, 47), TextSize = 14 })

local currentPage = "Inventory"
local pages = {}
local tabs = {}
local refreshProfile
local pageNames = { "Inventory", "Equipment", "Stats", "World", "Quest" }
local pageTabLabels = {
	Inventory = "BAG",
	Equipment = "GEAR",
	Stats = "STATS",
	World = "WORLD",
	Quest = "QUEST",
}
for index, pageName in ipairs(pageNames) do
	local capturedPageName = pageName
	local pageButton = makeButton(inventoryPanel, pageTabLabels[capturedPageName], UDim2.new(1 / #pageNames, -8, 0, 32), UDim2.new((index - 1) / #pageNames, 5, 0, 48), function()
		currentPage = capturedPageName
		inventoryTitle.Text = string.upper(capturedPageName)
		for name, page in pairs(pages) do
			page.Visible = name == currentPage
		end
		for name, tab in pairs(tabs) do
			tab.BackgroundColor3 = name == currentPage and Color3.fromRGB(54, 91, 77) or palette.Raised
		end
		if capturedPageName == "Stats" and refreshProfile then
			refreshProfile()
		elseif capturedPageName == "World" then
			zoneRemote:FireServer("sync")
			dungeonRemote:FireServer("sync")
		elseif capturedPageName == "Quest" then
			questRemote:FireServer("sync")
		end
	end, { TextSize = 11 })
	tabs[pageName] = pageButton
	local page = create("Frame", inventoryPanel, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 88),
		Size = UDim2.new(1, -20, 1, -100),
		Visible = pageName == currentPage,
		ZIndex = 2,
	})
	pages[pageName] = page
end
tabs.Inventory.BackgroundColor3 = Color3.fromRGB(54, 91, 77)

local inventoryCountLabel = makeLabel(pages.Inventory, "BAG  0 / 24", UDim2.new(1, -4, 0, 25), UDim2.fromOffset(2, 0), {
	Color = palette.Muted,
	TextSize = 11,
})
local inventoryList = create("ScrollingFrame", pages.Inventory, {
	Active = true,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	Position = UDim2.fromOffset(0, 27),
	ScrollBarThickness = 4,
	Size = UDim2.new(1, 0, 1, -27),
	ZIndex = 2,
})
create("UIListLayout", inventoryList, {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local equipmentList = create("ScrollingFrame", pages.Equipment, {
	Active = true,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarThickness = 4,
	Size = UDim2.new(1, 0, 1, 0),
	ZIndex = 2,
})
create("UIListLayout", equipmentList, {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local statPointsLabel = makeLabel(pages.Stats, "AVAILABLE POINTS  0", UDim2.new(1, -4, 0, 25), UDim2.fromOffset(2, 0), {
	Color = palette.Gold,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
})
local statsList = create("ScrollingFrame", pages.Stats, {
	Active = true,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	Position = UDim2.fromOffset(0, 30),
	ScrollBarThickness = 4,
	Size = UDim2.new(1, 0, 1, -30),
	ZIndex = 2,
})
create("UIListLayout", statsList, {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local zoneSummary = makeLabel(pages.World, "UNLOCKED REGIONS", UDim2.new(1, -4, 0, 25), UDim2.fromOffset(2, 0), {
	Color = palette.Muted,
	TextSize = 11,
})
local zoneList = create("ScrollingFrame", pages.World, {
	Active = true,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	Position = UDim2.fromOffset(0, 27),
	ScrollBarThickness = 4,
	Size = UDim2.new(1, 0, 1, -150),
	ZIndex = 2,
})
create("UIListLayout", zoneList, {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
local dungeonState = { Active = false, Completed = false }
local dungeonStatus = makeLabel(pages.World, "Dungeon access requires level 25.", UDim2.new(1, -4, 0, 38), UDim2.new(0, 2, 1, -112), {
	Color = palette.Muted,
	TextSize = 11,
})
local dungeonButton = makeButton(pages.World, "ENTER ANCIENT RUINS DUNGEON", UDim2.new(1, -8, 0, 38), UDim2.new(0, 4, 1, -62), function()
	dungeonRemote:FireServer(dungeonState.Active and "exit" or "enter")
end, { Background = Color3.fromRGB(84, 66, 47), TextSize = 11 })

local questDescription = create("TextLabel", pages.Quest, {
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "Defeat 3 Slimes near the village.",
	TextColor3 = palette.Text,
	TextSize = 14,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromOffset(4, 8),
	Size = UDim2.new(1, -8, 0, 58),
	ZIndex = 2,
})
local questProgressLabel = makeLabel(pages.Quest, "PROGRESS  0 / 3", UDim2.new(1, -8, 0, 24), UDim2.fromOffset(4, 78), {
	Color = palette.Mint,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
})
local questProgressBar = makeBar(pages.Quest, 106, palette.Mint, "")
local questRewardLabel = makeLabel(pages.Quest, "REWARD  120 EXP  /  80 GOLD", UDim2.new(1, -8, 0, 24), UDim2.fromOffset(4, 138), {
	Color = palette.Gold,
	TextSize = 11,
})
local questStatusLabel = makeLabel(pages.Quest, "Quest in progress", UDim2.new(1, -8, 0, 40), UDim2.fromOffset(4, 172), {
	Color = palette.Muted,
	TextSize = 11,
})
local claimQuestButton = makeButton(pages.Quest, "CLAIM REWARD", UDim2.new(1, -8, 0, 38), UDim2.new(0, 4, 1, -48), function()
	questRemote:FireServer("claim")
end, { Background = Color3.fromRGB(53, 91, 72), TextSize = 12 })

local actionBar = makePanel(screenGui, UDim2.fromOffset(464, 70), UDim2.new(0.5, 0, 1, -18), Vector2.new(0.5, 1))
local function makeAction(text, key, callback, index, color)
	local button = makeButton(actionBar, text .. "\n" .. key, UDim2.new(0, 105, 0, 48), UDim2.fromOffset(12 + (index - 1) * 112, 11), callback, {
		Background = color or palette.Raised,
		TextSize = 12,
	})
	return button
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

local function getNearestMonster()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local monstersFolder = workspace:FindFirstChild("Monsters")
	if not rootPart or not monstersFolder then
		return nil
	end

	local nearestMonster = nil
	local nearestDistance = math.huge
	local lockedMonster = nil
	local lockedDistance = math.huge
	local playerLevel = player:GetAttribute("Level") or 1
	for _, monster in ipairs(monstersFolder:GetChildren()) do
		local monsterRoot = monster:FindFirstChild("HumanoidRootPart")
		local humanoid = monster:FindFirstChildOfClass("Humanoid")
		if monsterRoot and humanoid and humanoid.Health > 0 then
			local distance = (monsterRoot.Position - rootPart.Position).Magnitude
			local requiredLevel = monster:GetAttribute("MonsterLevel") or 1
			if requiredLevel <= playerLevel and distance < nearestDistance then
				nearestMonster = monster
				nearestDistance = distance
			elseif requiredLevel > playerLevel and distance < lockedDistance then
				lockedMonster = monster
				lockedDistance = distance
			end
		end
	end
	if nearestMonster then
		return nearestMonster, nearestDistance, false
	end
	return lockedMonster, lockedDistance, lockedMonster ~= nil
end

local function fireAttack()
	local target, _, locked = getNearestMonster()
	local monsterId = target and target:GetAttribute("MonsterId")
	if monsterId and not locked then
		attackRemote:FireServer(monsterId)
	end
end

local function fireSkill()
	local target, _, locked = getNearestMonster()
	local monsterId = target and target:GetAttribute("MonsterId")
	if monsterId and not locked then
		skillRemote:FireServer(getCurrentSkillName(), monsterId)
	end
end

local function useHealthPotion()
	inventoryRemote:FireServer("use", "HealthPotion")
end

makeAction("ATTACK", "F", fireAttack, 1, Color3.fromRGB(62, 71, 66))
local skillButton = makeAction("SKILL", "Q", fireSkill, 2, Color3.fromRGB(47, 70, 81))
makeAction("POTION", "H", useHealthPotion, 3, Color3.fromRGB(86, 54, 51))
makeAction("BAG", "I", function()
	inventoryPanel.Visible = not inventoryPanel.Visible
	if inventoryPanel.Visible then
		inventoryRemote:FireServer("sync")
	end
end, 4)

local farmPanel = makePanel(screenGui, UDim2.fromOffset(242, 228), UDim2.new(1, -18, 1, -102), Vector2.new(1, 1))
makeLabel(farmPanel, "AUTO FARM", UDim2.new(1, -24, 0, 25), UDim2.fromOffset(12, 8), {
	Font = Enum.Font.GothamBlack,
	TextSize = 14,
})

local farmSettings = {
	enabled = false,
	autoAttack = true,
	autoSkill = true,
	autoLoot = true,
	autoPotion = true,
}
local farmButtons = {}

local function sendFarmSettings()
	autoFarmRemote:FireServer(farmSettings)
end

local function updateFarmButtons()
	for settingName, button in pairs(farmButtons) do
		local enabled = farmSettings[settingName]
		button.Text = (enabled and "ON   " or "OFF  ") .. button:GetAttribute("SettingLabel")
		button.BackgroundColor3 = enabled and Color3.fromRGB(47, 83, 67) or Color3.fromRGB(55, 59, 59)
	end
end

local farmRows = {
	{ Key = "enabled", Label = "Farming" },
	{ Key = "autoAttack", Label = "Auto attack" },
	{ Key = "autoSkill", Label = "Auto skill" },
	{ Key = "autoLoot", Label = "Auto loot" },
	{ Key = "autoPotion", Label = "Auto potion" },
}
for index, row in ipairs(farmRows) do
	local settingKey = row.Key
	local settingLabel = row.Label
	local button = makeButton(farmPanel, "", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 39 + (index - 1) * 35), function()
		farmSettings[settingKey] = not farmSettings[settingKey]
		updateFarmButtons()
		sendFarmSettings()
	end, { TextSize = 11 })
	button:SetAttribute("SettingLabel", settingLabel)
	farmButtons[settingKey] = button
end
updateFarmButtons()

local currentInventory = nil
local profileData = nil
local renderInventoryStats
local updateProfileHud
local clearRows
local showDamageText

local function renderZones(zones)
	if type(zones) ~= "table" then
		return
	end
	clearRows(zoneList)
	local unlockedCount = 0
	for index, zone in ipairs(zones) do
		if zone.Unlocked then
			unlockedCount = unlockedCount + 1
		end
		local current = zone.Current == true
		local actionText = current and "HERE" or zone.Unlocked and "TRAVEL" or ("LV " .. tostring(zone.LevelMin))
		local row = create("Frame", zoneList, {
			BackgroundColor3 = current and Color3.fromRGB(42, 67, 55) or palette.Raised,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Size = UDim2.new(1, -8, 0, 48),
			ZIndex = 2,
		})
		addCorner(row, 5)
		makeLabel(row, zone.Name, UDim2.new(1, -105, 0, 22), UDim2.fromOffset(12, 4), {
			Font = Enum.Font.GothamBold,
			TextSize = 11,
		})
		makeLabel(row, "LEVEL " .. tostring(zone.LevelMin) .. "+", UDim2.new(1, -105, 0, 16), UDim2.fromOffset(12, 26), {
			Color = palette.Muted,
			TextSize = 9,
		})
		local capturedZoneKey = zone.Key
		local button = makeButton(row, actionText, UDim2.fromOffset(78, 30), UDim2.new(1, -86, 0.5, -15), function()
			if zone.Unlocked and not current then
				zoneRemote:FireServer(capturedZoneKey)
			end
		end, {
			Background = current and Color3.fromRGB(59, 83, 68) or (zone.Unlocked and Color3.fromRGB(49, 73, 82) or Color3.fromRGB(50, 55, 55)),
			TextSize = 9,
		})
		button.Active = zone.Unlocked and not current
		button.AutoButtonColor = zone.Unlocked and not current
	end
	zoneSummary.Text = string.format("UNLOCKED REGIONS  %d / %d", unlockedCount, #zones)
end

local function renderDungeon(payload)
	if type(payload) ~= "table" then
		return
	end
	dungeonState = payload
	if payload.Active then
		dungeonStatus.Text = payload.Completed and "CLEAR COMPLETE  /  REWARDS GRANTED" or string.format("WAVE %d / %d", payload.Wave or 0, payload.WaveCount or 3)
		dungeonButton.Text = payload.Completed and "EXIT DUNGEON" or "LEAVE DUNGEON"
		dungeonButton.BackgroundColor3 = payload.Completed and Color3.fromRGB(53, 91, 72) or Color3.fromRGB(84, 66, 47)
	else
		dungeonStatus.Text = payload.Message ~= "" and payload.Message or "Dungeon access requires level 25."
		dungeonButton.Text = "ENTER ANCIENT RUINS DUNGEON"
		dungeonButton.BackgroundColor3 = Color3.fromRGB(84, 66, 47)
	end
	if payload.Message and payload.Message ~= "" and (payload.Completed or not payload.Active) then
		showDamageText(payload.Message, payload.Completed and palette.Gold or palette.Muted)
	end
end

local function renderQuest(snapshot)
	if type(snapshot) ~= "table" then
		return
	end
	questDescription.Text = snapshot.Title .. "\n" .. snapshot.Description
	questProgressLabel.Text = string.format("PROGRESS  %d / %d", snapshot.Progress or 0, snapshot.Target or 3)
	questRewardLabel.Text = string.format("REWARD  %d EXP  /  %d GOLD", snapshot.RewardExp or 0, snapshot.RewardGold or 0)
	questProgressBar.Fill.Size = UDim2.new(math.max(0, math.min(1, (snapshot.Progress or 0) / math.max(1, snapshot.Target or 1))), 0, 1, 0)
	questStatusLabel.Text = snapshot.Claimed and "Quest reward claimed." or snapshot.Complete and "Objective complete. Claim your reward." or "Defeat Slimes near the village to progress."
	claimQuestButton.Text = snapshot.Claimed and "REWARD CLAIMED" or snapshot.Complete and "CLAIM REWARD" or "IN PROGRESS"
	claimQuestButton.Active = snapshot.Complete and not snapshot.Claimed
	claimQuestButton.AutoButtonColor = snapshot.Complete and not snapshot.Claimed
	claimQuestButton.BackgroundColor3 = snapshot.Complete and not snapshot.Claimed and Color3.fromRGB(53, 91, 72) or palette.Raised
	if snapshot.Message and snapshot.Message ~= "" then
		questStatusLabel.Text = snapshot.Message
	end
end

clearRows = function(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function addInventoryRow(container, title, detail, actionText, callback, rarityColor, layoutOrder)
	local row = create("Frame", container, {
		BackgroundColor3 = palette.Raised,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
		Size = UDim2.new(1, -8, 0, 54),
		ZIndex = 2,
	})
	addCorner(row, 5)
	create("Frame", row, {
		BackgroundColor3 = rarityColor or palette.Muted,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.fromOffset(7, 6),
		ZIndex = 3,
	})
	makeLabel(row, title, UDim2.new(1, -112, 0, 22), UDim2.fromOffset(17, 5), {
		Font = Enum.Font.GothamBold,
		TextSize = 12,
	})
	makeLabel(row, detail, UDim2.new(1, -112, 0, 18), UDim2.fromOffset(17, 28), {
		Color = palette.Muted,
		TextSize = 10,
	})
	if actionText then
		makeButton(row, actionText, UDim2.fromOffset(82, 32), UDim2.new(1, -91, 0.5, -16), callback, {
			Background = Color3.fromRGB(53, 78, 66),
			TextSize = 10,
		})
	end
	return row
end

local slotNames = { "Weapon", "Head", "Body", "Legs", "Gloves", "Boots", "Accessory1", "Accessory2" }
local statNames = { "STR", "AGI", "INT", "VIT", "DEX", "LUK" }

local function renderInventory(snapshot)
	currentInventory = snapshot
	if not snapshot then
		return
	end
	local entries = snapshot.Inventory or {}
	local entryCount = 0
	for _, entry in ipairs(entries) do
		if entry then
			entryCount = entryCount + 1
		end
	end
	inventoryCountLabel.Text = string.format("BAG  %d / %d SLOTS", entryCount, snapshot.Capacity or 24)
	clearRows(inventoryList)
	for index, entry in ipairs(entries) do
		local itemId = entry.ItemId
		local item = Items.GetDefinition(itemId)
		local itemName = item and item.Name or tostring(itemId)
		local itemType = item and item.Type or "Item"
		local rarity = item and item.Rarity or "Common"
		local rarityColor = Items.RarityColors[rarity] or palette.Muted
		local actionText = nil
		local callback = nil
		if itemType == "Equipment" then
			actionText = "EQUIP"
			callback = function()
				inventoryRemote:FireServer("equip", itemId)
			end
		elseif itemType == "Consumable" then
			actionText = "USE"
			callback = function()
				inventoryRemote:FireServer("use", itemId)
			end
		end
		addInventoryRow(inventoryList, itemName, string.format("%s  /  %s  /  x%d", rarity, itemType, entry.Quantity or 1), actionText, callback, rarityColor, index)
	end

	clearRows(equipmentList)
	local equipment = snapshot.Equipment or {}
	for index, slotName in ipairs(slotNames) do
		local itemId = equipment[slotName]
		local item = itemId and Items.GetDefinition(itemId)
		local itemName = item and item.Name or (itemId or "Empty")
		local capturedSlot = slotName
		local actionText = itemId and "REMOVE" or nil
		local callback = itemId and function()
			inventoryRemote:FireServer("unequip", capturedSlot)
		end or nil
		addInventoryRow(equipmentList, slotName, itemName, actionText, callback, item and Items.RarityColors[item.Rarity] or palette.Muted, index)
	end

	renderInventoryStats()
end

renderInventoryStats = function()
	clearRows(statsList)
	local stats = profileData and profileData.Stats or {}
	local availablePoints = profileData and profileData.StatPoints or 0
	statPointsLabel.Text = string.format("AVAILABLE POINTS  %d", availablePoints)
	for index, statName in ipairs(statNames) do
		local capturedStat = statName
		local canAllocate = availablePoints > 0
		local row = create("Frame", statsList, {
			BackgroundColor3 = palette.Raised,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Size = UDim2.new(1, -8, 0, 44),
			ZIndex = 2,
		})
		addCorner(row, 5)
		makeLabel(row, statName, UDim2.new(0.45, 0, 1, 0), UDim2.fromOffset(14, 0), {
			Font = Enum.Font.GothamBold,
			TextSize = 13,
		})
		makeLabel(row, tostring(stats[statName] or 0), UDim2.new(0.25, 0, 1, 0), UDim2.new(0.53, 0, 0, 0), {
			Color = palette.Mint,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Alignment = Enum.TextXAlignment.Center,
		})
		local allocateButton = makeButton(row, "+", UDim2.fromOffset(34, 32), UDim2.new(1, -45, 0.5, -16), function()
			if canAllocate then
				statRemote:FireServer(capturedStat)
				task.delay(0.2, function()
					local success, updatedProfile = pcall(function()
						return profileRemote:InvokeServer()
					end)
					if success and updatedProfile then
						profileData = updatedProfile
						updateProfileHud()
						renderInventoryStats()
					end
				end)
			end
		end, {
			Background = canAllocate and Color3.fromRGB(53, 91, 72) or Color3.fromRGB(55, 59, 59),
			TextSize = 18,
		})
		allocateButton.Active = canAllocate
	end
end

updateProfileHud = function()
	if not profileData then
		return
	end
	local level = profileData.Level or 1
	local className = profileData.Class or "Warrior"
	player:SetAttribute("Level", level)
	headerLabel.Text = string.upper(className) .. "  /  LEVEL " .. level
	goldLabel.Text = tostring(profileData.Gold or 0) .. " G"
	local stats = profileData.Stats or {}
	statsSummary.Text = string.format("STR %d   AGI %d   INT %d   VIT %d", stats.STR or 0, stats.AGI or 0, stats.INT or 0, stats.VIT or 0)
	local currentExp = profileData.Exp or 0
	local levelExp = profileData.ExpForLevel or 0
	local nextLevelExp = profileData.ExpForNextLevel or levelExp
	local expRatio = nextLevelExp > levelExp and (currentExp - levelExp) / (nextLevelExp - levelExp) or 1
	expRatio = math.max(0, math.min(1, expRatio))
	expBar.Fill.Size = UDim2.new(expRatio, 0, 1, 0)
	if nextLevelExp > levelExp then
		expBar.Label.Text = string.format("EXP %d / %d", math.max(0, currentExp - levelExp), nextLevelExp - levelExp)
	else
		expBar.Label.Text = "LEVEL MAX"
	end
	manaBar.Fill.Size = UDim2.new(math.max(0, math.min(1, (profileData.Mana or 0) / math.max(1, profileData.MaxMana or 1))), 0, 1, 0)
	manaBar.Label.Text = string.format("MP %d / %d", profileData.Mana or 0, profileData.MaxMana or 0)
	skillButton.Text = string.upper(getCurrentSkillName()) .. "\nQ"
	if currentInventory and pages.Stats.Visible then
		renderInventoryStats()
	end
end

refreshProfile = function()
	local success, snapshot = pcall(function()
		return profileRemote:InvokeServer()
	end)
	if success and snapshot then
		profileData = snapshot
		updateProfileHud()
	end
end

local function updateHud()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local healthRatio = math.max(0, math.min(1, humanoid.Health / math.max(1, humanoid.MaxHealth)))
		hpBar.Fill.Size = UDim2.new(healthRatio, 0, 1, 0)
		hpBar.Label.Text = string.format("HP %d / %d", math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5))
	end
	local target, distance, locked = getNearestMonster()
	if target then
		local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
		local targetName = target:GetAttribute("MonsterName") or target.Name
		local tier = target:GetAttribute("MonsterTier") or "NORMAL"
		local requiredLevel = target:GetAttribute("MonsterLevel") or 1
		local phase = target:GetAttribute("Phase") or 1
		if locked then
			targetLabel.Text = "LOCKED  /  " .. string.upper(targetName)
			targetDistance.Text = string.format("REQUIRES LEVEL %d", requiredLevel)
		else
			targetLabel.Text = tier == "NORMAL" and string.upper(targetName) or tier .. "  /  " .. string.upper(targetName)
			targetDistance.Text = string.format("LEVEL %d  /  %d STUDS%s", requiredLevel, math.floor((distance or 0) + 0.5), phase > 1 and "  /  PHASE " .. phase or "")
		end
		if tier == "BOSS" then
			targetHealth.Fill.BackgroundColor3 = Color3.fromRGB(211, 105, 78)
		elseif tier == "ELITE" then
			targetHealth.Fill.BackgroundColor3 = palette.Gold
		else
			targetHealth.Fill.BackgroundColor3 = palette.Mint
		end
		if targetHumanoid then
			local ratio = math.max(0, math.min(1, targetHumanoid.Health / math.max(1, targetHumanoid.MaxHealth)))
			targetHealth.Fill.Size = UDim2.new(ratio, 0, 1, 0)
			targetHealth.Label.Text = string.format("%d / %d", math.floor(targetHumanoid.Health + 0.5), math.floor(targetHumanoid.MaxHealth + 0.5))
		end
	else
		targetLabel.Text = "NO TARGET"
		targetDistance.Text = "Find a nearby creature"
		targetHealth.Fill.Size = UDim2.new(0, 0, 1, 0)
		targetHealth.Label.Text = ""
	end
end

showDamageText = function(text, color)
	local label = makeLabel(screenGui, text, UDim2.fromOffset(220, 32), UDim2.new(0.5, -110, 0.28, 0), {
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		Color = color or palette.Gold,
		Alignment = Enum.TextXAlignment.Center,
		ZIndex = 10,
	})
	local tween = TweenService:Create(label, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -110, 0.2, 0),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

local function updateScale()
	local camera = workspace.CurrentCamera
	local width = camera and camera.ViewportSize.X or 1280
	guiScale.Scale = width < 600 and 0.72 or width < 900 and 0.86 or 1
	if width < 700 then
		targetPanel.Position = UDim2.fromOffset(18, 181)
		targetPanel.AnchorPoint = Vector2.new(0, 0)
	else
		targetPanel.Position = UDim2.new(1, -18, 0, 18)
		targetPanel.AnchorPoint = Vector2.new(1, 0)
	end
end

local function showInventory()
	inventoryPanel.Visible = true
	inventoryRemote:FireServer("sync")
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
updateScale()

inventoryRemote:FireServer("sync")
zoneRemote:FireServer("sync")
dungeonRemote:FireServer("sync")
questRemote:FireServer("sync")
task.spawn(function()
	while screenGui.Parent do
		refreshProfile()
		task.wait(1.5)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.F then
		fireAttack()
	elseif input.KeyCode == Enum.KeyCode.Q then
		fireSkill()
	elseif input.KeyCode == Enum.KeyCode.H then
		useHealthPotion()
	elseif input.KeyCode == Enum.KeyCode.I then
		if inventoryPanel.Visible then
			inventoryPanel.Visible = false
		else
			showInventory()
		end
	elseif input.KeyCode == Enum.KeyCode.B then
		farmSettings.enabled = not farmSettings.enabled
		updateFarmButtons()
		sendFarmSettings()
	elseif input.KeyCode == Enum.KeyCode.Escape and inventoryPanel.Visible then
		inventoryPanel.Visible = false
	end
end)

feedbackRemote.OnClientEvent:Connect(function(messageType, payload)
	if messageType == "MonsterDamage" and payload then
		local target = getNearestMonster()
		if target and target:GetAttribute("MonsterId") == payload.MonsterId then
			showDamageText("-" .. tostring(payload.Damage or 0), palette.Red)
		end
	elseif messageType == "Reward" and payload then
		showDamageText("+" .. tostring(payload.Exp or 0) .. " EXP", palette.Gold)
		refreshProfile()
	elseif messageType == "InventoryUpdate" then
		renderInventory(payload)
		refreshProfile()
	elseif messageType == "SkillResult" then
		refreshProfile()
	elseif messageType == "BossPhase" and payload then
		showDamageText(string.upper(payload.MonsterName or "BOSS") .. "  /  PHASE 2", palette.Red)
	elseif messageType == "LevelLocked" and payload then
		showDamageText("REQUIRES LEVEL " .. tostring(payload.RequiredLevel or "?"), palette.Gold)
	elseif messageType == "MonsterDefeated" and payload and payload.Tier ~= "NORMAL" then
		showDamageText(string.upper(payload.Tier) .. " DEFEATED", palette.Gold)
	elseif messageType == "ZoneUpdate" and payload then
		renderZones(payload.Zones)
		if payload.Message then
			showDamageText(payload.Message, payload.Success and palette.Mint or palette.Gold)
		end
	elseif messageType == "DungeonUpdate" and payload then
		renderDungeon(payload)
	elseif messageType == "QuestUpdate" and payload then
		renderQuest(payload)
	end
	updateHud()
end)

player:GetAttributeChangedSignal("Class"):Connect(function()
	if profileData then
		profileData.Class = player:GetAttribute("Class") or profileData.Class
		updateProfileHud()
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(0.25)
	updateHud()
	refreshProfile()
end)

while screenGui.Parent do
	updateHud()
	task.wait(0.2)
end