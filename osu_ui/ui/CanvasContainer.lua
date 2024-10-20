local Container = require("osu_ui.ui.Container")

---@class osu.ui.CanvasContainer : osu.ui.Container
---@operator call: osu.ui.CanvasContainer
local CanvasContainer = Container + {}

---@param depth number?
---@param transform love.Transform?
---@param width number?
---@param height number?
function CanvasContainer:new(depth, transform, width, height)
	self.depth = depth or 0
	self.children = {}
	if width and height then
		self.canvas = love.graphics.newCanvas(width, height)
	else
		self.canvas = love.graphics.newCanvas(love.graphics.getDimensions())
	end
	self.alpha = 0
	self:setTransform(transform or love.math.newTransform(0, 0))
end

local gfx = love.graphics

function CanvasContainer:draw()
	local prev_canvas = gfx.getCanvas()
	gfx.setCanvas(self.canvas)
	gfx.clear()
	gfx.setBlendMode("alpha", "alphamultiply")

	gfx.push()
	gfx.applyTransform(self.transform)
	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		gfx.push()
		gfx.applyTransform(child.transform)
		child:draw()
		child:resetTransform()
		gfx.pop()
	end
	gfx.pop()

	local a = self.alpha
	gfx.setCanvas(prev_canvas)
	gfx.setBlendMode("alpha", "premultiplied")
	gfx.setColor(a, a, a, a)
	gfx.origin()
	gfx.draw(self.canvas)
	gfx.setBlendMode("alpha")
end

return CanvasContainer
