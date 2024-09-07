local gfx_util = require("gfx_util")

local Layout = require("sphere.views.Layout")

local _Layout = Layout()

_Layout.transform = { { 1 / 2, -16 / 9 / 2 }, 0, 0, { 0, 1 / 768 }, { 0, 1 / 768 }, 0, 0, 0, 0 }

function _Layout:draw()
	local width, height = love.graphics.getDimensions()

	love.graphics.replaceTransform(gfx_util.transform(self.transform))

	local _x, _y = love.graphics.inverseTransformPoint(0, 0)
	local _xw, _yh = love.graphics.inverseTransformPoint(width, height)

	local _w, _h = _xw - _x, _yh - _y

	local gx, gw = gfx_util.layout(_x, _xw, { 20, "*", 20 })

	self:pack("background", _x, _y, _w, _h)

	local y1, h1 = gfx_util.layout(_y, _h, { 74, -1, 74 })
	self:pack("title", gx[2], y1[1], gw[2], h1[1])
end

return _Layout
