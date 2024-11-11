local Container = require("osu_ui.ui.Container")

---@alias CanvasContainerParams { totalW: number?, totalH: number?, shader: love.Shader? }

---@class osu.ui.CanvasContainer : osu.ui.Container
---@overload fun(params: CanvasContainerParams): osu.ui.CanvasContainer
---@field canvas love.Canvas
---@field shader love.Shader
---@field stencil boolean?
local CanvasContainer = Container + {}

function CanvasContainer:load()
	self.automaticSizeCalc = false
	self.canvas = love.graphics.newCanvas(self.totalW, self.totalH)
	self.stencil = self.stencil or false
	Container.load(self)
end

local gfx = love.graphics

function CanvasContainer:draw()
	local prev_canvas = gfx.getCanvas()
	gfx.setCanvas({ self.canvas, stencil = self.stencil })
	gfx.clear()
	gfx.setBlendMode("alpha", "alphamultiply")

	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		gfx.push()
		gfx.applyTransform(child.transform)
		gfx.setColor(child.color)
		child:draw()
		gfx.pop()

		--gfx.push()
		--gfx.applyTransform(child.transform)
		--child:debugDraw()
		--gfx.pop()
	end

	local a = self.alpha
	gfx.setCanvas(prev_canvas)
	gfx.setBlendMode("alpha", "premultiplied")

	local wh = gfx.getHeight()
	local _, iwh = gfx.inverseTransformPoint(0, wh)

	local prev_shader = gfx.getShader()
	if self.shader then
		gfx.setShader(self.shader)
	end

	gfx.setColor(a, a, a, a)
	gfx.push()
	gfx.scale(iwh / wh)
	self:drawCanvas()
	gfx.pop()
	gfx.setBlendMode("alpha")

	gfx.setShader(prev_shader)
end

function CanvasContainer:drawCanvas()
	gfx.draw(self.canvas)
end

return CanvasContainer
