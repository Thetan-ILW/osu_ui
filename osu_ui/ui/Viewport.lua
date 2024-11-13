local Container = require("osu_ui.ui.Container")

---@alias ViewportParams { nativeHeight: number }

---@class osu.ui.Viewport : osu.ui.Container
---@overload fun(params: ViewportParams): osu.ui.Viewport
---@field nativeTransform love.Transform
---@field nativeScreenHeight number
local Viewport = Container + {}

local gfx = love.graphics

function Viewport:load()
	self.nativeTransform = love.math.newTransform()
	self.nativeScreenHeight = self.nativeScreenHeight or 768
	self.automaticSizeCalc = false
	self.handleClicks = true
	local ww, wh = love.graphics.getDimensions()
	self.screenW = self.screenW or ww
	self.screenH = self.screenH or wh
	self:updateNativeTransform()
	Container.load(self)
	self:addTags({ "viewport" })
end

---@param w number
---@param h number
function Viewport:setSize(w, h)
	self.screenW, self.screenH = w, h
	self.hoverWidth, self.hoverHeight = w, h
end

---@param v number
function Viewport:setTextScale(v)
	self.textScale = v
end

function Viewport:getScale()
	return 1 / self.nativeScreenHeight * self.screenH
end

local screen_ratio_half =  -16 / 9 / 2

function Viewport:updateNativeTransform()
	local scale = self:getScale()
	local w, h = self.screenW, self.screenH
	self.nativeTransform = love.math.newTransform(0.5 * w + screen_ratio_half * h, 0, 0, scale, scale)

	local x, y = self.nativeTransform:inverseTransformPoint(0, 0)
	local xw, yh = self.nativeTransform:inverseTransformPoint(self.screenW, self.screenH)
	self.totalW, self.totalH = xw - x, yh - y
end

function Viewport:update(dt)
	self:updateNativeTransform()

	gfx.push()
	gfx.applyTransform(self.transform)
	self:setMouseFocus(true)

	gfx.applyTransform(self.nativeTransform)
	gfx.translate(love.graphics.inverseTransformPoint(self.transform:transformPoint(0, 0)))

	Container.update(self, dt, true)
	gfx.pop()
end

function Viewport:draw()
	gfx.push()
	gfx.applyTransform(self.transform)
	gfx.applyTransform(self.nativeTransform)
	gfx.translate(love.graphics.inverseTransformPoint(self.transform:transformPoint(0, 0)))

	Container.draw(self)
	gfx.pop()
end

return Viewport
