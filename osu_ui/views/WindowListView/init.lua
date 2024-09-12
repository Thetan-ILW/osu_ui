local class = require("class")
local flux = require("flux")
local math_util = require("math_util")
local actions = require("osu_ui.actions")

---@class osu.ui.WindowListView
---@operator call: osu.ui.WindowListView
local WindowListView = class()

function WindowListView:getStateNumber() end
function WindowListView:getSelectedItemIndex() end
function WindowListView:getItems() end
function WindowListView:selectItem(delta) end

---@param window_index number
---@param visual_index number
function WindowListView:updateSet(window_index, visual_index) end

---@param f fun(ChartSetListView, table, number, number, ...)
function WindowListView:iterOverWindow(f, ...)
	local window = self.window
	local first = self.first
	local size = self.windowSize

	for i = 0, size - 1 do
		local index = 1 + (first + i - 1) % size
		f(self, window[index], i, index, ...) -- WindowListView, set, on_screen_index, window index
	end
end

function WindowListView:reloadItems()
	self.items = self:getItems()
	self.itemCount = #self.items
	self.stateCounter = self:getStateNumber()

	self.window = {}
	self.windowSize = math.min(16, self.itemCount) -- lists with less than 16 items exist

	if self.windowSize == 0 then
		return
	end

	local selected_index = self:getSelectedItemIndex()
	self.selectedVisualItemIndex = selected_index

	-- Visual index as float
	self.scroll = selected_index - math.floor(self.windowSize / 2)
	self.smoothScroll = self.scroll
	self.previousScroll = self.scroll

	self.minScroll = -self.windowSize / 2 + 1
	self.maxScroll = self.itemCount - self.windowSize / 2

	-- scroll can be negative and greater than item count
	-- and we need make sure it's not greater than (self.itemCount - self.windowSize + 1) cuz otherwise self.last would be not where we want
	local scroll_clamped = math_util.clamp(self.scroll, 1, self.itemCount - self.windowSize + 1)
	-- Represents range
	self.first = 1 + (scroll_clamped - 1) % self.windowSize
	self.last = 1 + (scroll_clamped - 1 - 1) % self.windowSize

	self.mouseOverIndex = -1

	for _ = 1, self.windowSize do
		table.insert(self.window, {})
	end

	local start_index =
		math.min(math.max(1, selected_index - math.floor(self.windowSize / 2)), self.itemCount - self.windowSize + 1)

	self:iterOverWindow(function(s, set, on_screen_index, window_index)
		self:updateSet(window_index, start_index + on_screen_index)
	end)
end

function WindowListView:loadNewSets()
	if self.smoothScroll < self.minScroll then
		return
	end

	if self.smoothScroll > self.maxScroll then
		return
	end

	local scroll_floored = math.floor(math_util.clamp(self.smoothScroll, 1, self.itemCount - self.windowSize + 1))

	self.first = 1 + ((scroll_floored - 1) % self.windowSize)
	self.last = 1 + ((scroll_floored - 1 - 1) % self.windowSize)

	-- Visible sets on the screen. Anything greater than that is not visible on the screen.
	-- If the scroll is millions sets per second, we would only see {self.windowSize} sets on the screen each frame
	local delta = scroll_floored - math.floor(self.previousScroll)
	local new_sets_count = math.min(math.abs(delta), self.windowSize)

	if delta >= 1 then
		self.previousScroll = scroll_floored
		for i = 1, new_sets_count do
			-- first - i
			local window_i = 1 + (self.first - 1 - i) % self.windowSize
			self:updateSet(window_i, scroll_floored - i + self.windowSize)
		end
	elseif delta <= -1 then
		self.previousScroll = scroll_floored
		for i = 1, new_sets_count do
			-- last + i
			local window_i = 1 + (self.last - 1 + i) % self.windowSize
			self:updateSet(window_i, scroll_floored - 1 + i)
		end
	end
end

function WindowListView:animateScroll()
	if self.scroll < self.minScroll then
		self.scroll = self.minScroll
	end

	if self.scroll > self.maxScroll then
		self.scroll = self.maxScroll
	end

	if self.scrollTween then
		self.scrollTween:stop()
	end

	self.scrollTween = flux.to(self, 0.2, { smoothScroll = self.scroll }):ease("quadout")
end

function WindowListView:followSelection()
	local target = self:getSelectedItemIndex() - math.floor(self.windowSize / 2)
	self.scroll = math_util.clamp(target, self.minScroll, self.maxScroll)
	self.scrollTween = flux.to(self, 0.2, { smoothScroll = target }):ease("quadout")
end

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

function WindowListView:keyScroll(delta)
	self:selectItem(delta)
	self:followSelection()
end

function WindowListView:processActions()
	local ca = actions.consumeAction
	local ad = actions.isActionDown
	local gc = actions.getCount

	if ad("up") then
		self:autoScroll(-1 * gc(), ca("up"))
	elseif ad("down") then
		self:autoScroll(1 * gc(), ca("down"))
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

---@param dt number
function WindowListView:update(dt)
	if self.stateCounter ~= self:getStateNumber() then
		self:reloadItems()
	end

	if self.windowSize == 0 then
		return
	end

	self:processActions()
	self:loadNewSets()

	self.selectedVisualItemIndex = self:getSelectedItemIndex()
end

---@param w number
---@param h number
function WindowListView:draw(w, h) end

return WindowListView
