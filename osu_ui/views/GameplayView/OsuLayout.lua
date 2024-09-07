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

    local x1, w1 = gfx_util.layout(_x, _w, { -0.5, -0.5 })
    local y1, h1 = gfx_util.layout(_y, _h, { 224, 176, 176, -1 })

    self:pack("continue", x1[2], y1[2], w1[2], h1[2])
    self:pack("retry", x1[2], y1[3], w1[2], h1[3])
    self:pack("back", x1[2], y1[4], w1[2], h1[4])

    local y2, h2 = gfx_util.layout(_y, _h, { -0.5, -0.5 })
    self:pack("overlay", x1[2], y2[2], w1[2], h2[2])
end

return _Layout
