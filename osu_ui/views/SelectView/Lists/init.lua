local class = require("class")

local ChartSetListView = require("osu_ui.views.SelectView.Lists.ChartSetListView")
local ChartListView = require("osu_ui.views.SelectView.Lists.ChartListView")
local CollectionsListView = require("osu_ui.views.SelectView.Lists.CollectionsListView")

---@class osu.ui.SelectViewLists
---@operator call: osu.ui.SelectViewLists
---@field showing "charts" | "locations" | "directories"
local Lists = class()

Lists.groups = {
	"charts",
	"locations",
	"directories",
}

---@param view osu.ui.SelectView
function Lists:new(view)
	self.view = view
	self.game = view.game
	self.assets = view.assets
	self.focus = true

	local settings = self.game.configModel.configs.settings
	local s = settings.select

	if not s.collapse then
		view.popupView:add("Grouping charts is enabled.", "purple")
		s.collapse = true
	end

	self.selectModel = self.game.selectModel
	self.chartsStateCounter = 1
	self.showing = self.groups[1]
	self.pullNoteChart = false

	view.game.selectController:load()
end

---@param mode "charts" | "locations" | "directories"
function Lists:show(mode)
	self.showing = mode

	if mode == "charts" then
		self:showCharts()
		return
	end

	self:showCollections()
end

function Lists:showCollections()
	local game = self.view.game
	local assets = self.assets

	self.game.selectModel.collectionLibrary:load(self.showing == "locations")
	self.list = CollectionsListView(game, assets)

	self.pullNoteChart = true
end

local sets = {
	id = true,
	title = true,
	artist = true,
	["set modtime"] = true,
}

function Lists:showCharts()
	if self.pullNoteChart then
		self.list = nil
		self.game.selectModel:noDebouncePullNoteChartSet()
		self.pullNoteChart = false
		return
	end

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
	if self.showing == "charts" then
		local state = self.selectModel.noteChartSetStateCounter
		if state ~= self.chartsStateCounter then
			self.chartsStateCounter = self.selectModel.noteChartSetStateCounter
			self:showCharts()
		end
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
