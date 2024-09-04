local class = require("class")
local flux = require("flux")
local ui = require("osu_ui.ui")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.PopupView
---@operator call: osu.ui.PopupView
---@field fonts table<string, love.Font>
---@field messages {text: string, fadeOutTween: table, fadeOutAnimation: number, x: number, y: number, xTween: table?, yTween: table?, onClick: function?, remove: boolean}[]
local PopupView = class()

function PopupView:new()
	self.messages = {}
end

---@param assets osu.ui.OsuAssets
function PopupView:load(assets)
	self.fonts = assets.localization.fontGroups.misc
end

local colors = {
	error = { 0.76, 0.05, 0.05, 1 },
	purple = { 0.51, 0.31, 0.8, 1 },
}

local width = 234

---@param text string
---@param color "error" | "purple"
---@param on_click any
function PopupView:add(text, color, on_click)
	local font = self.fonts.popup
	local _, wrapped_text = font:getWrap(text, (width - 8) / ui.getTextScale())
	local h = font:getHeight() * font:getLineHeight() * #wrapped_text

	local t = {
		text = text,
		color = colors[color],
		onClick = on_click,
		creationTime = love.timer.getTime(),
		fadeOutAnimation = 0,
		x = 0,
		y = 0,
		h = math.max(80, h + 8),
		remove = false,
	}

	t.xTween = flux.to(t, 1, { x = 1 }):ease("elasticout")
	t.fadeOutTween = flux.to(t, 1, { fadeOutAnimation = 1 }):delay(3):oncomplete(function()
		t.remove = true
	end)

	local current_h = 0

	table.insert(self.messages, t)
	local count = #self.messages

	for i = count, 1, -1 do
		local msg = self.messages[i]
		if msg.yTween then
			msg.yTween:stop()
		end
		msg.yTween = flux.to(msg, 0.5, { y = msg.h + current_h }):ease("quadout")
		current_h = current_h + msg.h
	end
end

local function force_hide(msg)
	msg.fadeOutTween:stop()
	msg.fadeOutTween = flux.to(msg, 0.3, { fadeOutAnimation = 1 }):ease("quadout"):oncomplete(function()
		msg.remove = true
	end)
end

local gfx = love.graphics
local indexes_to_remove = {}

function PopupView:draw()
	gfx.push()
	Layout:draw()
	local w, h = Layout:move("base")
	local count = #self.messages

	gfx.setFont(self.fonts.popup)
	gfx.translate(0, h - 50)

	for i = count, 1, -1 do
		local msg = self.messages[i]
		local x = w - (msg.x * (width + 5))
		local y = -msg.y - (10 * (count - i + 1))
		local mh = msg.h

		local a = 1 - msg.fadeOutAnimation

		gfx.setColor(0, 0, 0, math.min(0.8, a))
		gfx.rectangle("fill", x, y, width, mh, 8, 8)

		local color = msg.color
		color[4] = a
		gfx.setColor(color)
		gfx.setLineWidth(1)
		gfx.rectangle("line", x, y, width, mh, 8, 8)

		gfx.setColor(1, 1, 1, a)
		ui.frame(msg.text, x + 4, y + 8, width - 8, msg.h, "left", "top")

		local mouse_over = ui.isOver(width, mh, x, y)

		if mouse_over and ui.mousePressed(1) then
			if msg.onClick then
				msg.onClick()
			end

			force_hide(msg)
		end

		if mouse_over and ui.mousePressed(2) then
			force_hide(msg)
		end

		if msg.remove then
			table.insert(indexes_to_remove, i)
		end
	end
	gfx.pop()

	if #indexes_to_remove == 0 then
		return
	end

	for _, v in ipairs(indexes_to_remove) do
		table.remove(self.messages, v)
	end

	indexes_to_remove = {}
end

return PopupView
