local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local InventoryService = {}

local function getProfile(player)
	if not player then
		return nil
	end
	return PlayerDataService.GetProfile(player)
end

local function findInventoryEntry(profile, itemId)
	if not profile or not profile.Inventory then
		return nil
	end
	for index, entry in ipairs(profile.Inventory) do
		if entry and entry.ItemId == itemId then
			return index, entry
		end
	end
	return nil, nil
end

local function createInventoryEntry(itemId, quantity)
	return {
		ItemId = itemId,
		Quantity = quantity or 1,
	}
end

function InventoryService.GetInventory(player)
	local profile = getProfile(player)
	if not profile then
		return {}
	end
	return profile.Inventory or {}
end

function InventoryService.GetEquipment(player)
	local profile = getProfile(player)
	if not profile then
		return {}
	end
	return profile.Equipment or {}
end

function InventoryService.GetSnapshot(player)
	local profile = getProfile(player)
	if not profile then
		return {
			Inventory = {},
			Equipment = {},
			Capacity = Config.InventoryCapacity,
		}
	end

	return {
		Inventory = profile.Inventory or {},
		Equipment = profile.Equipment or {},
		Capacity = Config.InventoryCapacity,
	}
end

function InventoryService.AddItem(player, itemId, quantity)
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local itemDefinition = Items.GetDefinition(itemId)
	if not itemDefinition then
		return false
	end
	if quantity == nil then
		quantity = 1
	end
	if quantity <= 0 then
		return false
	end
	if itemDefinition.Stackable then
		local index, entry = findInventoryEntry(profile, itemId)
		if entry then
			entry.Quantity = entry.Quantity + quantity
			return true
		end
	end
	if #profile.Inventory >= Config.InventoryCapacity then
		return false
	end
	table.insert(profile.Inventory, createInventoryEntry(itemId, quantity))
	return true
end

function InventoryService.EquipItem(player, itemId)
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local itemDefinition = Items.GetDefinition(itemId)
	if not itemDefinition or itemDefinition.Type ~= "Equipment" then
		return false
	end

	local slot = itemDefinition.Slot
	if slot == "None" or not slot then
		return false
	end
	local index, entry = findInventoryEntry(profile, itemId)
	if not entry then
		return false
	end

	profile.Equipment = profile.Equipment or {}
	local currentItemId = profile.Equipment[slot]
	if currentItemId then
		InventoryService.AddItem(player, currentItemId, 1)
	end

	profile.Equipment[slot] = itemId
	table.remove(profile.Inventory, index)
	PlayerDataService.RefreshDerivedProfile(profile)
	return true
end

function InventoryService.UnequipItem(player, slot)
	local profile = getProfile(player)
	if not profile then
		return false
	end
	profile.Equipment = profile.Equipment or {}
	local itemId = profile.Equipment[slot]
	if not itemId then
		return false
	end

	local itemDefinition = Items.GetDefinition(itemId)
	if not itemDefinition then
		return false
	end

	if #profile.Inventory >= Config.InventoryCapacity then
		return false
	end
	profile.Equipment[slot] = nil
	table.insert(profile.Inventory, createInventoryEntry(itemId, 1))
	PlayerDataService.RefreshDerivedProfile(profile)
	return true
end

function InventoryService.RemoveItem(player, itemId, quantity)
	local profile = getProfile(player)
	if not profile then
		return false
	end
	local index, entry = findInventoryEntry(profile, itemId)
	if not entry then
		return false
	end
	quantity = quantity or 1
	if quantity <= 0 then
		return false
	end
	if entry.Quantity > quantity then
		entry.Quantity = entry.Quantity - quantity
		return true
	end
	table.remove(profile.Inventory, index)
	return true
end

function InventoryService.UseConsumable(player, itemId)
	local profile = getProfile(player)
	local itemDefinition = Items.GetDefinition(itemId)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not profile or not itemDefinition or itemDefinition.Type ~= "Consumable" or not humanoid then
		return false
	end
	if humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return false
	end
	local _, entry = findInventoryEntry(profile, itemId)
	if not entry or not InventoryService.RemoveItem(player, itemId, 1) then
		return false
	end

	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (itemDefinition.RestoreHealth or 0))
	return true
end

return InventoryService
