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

	self.redrawEveryFrame = self.redrawEveryFrame == nil and true or self.redrawEveryFrame
	self.redraw = true
end

function Canvas:draw()
	love.graphics.draw(self.canvas)
end

function Canvas:drawTree()
	local r, g, b, a = self:mixColors()
	if a <= 0 then
		return
	end

	if self.redraw then
		local prev_canvas = love.graphics.getCanvas()

		love.graphics.setCanvas({ self.canvas, stencil = self.stencil })

		love.graphics.push("all")
		love.graphics.origin()
		love.graphics.setBlendMode("alpha", "alphamultiply")
		love.graphics.scale(self.viewportScale)
		love.graphics.clear()
		love.graphics.setColor(1, 1, 1)
		self:drawChildren()
		love.graphics.pop()

		love.graphics.setCanvas(prev_canvas)
		self.redraw = self.redrawEveryFrame
	end

	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.applyTransform(self.transform)
	love.graphics.scale(1 / self.viewportScale)
	love.graphics.setColor(r * a, g * a, b * a, a)
	self:draw()
	love.graphics.setBlendMode("alpha")
end

return Canvas
