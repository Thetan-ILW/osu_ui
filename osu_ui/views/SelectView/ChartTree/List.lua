local Component = require("ui.Component")
local ArrayContainer = require("osu_ui.views.SelectView.ChartTree.ArrayContainer")

local math_util = require("math_util")

---@class osu.ui.WindowList : ui.Component
---@operator call: osu.ui.WindowList
---@field scrollPosition number
---@field scrollVelocity number
---@field relativeScrollPosition number
---@field scrollToPosition fun(position: number)
---@field childList? osu.ui.WindowList
local WindowList = Component + {}

WindowList.NOT_HOVERING = -1

function WindowList:load()
	self.highScrollSpeed = false
	self.speedLimit = 10
	self.scrollPosition = 0
	self.scrollVelocity = 0
	self.relativeScrollPosition = 0
	self.positionUpdateRange = self.positionUpdateRange or 13
	self.panelHeight = self.panelHeight or 77
	self.maxWindowSize = self.maxWindowSize or 11

	self.itemCount = #self:getItems()
	self.windowSize = math.min(self.maxWindowSize, self.itemCount)

	self.previousVisualIndex = 0
	self.visualIndex = 0
	self.maxVisualIndex = self.itemCount

	self.hoverIndex = self.NOT_HOVERING
	self.holeSize = 0
	self.holeY = math.huge

	local panel_container = self:addChild("panels", ArrayContainer({
		windowSize = self.windowSize,
		z = 0.5
	})) ---@cast panel_container osu.ui.ArrayContainer

	self.panelContainer = panel_container
	self.panels = panel_container.children
	self.height = self:getHeight()
end

---@return number
function WindowList:getHeight()
	return self.itemCount * self.panelHeight + self.holeSize
end

---@return {[string]: any}
function WindowList:getItems() error("Not implemented") end

---@param index integer
---@param mouse_click boolean?
function WindowList:selectItem(index, mouse_click) error("Not implemented") end

---@return integer
function WindowList:getSelectedItemIndex() return -9999 end

---@param index number
---@return number
function WindowList:scrollPositionFromIndex(index)
	return self.panelHeight * index
end

function WindowList:getCurrentVisualIndex()
	local visual_index = math.floor(math.max(0, self.scrollPosition - self.y) / self.panelHeight)

	if self.childList then
		local child_index = self:getSelectedItemIndex()
		local height = math.floor(self.childList:getHeight() / self.panelHeight)
		local skip = math_util.clamp(visual_index - child_index, 0, height)
		visual_index = math.max(0, visual_index - skip)
	end

	visual_index = math.min(visual_index, self.itemCount - self.windowSize)

	return visual_index
end

---@param dt number
function WindowList:update(dt)
	if self.itemCount == 0 then
		return
	end

	if self.highScrollSpeed and math.abs(self.scrollVelocity) <= self.speedLimit then
		self.highScrollSpeed = false
		for i = 1, self.windowSize do
			self:updatePanelInfo(self.panels[i], self.visualIndex + i)
		end
	end

	self.relativeScrollPosition = self.scrollPosition - self.y

	self.hoverIndex = self.NOT_HOVERING
	for _, v in pairs(self.panels) do
		if v.mouseOver then
			self.hoverIndex = v.index
		end
	end

	local current_visual_index = self:getCurrentVisualIndex()

	if current_visual_index ~= self.visualIndex then
		self.previousVisualIndex = self.visualIndex
		self.visualIndex = current_visual_index
		self:shiftPanels()
	end

	local first = math.max(1, current_visual_index - self.positionUpdateRange)
	local last = math.min(current_visual_index + self.windowSize + self.positionUpdateRange, self.itemCount)

	for i = first, last do
		self:updateItemPosition(i, dt)
	end

	self:applyPanelEffects(dt)
end

function WindowList:shiftPanels()
	local delta = self.visualIndex - self.previousVisualIndex

	local new_list = {}

	for i = 0, self.windowSize - 1 do
		table.insert(new_list, self.panels[1 + (i + delta) % self.windowSize])
	end

	self.highScrollSpeed = math.abs(self.scrollVelocity) > self.speedLimit
	self.panels = new_list
	self.panelContainer.children = new_list

	local delta_c = math.min(self.windowSize, math.abs(delta))
	local start_index = delta > 0 and self.windowSize or delta_c

	for i = 1, delta_c do
		self:updatePanelInfo(
			self.panels[start_index - (i - 1)],
			self.visualIndex + start_index - i + 1
		)
	end
end

---@param panel ui.Component
---@param index integer
function WindowList:updatePanelInfo(panel, index) end

---@param index integer
function WindowList:justHoveredOver(index) end

---@param index integer
---@param dt number
function WindowList:updateItemPosition(index, dt) end

---@param dt number
function WindowList:applyPanelEffects(dt) end

return WindowList
