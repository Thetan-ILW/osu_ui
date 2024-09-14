local WindowListView = require("osu_ui.views.WindowListView")
local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")

local ItemList = require("osu_ui.views.SelectView.ItemList")

---@class osu.ui.ChartListView : osu.ui.WindowListView
---@operator call: osu.ui.ChartListView
---@field window osu.ui.ChartWindowListItem
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
		ItemList.applyChartEffects(self, set, 9999)
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
	self:iterOverWindow(ItemList.applySetEffects, 9999)
end

function ChartSetListView:replaceItem(window_index, visual_index)
	local item = self.items[visual_index]

	local set = self.window[window_index]
	ItemList.resetChartWindow(set, item)
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
		ItemList.resetChartWindow(set, chart)
		set.visualIndex = selected_visual_item_index + i - 1
		set.isChart = true
		set.chartIndex = i

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

function ChartSetListView:update(dt)
	WindowListView.update(self, dt)
	self:iterOverWindow(ItemList.applySetEffects, dt)

	for i, item in ipairs(self.setItems) do
		ItemList.applyChartEffects(self, item, dt)
	end

	self.mouseOverIndex = -1
end

function ChartSetListView:mouseClick(set)
	local prev_selected_items_count = self:getSetItemsCount()

	if set.isChart then
		self.game.selectModel:scrollNoteChart(0, set.chartIndex)
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

function ChartSetListView:drawPanels(set, w, h)
	if not set.isChart and set.visualIndex == self.selectedVisualItemIndex then
		for _, item in ipairs(self.setItems) do
			self:drawPanels(item, w, h)
		end
		return
	end

	local x, y = w - set.x - 540, set.y

	local panel_w = ItemList.panelW
	local panel_h = ItemList.panelH

	if y < -panel_h or y > 768 then
		return
	end

	local inactive_panel = ItemList.inactivePanel
	local inactive_chart = ItemList.InactiveChart
	local active_panel = ItemList.activePanel

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

	local ct = set.isChart and 1 - math.pow(1 - math.min(1, set.colorT), 3) or set.selectedT

	if set.isChart then
		local unwrap = 1
		if set.chartIndex ~= 1 then
			unwrap = math.min(1, love.timer.getTime() - self.unwrapStartTime)
			unwrap = 1 - math.pow(1 - math.min(1, unwrap), 4)
		end

		main_color = {
			inactive_chart[1] * (1 - ct) + main_color[1] * ct,
			inactive_chart[2] * (1 - ct) + main_color[2] * ct,
			inactive_chart[3] * (1 - ct) + main_color[3] * ct,
			unwrap,
		}
	end

	local color_mix = {
		main_color[1] * (1 - ct) + active_panel[1] * ct,
		main_color[2] * (1 - ct) + active_panel[2] * ct,
		main_color[3] * (1 - ct) + active_panel[3] * ct,
		main_color[4],
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
