local Component = require("ui.Component")
local Label = require("ui.Label")
local Rectangle = require("ui.Rectangle")

---@class ui.Inspector : ui.Component
---@operator call: ui.Inspector
local Inspector = Component + {}

function Inspector:load()
	local viewport = self:getViewport()
	local fonts = viewport:getFontManager()

	self:addChild("label", Label({
		x = 5, y = 5,
		text = "",
		font = fonts:loadFont("Regular", 16),
		z = 1,
	}))

	self:addChild("background", Rectangle({
		color = { 0, 0, 0, 0.4 }
	}))
end

---@param components ui.Component[]
function Inspector:printInfo(components)
	local str = ("Count: %i\n"):format(#components)
	for i, v in ipairs(components) do
		str = str .. ("ID: %s\n"):format(v.id)
	end

	local label = self.children.label
	local bg = self.children.background

	label:replaceText(str)
	bg.width, bg.height = label:getDimensions()
	self.width, self.height = label:getDimensions()
end

return Inspector
