local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Convert = ReplicatedStorage.Convert
local GunScript = require(ReplicatedStorage.Gun)

local rnd = Random.new()

-- Each building should be:
-- (name): Model
--   NewVersion: ObjectValue
--   OldVersion: ObjectValue
--   Field: Part (A no-collide bounding box for effects)
--   Plot: Part (The PrimaryPart, sets the size of the building)

-- NewVersion and OldVersion should point to Models that define the
-- looks of the two versions of the building. The only requirements
-- are that the PrimaryParts of these models match the size of the
-- PrimaryPart of the building model's Plot.

local function replaceBuilding(obj, with)
	local clone = with:Clone()

	local building = obj:FindFirstChild("Building")
	if building then
		building:Destroy()
	end

	clone:SetPrimaryPartCFrame(obj.PrimaryPart.CFrame)
	clone.PrimaryPart:Destroy()
	clone.Name = "Building"
	clone.Parent = obj
end

local function convertBuilding(obj: Instance, team: Team)
	obj = obj:FindFirstAncestorWhichIsA("Model")
	if obj and obj:GetAttribute("Stability") then
		obj.Field.Color = team.TeamColor.Color
		obj.Field.Transparency = 0.8
		local stability = obj:GetAttribute("Stability")
		if team == Teams.OldTeam then
			stability = math.max(-100, stability - 1)
			if stability == 0 then
				replaceBuilding(obj, obj.OldVersion.Value)
				stability = -50
			end
		else
			stability = math.min(100, stability + 1)
			if stability == 0 then
				replaceBuilding(obj, obj.NewVersion.Value)
				stability = 50
			end
		end
		obj:SetAttribute("Stability", stability)
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
		gun.onHit.Event:Connect(convertBuilding)
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
		-- Temporary. This should randomize buildings.
		part:SetAttribute("Stability", 100)
		replaceBuilding(part, part.NewVersion.Value)
	end
end
