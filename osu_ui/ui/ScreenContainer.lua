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

	local ww, wh = love.graphics.getDimensions()
	self.totalW = self.totalW or ww
	self.totalH = self.totalH or wh
	Container.load(self)
end

---@param w number
---@param h number
function ScreenContainer:setSize(w, h)
	self.totalW, self.totalH = w, h
end

local screen_ratio_half =  -16 / 9 / 2

function ScreenContainer:updateNativeTransform()
	local w, h = self.totalW, self.totalH
	local scale = 1 / self.nativeScreenHeight * h
	self.nativeTransform = love.math.newTransform(0.5 * w + screen_ratio_half * h, 0, 0, scale, scale)
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
	--Container.debugDraw(self)
	gfx.applyTransform(self.nativeTransform)
	gfx.translate(love.graphics.inverseTransformPoint(self.transform:transformPoint(0, 0)))

	Container.draw(self)
	gfx.pop()
end

return ScreenContainer
