-- WARNING!!!
-- This old beta version of one of the Roblox API Tools
-- This version is very unstable and we dont prefer using this one!
-- Please use the python version instead!

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Create a folder for user-defined settings
local SettingsFolder = ReplicatedStorage:FindFirstChild("ScanSettings") or Instance.new("Folder")
SettingsFolder.Name = "ScanSettings"
SettingsFolder.Parent = ReplicatedStorage

-- NumberValue instance for the friend check limit
local FriendCheckLimit = SettingsFolder:FindFirstChild("FriendCheckLimit") or Instance.new("NumberValue")
FriendCheckLimit.Value = FriendCheckLimit.Value > 0 and FriendCheckLimit.Value or 115 -- Default value (player can change this)
FriendCheckLimit.Name = "FriendCheckLimit"
FriendCheckLimit.Parent = SettingsFolder

-- StringValue instance for target player name
local TargetPlayerName = SettingsFolder:FindFirstChild("TargetPlayerName") or Instance.new("StringValue")
TargetPlayerName.Value = TargetPlayerName.Value ~= "" and TargetPlayerName.Value or "ToomikQu" -- Default target player
TargetPlayerName.Name = "TargetPlayerName"
TargetPlayerName.Parent = SettingsFolder

-- Folder for item names
local ItemNamesFolder = SettingsFolder:FindFirstChild("ItemNames") or Instance.new("Folder")
ItemNamesFolder.Name = "ItemNames"
ItemNamesFolder.Parent = SettingsFolder

-- Predefined item names that the script will scan for
local PredefinedItemNames = {"BrownCharmerHair"} -- Replace with actual item names

-- Function to get required item names from the folder and predefined list
local function getRequiredItemNames()
	local itemNames = {}

	-- Get user-defined item names
	for _, child in ipairs(ItemNamesFolder:GetChildren()) do
		if child:IsA("StringValue") then
			table.insert(itemNames, child.Value)
		end
	end

	-- Add predefined item names
	for _, name in ipairs(PredefinedItemNames) do
		table.insert(itemNames, name)
	end

	return itemNames
end

-- Function to check if a player's character has specific named items equipped
local function checkCharacterItems(character, requiredItemNames)
	local foundItems = {}

	for _, obj in pairs(character:GetChildren()) do
		if table.find(requiredItemNames, obj.Name) then
			table.insert(foundItems, obj.Name)
		end
	end

	return foundItems
end

-- Function to load a player's character into the game and clone it
local function loadCharacter(userId)
	local success, characterModel = pcall(function()
		return Players:GetCharacterAppearanceAsync(userId)
	end)

	if success and characterModel then
		local tempPlayer = Instance.new("Model")
		tempPlayer.Name = "Player_" .. tostring(userId)
		tempPlayer.Parent = Workspace

		local character = Instance.new("Model")
		character.Name = "Character"
		character.Parent = tempPlayer

		for _, obj in pairs(characterModel:GetChildren()) do
			local clonedObj = obj:Clone()
			clonedObj.Parent = character
		end

		return tempPlayer
	end

	return nil
end

-- Function to start scanning when "startScan" is said in chat
local function onPlayerChatted(player, message)
	if message:lower() == "startscan" then
		-- Dynamically retrieve values before each scan
		local targetUsername = TargetPlayerName.Value
		local checkLimit = FriendCheckLimit.Value
		local requiredItemNames = getRequiredItemNames()

		local targetPlayer = Players:FindFirstChild(targetUsername)
		if not targetPlayer then
			warn("Invalid target player username.")
			return
		end

		local friendsList = {}
		local success, pages = pcall(function()
			return Players:GetFriendsAsync(targetPlayer.UserId)
		end)

		if success then
			while true do
				for _, friend in ipairs(pages:GetCurrentPage()) do
					table.insert(friendsList, friend.Id)
				end
				if pages.IsFinished then
					break
				end
				pages:AdvanceToNextPageAsync()
			end
		else
			warn("Failed to retrieve friends list for " .. targetPlayer.Name)
			return
		end

		print("Checking up to " .. checkLimit .. " friends for player " .. targetUsername .. "...")
		local detectedCount = 0
		local detectedPlayers = {}

		for i = 1, math.min(checkLimit, #friendsList) do
			local friendId = friendsList[i]
			local clonedCharacter = loadCharacter(friendId)

			if clonedCharacter then
				local foundItems = checkCharacterItems(clonedCharacter.Character, requiredItemNames)
				if #foundItems > 0 then
					warn("Try " .. i .. ": Friend ID " .. friendId .. " has required items: " .. table.concat(foundItems, ", "))
					table.insert(detectedPlayers, friendId)
					detectedCount = detectedCount + 1
				else
					print("Try " .. i .. ": Friend ID " .. friendId .. " has none of the required items.")
				end

				-- Clean up character after checking
				clonedCharacter:Destroy()
			else
				print("Try " .. i .. ": Failed to load character for Friend ID " .. friendId)
			end

			task.wait(0.01) -- Delay of 1 second between each check
		end

		warn("The player scan is done, detected " .. detectedCount .. " players with the required items equipped.")
	end
end

-- Connect chat event to function
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end)
