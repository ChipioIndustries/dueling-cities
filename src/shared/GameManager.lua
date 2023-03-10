local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Convert = ReplicatedStorage:WaitForChild("Convert")
local GunScript = require(ReplicatedStorage:WaitForChild("Gun"))
local Building = require(ReplicatedStorage:WaitForChild("Building"))
local RoundTimer = require(ReplicatedStorage:WaitForChild("RoundTimer"))

local RoundLength: IntValue = ReplicatedStorage:WaitForChild("RoundLength")
local WaitLength: IntValue = ReplicatedStorage:WaitForChild("WaitLength")

local buildings = {}
local Gun = nil
local timer = nil

local ROUND_TIME
local WAIT_TIME

if not RoundLength.Value then
	RoundLength.Changed:Wait()
end
ROUND_TIME = RoundLength.Value

if not WaitLength.Value then
	WaitLength.Changed:Wait()
end
WAIT_TIME = WaitLength.Value

local function isBuildingRoot(part: Instance): boolean
	return part:IsA("Model") and part:FindFirstChild("OldVersion")
end

local function getBuildingRoot(part: Instance): Model?
	while not isBuildingRoot(part) do
		part = part:FindFirstAncestorWhichIsA("Model")
		if not part then
			return nil
		end	
	end
	return part
end

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
		if isBuildingRoot(part) then
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
	local playerHit = Players:GetPlayerFromCharacter(model)
	if playerHit then
		model.Humanoid.Health -= 2
		return
	end
	
	model = getBuildingRoot(model)
	local building = model and buildings[model]
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
		gunModel.AncestryChanged:Connect(function(child, parent)
			if parent == workspace then
				gunModel.Handle.WeldConstraint.Part1 = character.RightHand
				gunModel.Handle.Position = character.RightHand.Position
				gunModel.Handle:SetNetworkOwner(player)
			end
		end)

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
        building:initServer()
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
