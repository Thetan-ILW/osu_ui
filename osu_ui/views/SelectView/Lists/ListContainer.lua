local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

---@alias ListContainerParams { scrollLimit: number, root: osu.ui.WindowListView, assets: osu.ui.OsuAssets }

---@class osu.ui.ListContainer : osu.ui.ScrollAreaContainer
---@overload fun(params: ListContainerParams): osu.ui.ListContainer
---@field root osu.ui.WindowListView
---@field selectView osu.ui.SelectViewContainer
local ListContainer = ScrollAreaContainer + {}

function ListContainer:load()
	ScrollAreaContainer.load(self)
	self:addChild("root", self.root)
	self.teleportScrollPosition = true
	self.debug = true
end

function ListContainer:updateTree(state)
	local current_h = 0
	local max_h = 0
	for _, v in pairs(self.children) do
		---@cast v osu.ui.WindowListView
		current_h = math.max(current_h, v.y + v.height)
		max_h = max_h + #v.items * v.panelHeight
	end
	self.scrollLimit = current_h

	if self.scrollPosition > self.scrollLimit then
		self.scrollLimit = max_h
	end

	if love.mouse.isDown(2) and self.mouseOver then
		local scale = 768 / love.graphics.getHeight()
		local my = love.mouse.getY() * scale
		local y = math.min(math.max(0, my - 117) / 560, 1)
		self:scrollToPosition(self.scrollLimit * y)
	end

	local charts = self.children.charts ---@cast charts osu.ui.WindowListView

	if self.teleportScrollPosition and charts then
		self.teleportScrollPosition = false
		self.scrollVelocity = 0
		self.scrollPosition = charts.y + charts:getSelectedItemIndex() * charts.panelHeight
	end

	ScrollAreaContainer.updateTree(self, state)
end

function ListContainer:playChart()
	self.selectView:transitToGameplay()
end

return ListContainer
