local ModifierEncoder = require("sphere.models.ModifierEncoder")
local ModifierModel = require("sphere.models.ModifierModel")

---@param mods table
---@return string
return function(mods)
	if type(mods) == "string" then
		mods = ModifierEncoder:decode(mods)
	end
	local modString = ""
	for _, mod in pairs(mods) do
		local modifier = ModifierModel:getModifier(mod.id)

		if modifier then
			local modifierString, modifierSubString = modifier:getString(mod)
			modString = string.format("%s %s%s", modString, modifierString, modifierSubString or "")
		end
	end

	return modString
end
