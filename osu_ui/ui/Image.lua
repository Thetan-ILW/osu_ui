local UiElement = require("osu_ui.ui.UiElement")

---@class osu.ui.Image : osu.ui.UiElement
---@operator call: osu.ui.Image
---@field ox number
---@field oy number
local Image = UiElement + {}

---@param params { image: love.Image, ox: number?, oy: number? }
function Image:new(params)
	UiElement.new(self, params)
	self.image = params.image

	local iw, ih = self.image:getDimensions()
	self.ox = iw * (params.ox or 0)
	self.oy = ih * (params.oy or 0)
end

function Image:draw()
	love.graphics.draw(self.image, 0, 0, 0, 1, 1, self.ox, self.oy)
end

return Image
