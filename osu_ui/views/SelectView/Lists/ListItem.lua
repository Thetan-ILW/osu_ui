local class = require("class")
local math_util = require("math_util")

---@class osu.ui.WindowListItem
---@field x number
---@field y number
---@field visualIndex number
---@field mouseOver boolean
---@field hoverT number
---@field selectedT number
---@field colorT number
---@field slideX number
local ListItem = class()

ListItem.panelW = 500
ListItem.panelH = 90

local function color(r, g, b, a)
	return { r / 255, g / 255, b / 255, a / 255 }
end

ListItem.inactivePanel = color(235, 73, 153, 240)
ListItem.InactiveChart = color(0, 150, 236, 240)
ListItem.activePanel = color(255, 255, 255, 220)

-- played 233, 104, 0, 240

local hover_anim_speed = 3
local slide_anim_speed = 1.3
local slide_delta_limit = 8
local select_anim_speed = 3
local slide_power = 5

function ListItem:replaceWith(item)
	self.x = 0
	self.y = 0
	self.mouseOver = false
	self.hoverT = 0
	self.colorT = 0
	self.selectedT = 0
	self.slideX = 55
	self.flashColorT = 0
end

---@param dt number
---@return number
function ListItem:applyHover(dt)
	if self.mouseOver then
		self.hoverT = math.min(1, self.hoverT + dt * hover_anim_speed)
	else
		self.hoverT = math.max(0, self.hoverT - dt * hover_anim_speed)
	end

	return 1 - math.pow(1 - self.hoverT, 3)
end

---@param actual_visual_index number
---@param target_visual_index number
---@param dt number
---@return number
function ListItem:applySlide(actual_visual_index, target_visual_index, dt)
	local target_slide = math.abs(actual_visual_index - target_visual_index)

	if math.abs(target_slide) < slide_delta_limit then
		target_slide = (target_slide * target_slide)

		local distance = target_slide - self.slideX
		local step = distance * slide_anim_speed * dt
		local progress = math.min(math.abs(step) / math.abs(distance), 1)
		local slide_ease = 1 - (1 - progress) ^ 3
		self.slideX = self.slideX + distance * slide_ease
	end

	return self.slideX * slide_power
end

---@param is_selected boolean
---@param dt number
---@return number
function ListItem:applySelect(is_selected, dt)
	local selected_t =
		math_util.clamp(self.selectedT + (is_selected and dt * select_anim_speed or -dt * select_anim_speed), 0, 1)

	self.selectedT = selected_t

	return 1 - math.pow(1 - math.min(1, selected_t), 3)
end

---@param increase boolean
function ListItem:applyColor(increase, dt)
	self.colorT = math_util.clamp(self.colorT + (increase and dt * select_anim_speed or -dt * select_anim_speed), 0, 1)
end

function ListItem:applyFlash(dt)
	self.flashColorT = math.max(0, self.flashColorT - dt)
end

---@param start_time number
---@return number
function ListItem.getUnwrap(start_time)
	local unwrap = math.min(1, love.timer.getTime() - start_time)
	return 1 - math.pow(1 - math.min(1, unwrap), 4)
end

function ListItem.mixColors(a, b, t)
	return {
		a[1] * (1 - t) + b[1] * t,
		a[2] * (1 - t) + b[2] * t,
		a[3] * (1 - t) + b[3] * t,
		a[4],
	}
end

function ListItem.lighten(c, amount)
	return {
		math.min(1, c[1] * (1 + amount)),
		math.min(1, c[2] * (1 + amount)),
		math.min(1, c[3] * (1 + amount)),
		c[4],
	}
end

function ListItem.lighten2(c, amount)
	amount = amount * 0.5
	return {
		math.min(1, c[1] * (1 + 0.5 * amount) + 1 * amount),
		math.min(1, c[2] * (1 + 0.5 * amount) + 1 * amount),
		math.min(1, c[3] * (1 + 0.5 * amount) + 1 * amount),
		c[4],
	}
end

return ListItem
