local gfx_util = require("gfx_util")
local just = require("just")
local math_util = require("math_util")
local ScrollBar = require("aqua.imgui.ScrollBar")

local ui = {}

local shadow = { 0, 0, 0, 0.7 }

ui.inputMode = "keyboard"
ui.getCanvas = gfx_util.getCanvas
ui.button = just.button
ui.isOver = just.is_over
ui.wheelOver = just.wheel_over
ui.mousePressed = just.mousepressed
ui.keyPressed = just.keypressed
ui.next = just.next
ui.sameline = just.sameline
ui.focus = just.focus
ui.textInput = just.textinput
ui.row = just.row
ui.resetJust = just.reset

local text_transform = love.math.newTransform()
local text_scale = 1

function ui.setTextScale(scale)
	text_transform = love.math.newTransform(0, 0, 0, scale, scale, 0, 0, 0, 0)
	text_scale = scale
end

---@return number
function ui.getTextScale()
	return text_scale
end

function ui.text(text, w, ax)
	love.graphics.push()
	love.graphics.applyTransform(text_transform)
	gfx_util.printFrame(text, 0, 0, (w or math.huge) / text_scale, math.huge, ax or "left", "top")
	love.graphics.pop()

	local font = love.graphics.getFont()
	just.next(w, font:getHeight() * text_scale)
end

function ui.frame(text, x, y, w, h, ax, ay)
	w = w or math.huge
	h = h or math.huge
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.applyTransform(text_transform)
	gfx_util.printFrame(text, 0, 0, w / text_scale, h / text_scale, ax, ay)
	love.graphics.pop()
end

---@param img love.Text
---@param x number
---@param y number
---@param w number
---@param h number
---@param ax? "left" | "center" | "right"
---@param ay? "top" | "center" | "bottom"
function ui.textFrame(img, x, y, w, h, ax, ay)
	w = w or math.huge
	h = h or math.huge
	love.graphics.push()
	love.graphics.translate(x, y)

	x = 0
	y = 0

	local iw, ih = img:getDimensions()
	iw, ih = iw * text_scale, ih * text_scale

	if ax == "center" then
		x = w / 2 - iw / 2
	elseif ax == "right" then
		x = w - iw
	end

	if ay == "center" then
		y = h / 2 - ih / 2
	elseif ay == "right" then
		y = h - ih
	end

	love.graphics.translate(x, y)
	love.graphics.draw(img, 0, 0, 0, text_scale, text_scale)
	love.graphics.pop()
end

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

	gfx.setColor({ r, g, b, a })
	ui.frame(text, x, y, w, h, ax, ay)
end

---@param img love.Text
---@param x number
---@param y number
---@param w number
---@param h number
---@param ax? "left" | "center" | "right"
---@param ay? "top" | "center" | "bottom"
function ui.textFrameShadow(img, x, y, w, h, ax, ay)
	local r, g, b, a = gfx.getColor()

	gfx.push()
	gfx.setColor(shadow)
	ui.textFrame(img, x, y + 2, w, h, ax, ay)
	gfx.pop()

	gfx.setColor({ r, g, b, a })
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
	local prev_time = sound_play_time[sound] or 0
	local current_time = love.timer.getTime()

	if current_time > prev_time + 0.05 then
		sound:stop()
		sound_play_time[sound] = current_time
	end

	sound:play()
end

---@param list osu.ui.ListView
---@param w number
---@param h number
function ui.scrollBar(list, w, h)
	local count = #list.items - 1

	love.graphics.translate(w - 16, 0)

	local pos = (list.visualItemIndex - 1) / count
	local newScroll = ScrollBar("ncs_sb", pos, 16, h, count / list.rows)
	if newScroll then
		list:scroll(math.floor(count * newScroll + 1) - list.itemIndex)
	end
end

---@param time number
---@param interval number
---@return number
function ui.easeOutCubic(time, interval)
	local t = math.min(love.timer.getTime() - time, interval)
	local progress = t / interval
	return math_util.clamp(1 - math.pow(1 - progress, 3), 0, 1)
end

return ui
