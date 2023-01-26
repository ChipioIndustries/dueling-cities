local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Convert = ReplicatedStorage:WaitForChild("Convert")
local GunScript = require(ReplicatedStorage:WaitForChild("Gun"))
local Building = require(ReplicatedStorage:WaitForChild("Building"))
local RoundTimer = require(ReplicatedStorage:WaitForChild("RoundTimer"))

local buildings = {}
local Gun = nil
local timer = nil

local ROUND_TIME = 20
local WAIT_TIME = 10

-- Client functions

local function onCharacterAddedClient(character)
	local GunModel = character:WaitForChild("Gun")
	GunModel.Handle.WeldConstraint.Part1 = character.RightHand
	GunModel.Handle.Position = character.RightHand.Position

	Gun = GunScript.new(GunModel.Handle, GunModel.Target, Convert)
	Gun:connectToUserInput()
end

local function onCharacterRemovingClient()
	Gun:cleanup()
	Gun = nil
end

local function initClient()
	local localPlayer = Players.LocalPlayer
	localPlayer.CharacterAdded:Connect(onCharacterAddedClient)
	localPlayer.CharacterRemoving:Connect(onCharacterRemovingClient)

	timer = RoundTimer.new(ROUND_TIME, WAIT_TIME)
	timer:initClient(localPlayer.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("TextLabel"))

	for _, part in workspace:GetChildren() do
		if part:IsA("Model") and part:FindFirstChild("OldVersion") then
			-- This assumes that buildings aren't created or destroyed.
			-- TODO: This is too optimistic about buildings loading in in time
			local building = Building.new(part)
			building:initClient()
		end
	end
end

-- Server functions

local lastHit = {}

local function setHit(gunHandle, building, team)
	local lastBuilding = lastHit[gunHandle]
	if lastBuilding and lastBuilding ~= building then
		lastBuilding:clearHit()
	end
	if building then
		building:onHit(team)
	end
	lastHit[gunHandle] = building
end

local function hitBuilding(gunHandle: Instance, instance: Instance?, team: Team?)
	if not instance then
		setHit(gunHandle, nil, team)
		return
	end

	local model = instance:FindFirstAncestorWhichIsA("Model")
	local building = buildings[model] or buildings[model.Parent]
	if building then
		setHit(gunHandle, building, team)
	else
		setHit(gunHandle, nil, team)
	end
end

local function onPlayerAdded(player)
	local added = nil
	local removing = nil
	local gun = nil

	local function onCharacterAddedServer(character)
		local gunModel = character.Gun
		gun = GunScript.new(gunModel.Handle, gunModel.Target, Convert)
		gun:connectToServerEvent()
		gun.onHit.Event:Connect(hitBuilding)
		gun.onStop.Event:Connect(hitBuilding)
	end

	local function onCharacterRemovingServer()
		if added then
			added:Disconnect()
			added = nil
		end
		if removing then
			removing:Disconnect()
			removing = nil
		end
		if gun then
			gun:cleanup()
			gun = nil
		end
	end

	player.CharacterAdded:Connect(onCharacterAddedServer)
	player.CharacterRemoving:Connect(onCharacterRemovingServer)
end

local function startRound()
    for _, building in buildings do
        building:changeVersion(Building.NEW)
    end

    for _, player in Players:GetPlayers() do
        player:LoadCharacter()
    end
end

local function endRound()
    -- Nothing at the moment
end

local function initServer()
	Players.PlayerAdded:Connect(onPlayerAdded)

	timer = RoundTimer.new(ROUND_TIME, WAIT_TIME)
	timer:initServer()

    timer.onStart.Event:Connect(startRound)
    timer.onStop.Event:Connect(endRound)

	for _, part in workspace:GetChildren() do
		if part:IsA("Model") and part:FindFirstChild("OldVersion") then
			-- This assumes that buildings aren't created or destroyed.
			local building = Building.new(part)
			buildings[part] = building
			building:initServer()
		end
	end
end

return  {
	initClient = initClient,
	initServer = initServer,
}