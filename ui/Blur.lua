local Component = require("ui.Component")
local GaussianBlurView = require("sphere.views.GaussianBlurView")

local Blur = Component + {}

function Blur:load()
	self:assert(self.image, "You need to provide a canvas or an image")
	self.percent = self.percent or 0.2
	local w, h = math.ceil(self.image:getWidth() * self.percent), math.ceil(self.image:getHeight() * self.percent)
	self.lowResCanvas = love.graphics.newCanvas(w, h)
	self.viewportScale = self:getViewport():getInnerScale()
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
	love.graphics.draw(self.image)
	GaussianBlurView:draw(3)
	love.graphics.pop()
	love.graphics.scale(1 / self.percent)
	love.graphics.draw(self.lowResCanvas)
end

return Blur
