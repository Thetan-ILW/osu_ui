local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")

local ChartListItem = require("osu_ui.views.SelectView.Lists.ChartListItem")

---@class osu.ui.ChartListView : osu.ui.WindowListView
---@operator call: osu.ui.ChartListView
---@field window osu.ui.WindowListChartItem[]
local ChartListView = WindowListView + {}

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ChartListView:new(game, assets)
	self.game = game
	self.assets = assets
	self.itemClass = ChartListItem

	self.unwrapStartTime = -math.huge
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
end

function ChartListView:getSelectedItemIndex()
	return self.game.selectModel.chartview_set_index
end

function ChartListView:getItems()
	return self.game.selectModel.noteChartSetLibrary.items
end

function ChartListView:getStateNumber()
	return self.game.selectModel.noteChartSetStateCounter
end

function ChartListView:getChildSelectedItemIndex()
	return 1
end

function ChartListView:getChildItemsCount()
	return 1
end

function ChartListView:selectItem(visual_index)
	self.game.selectModel:scrollNoteChartSet(nil, visual_index)
end

function ChartListView:reloadItems()
	WindowListView.reloadItems(self)
	self:iterOverWindow(ChartListItem.applySetEffects, 9999)
end

function ChartListView:replaceItem(window_index, visual_index)
	local chart_set = self.items[visual_index]
	local item = self.window[window_index]
	item:replaceWith(chart_set)
	item.visualIndex = visual_index
end

function ChartListView:update(dt)
	WindowListView.update(self, dt)
	self:iterOverWindow(ChartListItem.applySetEffects, dt)
	self.mouseOverIndex = -1
end

local gfx = love.graphics

function ChartListView:drawPanels(item, w, h)
	local x, y = w - item.x - 540, item.y

	local panel_w = ChartListItem.panelW
	local panel_h = ChartListItem.panelH

	if y < -panel_h or y > 768 then
		return
	end

	local inactive_panel = ChartListItem.inactivePanel
	local active_panel = ChartListItem.activePanel

	self:checkForMouseActions(item, x, y, panel_w, panel_h)

	gfx.push()
	gfx.translate(x, y)

	local main_color = inactive_panel

	local ct = item.selectedT

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

	item:drawChartPanel(self, x, y, color_mix, color_text_mix)
end

function ChartListView:draw(w, h)
	if self.windowSize == 0 then
		return
	end

	for i, item in ipairs(self.window) do
		self:drawPanels(item, w, h)
	end
end

return ChartListView
