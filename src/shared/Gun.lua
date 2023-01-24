local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TICK_RATE = 0.1

local TWEEN_INFO = TweenInfo.new(TICK_RATE)

local Gun = {}
Gun.__index = Gun

-- Assumes that the Gun is a model under the starter character
-- The gun model should contain at least:
--   Gun: Model
--     Handle: Part
--       Attachment: Attachment
--       WeldConstraint: WeldConstraint
--     Target: Part
--       Attachment: Attachment
--       Beam: Beam (connected to the two attachments above)
--       ParticleEmitter: ParticleEmitter
function Gun.new(handle: Part, target: Part, event: RemoteEvent)
	local gun = {
		handle = handle,
		target = target,
		event = event,
		enabled = false,
		connections = {},
		onHit = Instance.new("BindableEvent"),
		onStop = Instance.new("BindableEvent"),
	}

	return setmetatable(gun, Gun)
end

function Gun:cleanup()
	for _, conn in self.connections do
		conn:Disconnect()
	end
	self.connections = {}
end

function Gun:_connect(event, func)
	table.insert(self.connections, event:Connect(func))
end

-- Client functions

function Gun:_tick()
	local mousePos = UserInputService:GetMouseLocation()
	local viewRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local result = workspace:Raycast(viewRay.Origin, viewRay.Direction * 1000)

	if result and result.Position then
		self.event:FireServer(true, result.Position)
	end
end

function Gun:setEnable(enabled: boolean)
	self.enabled = enabled
	self.event:FireServer(enabled)
	while self.enabled do
		self:_tick()
		task.wait(TICK_RATE)
	end
end

function Gun:connectToUserInput()
	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:setEnable(true)
		end
	end
	
	local function onInputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:setEnable(false)
		end
	end
	
	self:_connect(UserInputService.InputBegan, onInputBegan)
	self:_connect(UserInputService.InputEnded, onInputEnded)
end

-- Server functions

function Gun:setColor(color: Color3)
	self.target.Beam.Color = ColorSequence.new(color)
end

function Gun:setBeamEnabled(enabled: boolean)
	self.target.Beam.Enabled = enabled
	self.target.ParticleEmitter.Enabled = enabled
end

function Gun:connectToServerEvent()
	local function onServerEvent(player, enabled, pos)
		self:setColor(player.Team.TeamColor.Color)
		self:setBeamEnabled(enabled)
		if enabled and pos then
			local result = workspace:Raycast(self.handle.Position, (pos - self.handle.Position) * 1.1)
			if result then
				pos = result.Position

				self.onHit:Fire(self.handle, result.Instance, player.Team)
			else
				self.onStop:Fire(self.handle)
			end
			TweenService:Create(self.target, TWEEN_INFO, {Position = pos}):Play()
		else
			self.onStop:Fire(self.handle)
		end
	end

	self:_connect(self.event.OnServerEvent, onServerEvent)
end

return Gun
