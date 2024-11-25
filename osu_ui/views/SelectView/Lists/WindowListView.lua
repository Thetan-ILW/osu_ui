local Component = require("ui.Component")

local math_util = require("math_util")

---@class osu.ui.WindowListView : ui.Component
---@operator call: osu.ui.WindowListView
---@field parent osu.ui.ListContainer
---@field window osu.ui.WindowListItem[]
---@field parentList osu.ui.CollectionsListView
---@field itemClass osu.ui.WindowListItem
---@field itemParams table
local WindowListView = Component + {}

function WindowListView:getSelectedItemIndex() end
function WindowListView:getItems() end
function WindowListView:getStateCounter()
	return 0
end
function WindowListView:childUpdated() end

function WindowListView:selectItem(child) end

---@param window_index number
---@param visual_index number
--- Replaces item at the [window index] with the new item using visual index
function WindowListView:replaceItem(window_index, visual_index) end

function WindowListView:justHoveredOver(item) end

---@param f fun(ChartSetListView, table, ...)
function WindowListView:iterOverWindow(f, ...)
	local window = self.window
	local first = self.first
	local size = self.windowSize

	for i = 0, size - 1 do
		local index = 1 + (first + i - 1) % size
		f(window[index], self, ...) -- WindowItem, List, ...
	end
end

function WindowListView:loadItems()
	self.stateCounter = self:getStateCounter()
	self.children = {}
	self.childrenOrder = {}
	self.panelHeight = 90

	self.items = self:getItems()
	self.itemCount = #self.items

	self.windowSize = math.min(16, self.itemCount) -- lists with less than 16 items exist

	if self.windowSize == 0 then
		if self.parentList then
			self.parentList:childUpdated()
			self:scrollToPosition(self.parentList:getSelectedItemIndex())
		end
		return
	end

	local selected_index = self:getSelectedItemIndex()

	self.prevVisualIndex = selected_index
	self.holeSize = 0

	if self.parentList then
		self.y = self.parentList:getSelectedItemIndex() * self.parentList.panelHeight
		self.parentList:childUpdated()
		self:scrollToPosition(self.parentList:getSelectedItemIndex() + self:getSelectedItemIndex())
	end

	self.minScroll = -self.windowSize / 2 + 1
	self.maxScroll = self.itemCount - self.windowSize / 2

	-- scroll can be negative and greater than item count
	-- and we need to make sure it's not greater than (self.itemCount - self.windowSize + 1) cuz otherwise self.last would be not where we want
	local index_clamped = math_util.clamp(selected_index - math.floor(self.windowSize / 2), 1, self.itemCount - self.windowSize + 1)

	-- Represents range
	self.first = 1 + (index_clamped - 1) % self.windowSize
	self.last = 1 + (index_clamped - 1 - 1) % self.windowSize

	self.window = {}

	for i = 1, self.windowSize do
		local params = {}
		for k, v in pairs(self.itemParams) do
			params[k] = v
		end
		local item = self.itemClass(params)
		table.insert(self.window, item)
		self:addChild(tostring(i), item)
	end

	local start_index = math.min(math.max(1, selected_index - math.floor(self.windowSize / 2)), self.itemCount - self.windowSize + 1)

	for i = 0, self.windowSize - 1 do
		local index = 1 + (self.first + i - 1) % self.windowSize
		self:replaceItem(index, i + start_index)
	end
end

---@return number
--- Converts current scroll position to visual index
function WindowListView:getVisualIndex()
	local half = (self.windowSize / 2) * self.panelHeight
	local center = (self.parent.scrollPosition - self.y) - half
	local selected_y = self:getSelectedItemIndex() * self.panelHeight - half
	local a = math.max(0, center - selected_y)
	local b = self.holeSize - math.max(0, self.holeSize - a)
	return (center - b) / self.panelHeight
end

function WindowListView:setScroll(index)
	self.parent.scrollPosition = index * self.panelHeight
end

function WindowListView:scrollToPosition(index)
	self.parent:scrollToPosition(index * self.panelHeight, 0)
end

function WindowListView:loadNewItems()
	local visual_index = self:getVisualIndex()
	local visual_index_floored = math.floor(math_util.clamp(visual_index, 1, self.itemCount - self.windowSize + 1))

	self.first = 1 + ((visual_index_floored - 1) % self.windowSize)
	self.last = 1 + ((visual_index_floored - 1 - 1) % self.windowSize)

	-- Visible items on the screen. Anything greater than that is not visible on the screen.
	-- If the scroll is millions items per second, we would only see {self.windowSize} sets on the screen each frame
	local delta = visual_index_floored - math.floor(self.prevVisualIndex)
	local new_sets_count = math.min(math.abs(delta), self.windowSize)

	if delta >= 1 then
		self.prevVisualIndex = visual_index_floored
		for i = 1, new_sets_count do
			-- first - i
			local window_i = 1 + (self.first - 1 - i) % self.windowSize
			self:replaceItem(window_i, visual_index_floored - i + self.windowSize)
		end
	elseif delta <= -1 then
		self.prevVisualIndex = visual_index_floored
		for i = 1, new_sets_count do
			-- last + i
			local window_i = 1 + (self.last - 1 + i) % self.windowSize
			self:replaceItem(window_i, visual_index_floored - 1 + i)
		end
	end
end

---@param child osu.ui.WindowListItem
function WindowListView:select(child)
	self:selectItem(child)
	self.parent.isDragging = false -- Or else the scroll velocity will not be updated
end

---@param delta number
---@param just_pressed boolean
function WindowListView:autoScroll(delta, just_pressed)
	local time = love.timer.getTime()

	if time < self.nextAutoScrollTime then
		return
	end

	self:keyScroll(delta)

	local max_interval = 0.05
	local press_interval = max_interval + 0.07

	local interval = just_pressed and press_interval or max_interval

	self.nextAutoScrollTime = time + interval
end

---@param delta number
function WindowListView:keyScroll(delta)
	self:selectItem(self:getSelectedItemIndex() + delta)
	--self:scrollToPosition(self:getSelectedItemIndex() * self.panelHeight - self.panelHeight / 2, 0)
end

function WindowListView:processActions()
	local ca = actions.consumeAction
	local ad = actions.isActionDown
	local gc = actions.getCount

	if ad("left") then
		self:autoScroll(-1 * gc(), ca("left"))
	elseif ad("right") then
		self:autoScroll(1 * gc(), ca("right"))
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

function WindowListView:translateToCenter()
	love.graphics.translate(0, 768 / 2 - self.panelHeight / 2)
end

---@param state ui.FrameState
function WindowListView:updateTree(state)
	if self.stateCounter ~= self:getStateCounter() then
		self:loadItems()
	end

	if self.windowSize == 0 then
		self.height = 0
		return
	end

	self:loadNewItems()
	self.height = self.holeSize + self.itemCount * self.panelHeight

	love.graphics.push()
	self:translateToCenter()
	Component.updateTree(self, state)
	love.graphics.pop()
end

function WindowListView:drawTree()
	self:translateToCenter()
	Component.drawTree(self)
end

return WindowListView
