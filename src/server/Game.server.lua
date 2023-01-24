local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Convert = ReplicatedStorage.Convert
local GunScript = require(ReplicatedStorage.Gun)
local Building = require(ReplicatedStorage.Building)

local rnd = Random.new()
local buildings = {}

local function hitBuilding(instance: Instance, team: Team)
	local model = instance:FindFirstAncestorWhichIsA("Model")
	local building = buildings[model]
	if building then
		building:onHit(team)
	end
end

local function onPlayerAdded(player)
	local added = nil
	local removing = nil
	local gun = nil

	local function onCharacterAdded(character)
		local gunModel = character.Gun
		gun = GunScript.new(gunModel.Handle, gunModel.Target, Convert)
		gun:connectToServerEvent()
		gun.onHit.Event:Connect(hitBuilding)
	end

	local function onCharacterRemoving()
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

	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, part in workspace:GetChildren() do
	if part:IsA("Model") and part:FindFirstChild("OldVersion") then
		-- This assumes that buildings aren't created or destroyed.
		local building = Building.new(part)
		buildings[part] = building
		building:init()
	end
end
