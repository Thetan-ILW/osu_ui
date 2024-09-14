local math_util = require("math_util")
local Format = require("sphere.views.Format")

local ItemList = {}

ItemList.panelW = 500
ItemList.panelH = 90

ItemList.inactivePanel = { 0.89, 0.3, 0.59, 1 }
ItemList.InactiveChart = { 0, 0.6, 0.9, 1 }
ItemList.activePanel = { 1, 1, 1, 1 }

local hover_anim_speed = 3
local slide_anim_speed = 1.3
local slide_delta_limit = 8
local select_anim_speed = 3
local slide_power = 5

---@class osu.ui.ChartWindowListItem : osu.ui.WindowListItem
---@field title string
---@field secondRow string
---@field thirdRow string
---@field stars number
---@field mouseOver boolean
---@field hoverT number
---@field selectedT number
---@field colorT number
---@field slideX number
---@field isChart boolean
---@field chartIndex number?

function ItemList.resetChartWindow(set, item)
	set.x = 0
	set.y = 0

	set.mouseOver = false
	set.hoverT = 0
	set.colorT = 0
	set.selectedT = 0
	set.slideX = 55

	set.title = item.title or "Invalid title"

	if item.format == "sm" then
		set.secondRow = ("%s // %s"):format(item.artist, item.set_dir)
	else
		set.secondRow = ("%s // %s"):format(item.artist, item.creator)
	end

	set.thirdRow = ("%s (%s)"):format(item.name, Format.inputMode(item.inputmode))
	set.stars = item.osu_diff
	set.isChart = false
	set.chartIndex = -1
end

---@param list osu.ui.ChartListView
---@param item osu.ui.ChartWindowListItem
---@param dt number
function ItemList.applySetEffects(list, item, dt)
	local panel_h = ItemList.panelH

	local selected_visual_index = list.selectedVisualItemIndex
	local set_items_count = list:getSetItemsCount() - 1

	local smooth_scroll = list.smoothScroll
	local window_size = list.windowSize

	local unwrap = ItemList.getUnwrap(list.unwrapStartTime)

	local actual_visual_index = item.visualIndex
	if item.visualIndex > list.selectedVisualItemIndex then
		actual_visual_index = actual_visual_index + (set_items_count * unwrap)
	end

	local hover = ItemList.applyHover(item, dt)
	local slide = ItemList.applySlide(item, actual_visual_index, list.smoothScroll + list.windowSize / 2, dt)
	local selected = ItemList.applySelect(item, item.visualIndex == selected_visual_index, dt)

	local x = hover * 20 - slide * slide_power
	item.x = x + selected * 84

	local scroll = (actual_visual_index - (smooth_scroll + window_size / 2)) * panel_h
	scroll = scroll + panel_h * (window_size / (window_size / 4)) - panel_h / 3

	item.y = scroll
end

---@param list osu.ui.ChartListView
---@param item osu.ui.ChartWindowListItem
---@param dt number
function ItemList.applyChartEffects(list, item, dt)
	local panel_h = ItemList.panelH

	local smooth_scroll = list.smoothScroll
	local window_size = list.windowSize

	local unwrap = ItemList.getUnwrap(list.unwrapStartTime)
	local actual_visual_index = list.selectedVisualItemIndex + ((item.chartIndex - 1) * unwrap)

	local hover = ItemList.applyHover(item, dt)
	local slide = ItemList.applySlide(item, actual_visual_index, list.smoothScroll + list.windowSize / 2, dt)
	local selected = ItemList.applySelect(item, true, dt)

	item.colorT = math_util.clamp(
		item.colorT
			+ (
				item.chartIndex == list.game.selectModel.chartview_index and dt * select_anim_speed
				or -dt * select_anim_speed
			),
		0,
		1
	)

	local x = hover * 20 - slide * slide_power
	item.x = x + selected * 84

	local scroll = (actual_visual_index - (smooth_scroll + window_size / 2)) * panel_h
	scroll = scroll + panel_h * (window_size / (window_size / 4)) - panel_h / 3

	item.y = scroll
end

---@param item osu.ui.ChartWindowListItem
---@param dt number
---@return number
function ItemList.applyHover(item, dt)
	if item.mouseOver then
		item.hoverT = math.min(1, item.hoverT + dt * hover_anim_speed)
	else
		item.hoverT = math.max(0, item.hoverT - dt * hover_anim_speed)
	end

	return 1 - math.pow(1 - item.hoverT, 3)
end

---@param item osu.ui.ChartWindowListItem
---@param actual_visual_index number
---@param target_visual_index number
---@param dt number
---@return number
function ItemList.applySlide(item, actual_visual_index, target_visual_index, dt)
	local target_slide = math.abs(actual_visual_index - target_visual_index)

	if math.abs(target_slide) < slide_delta_limit then
		target_slide = (target_slide * target_slide)

		local distance = target_slide - item.slideX
		local step = distance * slide_anim_speed * dt
		local progress = math.min(math.abs(step) / math.abs(distance), 1)
		local slide_ease = 1 - (1 - progress) ^ 3
		item.slideX = item.slideX + distance * slide_ease
	end

	return item.slideX
end

---@param item osu.ui.ChartWindowListItem
---@param is_selected boolean
---@param dt number
---@return number
function ItemList.applySelect(item, is_selected, dt)
	local selected_t =
		math_util.clamp(item.selectedT + (is_selected and dt * select_anim_speed or -dt * select_anim_speed), 0, 1)

	item.selectedT = selected_t

	return 1 - math.pow(1 - math.min(1, selected_t), 3)
end

---@param start_time number
---@return number
function ItemList.getUnwrap(start_time)
	local unwrap = math.min(1, love.timer.getTime() - start_time)
	return 1 - math.pow(1 - math.min(1, unwrap), 4)
end

return ItemList
