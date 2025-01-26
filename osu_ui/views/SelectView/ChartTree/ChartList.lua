local Component = require("ui.Component")
local OsuList = require("osu_ui.views.SelectView.ChartTree.OsuList")
local ChartEntry = require("osu_ui.views.SelectView.ChartTree.ChartEntry")
local math_util = require("math_util")

---@class osu.ui.ChartList : osu.ui.OsuWindowList
---@operator call: osu.ui.ChartList
---@field mainChartList boolean?
local ChartList = OsuList + {}

function ChartList:load()
	self.charts = true
	OsuList.load(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.musicFft = scene.musicFft

	for i = 1, self.windowSize do
		local panel = self.panelContainer:insertChild(i, ChartEntry({
			list = self,
		})) ---@cast panel osu.ui.ChartEntry

		local start_index = math.max(1, self:getSelectedItemIndex() - self.windowSize)
		self:updatePanelInfo(panel, start_index + i - 1)
	end

	if self.groupSets then
		local list = self:addChild("charts", ChartList({
			y = self:getSelectedItemIndex() * self.panelHeight,
			panelHeight = 88,
			selectedItemHole = 5,
			startChart = self.startChart,
			z = 0.1,
			getItems = function()
				return self.selectApi:getNotechartSetChildren()
			end,
			getSelectedItemIndex = function()
				return self.selectApi:getNotechartSetChildrenIndex()
			end,
			selectItem = function(this, index)
				if index == this:getSelectedItemIndex() then
					this.startChart()
					return
				end
				self.playSound(self.sameSetClickSound)
				self.selectApi:setNotechartSetChildrenIndex(index)
				self.selectedSetIndex = self:getSelectedItemSetIndex()
				self.scrollToPosition(self.y + this:getSelectedItemScrollPosition())
			end,
			getHeight = function(this)
				return this.height - this.panelHeight
			end
		})) ---@cast list osu.ui.ChartList
		self.childList = list
		self:createHole()
	end

	if self.teleportToPosition then
		self.teleportToPosition(self.y + (self:getSelectedItemIndex() - 4) * self.panelHeight)
	end

	if not self.groupSets and self.itemCount ~= 0 then
		local star = scene.assets:loadImage("star2")
		local iw, ih = star:getDimensions()
		if iw * ih > 1 then
			local p = love.graphics.newParticleSystem(star, 200)
			p:setParticleLifetime(0.4, 0.9)
			p:setEmissionRate(10)
			p:setDirection(math.pi)
			p:setRadialAcceleration(400, 1700)
			p:setSpin(-math.pi, math.pi)
			p:setColors(1, 1, 1, 0.7, 1, 1, 1, 0)
			p:setSpeed(1000)
			p:setEmissionArea("normal", 0, 15, math.pi * 2, false)
			self.particles = p
		end
	end
end

function ChartList:getItems()
	return self.selectApi:getNotechartSets()
end

---@return integer
function ChartList:getSelectedItemIndex()
	return self.selectApi:getSelectedNoteChartSetIndex()
end

---@param index integer
---@param mouse_click boolean?
function ChartList:selectItem(index, mouse_click)
	local prev_set_index = self.selectedSetIndex

	if self.groupSets then
		self.xDestinations[self:getSelectedItemIndex()] = self.childList.xDestinations[1]
	else
		if mouse_click and index == self:getSelectedItemIndex() then
			self.startChart()
			return
		end
	end

	self.selectApi:setNotechartSetIndex(index)
	self.selectedSetIndex = self:getSelectedItemSetIndex()

	local items = self:getItems()
	if items[index].chartfile_set_id == prev_set_index then
		self.playSound(self.sameSetClickSound)
	else
		self.playSound(self.expandSound)
	end

	if self.groupSets then
		self.selectApi:setNotechartSetChildrenIndex(1)
		self.childList:reload()
		self:createHole()

		local si = self:getSelectedItemIndex()
		local x_dest = self.xDestinations[si]
		self.childList.xDestinations[1] = x_dest

		if self.childList.itemCount > 1 then
			for i = 2, self.childList.itemCount do
				self.childList.xDestinations[i] = x_dest
				self.childList.yDestinations[i] = 0
			end
		end
	end

	self.scrollToPosition(self:getSelectedItemScrollPosition())
end

function ChartList:keyPressed(event)
	local prev_key = "left"
	local next_key = "right"

	if not self.mainChartList then
		prev_key = "up"
		next_key = "down"
	end

	local delta = 0
	if event[2] == prev_key then
		delta = -1
	elseif event[2] == next_key then
		delta = 1
	end

	local i = math_util.clamp(self:getSelectedItemIndex() + delta, 1, self.itemCount)
	if delta ~= 0 then
		self:selectItem(i)
		return true
	end
end

function ChartList:createHole()
	self.holeSize = (#self.childList:getItems() - 1) * self.childList.panelHeight
	self.holeY = self.panelHeight * self:getSelectedItemIndex()
end

---@param dt number
function ChartList:update(dt)
	if self.itemCount == 0 then
		return
	end

	OsuList.update(self, dt)

	if self.groupSets then
		local s = self:getSelectedItemIndex()
		self.childList.scrollPosition = self.scrollPosition - self.y
		self.childList.scrollVelocity = self.scrollVelocity
		self.childList.y = self.yDestinations[s]
	end

	if self.particles then
		local beat = self.musicFft.beatValue
		self.particles:setPosition(550, self.yDestinations[self:getSelectedItemIndex()] + 35)
		self.particles:setEmissionRate(10 + (800 * beat))
		self.particles:setSpeed(500 + beat * 50000)
		self.particles:update(dt)
	end
end

function ChartList:drawChildren()
	if self.itemCount == 0 then
		return
	end

	for i = 1, #self.childrenOrder do
		local child = self.children[self.childrenOrder[i]]
		love.graphics.push("all")
		child:drawTree()
		love.graphics.pop()

		if child.debug then
			love.graphics.push("all")
			love.graphics.applyTransform(child.transform)
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("line", 0, 0, child.width, child.height)
			love.graphics.pop()
		end
	end

	if self.particles then
		love.graphics.setBlendMode("add")
		love.graphics.draw(self.particles)
		love.graphics.setBlendMode("alpha")
	end
end

function ChartList:justHoveredOver(index)
	self.hoverTime[index] = love.timer.getTime()
	self.playSound(self.hoverSound)
end

---@param panel osu.ui.ChartEntry
---@param index integer
function ChartList:updatePanelInfo(panel, index)
	local items = self:getItems()
	panel.index = index

	if not self.highScrollSpeed then
		---@type number
		local set_index = items[index].chartfile_set_id
		self.setIndex[index] = set_index
		panel.setIndex = set_index
		panel:setInfo(items[index])
	end

	self.selectT[index] = 0
	self.setSelectT[index] = 0

	if index > self:getSelectedItemIndex() then
		self:updateYItemPosition(index, 1)
	end
end

return ChartList
