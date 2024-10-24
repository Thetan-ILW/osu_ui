local UiElement = require("osu_ui.ui.UiElement")

local math_util = require("math_util")

---@alias ParallaxBackgroundMode "single_image" | "background_model"
---@alias ParallaxBackgroundParams { mode: ParallaxBackgroundMode, parallax: number?, dim: number?, image: love.Image?, backgroundModel: sphere.BackgroundModel }

---@class osu.ui.ParallaxBackground : osu.ui.UiElement
---@overload fun(params: ParallaxBackgroundParams): osu.ui.ParallaxBackground
---@field parallax number
---@field dim number
---@field image love.Image?
---@field backgroundModel sphere.BackgroundModel?
---@field mode ParallaxBackgroundMode
local ParallaxBackground = UiElement + {}

function ParallaxBackground:load()
	self.parallax = self.parallax or 0.01
	self.dim = self.dim or 0

	if self.mode == "background_model" then
		assert(self.backgroundModel, "backgroundModel was not provided")
	end

	UiElement.load(self)
end

function ParallaxBackground:drawImage(image)
	local w, h = self.parent.totalW, self.parent.totalH
	local mx, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
	local parallax = self.parallax

	local x = -math_util.map(mx, 0, w, parallax, 0) * w
	local y = -math_util.map(my, 0, h, parallax, 0) * h
	local iw = (1 + 2 * parallax) * w
	local ih = (1 + 2 * parallax) * h
	local dw = image:getWidth()
	local dh = image:getHeight()

	local s = 1
	local s1 = w / h <= dw / dh
	local s2 = w / h >= dw / dh

	if s1 then
		s = h / dh
	elseif s2 then
		s = w / dw
	end

	love.graphics.draw(image, x + (iw - dw * s) / 2, y + (ih - dh * s) / 2, 0, s)
end

function ParallaxBackground:draw()
	if self.dim == 1 then
		return
	end

	if self.mode == "single_image" then
		if self.image then
			self:drawImage(self.image)
		end
		return
	end

	local images = self.backgroundModel.images
	local alpha = self.backgroundModel.alpha

	local dim = 1 - self.dim
	local r, g, b = dim, dim, dim

	for i = 1, 3 do
		if not images[i] then
			return
		end

		if i == 1 then
			love.graphics.setColor(r, g, b, 1)
		elseif i == 2 then
			love.graphics.setColor(r, g, b, alpha)
		elseif i == 3 then
			love.graphics.setColor(r, g, b, 0)
		end

		self:drawImage(images[i])
	end
end

return ParallaxBackground
