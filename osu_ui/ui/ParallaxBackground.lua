local Component = require("ui.Component")

---@alias ParallaxBackgroundMode "single_image" | "background_model"
---@alias ParallaxBackgroundParams { mode: ParallaxBackgroundMode, parallax: number?, dim: number?, image: love.Image?, backgroundModel: sphere.BackgroundModel }

---@class osu.ui.ParallaxBackground : ui.Component
---@overload fun(params: ParallaxBackgroundParams): osu.ui.ParallaxBackground
---@field parallax number
---@field dim number
---@field image love.Image?
---@field backgroundModel sphere.BackgroundModel?
---@field mode ParallaxBackgroundMode
local ParallaxBackground = Component + {}

function ParallaxBackground:load()
	self.parallax = self.parallax or 0.01
	self.dim = self.dim or 0
	self.blur = 0
	self.mode = self.mode or "single_image"

	if self.mode == "background_model" then
		assert(self.backgroundModel, "backgroundModel was not provided")
	end
end

function ParallaxBackground:drawImage(image)
	local w, h = self.parent.width, self.parent.height
	local mx, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
	local parallax = self.parallax
	local iw, ih = image:getDimensions()
	local px = (w / 2 - mx) * parallax
	local py = (h / 2 - my) * parallax
	local scale = math.max((w + w * parallax) / iw, (h + h * parallax) / ih)
	love.graphics.draw(image, w / 2 - px, h / 2 - py, 0, scale, scale, iw / 2, ih / 2)
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
	local r, g, b, a = love.graphics.getColor()
	r, g, b = r * dim, g * dim, b * dim

	if images[1] then
		love.graphics.setColor(r, g, b, a)
		self:drawImage(images[1])
	end
	if images[2] then
		love.graphics.setColor(r, g, b, alpha * a)
		self:drawImage(images[2])
	end
end

return ParallaxBackground
