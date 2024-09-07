local class = require("class")
local actions = require("osu_ui.actions")

---@class osu.ui.InputMap
---@operator call: osu.ui.InputMap
local InputMap = class()

---@param view osu.ui.ScreenView
function InputMap:createBindings(view) end

---@param view osu.ui.ScreenView
function InputMap:new(view)
	self:createBindings(view)
end

---@param group string
---@return boolean
function InputMap:call(group)
	local bindings = self[group]

	local f = bindings[actions.getAction()]

	if f then
		f()
		actions.resetAction()
		return true
	end

	return false
end

return InputMap
