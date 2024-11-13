local gfx_util = require("gfx_util")
local just = require("just")
local math_util = require("math_util")

local ui = {}

local shadow = { 0.078, 0.078, 0.078, 0.64 }

ui.inputMode = "keyboard"
ui.getCanvas = gfx_util.getCanvas
ui.isOver = just.is_over

local gfx = love.graphics

---@param text string
---@param x number
---@param y number
---@param w number
---@param h number
---@param ax "left" | "center" | "right"
---@param ay "top" | "center" | "bottom"
function ui.frameWithShadow(text, x, y, w, h, ax, ay)
	local r, g, b, a = gfx.getColor()

	gfx.push()
	gfx.setColor(shadow)
	ui.frame(text, x, y + 2, w, h, ax, ay)
	gfx.pop()

	gfx.setColor(r, g, b, a)
	ui.frame(text, x, y, w, h, ax, ay)
end

local shadow_offset = 0.6

---@param img love.Text
---@param x number
---@param y number
---@param w number
---@param h number
---@param ax? "left" | "center" | "right"
---@param ay? "top" | "center" | "bottom"
function ui.textFrameShadow(img, x, y, w, h, ax, ay)
	local r, g, b, a = gfx.getColor()
	local shadow_color = shadow
	shadow_color[4] = a

	gfx.push()
	gfx.setColor(shadow_color)
	ui.textFrame(img, x + shadow_offset, y + shadow_offset, w, h, ax, ay)
	ui.textFrame(img, x - shadow_offset, y - shadow_offset, w, h, ax, ay)
	ui.textFrame(img, x + shadow_offset, y - shadow_offset, w, h, ax, ay)
	ui.textFrame(img, x - shadow_offset, y + shadow_offset, w, h, ax, ay)
	gfx.pop()


	gfx.setColor(r, g, b, a)
	ui.textFrame(img, x, y, w, h, ax, ay)
end

---@param text string
---@param x number?
---@param ax string?
function ui.textWithShadow(text, x, ax)
	local r, g, b, a = gfx.getColor()

	gfx.push()
	gfx.setColor(shadow)
	gfx.translate(0, 2)
	ui.text(text, x, ax)
	gfx.pop()

	gfx.setColor({ r, g, b, a })
	ui.text(text, x, ax)
end

local sound_play_time = {}

---@param sound audio.Source
function ui.playSound(sound)
	if not sound then
		return
	end

	local prev_time = sound_play_time[sound] or 0
	local current_time = love.timer.getTime()

	if current_time > prev_time + 0.05 then
		sound:stop()
		sound_play_time[sound] = current_time
	end

	sound:play()
end

function ui.lighten(c, amount)
	return {
		math.min(1, c[1] * (1 + amount)),
		math.min(1, c[2] * (1 + amount)),
		math.min(1, c[3] * (1 + amount)),
		c[4],
	}
end

return ui
