local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local Convert = ReplicatedStorage:WaitForChild("Convert")
local GunScript = require(ReplicatedStorage:WaitForChild("Gun"))

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

local Gun = nil

local function onCharacterAdded(character)
	local GunModel = character:WaitForChild("Gun")
	GunModel.Handle.WeldConstraint.Part1 = character.RightHand
	GunModel.Handle.Position = character.RightHand.Position

	Gun = GunScript.new(GunModel.Handle, GunModel.Target, Convert)
	Gun:connectToUserInput()
end

local function onCharacterRemoving()
	Gun:cleanup()
	Gun = nil
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
localPlayer.CharacterRemoving:Connect(onCharacterRemoving)
