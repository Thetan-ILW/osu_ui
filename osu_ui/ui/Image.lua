local UiElement = require("osu_ui.ui.UiElement")

---@alias ImageParams { image: love.Image, wrap: string?, quad: love.Quad?  }

---@class osu.ui.Image : osu.ui.UiElement
---@overload fun(params: ImageParams): osu.ui.Image
---@field image love.Image
---@field quad love.Quad?
---@field private sx number
---@field private sy number
local Image = UiElement + {}

function Image:load()
	assert(self.image, debug.traceback("Image is not defined"))

	if self.quad then
		local _, _, w, h = self.quad:getViewport()
		self.totalW, self.totalH = w, h
		self.sx, self.sy = 1, 1
	else
		local iw, ih = self.image:getDimensions()
		self.totalW, self.totalH = self.totalW or iw, self.totalH or ih
		self.sx, self.sy = self.totalW / iw, self.totalH / ih
	end

	UiElement.load(self)
end

---@param image love.Image
function Image:replaceImage(image, total_w, total_h)
	self.image = image
	local iw, ih = self.image:getDimensions()
	self.totalW = total_w or iw
	self.totalH = total_h or ih
	self:load()
end

local gfx = love.graphics

function Image:draw()
	if self.quad then
		gfx.draw(self.image, self.quad)
		return
	end

	gfx.draw(self.image, 0, 0, 0, self.sx, self.sy)
end

return Image
