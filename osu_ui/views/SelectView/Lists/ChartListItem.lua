local ListItem = require("osu_ui.views.SelectView.Lists.ListItem")

local ui = require("osu_ui.ui")
local math_util = require("math_util")
local Format = require("sphere.views.Format")
local getModifierString = require("osu_ui.views.modifier_string")

---@class osu.ui.WindowListChartItem : osu.ui.WindowListItem
---@operator call: osu.ui.WindowListChartItem
---@field title string
---@field secondRow string
---@field thirdRow string
---@field stars number
---@field isChart boolean
---@field chartIndex number?
local ChartItem = ListItem + {}

function ChartItem:new(chart)
	if chart then
		self:replaceWith(chart)
	end
end

---@param chart table
function ChartItem:replaceWith(chart)
	ListItem.replaceWith(self)

	self.title = chart.title or "Invalid title"

	if chart.format == "sm" then
		self.secondRow = ("%s // %s"):format(chart.artist, chart.set_dir)
	else
		self.secondRow = ("%s // %s"):format(chart.artist, chart.creator)
	end

	local rate = chart.rate or 1
	local mods = getModifierString(chart.modifiers or {})

	if rate ~= 1 then
		self.thirdRow = ("%s %gx (%s)"):format(chart.name, rate, Format.inputMode(chart.inputmode))
	elseif mods ~= "" then
		self.thirdRow = ("%s (%s)%s"):format(chart.name, Format.inputMode(chart.inputmode), mods)
	elseif rate ~= 1 and mods ~= "" then
		self.thirdRow = ("%s %gx (%s)%s"):format(chart.name, rate, Format.inputMode(chart.inputmode), mods)
	else
		self.thirdRow = ("%s (%s)"):format(chart.name, Format.inputMode(chart.inputmode))
	end

	self.stars = math.min(chart.osu_diff or 0, 10)
	self.isChart = false
	self.chartIndex = -1
end

---@param list osu.ui.ChartListView
---@param dt number
function ChartItem:applySetEffects(list, dt)
	local panel_h = ListItem.panelH

	local selected_visual_index = list.selectedVisualItemIndex
	local set_items_count = list:getChildItemsCount() - 1

	local smooth_scroll = list.smoothScroll
	local window_size = list.windowSize

	local unwrap = ListItem.getUnwrap(list.unwrapStartTime)

	local actual_visual_index = self.visualIndex
	if self.visualIndex > list.selectedVisualItemIndex then
		actual_visual_index = actual_visual_index + (set_items_count * unwrap)
	end

	local hover = self:applyHover(dt)
	local slide = self:applySlide(actual_visual_index, list.smoothScroll + list.windowSize / 2, dt)
	local selected = self:applySelect(self.visualIndex == selected_visual_index, dt)
	self:applyFlash(dt)

	local x = hover * 20 - slide
	self.x = x + selected * 84

	local scroll = (actual_visual_index - (smooth_scroll + window_size / 2)) * panel_h
	scroll = scroll + panel_h * (window_size / (window_size / 4)) - panel_h / 3

	self.y = scroll
end

---@param list osu.ui.ChartListView
---@param dt number
function ChartItem:applyChartEffects(list, dt)
	local panel_h = ListItem.panelH

	local smooth_scroll = list.smoothScroll
	local window_size = list.windowSize

	local unwrap = ListItem.getUnwrap(list.unwrapStartTime)
	local actual_visual_index = list.selectedVisualItemIndex + ((self.chartIndex - 1) * unwrap)

	local hover = self:applyHover(dt)
	local slide = self:applySlide(actual_visual_index, list.smoothScroll + list.windowSize / 2, dt)
	local selected = self:applySelect(true, dt)
	self:applyColor(self.chartIndex == list.game.selectModel.chartview_index, dt)
	self:applyFlash(dt)

	local x = hover * 20 - slide
	self.x = x + selected * 84

	local scroll = (actual_visual_index - (smooth_scroll + window_size / 2)) * panel_h
	scroll = scroll + panel_h * (window_size / (window_size / 4)) - panel_h / 3

	self.y = scroll
end

local gfx = love.graphics

function ChartItem:drawChartPanel(list, panel_color, text_color)
	gfx.push()
	gfx.setColor(panel_color)
	gfx.draw(list.panelImage, 0, 52, 0, 1, 1, 0, list.panelImage:getHeight() / 2)

	local preview_icon_w = list.previewIcon and 115 or 0
	gfx.setColor(text_color)
	gfx.translate(20 + preview_icon_w, 12)
	gfx.draw(list.maniaIcon)

	gfx.translate(40, -4)
	gfx.setFont(list.font.title)
	ui.text(self.title)

	gfx.setFont(list.font.secondRow)
	gfx.translate(0, -2)
	ui.text(self.secondRow)
	gfx.translate(0, -2)
	gfx.setFont(list.font.thirdRow)
	ui.text(self.thirdRow)
	gfx.pop()

	local star = list.starImage
	local iw, ih = star:getDimensions()

	gfx.translate(80 + preview_icon_w, ListItem.panelH - 10)

	for si = 0, 10, 1 do
		if si >= self.stars then
			return
		end

		local scale = math_util.clamp(self.stars - si, 0.3, 1) * 0.6

		gfx.draw(star, 0, 0, 0, scale, scale, iw / 2, ih / 2)
		gfx.translate(iw * 0.6, 0)
		gfx.setColor(text_color)
	end
end

---@param list osu.ui.ChartSetListView | osu.ui.ChartListView
function ChartItem:draw(list)
	local inactive_panel = ChartItem.inactivePanel
	local inactive_chart = ChartItem.InactiveChart
	local active_panel = ChartItem.activePanel
	local inactive_text = list.assets.params.songSelectInactiveText
	local active_text = list.assets.params.songSelectActiveText

	local main_color = inactive_panel

	local ct = self.isChart and 1 - math.pow(1 - math.min(1, self.colorT), 3) or self.selectedT

	if self.isChart then
		local unwrap = 1
		if self.chartIndex ~= 1 then
			unwrap = math.min(1, love.timer.getTime() - list.unwrapStartTime)
			unwrap = 1 - math.pow(1 - math.min(1, unwrap), 4)
		end

		main_color = self.mixColors(inactive_chart, inactive_panel, ct)
		main_color[4] = unwrap
	end

	local panel_color = self.mixColors(main_color, active_panel, ct)

	if self.flashColorT ~= 0 then
		panel_color = self.lighten(panel_color, self.flashColorT * 0.3)
	end

	local text_color = self.mixColors(inactive_text, active_text, ct)

	self:drawChartPanel(list, panel_color, text_color)
end

return ChartItem
