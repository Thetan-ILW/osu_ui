local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")
local Image = require("ui.Image")

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
	local fonts = self.shared.fontManager
	local assets = self.shared.assets

	self.width, self.height = self.parent:getDimensions()
	self.holeSize = 0
	self.wrapProgress = 0
	self.state = "loading"
	self.itemClass = CollectionItem
	self.itemParams = {
		background = assets:loadImage("menu-button-background"),
		titleFont = fonts:loadFont("Regular", 32),
		infoFont = fonts:loadFont("Regular", 16),
		list = self
	}
	self:loadItems()

	local img = assets:loadImage("loading")
	local scale = 0.7
	self:addChild("loading", Image({
		x = self.width - img:getWidth() * scale,
		origin = { x = 0.5, y = 0.5 },
		scale = scale,
		image = img,
		alpha = 0,
		z = 1,
		update = function(this, dt)
			this.alpha = 0
			if self.state == "loading" then
				this.angle = this.angle + dt * 3
				this.y = self:getSelectedItemIndex() * self.panelHeight - self.panelHeight / 2
				this.alpha = 1
			end
		end
	}))
end

function CollectionsListView:getSelectedItemIndex()
	local tree = self.game.selectModel.collectionLibrary.tree
	return tree.selected
end

function CollectionsListView:getItems()
	return self.game.selectModel.collectionLibrary.tree.items
end

function CollectionsListView:update()
	if self.state == "loading" then
		if self.lastStateCounter ~= self.game.selectModel.noteChartSetStateCounter then
			self:collectionLoaded()
		end
	end
end

function CollectionsListView:getChildItemCount()
	return #self.childList:getItems()
end

function CollectionsListView:childUpdated()
	self:stopWrapTween()
	local size = self:getChildItemCount() * self.panelHeight
	self.wrapTween = flux.to(self, 0.4, { holeSize = size, wrapProgress = 1 }):ease("cubicout")
end

function CollectionsListView:collectionLoaded()
	if self.parent:getChild("charts") then
		self.parent:removeChild("charts")
	end
	self.childList = ChartListView({
		game = self.game,
		assets = self.assets,
		parentList = self,
		depth = 0.9,
	})
	self.parent:addChild("charts", self.childList)
	self.state = "opening"
	self.holeSize = 0
	self.wrapProgress = 0
	self:childUpdated()
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
			local h = (self.windowSize / 2) * self.panelHeight
			if self.holeSize > h then
				self.holeSize = h
			end
			self.wrapTween = flux.to(self, 0.3, { holeSize = 0, wrapProgress = 0 }):ease("cubicout")
		elseif self.state == "closing" or self.state == "closed" then
			self.state = "opening"
			self:stopWrapTween()
			local size = self:getChildItemCount() * self.panelHeight
			self.wrapTween = flux.to(self, 0.4, { holeSize = size, wrapProgress = 1 }):ease("cubicout")
		end
		return
	end

	local prev_index = self:getSelectedItemIndex()
	local prev_charts = self.parent:getChild("charts")
	local prev_size = 0
	if prev_charts then
		prev_size = prev_charts.height * self.wrapProgress
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

return CollectionsListView
