local Component = require("ui.Component")

---@class ui.CanvasComponent : ui.Component
---@field stencil boolean
local Canvas = Component + {}

function Canvas:load()
	self:createCanvas(self.width, self.height)
	self.stencil = self.stencil or false
end

---@param width number
---@param height number
function Canvas:createCanvas(width, height)
	self:assert(width > 0 and height > 0, "Canvas should have width and height")
	self.viewportScale = self:getViewport():getInnerScale()
	self.canvas = love.graphics.newCanvas(width * self.viewportScale, height * self.viewportScale)
end

function Canvas:draw()
	love.graphics.draw(self.canvas)
end

function Canvas:drawTree()
	local r, g, b, a = self:mixColors()
	if a <= 0 then
		return
	end

	local prev_canvas = love.graphics.getCanvas()

	love.graphics.setCanvas({ self.canvas, stencil = self.stencil })
	love.graphics.setBlendMode("alpha", "alphamultiply")

	love.graphics.push("all")
	love.graphics.origin()
	love.graphics.scale(self.viewportScale)
	love.graphics.clear()
	love.graphics.setColor(r, g, b, a)
	self:drawChildren()
	love.graphics.pop()

	love.graphics.setCanvas(prev_canvas)

	love.graphics.applyTransform(self.transform)
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.origin()
	self:draw()
	love.graphics.setBlendMode("alpha")
end

return Canvas
