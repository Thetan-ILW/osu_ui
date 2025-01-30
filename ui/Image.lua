local Component = require("ui.Component")

---@class ui.Image : ui.Component
---@operator call: ui.Image
---@field image love.Image
---@field blendMode love.BlendMode
local Image = Component + {}

function Image:load()
	self:assert(self.image, "No image")

	local iw, ih = self.image:getDimensions()

	self.blendMode = self.blendMode or "alpha"
	self.width = self.width ~= 0 and self.width or iw
	self.height = self.height ~= 0 and self.height or ih
	self.blockMouseFocus = (self.blockMouseFocus == nil) and true or self.blockMouseFocus
end

---@param image love.Image
---@param width number?
---@param height number?
function Image:replaceImage(image, width, height)
	self.image = image
	local iw, ih = self.image:getDimensions()
	self.width = width or iw
	self.height = height or ih
	self:load()
end

local gfx = love.graphics

function Image:draw()
	gfx.setBlendMode(self.blendMode)
	gfx.draw(self.image)
end

return Image
