local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Flipper = require(ReplicatedStorage.Packages.Flipper)

local Building = {}
Building.__index = Building

Building.NEW = 1
Building.OLD = -1
export type VERSION = Building.NEW | Building.OLD

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
function Building.new(model: Model)
	local building = {
		model = model,
		stability = 0,
		motor = Flipper.SingleMotor.new(0),
	}

	return setmetatable(building, Building)
end

-- Server functions

function Building:_replace(with)
	local clone = with:Clone()

	local building = self.model:FindFirstChild("Building")
	if building then
		building:Destroy()
	end

	clone:SetPrimaryPartCFrame(self.model.PrimaryPart.CFrame)
	clone.PrimaryPart:Destroy()
	clone.Name = "Building"
	clone.Parent = self.model
end

function Building:_changeVersion(version: VERSION)
	if version == Building.NEW then
		self:_replace(self.model.NewVersion.Value)
	else
		self:_replace(self.model.OldVersion.Value)
	end
end

function Building:init()
	self:_changeVersion(Building.NEW)
	self.stability = 100
end

function Building:onHit(team: Team)
	if team == Teams.NewTeam then
		self:applyChange(1)
	else
		self:applyChange(-1)
	end
end

function Building:applyChange(value: number)
	self.stability += value
	if self.stability == 0 then
		if value < 0 then
			self.stability = -50
			self:_changeVersion(Building.OLD)
		else
			self.stability = 50
			self:_changeVersion(Building.NEW)
		end
	end
end

return Building
