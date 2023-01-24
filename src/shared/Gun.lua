local UserInputService = game:GetService("UserInputService")

local TICK_RATE = 0.1

local Gun = {}
Gun.__index = Gun

function Gun.new(handle: Part, target: Part, event: RemoteEvent)
	local gun = {
		handle = handle,
		target = target,
		event = event,
		enabled = false,
		inputBegan = nil,
		inputEnded = nil,
	}

	return setmetatable(gun, Gun)
end

function Gun:_tick()
	local mousePos = UserInputService:GetMouseLocation()
	local viewRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local result = workspace:Raycast(viewRay.Origin, viewRay.Direction * 1000)

	if result and result.Position then
		self.event:FireServer(true, result.Position)
	end
end

-- Client functions

function Gun:setEnable(enabled: boolean)
	self.enabled = enabled
	self.event:FireServer(enabled)
	if enabled then
		while self.enabled do
			self:_tick()
			task.wait(TICK_RATE)
		end
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
	
	self.inputBegan = UserInputService.InputBegan:Connect(onInputBegan)
	self.inputEnded = UserInputService.InputEnded:Connect(onInputEnded)
end

function Gun:cleanup()
	self.inputBegan:Disconnect()
	self.inputEnded:Disconnect()
end

return Gun
