local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local rng = Random.new()

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local ChangeRate: NumberValue = ReplicatedStorage:WaitForChild("ChangeRate")

local Building = {}
Building.__index = Building

Building.NEW = 1
Building.OLD = -1
export type VERSION = Building.NEW | Building.OLD

local CHANGE_RATE

if not ChangeRate.Value then
	ChangeRate.Changed:Wait()
end
CHANGE_RATE = ChangeRate.Value

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
	}

	return setmetatable(building, Building)
end

-- Client functions

function Building:initClient()
	local motor = Flipper.SingleMotor.new(0)

	local function onStep(value)
		local field = self.model.Field
		if value > 0 then
			field.Color = Teams.NewTeam.TeamColor.Color
		else
			field.Color = Teams.OldTeam.TeamColor.Color
		end
		field.Transparency = math.max(0, 1 - 0.5 * math.abs(value))
	end

	local function onAttributeChanged(attr)
		if attr == "Flux" then
			motor:setGoal(Flipper.Spring.new(self.model:GetAttribute("Flux"), {frequency = 1/3}))
		end
	end

	motor:onStep(onStep)
	self.model.AttributeChanged:Connect(onAttributeChanged)
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

	-- Assumes at most one spawn per building
	local spawn = clone:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then
		spawn.Enabled = true
	end

	clone.Parent = self.model
end

function Building:changeVersion(version: VERSION)
	if version == Building.NEW then
		self:_replace(self.model.NewVersion.Value)
	else
		self:_replace(self.model.OldVersion.Value)
	end
end

function Building:initServer()
	if rng:NextNumber() < 0.5 then
		self:changeVersion(Building.NEW)
		self.model:SetAttribute("Stability", 100)
	else
		self:changeVersion(Building.OLD)
		self.model:SetAttribute("Stability", -100)
	end
end

function Building:onHit(team: Team)
	if team == Teams.NewTeam then
		self:applyChange(CHANGE_RATE)
	else
		self:applyChange(-CHANGE_RATE)
	end
end

function Building:clearHit()
	self.model:SetAttribute("Flux", 0)
end

function Building:applyChange(value: number)
	local oldStability = self.model:GetAttribute("Stability")
	local stability = math.clamp(oldStability + value, -100, 100)

	if math.sign(oldStability) ~= math.sign(stability) then
		if value < 0 then
			stability = -50
			self.model:SetAttribute("Flux", -10)
			self:changeVersion(Building.OLD)
		else
			stability = 50
			self.model:SetAttribute("Flux", 10)
			self:changeVersion(Building.NEW)
		end
	else
		if math.sign(stability) == math.sign(value) then
			self.model:SetAttribute("Flux", value * (1 - math.abs(stability) / CHANGE_RATE / 100))
		else
			self.model:SetAttribute("Flux", value / CHANGE_RATE)
		end
	end

	self.model:SetAttribute("Stability", stability)
end

return Building
