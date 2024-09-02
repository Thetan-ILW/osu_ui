local class = require("class")

---@class osu.ui.InputMap
---@operator call: osu.ui.InputMap
local InputMap = class()

---@type osu.ui.ActionModel
InputMap.actionModel = nil

---@param view osu.ui.ScreenView
function InputMap:createBindings(view) end

---@param view osu.ui.ScreenView
---@param actionModel osu.ui.ActionModel
function InputMap:new(view, actionModel)
	self:createBindings(view)
	self.actionModel = actionModel
end

---@param group string
---@return boolean
function InputMap:call(group)
	local bindings = self[group]

	local f = bindings[self.actionModel.getAction()]

	if f then
		f()
		self.actionModel.resetAction()
		return true
	end

	return false
end

return InputMap
