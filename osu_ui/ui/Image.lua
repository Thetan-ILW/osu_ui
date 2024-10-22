local UiElement = require("osu_ui.ui.UiElement")

---@alias ImageParams { image: love.Image }

---@class osu.ui.Image : osu.ui.UiElement
---@overload fun(params: ImageParams): osu.ui.Image
---@field image love.Image
local Image = UiElement + {}

function Image:load()
	assert(self.image, "Image is not defined")
	self.totalW, self.totalH = self.image:getDimensions()
	UiElement.load(self)
end

local gfx = love.graphics

function Image:draw()
	local c = self.color
	gfx.setColor(c[1], c[2], c[3], c[4] * self.alpha)
	gfx.draw(self.image)
end

return Image
