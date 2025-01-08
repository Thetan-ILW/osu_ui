local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")
local actions = require("osu_ui.actions")

local ui = require("osu_ui.ui")

local ChartListItem = require("osu_ui.views.SelectView.Lists.ChartListItem")

---@class osu.ui.ChartSetListView : osu.ui.WindowListView
---@operator call: osu.ui.ChartSetListView
---@field window osu.ui.WindowListChartItem[]
local ChartSetListView = WindowListView + {}

function ChartSetListView:load()
	self.config = self.game.configModel.configs.osu_ui
	self.itemClass = ChartListItem

	self.creationTime = love.timer.getTime()
	self.unwrapStartTime = 0
	self.nextAutoScrollTime = 0
	self.previewIcon = false

	self.maniaIcon = self.assets:loadImage("mode-mania-small")
	self.starImage = self.assets:loadImage("star")
	self.hoverSound = self.assets:loadAudio("menuclick")
	self.selectSound = self.assets:loadAudio("select-difficulty")

	self.itemParams = {
		background = self.assets:loadImage("menu-button-background"),
		titleFont = self.assets:loadFont("Regular", 22),
		infoFont = self.assets:loadFont("Regular", 16)
	}

	self:reloadItems()
end

function ChartSetListView:getSelectedItemIndex()
	return self.game.selectModel.chartview_set_index
end

function ChartSetListView:getChildSelectedItemIndex()
	return self.game.selectModel.chartview_index
end

function ChartSetListView:getItems()
	return self.game.selectModel.noteChartSetLibrary.items
end

function ChartSetListView:selectItem(visual_index)
	if self.state == "locked" then
		return
	end

	ui.playSound(self.selectSound)

	self.game.selectModel:scrollNoteChartSet(nil, visual_index)
	self.game.selectModel:scrollNoteChart(nil, 1)
end

function ChartSetListView:selectChildItem(index)
	if self.state == "locked" then
		return
	end

	ui.playSound(self.selectSound)

	if index == self:getChildSelectedItemIndex() then
		self.state = "item_selected"
		return
	end

	self.game.selectModel:scrollNoteChart(nil, index)
end

function ChartSetListView:getChildItemsCount()
	return self.selectedSetItemsCount or 1
end

function ChartSetListView:replaceItem(window_index, visual_index)
	local chart_set = self.items[visual_index]
	local item = self.window[window_index]
	item:replaceWith(chart_set)
	item.visualIndex = visual_index
end

function ChartSetListView:loadChildItems()
	local items = self.game.selectModel.noteChartLibrary.items
	self.selectedSetItemsCount = #items

	self.setItems = {}

	local selected_visual_item_index = self:getSelectedItemIndex()

	local parent_window_item

	for _, item in ipairs(self.window) do
		if item.visualIndex == selected_visual_item_index then
			parent_window_item = item
		end
	end

	for i, chart in ipairs(items) do
		local chart_item = ChartListItem(chart)
		chart_item.visualIndex = selected_visual_item_index + i - 1
		chart_item.isChart = true
		chart_item.chartIndex = i

		-- Parent might be out of screen
		if parent_window_item then
			chart_item.slideX = parent_window_item.slideX
			chart_item.selectedT = parent_window_item.selectedT
			chart_item.hoverT = parent_window_item.hoverT
		end

		table.insert(self.setItems, chart_item)
	end

	self.unwrapStartTime = love.timer.getTime()
end

---@param item osu.ui.WindowListChartItem
function ChartSetListView:justHoveredOver(item)
	ui.playSound(self.hoverSound)
	item.flashColorT = 1
end

function ChartSetListView:processActions()
	local ca = actions.consumeAction
	local ad = actions.isActionDown
	local gc = actions.getCount

	if ad("left") then
		self:autoScroll(-1 * gc(), ca("left"), "self")
	elseif ad("right") then
		self:autoScroll(1 * gc(), ca("right"), "self")
	elseif ad("up") then
		self:autoScroll(-1 * gc(), ca("up"), "child")
	elseif ad("down") then
		self:autoScroll(1 * gc(), ca("down"), "child")
	elseif ad("up10") then
		self:autoScroll(-10 * gc(), ca("up10"), "self")
	elseif ad("down10") then
		self:autoScroll(10 * gc(), ca("down10"), "self")
	elseif ca("toStart") then
		self:keyScroll(-math.huge, "self")
	elseif ca("toEnd") then
		self:keyScroll(math.huge, "self")
	end
end

function ChartSetListView:update(dt)
	if self.windowSize == 0 then
		return
	end

	WindowListView.update(self, dt)
	self:iterOverWindow(ChartListItem.applySetEffects, dt)

	for i, chart in ipairs(self.setItems) do
		chart:applyChartEffects(self, dt)
	end

	self.mouseOverIndex = -1

	self.previewIcon = self.config.songSelect.previewIcon
end

function ChartSetListView:mouseClick(set)
	local prev_selected_items_count = self:getChildItemsCount()

	if set.isChart then
		self:selectChildItem(set.chartIndex)
	else
		self.previousSelectedVisualIndex = self.selectedVisualItemIndex
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

---@param item osu.ui.WindowListChartItem
---@param w number
---@param h number
function ChartSetListView:drawPanels(item, w, h)
	local slide_in = ui.easeOutCubic(self.creationTime, 0.7)
	local x, y = w - item.x - (540 * slide_in), item.y

	if y > 768 then
		return
	end

	local panel_h = ChartListItem.panelH
	local panel_w = ChartListItem.panelW

	if not item.isChart and item.visualIndex == self.selectedVisualItemIndex then
		item.mouseOver = false -- or else it be forever true

		for _, v in ipairs(self.setItems) do
			self:drawPanels(v, w, h)
		end
		return
	end

	if y < -panel_h then
		return
	end

	if self.mouseOver then
		self:checkForMouseActions(item, x, y, panel_w, panel_h)
	end

	gfx.push()
	gfx.translate(x, y)
	item:draw(self)
	gfx.pop()
end

function ChartSetListView:draw(w, h)
	if self.windowSize == 0 then
		return
	end

	for _, item in ipairs(self.window) do
		self:drawPanels(item, w, h)
	end
end

return ChartSetListView
