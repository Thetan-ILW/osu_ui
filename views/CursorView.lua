local class = require("class")

---@class osu.ui.CursorView
---@operator call: osu.ui.CursorView
---@field alpha number
local CursorView = class()

---@type table<string,love.Image>
local img
---@type table<string, number | string | boolean>
local skin_params

function CursorView:new()
	self.alpha = 1
end

---@param assets osu.ui.OsuAssets
function CursorView:load(assets)
	img = assets.images
	skin_params = assets.params
end

local cursor_scale = 1
local cursor_rotation = 0

function CursorView:update(dt)
	if skin_params.cursorRotate then
		cursor_rotation = (cursor_rotation + 1.5 * dt) % (math.pi * 2)
	end

	if skin_params.cursorExpand then
		local add = love.mouse.isDown(1) and dt or -dt
		cursor_scale = math.min(cursor_scale + add * 3, 1.2)
		cursor_scale = math.max(cursor_scale, 1)
	end
end

local gfx = love.graphics

function CursorView:draw()
	if self.alpha == 0 then
		return
	end

	gfx.origin()
	gfx.setColor(1, 1, 1, self.alpha)

	local x, y = love.mouse.getPosition()

	local cursor = img.cursor
	local middle = img.cursorMiddle
	local cw, ch = cursor:getDimensions()
	local mw, mh = middle:getDimensions()

	local cxo, cyo = cw / 2, ch / 2
	local mxo, myo = mw / 2, mh / 2

	local cx, cy = 0, 0

	if skin_params.cursorCenter == 0 then
		cx, cy = cxo, cyo
		mxo, myo = 0, 0
	end

	gfx.draw(middle, x, y, 0, 1, 1, mxo, myo)
	gfx.draw(cursor, cx + x, cy + y, cursor_rotation, cursor_scale, cursor_scale, cxo, cyo)
end

return CursorView
