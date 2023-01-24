local Building = {}
Building.__index = Building

function Building.new(model: Model, version: )
	local building = {
		model = model,
	}

	return setmetatable(building, Building)
end

function Building:applyChange(value: number)

end

return Building
