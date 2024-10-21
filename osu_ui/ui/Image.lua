local UiElement = require("osu_ui.ui.UiElement")

---@alias ImageParams { image: love.Image }

---@class osu.ui.Image : osu.ui.UiElement
---@overload fun(params: ImageParams): osu.ui.Image
---@field image love.Image
local Image = UiElement + {}

function Image:load()
	UiElement.load(self)
	assert(self.image, "Image is not defined")
	self.totalW, self.totalH = self.image:getDimensions()
	self:replaceTransform(self.transform)
end

local gfx = love.graphics

function Image:draw()
	gfx.setColor(self.color)
	gfx.draw(self.image)
end

return Image
