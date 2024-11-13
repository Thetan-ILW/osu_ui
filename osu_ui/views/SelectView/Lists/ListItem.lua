local UiElement = require("osu_ui.ui.UiElement")
local math_util = require("math_util")

---@alias ListItemParams { background: love.Image, titleFont: love.Font, infoFont: love.Font }

---@class osu.ui.WindowListItem : osu.ui.UiElement
---@overload fun(params: ListItemParams): osu.ui.WindowListView
---@field parent osu.ui.WindowListView
---@field x number
---@field y number
---@field visualIndex number
---@field mouseOver boolean
---@field hoverT number
---@field selectedT number
---@field colorT number
---@field slideX number
---@field background love.Image
---@field titleFont love.Font
---@field infoFont love.Font
---@field title string
---@field secondRow string
---@field thirdRow string
---@field color number[]
---@field list osu.ui.WindowListView
local ListItem = UiElement + {}

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
local hover_distance = 20

function ListItem:load()
	self.x = 0
	self.y = 0
	self.mouseOver = false
	self.hoverT = 0
	self.colorT = 0
	self.selectedT = 0
	self.slideX = 55
	self.flashColorT = 0
	self.title = ""
	self.secondRow = ""
	self.thirdRow = ""
	self.totalW = 640
	self.totalH = 90
	self.color = { self.inactivePanel[1], self.inactivePanel[2], self.inactivePanel[3], 1 }
	UiElement.load(self)
end

function ListItem:bindEvents()
	self.parent:bindEvent(self, "mouseClick")
end

function ListItem:mouseClick(event)
	if not self.mouseOver or event.key ~= 1 then
		return false
	end
	self.parent:select(self)
	return true
end

function ListItem:replaceWith(item)
	self.hoverT = 0
	self.colorT = 0
	self.selectedT = 0
	self.slideX = 55
	self.flashColorT = 0
end

function ListItem:isVisible()
	local sp = self.list.parent.scrollPosition - self.list.y
	return sp > self.y - 400 and sp < self.y + 500
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
		math_util.clamp(self.selectedT + (is_selected and dt * select_anim_speed * 3 or -dt * select_anim_speed), 0, 1)

	self.selectedT = selected_t

	return math.pow(1 - math.min(1, selected_t), 3)
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

function ListItem:update(dt)
	local vi = self.visualIndex
	local wrap_p = 0

	if self.list.parentList then
		wrap_p = self.list.parentList.wrapProgress
		vi = vi * wrap_p
		dt = dt / wrap_p
		self.alpha = wrap_p
	end

	self.y = (vi - 1) * (self.totalH * wrap_p) - ((1 - wrap_p) * self.totalH)
	if vi > self.list:getSelectedItemIndex() then
		self.y = self.y + self.list.holeSize
	end

	local hover = self:applyHover(dt)
	local slide = self:applySlide(vi, self.list:getVisualIndex() + self.list.windowSize / 2, dt)
	local selected = self:applySelect(self.visualIndex == self.list:getSelectedItemIndex(), dt)
	self:applyColor(false, dt)
	self:applyFlash(dt)

	local x = -hover * hover_distance + hover_distance + slide
	self.x = x + selected * 80

	self:applyTransform()
end

function ListItem:justHovered()
	self.flashColorT = 1
end

function ListItem:draw()
	love.graphics.draw(self.background, 0, self.totalH / 2, 0, 1, 1, 0, self.background:getHeight() / 2)
	love.graphics.setColor(1, 1, 1, self.alpha)
	love.graphics.print(self.id, 20, 20)
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
