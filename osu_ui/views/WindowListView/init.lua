local class = require("class")
local flux = require("flux")
local math_util = require("math_util")

---@class osu.ui.WindowListView
---@operator call: osu.ui.WindowListView
local WindowListView = class()

function WindowListView:getSelectedItemIndex() end
function WindowListView:getItems() end

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
	self.stateCounter = self.game.selectModel.noteChartSetStateCounter

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
	if self.smoothScroll < 1 then
		return
	end

	if self.smoothScroll > self.itemCount - self.windowSize + 1 then
		return
	end

	local scroll_floored = math.floor(self.smoothScroll)

	self.first = 1 + ((scroll_floored - 1) % self.windowSize)
	self.last = 1 + ((scroll_floored - 1 - 1) % self.windowSize)

	-- Visible sets on the screen. Anything greater than that is not visible on the screen.
	-- If the scroll is millions sets per second, we would only see {self.windowSize} sets on the screen each frame
	local delta = scroll_floored - math.floor(self.previousScroll)
	local new_sets_count = math.min(math.abs(delta), self.windowSize)

	if delta >= 1 then
		self.previousScroll = self.smoothScroll
		for i = 1, new_sets_count do
			-- first - i
			local window_i = 1 + (self.first - 1 - i) % self.windowSize
			self:updateSet(window_i, scroll_floored - i + self.windowSize)
		end
	elseif delta <= -1 then
		self.previousScroll = self.smoothScroll
		for i = 1, new_sets_count do
			-- last + i
			local window_i = 1 + (self.last - 1 + i) % self.windowSize
			self:updateSet(window_i, scroll_floored - 1 + i)
		end
	end
end

function WindowListView:animateScroll()
	if self.scroll < -self.windowSize / 2 then
		self.scroll = -self.windowSize / 2
	end

	if self.scrollTween then
		self.scrollTween:stop()
	end

	self.scrollTween = flux.to(self, 0.2, { smoothScroll = self.scroll }):ease("quadout"):onupdate(function()
		self:loadNewSets()
	end)
end

---@param dt number
function WindowListView:update(dt) end
---@param w number
---@param h number
function WindowListView:draw(w, h) end

return WindowListView
