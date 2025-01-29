local OsuList = require("osu_ui.views.SelectView.ChartTree.OsuList")
local GroupEntry = require("osu_ui.views.SelectView.ChartTree.GroupEntry")
local ChartList = require("osu_ui.views.SelectView.ChartTree.ChartList")

local flux = require("flux")
local math_util = require("math_util")

---@class osu.ui.GroupList : osu.ui.OsuWindowList
---@operator call: osu.ui.GroupList
local GroupList = OsuList + {}

function GroupList:load()
	self.groups = true
	OsuList.load(self)

	for i = 1, self.windowSize do
		local panel = self.panelContainer:insertChild(i, GroupEntry({
			list = self,
		})) ---@cast panel osu.ui.ChartEntry

		local start_index = math.max(1, self:getSelectedItemIndex() - self.windowSize)
		self:updatePanelInfo(panel, start_index + i - 1)
	end

	local sort = self.selectApi:getSortFunction()

	local list = self:addChild("mainChartList", ChartList({
		y = self:getSelectedItemIndex() * self.panelHeight,
		maxWindowSize = 14,
		mainChartList = true,
		groupSets = self.selectApi.sets[sort],
		startChart = self.startChart,
		scrollToPosition = function(position)
			self.scrollToPosition(position + self.y)
		end,
		teleportToPosition = function(position)
			self.teleportToPosition(position + self.y)
		end
	})) ---@cast list osu.ui.ChartList

	self.childList = list
	self:createHole()
	self:teleportPanels()

	self.selectedGroupExpanded = true
	self.stateCounter = self.selectApi:getNotechartSetStateCounter()
	self.loadingGroup = false
end

function GroupList:teleportPanels()
	local selected_index = self:getSelectedItemIndex()
	for i = 1, self.itemCount do
		local y = self.panelHeight * (i - 1)
		if i > selected_index then
			y = y + self.holeSize
		end
		self.yDestinations[i] = y
	end

end

function GroupList:getItems()
	return self.selectApi:getCollectionLibrary().tree.items
end

---@return integer
function GroupList:getSelectedItemIndex()
	return self.selectApi:getCollectionLibrary().tree.selected
end

function GroupList:expand()
	self.selectedGroupExpanded = true
	self.childList.handleEvents = true
	flux.to(self.childList, 0.2, { wrap = 1 }):ease("cubicout")
end

function GroupList:collapse()
	self.selectedGroupExpanded = false
	self.childList.handleEvents = false

	if self.holeSize > 1000  then
		local first = math.min(self.itemCount, self:getSelectedItemIndex() + 1)
		local last = math.min(self.itemCount, first + 10)
		for i = first, last do
			self.yDestinations[i] = self.yPositions[i] + 1000
		end
	end

	self.holeSize = 0
end

function GroupList:groupLoaded()
	self.childList:reload()
	self.loadingGroup = false

	self:expand()
	self:createHole()

	local si = self:getSelectedItemIndex()
	local x_dest = self.xDestinations[si]
	self.childList.xDestinations[1] = x_dest

	if self.childList.itemCount > 1 then
		for i = 2, math.min(self.childList.windowSize, self.childList.itemCount) do
			self.childList.xDestinations[i] = x_dest
			self.childList.yDestinations[i] = 0
		end
	end

	if self.childList.itemCount > self.childList.windowSize then
		self:teleportPanels()
	end
end

---@param index integer
function GroupList:selectItem(index)
	self.playSound(self.expandSound)

	if index == self:getSelectedItemIndex() then
		if self.selectedGroupExpanded then
			self:collapse()
			flux.to(self.childList, 0.3, { wrap = 0 }):ease("cubicout")
		else
			self:expand()
		end
		return
	end

	local item_y = self.yDestinations[index]

	self:collapse()
	self.childList.wrap = 0

	local scroll_dest = self.y + (index - 4) * self.panelHeight
	if self.scrollPosition > index * self.panelHeight + 1000 then
		local s = self:getSelectedItemIndex()
		local delta = self.scrollPosition - item_y

		for i = s, math.min(s + self.windowSize, self.itemCount) do
			self.yDestinations[i] = i * self.panelHeight
		end
		self.teleportToPosition(self.yDestinations[index] + delta)
	else
		self.scrollToPosition(scroll_dest)
	end

	self.loadingGroup = true
	self.stateCounter = self.selectApi:getNotechartSetStateCounter()
	self.selectApi:setCollectionIndex(index)
end

function GroupList:createHole()
	self.holeSize = self.childList:getHeight() + 45
	self.holeY = self.panelHeight * self:getSelectedItemIndex() + 30
end

---@param dt number
function GroupList:update(dt)
	OsuList.update(self, dt)

	local s = self:getSelectedItemIndex()
	self.childList.scrollPosition = self.scrollPosition - self.y
	self.childList.scrollVelocity = self.scrollVelocity
	self.childList.y = self.yDestinations[s] + self.panelHeight + 30
	self.childList.y = self.childList.y - (1 - self.childList.wrap) * self.panelHeight
	self.childList.alpha = self.childList.wrap

	if self.selectedGroupExpanded then
		self:createHole()
	end

	if self.loadingGroup then
		if self.stateCounter ~= self.selectApi:getNotechartSetStateCounter() then
			self:groupLoaded()
		end
	end
end

function GroupList:justHoveredOver(index)
	self.hoverTime[index] = love.timer.getTime()
	self.playSound(self.hoverSound)
end

---@param panel osu.ui.ChartEntry
---@param index integer
function GroupList:updatePanelInfo(panel, index)
	local items = self:getItems()
	panel.index = index
	panel:setInfo(items[index], self.selectApi:getCollectionLibrary().tree)
	self:updateItemPosition(index, math.abs(self.scrollVelocity * 0.005))
end

return GroupList
