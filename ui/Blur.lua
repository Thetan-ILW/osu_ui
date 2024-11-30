local Component = require("ui.Component")
local GaussianBlurView = require("sphere.views.GaussianBlurView")

local Blur = Component + {}

function Blur:load()
	self.percent = self.percent or 0.2
	self.viewport = self:getViewport()
	self.viewportScale = self.viewport:getInnerScale()

	local image = self.image or self.viewport.canvas
	local w, h = math.ceil(image:getWidth() * self.percent), math.ceil(image:getHeight() * self.percent)
	self.lowResCanvas = love.graphics.newCanvas(w, h)
end

function Blur:draw()
	love.graphics.push("all")
	love.graphics.setCanvas(self.lowResCanvas)
	love.graphics.origin()
	love.graphics.clear()
	love.graphics.scale(self.percent / self.viewportScale)
	love.graphics.setShader(self.shader)
	love.graphics.setColor(1, 1, 1, 1)
	GaussianBlurView:draw(3)
	love.graphics.draw(self.image and self.image or self.viewport.canvas)
	GaussianBlurView:draw(3)
	love.graphics.pop()
	love.graphics.scale(1 / self.percent)
	love.graphics.draw(self.lowResCanvas)
end

return Blur
