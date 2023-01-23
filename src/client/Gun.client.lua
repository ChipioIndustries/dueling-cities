local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local convert = ReplicatedStorage:WaitForChild("Convert")

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
localPlayer.CharacterAdded:Connect(function(character)
	character:WaitForChild("Gun")
	character.Gun.Handle.WeldConstraint.Part1 = character.RightHand
	character.Gun.Handle.Position = character.RightHand.Position

	local firing = false

	local function updateTarget()
		local mousePos = UserInputService:GetMouseLocation()
		local viewRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
		local result = workspace:Raycast(viewRay.Origin, viewRay.Direction * 1000)
		return result and result.Position
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			convert:FireServer(true)

			firing = true
			while firing do
				local pos = updateTarget()
				if pos then
					convert:FireServer(true, pos)
				end
				wait(0.1)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = false
			convert:FireServer(false)
		end
	end)
end)

