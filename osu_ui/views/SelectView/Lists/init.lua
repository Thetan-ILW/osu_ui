local class = require("class")

local ChartSetListView = require("osu_ui.views.SelectView.Lists.ChartSetListView")
local ChartListView = require("osu_ui.views.SelectView.Lists.ChartListView")

local Lists = class()

function Lists:new(view)
	self.view = view
	self.game = view.game
	self.assets = view.assets
	self.focus = true

	self.selectModel = self.game.selectModel
	self.stateCounter = 1
	view.game.selectController:load()
end

local sets = {
	id = true,
	title = true,
	artist = true,
	["set modtime"] = true,
}

function Lists:createList()
	local game = self.view.game
	local assets = self.assets

	local select_config = game.configModel.configs.select
	local sort = select_config.sortFunction

	if sets[sort] then
		self.list = ChartSetListView(game, assets)
	else
		self.list = ChartListView(game, assets)
	end
end

function Lists:update(dt)
	local state = self.selectModel.noteChartSetStateCounter
	if state ~= self.stateCounter then
		self:createList()
		self.stateCounter = state
	end

	if self.list then
		self.list.focus = self.focus
		self.list:update(dt)
	end
end

function Lists:mouseScroll(delta)
	if self.list then
		self.list:mouseScroll(delta)
	end
end

function Lists:draw(w, h)
	if self.list then
		self.list:draw(w, h)
	end
end

return Lists
