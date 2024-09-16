local class = require("class")
local flux = require("flux")
local math_util = require("math_util")
local actions = require("osu_ui.actions")
local ui = require("osu_ui.ui")
local Layout = require("osu_ui.views.OsuLayout")

local ListItem = require("osu_ui.views.SelectView.Lists.ListItem")

--[[
	This list stores items in a 'window'. It has limited size and allows items to have state for animations.
	State updates every frame. Loading items can also be used to format strings and store it in an item.
	Item is a table in the window table. When you scroll items, it checks if the next item is visible and replaces old item with the new.
	This class has [first] and [last] fields, used to iterate the window table. They move with the scroll.

	The window thing can be done much easier, by moving all items in a window table when you scroll, but this method looks cooler
]]

---@class osu.ui.WindowListView
---@operator call: osu.ui.WindowListView
---@field window osu.ui.WindowListItem[]
---@field itemClass osu.ui.WindowListItem?
---@field mouseAllowedArea { w: number, h: number, x: number, y: number }
---@field focus boolean
---@field state "idle" | "item_selected" | "locked"
local WindowListView = class()

function WindowListView:getSelectedItemIndex() end
function WindowListView:getChildSelectedItemIndex() end
function WindowListView:getItems() end
function WindowListView:getChildItemsCount() end
function WindowListView:selectItem(visual_index) end
function WindowListView:selectChildItem(index) end

---@param window_index number
---@param visual_index number
--- Replaces item at the [window index] with the new item using visual index
function WindowListView:replaceItem(window_index, visual_index) end
function WindowListView:loadChildItems() end

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

function WindowListView:reloadItems()
	self.items = self:getItems()
	self.itemCount = #self.items

	self.windowSize = math.min(16, self.itemCount) -- lists with less than 16 items exist

	if self.windowSize == 0 then
		return
	end

	local selected_index = self:getSelectedItemIndex()
	self.selectedVisualItemIndex = selected_index
	self.previousSelectedVisualIndex = 0

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

	self.window = {}

	local item_class = self.itemClass or ListItem

	for _ = 1, self.windowSize do
		table.insert(self.window, item_class())
	end

	local start_index =
		math.min(math.max(1, selected_index - math.floor(self.windowSize / 2)), self.itemCount - self.windowSize + 1)

	for i = 0, self.windowSize - 1 do
		local index = 1 + (self.first + i - 1) % self.windowSize
		self:replaceItem(index, i + start_index)
	end

	self:loadChildItems()
end

function WindowListView:loadNewSets()
	local smooth_scroll = self.smoothScroll

	if smooth_scroll < self.minScroll then
		return
	end

	-- Items can have their own items and we must count that to avoid visual bugs
	local set_items_count = self:getChildItemsCount() - 1

	if smooth_scroll > self.selectedVisualItemIndex then
		smooth_scroll = math.max(self.selectedVisualItemIndex, smooth_scroll - set_items_count)
	end

	if smooth_scroll > self.maxScroll + set_items_count then
		return
	end

	-- ^^^ allow negative scroll and greater than self.itemCount. Otherwise last and first item might not be loaded
	-- And scrolling to the start and end of the list would break the window

	-- vvv but clamp it so we don't access nil elements
	local scroll_floored = math.floor(math_util.clamp(smooth_scroll, 1, self.itemCount - self.windowSize + 1))

	self.first = 1 + ((scroll_floored - 1) % self.windowSize)
	self.last = 1 + ((scroll_floored - 1 - 1) % self.windowSize)

	-- Visible items on the screen. Anything greater than that is not visible on the screen.
	-- If the scroll is millions items per second, we would only see {self.windowSize} sets on the screen each frame
	local delta = scroll_floored - math.floor(self.previousScroll)
	local new_sets_count = math.min(math.abs(delta), self.windowSize)

	if delta >= 1 then
		self.previousScroll = scroll_floored
		for i = 1, new_sets_count do
			-- first - i
			local window_i = 1 + (self.first - 1 - i) % self.windowSize
			self:replaceItem(window_i, scroll_floored - i + self.windowSize)
		end
	elseif delta <= -1 then
		self.previousScroll = scroll_floored
		for i = 1, new_sets_count do
			-- last + i
			local window_i = 1 + (self.last - 1 + i) % self.windowSize
			self:replaceItem(window_i, scroll_floored - 1 + i)
		end
	end
end

function WindowListView:animateScroll()
	local set_items_count = self:getChildItemsCount() - 1
	self.scroll = math_util.clamp(self.scroll, self.minScroll, self.maxScroll + set_items_count)

	if self.scrollTween then
		self.scrollTween:stop()
	end

	self.scrollTween = flux.to(self, 0.2, { smoothScroll = self.scroll }):ease("quadout")
end

function WindowListView:followSelection(index)
	local target = (index or self:getSelectedItemIndex()) - math.floor(self.windowSize / 2)
	self.scroll = math_util.clamp(target, self.minScroll, self.maxScroll)
	self.scrollTween = flux.to(self, 0.2, { smoothScroll = target }):ease("quadout")
end

---@param delta number
---@param just_pressed boolean
---@param target "self" | "child"
function WindowListView:autoScroll(delta, just_pressed, target)
	local time = love.timer.getTime()

	if time < self.nextAutoScrollTime then
		return
	end

	self:keyScroll(delta, target)

	local max_interval = 0.05
	local press_interval = max_interval + 0.07

	local interval = just_pressed and press_interval or max_interval

	self.nextAutoScrollTime = time + interval
end

---@param delta number
---@param target "self" | "child"
function WindowListView:keyScroll(delta, target)
	if target == "self" then
		local prev_child_item_count = self:getChildSelectedItemIndex()

		self.previousSelectedVisualIndex = self.selectedVisualItemIndex
		self:selectItem(self.selectedVisualItemIndex + delta)

		self.smoothScroll = self.smoothScroll - (prev_child_item_count - 1)
		self.scroll = self:getSelectedItemIndex() - self.windowSize / 2

		self:loadChildItems()
		self:followSelection()
	else
		self:selectChildItem(self:getChildSelectedItemIndex() + delta)
		self:followSelection(self.selectedVisualItemIndex + self:getChildSelectedItemIndex() - 1)
	end
end

function WindowListView:processActions()
	local ca = actions.consumeAction
	local ad = actions.isActionDown
	local gc = actions.getCount

	if ad("left") then
		self:autoScroll(-1 * gc(), ca("left"), "self")
	elseif ad("right") then
		self:autoScroll(1 * gc(), ca("right"), "self")
	elseif ad("up10") then
		self:autoScroll(-10 * gc(), ca("up10"), "self")
	elseif ad("down10") then
		self:autoScroll(10 * gc(), ca("down10"), "self")
	elseif ca("toStart") then
		self:keyScroll(-math.huge, "self")
	elseif ca("toEnd") then
		self:keyScroll(math.huge, "self")
	end
end

function WindowListView:mouseClick(set)
	self:selectItem(set.visualIndex)
	self.scroll = set.visualIndex - self.windowSize / 2
	self:animateScroll()
end

function WindowListView:mouseScroll(y)
	if self.windowSize == 0 then
		return
	end

	local area = self.mouseAllowedArea
	Layout:move("base")
	local has_focus = ui.isOver(area.w, area.h, area.x, area.y)

	if has_focus then
		self.scroll = self.scroll + y
		self:animateScroll()
	end
end

function WindowListView:checkForMouseActions(item, x, y, panel_w, panel_h)
	local area = self.mouseAllowedArea
	local in_area = ui.isOver(area.w, area.h, area.x, area.y)

	if not in_area or not self.focus then
		return
	end

	local was_over = item.mouseOver

	item.mouseOver = ui.isOver(panel_w, panel_h, x, y)
	if item.mouseOver then
		if ui.mousePressed(1) then
			self:mouseClick(item)
		end
		self.mouseOverIndex = item.visualIndex
	end

	if not was_over and item.mouseOver then
		self:justHoveredOver(item)
	end
end

---@param dt number
function WindowListView:update(dt)
	local prev_selected_index = self.selectedVisualItemIndex
	self.selectedVisualItemIndex = self:getSelectedItemIndex()

	self:processActions()
	self:loadNewSets()

	if self.selectedVisualItemIndex ~= self.scroll then
		local area = self.mouseAllowedArea

		local mx, _ = love.graphics.inverseTransformPoint(love.mouse.getX(), 0)

		if mx < area.x then
			self.scroll = self.selectedVisualItemIndex - self.windowSize / 2
			self:animateScroll()
		end
	end

	if love.mouse.isDown(2) then
		local set_items_count = self:getChildItemsCount() - 1
		local item_count = self.maxScroll + set_items_count

		local start_y = self.mouseAllowedArea.y
		local h = self.mouseAllowedArea.h

		local _, my = love.graphics.inverseTransformPoint(0, love.mouse.getY())

		self.scroll = (item_count * ((my - start_y) / h)) - self.windowSize / 4
		self:animateScroll()
	end

	if prev_selected_index ~= self.selectedVisualItemIndex then
		self:loadChildItems()
	end
end

---@param w number
---@param h number
function WindowListView:draw(w, h) end

return WindowListView
