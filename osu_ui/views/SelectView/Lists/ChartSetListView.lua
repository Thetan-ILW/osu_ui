local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")
local actions = require("osu_ui.actions")

local ChartListItem = require("osu_ui.views.SelectView.Lists.ChartListItem")

---@class osu.ui.ChartSetListView : osu.ui.WindowListView
---@operator call: osu.ui.ChartSetListView
---@field window osu.ui.WindowListChartItem[]
local ChartSetListView = WindowListView + {}

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ChartSetListView:new(game, assets)
	self.game = game
	self.assets = assets
	self.itemClass = ChartListItem

	self.unwrapStartTime = 0
	self.nextAutoScrollTime = 0

	self.mouseAllowedArea = {
		w = 636,
		h = 598,
		x = 733,
		y = 82,
	}

	self.font = self.assets.localization.fontGroups.chartSetList

	local img = self.assets.images
	self.panelImage = img.listButtonBackground
	self.maniaIcon = img.maniaSmallIconForCharts
	self.starImage = img.star
	self:reloadItems()

	self.unwrapStartTime = 0

	for i, chart in ipairs(self.setItems) do
		chart:applyChartEffects(self, 9999)
	end
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

function ChartSetListView:getStateNumber()
	return self.game.selectModel.noteChartSetStateCounter
end

function ChartSetListView:selectItem(visual_index)
	self.game.selectModel:scrollNoteChartSet(nil, visual_index)
	self.game.selectModel:scrollNoteChart(nil, 1)
end

function ChartSetListView:selectChildItem(index)
	self.game.selectModel:scrollNoteChart(nil, index)
end

function ChartSetListView:getChildItemsCount()
	return self.selectedSetItemsCount or 1
end

function ChartSetListView:reloadItems()
	WindowListView.reloadItems(self)
	self:iterOverWindow(ChartListItem.applySetEffects, 9999)

	for _, chart in ipairs(self.setItems) do
		chart:applyChartEffects(self, 9999)
	end
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

function ChartSetListView:processActions()
	local ca = actions.consumeAction
	local ad = actions.isActionDown
	local gc = actions.getCount

	if ad("up") then
		self:autoScroll(-1 * gc(), ca("up"), "self")
	elseif ad("down") then
		self:autoScroll(1 * gc(), ca("down"), "self")
	elseif ad("left") then
		self:autoScroll(-1 * gc(), ca("left"), "child")
	elseif ad("right") then
		self:autoScroll(1 * gc(), ca("right"), "child")
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
	WindowListView.update(self, dt)
	self:iterOverWindow(ChartListItem.applySetEffects, dt)

	for i, chart in ipairs(self.setItems) do
		chart:applyChartEffects(self, dt)
	end

	self.mouseOverIndex = -1
end

function ChartSetListView:mouseClick(set)
	local prev_selected_items_count = self:getChildItemsCount()

	if set.isChart then
		self.game.selectModel:scrollNoteChart(0, set.chartIndex)
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
	local x, y = w - item.x - 540, item.y

	if y > 768 then
		return
	end

	local panel_h = ChartListItem.panelH
	local panel_w = ChartListItem.panelW

	if not item.isChart and item.visualIndex == self.selectedVisualItemIndex then
		for _, v in ipairs(self.setItems) do
			self:drawPanels(v, w, h)
		end
		return
	end

	if y < -panel_h then
		return
	end

	self:checkForMouseActions(item, x, y, panel_w, panel_h)

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
