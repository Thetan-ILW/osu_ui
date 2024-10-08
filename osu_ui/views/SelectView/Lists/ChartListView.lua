local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")

local ui = require("osu_ui.ui")

local ChartListItem = require("osu_ui.views.SelectView.Lists.ChartListItem")

---@class osu.ui.ChartListView : osu.ui.WindowListView
---@operator call: osu.ui.ChartListView
---@field window osu.ui.WindowListChartItem[]
local ChartListView = WindowListView + {}

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ChartListView:new(game, assets)
	WindowListView.new(self)
	self.game = game
	self.assets = assets
	self.config = self.game.configModel.configs.osu_ui
	self.itemClass = ChartListItem

	self.creationTime = love.timer.getTime()
	self.unwrapStartTime = -math.huge
	self.nextAutoScrollTime = 0
	self.previewIcon = false

	self.mouseAllowedArea = {
		w = 908,
		h = 598,
		x = 502,
		y = 82,
	}

	self.font = self.assets.localization.fontGroups.chartSetList

	local img = self.assets.images
	local snd = self.assets.sounds
	self.panelImage = img.listButtonBackground
	self.maniaIcon = img.maniaSmallIconForCharts
	self.starImage = img.star
	self.hoverSound = snd.hoverMenu
	self.selectSound = snd.selectChart
	self:reloadItems()
end

function ChartListView:getSelectedItemIndex()
	return self.game.selectModel.chartview_set_index
end

function ChartListView:getItems()
	return self.game.selectModel.noteChartSetLibrary.items
end

function ChartListView:getChildSelectedItemIndex()
	return 1
end

function ChartListView:getChildItemsCount()
	return 1
end

function ChartListView:selectItem(visual_index)
	if self.state == "locked" then
		return
	end

	ui.playSound(self.selectSound)

	if visual_index == self.selectedVisualItemIndex then
		self.state = "item_selected"
		return
	end

	self.game.selectModel:scrollNoteChartSet(nil, visual_index)
end

function ChartListView:replaceItem(window_index, visual_index)
	local chart_set = self.items[visual_index]
	local item = self.window[window_index]

	item:replaceWith(chart_set)
	item.visualIndex = visual_index
end

---@param item osu.ui.WindowListChartItem
function ChartListView:justHoveredOver(item)
	ui.playSound(self.hoverSound)
	item.flashColorT = 1
end

function ChartListView:update(dt)
	if self.windowSize == 0 then
		return
	end

	WindowListView.update(self, dt)
	self:iterOverWindow(ChartListItem.applySetEffects, dt)
	self.mouseOverIndex = -1

	self.previewIcon = self.config.songSelect.previewIcon
end

local gfx = love.graphics

function ChartListView:drawPanels(item, w, h)
	local slide_in = ui.easeOutCubic(self.creationTime, 0.7)
	local x, y = w - item.x - (540 * slide_in), item.y

	local panel_w = ChartListItem.panelW
	local panel_h = ChartListItem.panelH

	if y < -panel_h or y > 768 then
		return
	end

	self:checkForMouseActions(item, x, y, panel_w, panel_h)

	gfx.push()
	gfx.translate(x, y)
	item:draw(self)
	gfx.pop()
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
