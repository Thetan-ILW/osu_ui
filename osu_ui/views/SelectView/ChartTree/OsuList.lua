local WindowList = require("osu_ui.views.SelectView.ChartTree.List")

local math_util = require("math_util")

---@class osu.ui.OsuWindowList : osu.ui.WindowList
---@operator call: osu.ui.OsuWindowList
---@field childList? osu.ui.OsuWindowList
---@field charts boolean?
---@field groups boolean?
---@field groupSets boolean?
local OsuWindowList = WindowList + {}

local DECAY_FACTOR_X_NORMAL = 0.95
local DECAY_FACTOR_Y_NORMAL = 0.875

local frame_aim_time = 1 / 60

function OsuWindowList:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.selectApi = scene.ui.selectApi
	self.hoverSound = scene.assets:loadAudio("menuclick")
	self.sameSetClickSound = scene.assets:loadAudio("select-difficulty")
	self.expandSound = scene.assets:loadAudio("select-expand")

	self.side = 1
	self.panelHeight = self.panelHeight or 77
	self.maxWindowSize = self.maxWindowSize or 11
	self.positionUpdateRange = 13
	self.groups = self.groups == nil and false or self.groups
	self.charts = self.charts == nil and false or self.charts
	self.groupSets = self.groupSets == nil and false or self.groupSets
	WindowList.load(self)

	self.wrap = 1

	if self.itemCount == 0 then
		return
	end

	self.yPositions = {} ---@type number[]
	self.yDestinations = {} ---@type number[]
	self.xDestinations = {} ---@type number[]
	self.hoverTime = {} ---@type number[]
	self.selectT = {} ---@type number[]
	self.setSelectT = {} ---@type number[]
	self.setIndex = {} ---@type number[]
	self.selectedItemHole = self.selectedItemHole or 16

	if self.charts then
		self.selectedSetIndex = self:getSelectedItemSetIndex()
	end

	for i = 1, self.itemCount do
		local y = self.panelHeight * (i - 1)
		table.insert(self.yPositions, y)
		table.insert(self.yDestinations, y)
		table.insert(self.xDestinations, 320)
		table.insert(self.hoverTime, 0)
		table.insert(self.selectT, 0)

		if self.charts then
			table.insert(self.setSelectT, 0)
			table.insert(self.setIndex, 0)
		end
	end
end

---@return number
function OsuWindowList:getHeight()
	if self.childList then
		return (self.itemCount * self.panelHeight + self.childList:getHeight()) * self.wrap
	end
	return (self.yDestinations[self.itemCount] + self.panelHeight) * self.wrap
end

---@return number
function OsuWindowList:getSelectedItemSetIndex()
	local items = self:getItems()
	return items[self:getSelectedItemIndex()].chartfile_set_id
end

---@param index integer
function OsuWindowList:justHoveredOver(index)
	self.hoverTime[index] = love.timer.getTime()
end

---@param index integer
---@param dt number
function OsuWindowList:updateYItemPosition(index, dt)
	local y_destination = 0

	-- Hover Y
	if self.hoverIndex ~= self.NOT_HOVERING then
		if self.hoverIndex < index then
			y_destination = 16
		elseif self.hoverIndex > index then
			y_destination = -16
		end
	end

	local selected_index = self:getSelectedItemIndex()
	if index < selected_index then
		y_destination = y_destination - self.selectedItemHole
	elseif index > selected_index then
		y_destination = y_destination + self.selectedItemHole
	end

	local scroll_position = self.relativeScrollPosition

	if self:getSelectedItemIndex() < index then
		y_destination = y_destination + self.holeSize
		scroll_position = scroll_position - self.holeSize - self.panelHeight / 2
	end

	y_destination = y_destination + (self.yPositions[index] * self.wrap)

	local distance_y = y_destination - self.yDestinations[index]
	distance_y = distance_y * math.pow(DECAY_FACTOR_Y_NORMAL, dt / frame_aim_time)
	self.yDestinations[index] = y_destination - distance_y
end

---@param index integer
---@param dt number
function OsuWindowList:updateItemPosition(index, dt)
	self:updateYItemPosition(index, dt)

	local x_destination = 0

	if self.hoverIndex == index then
		x_destination = -72
	end

	local scroll_position = self.relativeScrollPosition

	if self:getSelectedItemIndex() < index then
		scroll_position = scroll_position - self.holeSize - self.panelHeight / 2
	end

	-- Scroll slide
	local target_distance = -self.scrollVelocity / math.log(0.996)
	local ay = self.yPositions[index] - scroll_position + target_distance
	local slide = math.min(320, math.abs((ay / 725) - 0.5) * 120)
	x_destination = x_destination + slide

	if not self.groups and self.charts and self.selectedSetIndex == self.setIndex[index] then
		x_destination = x_destination - 80
	end

	if self.groups then
		x_destination = x_destination - 80
	end

	local distance_x = x_destination - self.xDestinations[index]
	distance_x = distance_x * math.pow(DECAY_FACTOR_X_NORMAL, dt / frame_aim_time)
	self.xDestinations[index] = x_destination - distance_x
end

---@param dt number
function OsuWindowList:applyPanelEffects(dt)
	self.color[4] = math.max(0.4, 1 - math.min(math.max(0, math.abs(self.scrollVelocity) - 7) / self.speedLimit, 1))

	local current_time = love.timer.getTime()
	for _, v in pairs(self.panels) do
		---@cast v osu.ui.ChartEntry
		local i = v.index
		v.x = self.xDestinations[i] * self.side
		v.y = self.yDestinations[i]
		v.flashT = (1 - math.min(1, current_time - self.hoverTime[i])) * 0.3

		self.selectT[i] = math_util.clamp(self.selectT[i] + (self:getSelectedItemIndex() == v.index and dt * 5 or -dt * 5), 0, 1)
		v.selectedT = 1 - self.selectT[i]

		if self.charts then
			self.setSelectT[i] = math_util.clamp(self.setSelectT[i] + (self.selectedSetIndex == v.setIndex and dt * 5 or -dt * 5), 0, 1)
			v.selectedSetT = 1 - self.setSelectT[i]
		end

		if self:getSelectedItemIndex() == v.index and self.groupSets then
			v.alpha = 0
		else
			v.alpha = 1
		end
	end
end

return OsuWindowList
