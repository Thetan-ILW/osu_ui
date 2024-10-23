local Container = require("osu_ui.ui.Container")

---@alias ScreenContainerParams { nativeHeight: number }

---@class osu.ui.ScreenContainer : osu.ui.Container
---@overload fun(params: ScreenContainerParams): osu.ui.ScreenContainer
---@field nativeTransform love.Transform
---@field nativeScreenHeight number
local ScreenContainer = Container + {}

local gfx = love.graphics

function ScreenContainer:load()
	self.nativeTransform = love.math.newTransform()
	self.nativeScreenHeight = self.nativeScreenHeight or 768
	self.automaticSizeCalc = false
	local ww, wh = love.graphics.getDimensions()
	self.screenW = self.screenW or ww
	self.screenH = self.screenH or wh
	self:updateNativeTransform()
	Container.load(self)
end

---@param w number
---@param h number
function ScreenContainer:setSize(w, h)
	self.screenW, self.screenH = w, h
	self.hoverWidth, self.hoverHeight = w, h
end

local screen_ratio_half =  -16 / 9 / 2

function ScreenContainer:updateNativeTransform()
	local w, h = self.screenW, self.screenH
	local scale = 1 / self.nativeScreenHeight * h
	self.nativeTransform = love.math.newTransform(0.5 * w + screen_ratio_half * h, 0, 0, scale, scale)

	local x, y = self.nativeTransform:inverseTransformPoint(0, 0)
	local xw, yh = self.nativeTransform:inverseTransformPoint(self.screenW, self.screenH)
	self.totalW, self.totalH = xw - x, yh - y
end

function ScreenContainer:update(dt)
	self:updateNativeTransform()

	gfx.push()
	gfx.applyTransform(self.transform)
	self:setMouseFocus(true)

	gfx.applyTransform(self.nativeTransform)
	gfx.translate(love.graphics.inverseTransformPoint(self.transform:transformPoint(0, 0)))

	Container.update(self, dt)
	gfx.pop()
end

function ScreenContainer:draw()
	gfx.push()
	gfx.applyTransform(self.transform)
	gfx.applyTransform(self.nativeTransform)
	gfx.translate(love.graphics.inverseTransformPoint(self.transform:transformPoint(0, 0)))

	Container.draw(self)
	gfx.pop()
end

return ScreenContainer
