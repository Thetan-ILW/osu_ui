local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")

local CollectionItem = require("osu_ui.views.SelectView.Lists.CollectionItem")
local ChartListView = require("osu_ui.views.SelectView.Lists.ChartListView")

local flux = require("flux")

---@class osu.ui.CollectionsListView : osu.ui.WindowListView
---@operator call: osu.ui.CollectionsListView
---@field assets osu.ui.OsuAssets
---@field window osu.ui.CollectionItem[]
---@field state "closed" | "loading" | "opening" | "open" | "closing"
local CollectionsListView = WindowListView + {}

function CollectionsListView:load()
	local item_params = {
		background = self.assets:loadImage("menu-button-background"),
		titleFont = self.assets:loadFont("Regular", 32),
		infoFont = self.assets:loadFont("Regular", 16),
		list = self
	}

	WindowListView.load(self)
	self.state = "loading"
	self.loadingCircle = self.assets:loadImage("loading")
	self.loadingCircleR = 0
	self:loadItems(CollectionItem, item_params)
end

function CollectionsListView:getSelectedItemIndex()
	local tree = self.game.selectModel.collectionLibrary.tree
	return tree.selected
end

function CollectionsListView:getItems()
	return self.game.selectModel.collectionLibrary.tree.items
end

function CollectionsListView:update(dt, mouse_focus)
	local new_mouse_focus = WindowListView.update(self, dt, mouse_focus)

	if self.state == "loading" then
		self.loadingCircleR = self.loadingCircleR + dt * 3
		if self.lastStateCounter ~= self.game.selectModel.noteChartSetStateCounter then
			self:collectionLoaded()
		end
	end

	return new_mouse_focus
end

function CollectionsListView:collectionLoaded()
	if self.parent:getChild("charts") then
		self.parent:removeChild("charts")
	end
	self.childList = self.parent:addChild("charts", ChartListView({
		game = self.game,
		assets = self.assets,
		parentList = self,
		depth = 0.9,
	}))
	self.parent:build()

	self.holeSize = 0
	self.wrapProgress = 0
	self.state = "opening"
	self:stopWrapTween()
	local size = self.items[self:getSelectedItemIndex()].count * self.panelHeight
	self.wrapTween = flux.to(self, 0.4, { holeSize = size, wrapProgress = 1 }):ease("cubicout")
end

function CollectionsListView:stopWrapTween()
	if self.wrapTween then
		self.wrapTween:stop()
	end
end

---@param child osu.ui.CollectionItem
function CollectionsListView:selectItem(child)
	if child.visualIndex == self:getSelectedItemIndex() then
		if self.state == "opening" or self.state == "open" then
			self.state = "closing"
			self:stopWrapTween()
			self.holeSize = (self.windowSize / 2) * self.panelHeight
			self.wrapTween = flux.to(self, 0.3, { holeSize = 0, wrapProgress = 0 }):ease("cubicout")
		elseif self.state == "closing" or self.state == "closed" then
			self.state = "opening"
			self:stopWrapTween()
			local size = self.items[self:getSelectedItemIndex()].count * self.panelHeight
			self.wrapTween = flux.to(self, 0.4, { holeSize = size, wrapProgress = 1 }):ease("cubicout")
		end
		return
	end

	local prev_index = self:getSelectedItemIndex()
	local prev_charts = self.parent:getChild("charts")
	local prev_size = 0
	if prev_charts then
		prev_size = prev_charts.totalH * self.wrapProgress
		self.parent:removeChild("charts")
		self.parent:build()
	end

	self.game.selectModel:scrollCollection(nil, child.visualIndex)
	self.state = "loading"
	self:stopWrapTween()
	self.holeSize = 0
	self.wrapProgress = 0
	self.lastStateCounter = self.game.selectModel.noteChartSetStateCounter

	if self:getSelectedItemIndex() > prev_index then
		self.parent.scrollPosition = self.parent.scrollPosition - prev_size
	end

	self.parent:scrollToPosition(self:getSelectedItemIndex() * self.panelHeight, 0)
end

function CollectionsListView:replaceItem(window_index, visual_index)
	local collection = self.items[visual_index]
	local item = self.window[window_index]
	local tree = self.game.selectModel.collectionLibrary.tree
	item:replaceWith(collection, tree)
	item.visualIndex = visual_index
end

function CollectionsListView:draw()
	WindowListView.draw(self)
	if self.state == "loading" then
		local img = self.loadingCircle
		local iw, ih = img:getDimensions()
		local x = self.totalW - iw / 2
		local y = self:getSelectedItemIndex() * self.panelHeight - self.panelHeight / 2
		love.graphics.setColor(1, 1, 1, self.alpha)
		love.graphics.draw(img, x, y, self.loadingCircleR, 0.7, 0.7, iw / 2, ih / 2)
	end
end

return CollectionsListView
