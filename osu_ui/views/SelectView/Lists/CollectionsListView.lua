local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")

local ui = require("osu_ui.ui")

local CollectionItem = require("osu_ui.views.SelectView.Lists.CollectionItem")

---@class osu.ui.CollectionsListView : osu.ui.WindowListView
---@operator call: osu.ui.CollectionsListView
---@field window osu.ui.CollectionItem[]
local CollectionsListView = WindowListView + {}

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function CollectionsListView:new(game, assets)
	WindowListView.new(self)
	self.game = game
	self.assets = assets
	self.itemClass = CollectionItem

	self.creationTime = love.timer.getTime()
	self.unwrapStartTime = -math.huge
	self.nextAutoScrollTime = 0
	self.state = "idle"

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
	self.hoverSound = snd.hoverMenu
	self.selectSound = snd.selectChart
	self:reloadItems()
end

function CollectionsListView:getSelectedItemIndex()
	local tree = self.game.selectModel.collectionLibrary.tree
	return tree.selected
end

function CollectionsListView:getItems()
	return self.game.selectModel.collectionLibrary.tree.items
end

function CollectionsListView:getChildSelectedItemIndex()
	return 1
end

function CollectionsListView:getChildItemsCount()
	return 1
end

function CollectionsListView:selectItem(visual_index)
	if self.state == "locked" then
		return
	end

	ui.playSound(self.selectSound)

	if visual_index == self.selectedVisualItemIndex then
		self.state = "item_selected"
		return
	end

	self.game.selectModel:scrollCollection(nil, visual_index)
end

function CollectionsListView:replaceItem(window_index, visual_index)
	local collection = self.items[visual_index]
	local item = self.window[window_index]
	local tree = self.game.selectModel.collectionLibrary.tree
	item:replaceWith(collection, tree)
	item.visualIndex = visual_index
end

---@param item osu.ui.WindowListChartItem
function CollectionsListView:justHoveredOver(item)
	ui.playSound(self.hoverSound)
	item.flashColorT = 1
end

function CollectionsListView:update(dt)
	if self.windowSize == 0 then
		return
	end

	WindowListView.update(self, dt)
	self:iterOverWindow(CollectionItem.applyItemEffects, dt)
	self.mouseOverIndex = -1
end

local gfx = love.graphics

function CollectionsListView:drawPanels(item, w, h)
	local slide_in = ui.easeOutCubic(self.creationTime, 0.7)
	local x, y = w - item.x - (540 * slide_in), item.y

	local panel_w = CollectionItem.panelW
	local panel_h = CollectionItem.panelH

	if y < -panel_h or y > 768 then
		return
	end

	self:checkForMouseActions(item, x, y, panel_w, panel_h)

	gfx.push()
	gfx.translate(x, y)
	item:draw(self)
	gfx.pop()
end

function CollectionsListView:draw(w, h)
	if self.windowSize == 0 then
		return
	end

	for i, item in ipairs(self.window) do
		self:drawPanels(item, w, h)
	end
end

return CollectionsListView
