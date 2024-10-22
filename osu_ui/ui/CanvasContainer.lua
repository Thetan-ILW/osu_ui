local Container = require("osu_ui.ui.Container")

---@alias CanvasContainerParams { totalW: number?, totalH: number? }

---@class osu.ui.CanvasContainer : osu.ui.Container
---@overload fun(params: CanvasContainerParams): osu.ui.CanvasContainer
---@field canvas love.Canvas
local CanvasContainer = Container + {}

function CanvasContainer:load()
	self.automaticSizeCalc = false
	self.canvas = love.graphics.newCanvas(self.totalW, self.totalH)
	Container.load(self)
end

local gfx = love.graphics

function CanvasContainer:draw()
	local prev_canvas = gfx.getCanvas()
	gfx.setCanvas(self.canvas)
	gfx.clear()
	gfx.setBlendMode("alpha", "alphamultiply")

	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		gfx.push()
		gfx.applyTransform(child.transform)
		child:draw()
		gfx.pop()

		gfx.push()
		gfx.applyTransform(child.transform)
		child:debugDraw()
		gfx.pop()
	end

	local a = self.alpha
	gfx.setCanvas(prev_canvas)
	gfx.setBlendMode("alpha", "premultiplied")
	gfx.setColor(a, a, a, a)
	gfx.draw(self.canvas)
	gfx.setBlendMode("alpha")
end

return CanvasContainer
