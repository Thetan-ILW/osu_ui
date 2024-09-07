local gfx_util = require("gfx_util")

local Layout = require("sphere.views.Layout")

local _Layout = Layout()

_Layout.transform = { { 1 / 2, -16 / 9 / 2 }, 0, 0, { 0, 1 / 768 }, { 0, 1 / 768 }, 0, 0, 0, 0 }

function _Layout:draw()
	love.graphics.replaceTransform(gfx_util.transform(self.transform))

	local width, height = love.graphics.getDimensions()
	local _x, _y = love.graphics.inverseTransformPoint(0, 0)
	local _xw, _yh = love.graphics.inverseTransformPoint(width, height)

	local _w, _h = _xw - _x, _yh - _y

	self:pack("base", _x, _y, _w, _h)

	local y1, h1 = gfx_util.layout(_y, _h, { 96, 6, 500, 160 })

	local x0, w0 = gfx_util.layout(_x, _w, { -1, 30 })

	self:pack("title", _x, y1[1], _w, h1[1])
	self:pack("titleImage", x0[1], y1[1], w0[1], h1[1])
	self:pack("panel", _x, y1[3], _w, h1[3])

	local x1, w1 = gfx_util.layout(_x, _w, { 256, 311, -1 })

	self:pack("hitGraph", x1[2], y1[4], w1[2], h1[4])

	local x2, w2 = gfx_util.layout(_x, _w, { 1166, -1 })
	local y2, h2 = gfx_util.layout(_y, _h, { 321, 200, 573, -1 })
	self:pack("grade", x2[2], y2[2], w2[2], h2[2])
	self:pack("watch", x2[2], y2[3], w2[2], h2[3])

	local x3, w3 = gfx_util.layout(_x, _w, { 197, 309, -1 })
	local y3, h3 = gfx_util.layout(_y, _h, { 127, 46, -1 })

	self:pack("score", x3[2], y3[2], w3[2], h3[2])

	local x4, w4 = gfx_util.layout(_x, _w, { 130, 130, 57, 130, 130, -1 })
	local y4, h4 = gfx_util.layout(_y, _h, { 230, 45, 53, 45, 50, 45, 58, 51, -1 })

	self:pack("column1", x4[1], 0, w4[1], 0)
	self:pack("column2", x4[2], 0, w4[2], 0)
	self:pack("column3", x4[4], 0, w4[4], 0)
	self:pack("column4", x4[5], 0, w4[5], 0)
	self:pack("row1", 0, y4[2], 0, h4[2])
	self:pack("row2", 0, y4[4], 0, h4[4])
	self:pack("row3", 0, y4[6], 0, h4[6])

	local x5, w5 = gfx_util.layout(_x, _w, { 26, 130, 155, 130, -1 })
	self:pack("combo", x5[2], y4[8], w5[2], h4[8])
	self:pack("accuracy", x5[4], y4[8], w5[4], h4[8])

	local x6, w6 = gfx_util.layout(_x, _w, { 8, 283, -1 })
	local y5, h5 = gfx_util.layout(_y, _h, { 480, -1 })

	self:pack("comboText", x6[2], y5[2], w6[2], h5[2])
	self:pack("accuracyText", x6[3], y5[2], w6[3], y5[2])

	local x7, w7 = gfx_util.layout(_x, _w, { -1, 30 })
	local y7, h7 = gfx_util.layout(_y, _h, { 414, -1 })

	self:pack("mods", x7[1], y7[2], w7[1], h7[1])
end

return _Layout
