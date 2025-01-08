local Component = require("ui.Component")

---@class ui.StencilComponent : ui.Component
---@operator call: ui.StencilComponent
---@field stencilFunction function
---@field action string
---@field value number
---@field compareMode string
---@field compareValue number
local StencilComponent = Component + {}

function StencilComponent:new(params)
	Component.new(self, params)
	self.action = self.action or "replace"
	self.value = self.value or 1
	self.compareMode = self.compareMode or "greater"
	self.compareValue = self.compareValue or 0
end

function StencilComponent:drawTree()
	love.graphics.push()
	love.graphics.applyTransform(self.transform)
	love.graphics.stencil(self.stencilFunction, self.action, self.value)
	love.graphics.setStencilTest(self.compareMode, self.compareValue)
	love.graphics.pop()
	Component.drawTree(self)
	love.graphics.setStencilTest()
end

return StencilComponent
