local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")

local ChartListItem = require("osu_ui.views.SelectView.Lists.ChartListItem")

---@alias ChartListViewParams { game: sphere.GameController, assets: osu.ui.OsuAssets }

---@class osu.ui.ChartListView : osu.ui.WindowListView
---@overload fun(params: ChartListViewParams): osu.ui.ChartListView
---@field window osu.ui.WindowListChartItem[]
---@field selectApi game.SelectAPI
local ChartListView = WindowListView + {}

function ChartListView:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager
	local assets = scene.assets
	local star = assets:loadImage("star2")

	self.selectApi = scene.ui.selectApi
	self.assets = assets

	local iw, ih = star:getDimensions()
	if iw * ih > 1 then
		local p = love.graphics.newParticleSystem(star, 200)
		p:setParticleLifetime(0.4, 0.9)
		p:setEmissionRate(50)
		p:setDirection(math.pi)
		p:setRadialAcceleration(400, 1700)
		p:setSpin(-math.pi, math.pi)
		p:setColors(1, 1, 1, 0.7, 1, 1, 1, 0)
		p:setSpeed(1000)
		p:setEmissionArea("normal", 20, 10, math.pi * 2, false)
		self.particles = p
	end

	self.itemClass = ChartListItem
	self.itemParams = {
		background = assets:loadImage("menu-button-background"),
		maniaIcon = assets:loadImage("mode-mania-small-for-charts"),
		star = assets:loadImage("star"),
		titleFont = fonts:loadFont("Regular", 22),
		infoFont = fonts:loadFont("Regular", 16),
		hoverSound = assets:loadAudio("menuclick"),
		list = self
	}
	self.clickSound = assets:loadAudio("select-expand")

	self.width, self.height = self.parent:getDimensions()
	self:loadItems()
end

function ChartListView:loadItems()
	local chartviews_table = self.selectApi:getConfigs().settings.select.chartviews_table
	self.showScoreDate = chartviews_table == "chartplayviews"

	WindowListView.loadItems(self)
end

function ChartListView:getSelectedItemIndex()
	return self.selectApi:getSelectedNoteChartSetIndex()
end

function ChartListView:getItems()
	return self.selectApi:getNotechartSets()
end

function ChartListView:getStateCounter()
	return self.selectApi:getNotechartSetStateCounter()
end

function ChartListView:selectItem(child)
	self.playSound(self.clickSound)

	if self:getSelectedItemIndex() == child.visualIndex then
		self.parent:playChart()
	end
	self.selectApi:setNotechartSetIndex(child.visualIndex)
	self.parent:scrollToPosition(self.y + self:getSelectedItemIndex() * self.panelHeight, 0)
end

function ChartListView:replaceItem(window_index, visual_index)
	local chart_set = self.items[visual_index]
	local item = self.window[window_index]
	item:replaceWith(chart_set)
	item.visualIndex = visual_index
end

function ChartListView:calcTotalHeight()
	if not self.parentList then
		WindowListView.calcTotalSize(self)
		return
	end
	self.height = self.panelHeight * #self:getItems() * self.parentList.wrapProgress
end

function ChartListView:update(dt)
	if self.particles then
		self.particles:setPosition(self.width, self:getSelectedItemIndex() * self.panelHeight - self.panelHeight / 2)
		self.particles:update(dt)
	end

	WindowListView.update(self, dt)
end

function ChartListView:draw()
	WindowListView.draw(self)
	if self.particles and self.parentList and self.parentList.wrapProgress ~= 0 then
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(r, g, b, a * self.parentList.wrapProgress)
		love.graphics.draw(self.particles)
	end
end

return ChartListView
