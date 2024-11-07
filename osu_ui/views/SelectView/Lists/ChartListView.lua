local WindowListView = require("osu_ui.views.SelectView.Lists.WindowListView")

local ChartListItem = require("osu_ui.views.SelectView.Lists.ChartListItem")

---@alias ChartListViewParams { game: sphere.GameController, assets: osu.ui.OsuAssets }

---@class osu.ui.ChartListView : osu.ui.WindowListView
---@overload fun(params: ChartListViewParams): osu.ui.ChartListView
---@field window osu.ui.WindowListChartItem[]
---@field assets osu.ui.OsuAssets
local ChartListView = WindowListView + {}

function ChartListView:load()
	self.nextAutoScrollTime = 0

	local item_params = {
		background = self.assets:loadImage("menu-button-background"),
		maniaIcon = self.assets:loadImage("mode-mania-small-for-charts"),
		star = self.assets:loadImage("star"),
		titleFont = self.assets:loadFont("Regular", 22),
		infoFont = self.assets:loadFont("Regular", 16),
		list = self
	}

	local star = self.assets:loadImage("star2")

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

	WindowListView.load(self)
	self:loadItems(ChartListItem, item_params)
end

function ChartListView:getSelectedItemIndex()
	return self.game.selectModel.chartview_set_index
end

function ChartListView:getItems()
	return self.game.selectModel.noteChartSetLibrary.items
end

function ChartListView:selectItem(child)
	self.game.selectModel:scrollNoteChartSet(nil, child.visualIndex)
	self.parent:scrollToPosition(self.y + self:getSelectedItemIndex() * self.panelHeight, 0)
end

function ChartListView:replaceItem(window_index, visual_index)
	local chart_set = self.items[visual_index]
	local item = self.window[window_index]
	item:replaceWith(chart_set)
	item.visualIndex = visual_index
end

function ChartListView:update(dt, mouse_focus)
	local new_mouse_focus = WindowListView.update(self, dt, mouse_focus)

	if self.parentList then
		self.totalH = self.itemCount * self.panelHeight * self.parentList.wrapProgress
	end

	if self.particles then
		self.particles:setPosition(self.totalW, self:getSelectedItemIndex() * self.panelHeight - self.panelHeight / 2)
		self.particles:update(dt)
	end
	return new_mouse_focus
end

function ChartListView:draw()
	WindowListView.draw(self)
	if self.particles and self.parentList and self.parentList.wrapProgress ~= 0 then
		love.graphics.setColor(1, 1, 1, self.parentList.wrapProgress)
		love.graphics.draw(self.particles)
	end
end

return ChartListView
