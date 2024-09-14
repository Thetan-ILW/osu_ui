local WindowListView = require("osu_ui.views.WindowListView")
local math_util = require("math_util")
local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")

local Format = require("sphere.views.Format")

---@class osu.ui.ChartListView : osu.ui.WindowListView
---@operator call: osu.ui.ChartListView
local ChartSetListView = WindowListView + {}

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ChartSetListView:new(game, assets)
	self.game = game
	self.assets = assets

	self.unwrapStartTime = 0
	self.nextAutoScrollTime = 0
	self.previousSelectedVisualIndex = 0

	self.font = self.assets.localization.fontGroups.chartSetList

	local img = self.assets.images
	self.panelImage = img.listButtonBackground
	self.maniaIcon = img.maniaSmallIconForCharts
	self.starImage = img.star
	self:reloadItems()
	self:updateSetItems()

	self.unwrapStartTime = 0

	for i, set in ipairs(self.setItems) do
		self:applyEffects(set, 0, 0, 9999)
	end
end

function ChartSetListView:getSelectedItemIndex()
	return self.game.selectModel.chartview_set_index
end

function ChartSetListView:getItems()
	return self.game.selectModel.noteChartSetLibrary.items
end

function ChartSetListView:getStateNumber()
	return self.game.selectModel.noteChartSetStateCounter
end

function ChartSetListView:selectItem(visual_index)
	self.previousSelectedVisualIndex = self.selectedVisualItemIndex
	self.game.selectModel:scrollNoteChartSet(nil, visual_index)
	self.game.selectModel:scrollNoteChart(nil, 1)
end

function ChartSetListView:getSetItemsCount()
	return self.selectedSetItemsCount or 1
end

function ChartSetListView:reloadItems()
	WindowListView.reloadItems(self)
	self:iterOverWindow(self.applyEffects, 9999)
end

local inactive_panel = { 0.89, 0.3, 0.59 }
local inactive_chart = { 0, 0.6, 0.9 }
local active_panel = { 1, 1, 1 }

function ChartSetListView:resetWindowSet(set, item)
	set.x = 0
	set.y = 0
	set.mouseOver = false
	set.hoverT = 0
	set.selectedT = 0
	set.slideX = 55
	set.color = inactive_panel
	set.colorT = 0

	set.title = item.title or "Invalid title"

	if item.format == "sm" then
		set.secondRow = ("%s // %s"):format(item.artist, item.set_dir)
	else
		set.secondRow = ("%s // %s"):format(item.artist, item.creator)
	end

	set.thirdRow = ("%s (%s)"):format(item.name, Format.inputMode(item.inputmode))
	set.stars = item.osu_diff
end

function ChartSetListView:updateSet(window_index, visual_index)
	local item = self.items[visual_index]

	local set = self.window[window_index]
	self:resetWindowSet(set, item)
	set.visualIndex = visual_index
	set.setId = item.id
end

function ChartSetListView:updateSetItems()
	local items = self.game.selectModel.noteChartLibrary.items
	self.selectedSetItemsCount = #items

	self.setItems = {}

	local selected_visual_item_index = self:getSelectedItemIndex()

	local parent_set

	for _, set in ipairs(self.window) do
		if set.visualIndex == selected_visual_item_index then
			parent_set = set
		end
	end

	for i, chart in ipairs(items) do
		local set = {}
		self:resetWindowSet(set, chart)
		set.visualIndex = selected_visual_item_index + i - 1
		set.id = i
		set.isChart = true

		-- Parent set might be out of screen
		if parent_set then
			set.slideX = parent_set.slideX
			set.selectedT = parent_set.selectedT
			set.hoverT = parent_set.hoverT
		end

		table.insert(self.setItems, set)
	end

	self.unwrapStartTime = love.timer.getTime()
end

function ChartSetListView:processActions()
	local ca = actions.consumeAction
	local ad = actions.isActionDown
	local gc = actions.getCount

	if ad("up") then
		self:autoScroll(-1 * gc(), ca("up"))
	elseif ad("down") then
		self:autoScroll(1 * gc(), ca("down"))
	elseif ca("left") then
		self.game.selectModel:scrollNoteChart(-1)
		self:followSelection(self.selectedVisualItemIndex + self.game.selectModel.chartview_index - 1)
	elseif ca("right") then
		self.game.selectModel:scrollNoteChart(1)
		self:followSelection(self.selectedVisualItemIndex + self.game.selectModel.chartview_index - 1)
	elseif ad("up10") then
		self:autoScroll(-10 * gc(), ca("up10"))
	elseif ad("down10") then
		self:autoScroll(10 * gc(), ca("down10"))
	elseif ca("toStart") then
		self:keyScroll(-math.huge)
	elseif ca("toEnd") then
		self:keyScroll(math.huge)
	end
end

local panel_w = 500
local panel_h = 90

local hover_anim_speed = 3
local select_anim_speed = 3
local slide_anim_speed = 1.3
local slide_power = 5

function ChartSetListView:applyEffects(set, on_screen_index, window_index, dt)
	local set_items_count = self:getSetItemsCount() - 1

	local unwrap = math.min(1, love.timer.getTime() - self.unwrapStartTime)
	unwrap = 1 - math.pow(1 - math.min(1, unwrap), 4)

	local visual_index = set.visualIndex
	if not set.isChart and set.visualIndex > self.selectedVisualItemIndex then
		visual_index = visual_index + (set_items_count * unwrap)
	end

	---- HOVER
	if set.mouseOver then
		set.hoverT = math.min(1, set.hoverT + dt * hover_anim_speed)
	else
		set.hoverT = math.max(0, set.hoverT - dt * hover_anim_speed)
	end

	local hover = 1 - math.pow(1 - set.hoverT, 3)

	---- SELECTED

	local selected_t = 0
	if set.isChart then
		selected_t = math_util.clamp(set.selectedT + (dt * select_anim_speed), 0, 1)

		set.colorT = math_util.clamp(
			set.colorT
				+ (
					set.id == self.game.selectModel.chartview_index and dt * select_anim_speed
					or -dt * select_anim_speed
				),
			0,
			1
		)
	else
		selected_t = math_util.clamp(
			set.selectedT
				+ (visual_index == self.selectedVisualItemIndex and dt * select_anim_speed or -dt * select_anim_speed),
			0,
			1
		)
	end

	set.selectedT = selected_t

	local selected = 1 - math.pow(1 - math.min(1, selected_t), 3)

	---- SLIDE
	local target_slide = math.abs(visual_index - (self.smoothScroll + self.windowSize / 2))

	if math.abs(target_slide) < self.windowSize / 2 then
		target_slide = (target_slide * target_slide)

		local distance = target_slide - set.slideX
		local step = distance * slide_anim_speed * dt
		local progress = math.min(math.abs(step) / math.abs(distance), 1)
		local slide_ease = 1 - (1 - progress) ^ 3
		set.slideX = set.slideX + distance * slide_ease
	end

	-- X
	local x = hover * 20 - set.slideX * slide_power
	set.x = x + selected * 84

	-- Y
	local scroll = 0

	if set.isChart then
		scroll = ((self.selectedVisualItemIndex + ((set.id - 1) * unwrap)) - (self.smoothScroll + self.windowSize / 2))
			* panel_h
	else
		scroll = (visual_index - (self.smoothScroll + self.windowSize / 2)) * panel_h
	end

	scroll = scroll + panel_h * (self.windowSize / (self.windowSize / 4)) - panel_h / 3

	set.y = scroll
end

function ChartSetListView:mouseScroll(y)
	if self.windowSize == 0 then
		return
	end
	self.scroll = self.scroll + y
	self:animateScroll()
end

function ChartSetListView:update(dt)
	WindowListView.update(self, dt)
	self:iterOverWindow(self.applyEffects, dt)

	for i, set in ipairs(self.setItems) do
		self:applyEffects(set, 0, 0, dt)
	end

	self.mouseOverIndex = -1
end

function ChartSetListView:mouseClick(set)
	local prev_selected_items_count = self:getSetItemsCount()

	if set.isChart then
		self.game.selectModel:scrollNoteChart(0, set.id)
	else
		self:selectItem(set.visualIndex)

		local visual_index = self:getSelectedItemIndex()

		if visual_index > self.previousSelectedVisualIndex then
			self.smoothScroll = self.smoothScroll - (prev_selected_items_count - 1)
		end
	end

	self.scroll = set.visualIndex - self.windowSize / 2
	self:animateScroll()
end

local gfx = love.graphics

function ChartSetListView:drawPanels(set, on_screen_index, window_index, w, h)
	if not set.isChart and set.visualIndex == self.selectedVisualItemIndex then
		for _, item in ipairs(self.setItems) do
			self:drawPanels(item, 0, 0, w, h)
		end
		return
	end

	local x, y = w - set.x - 540, set.y

	gfx.push()
	gfx.translate(x, y)

	set.mouseOver = ui.isOver(panel_w, panel_h)
	if set.mouseOver then
		if ui.mousePressed(1) then
			self:mouseClick(set)
		end
		self.mouseOverIndex = set.visualIndex
	end

	local main_color = inactive_panel

	local ct = set.isChart and set.colorT or set.selectedT

	if set.isChart then
		main_color = {
			inactive_chart[1] * (1 - ct) + main_color[1] * ct,
			inactive_chart[2] * (1 - ct) + main_color[2] * ct,
			inactive_chart[3] * (1 - ct) + main_color[3] * ct,
		}
	end

	local color_mix = {
		main_color[1] * (1 - ct) + active_panel[1] * ct,
		main_color[2] * (1 - ct) + active_panel[2] * ct,
		main_color[3] * (1 - ct) + active_panel[3] * ct,
	}

	local inactive_text = self.assets.params.songSelectInactiveText
	local active_text = self.assets.params.songSelectActiveText
	local color_text_mix = {
		inactive_text[1] * (1 - ct) + active_text[1] * ct,
		inactive_text[2] * (1 - ct) + active_text[2] * ct,
		inactive_text[3] * (1 - ct) + active_text[3] * ct,
	}

	gfx.setColor(color_mix)
	gfx.draw(self.panelImage, 0, 52, 0, 1, 1, 0, self.panelImage:getHeight() / 2)

	gfx.setColor(color_text_mix)
	gfx.translate(20, 12)
	gfx.draw(self.maniaIcon)

	gfx.translate(40, -4)
	gfx.setFont(self.font.title)
	ui.text(set.title)

	gfx.setFont(self.font.secondRow)
	gfx.translate(0, -2)
	ui.text(set.secondRow)
	gfx.translate(0, -2)
	gfx.setFont(self.font.thirdRow)
	ui.text(set.thirdRow)
	gfx.pop()

	gfx.push()
	local iw, ih = self.starImage:getDimensions()

	gfx.translate(60 + x, y + panel_h + 6)
	gfx.scale(0.6)

	for si = 1, 10, 1 do
		if si >= (set.stars or 0) then
			gfx.setColor(1, 1, 1, 0.3)
		end

		gfx.draw(self.starImage, 0, 0, 0, 1, 1, 0, ih)
		gfx.translate(iw, 0)
		gfx.setColor(color_text_mix)
	end

	gfx.pop()
end

function ChartSetListView:draw(w, h)
	if self.windowSize == 0 then
		return
	end

	self:iterOverWindow(self.drawPanels, w, h)
end

return ChartSetListView
