local UiElement = require("osu_ui.ui.UiElement")

local ChartSetListView = require("osu_ui.views.SelectView.Lists.ChartSetListView")
local ChartListView = require("osu_ui.views.SelectView.Lists.ChartListView")
local CollectionsListView = require("osu_ui.views.SelectView.Lists.CollectionsListView")

---@alias SelectViewListsParams { game: sphere.GameController, assets: osu.ui.OsuAssets }

---@class osu.ui.SelectViewLists : osu.ui.UiElement
---@overload fun(params: SelectViewListsParams): osu.ui.SelectViewLists
---@field showing "charts" | "locations" | "directories" | "collections"
---@field game sphere.GameController
local Lists = UiElement + {}

Lists.groups = {
	"charts",
	"locations",
	"directories",
}

function Lists:load()
	self.selectModel = self.game.selectModel

	local settings = self.game.configModel.configs.settings
	local s = settings.select

	if not s.collapse then
		--popupView:add("Grouping charts is enabled.", "purple")
		s.collapse = true
	end

	self.chartsStateCounter = 1
	self.showing = self.groups[1]
	self.pullNoteChart = false
	UiElement.load(self)
end

function Lists:bindEvents()
	self.parent:bindEvent(self, "wheelUp")
	self.parent:bindEvent(self, "wheelDown")
end

---@param mode "charts" | "locations" | "directories" | "collections"
function Lists:show(mode)
	if mode == self.showing then
		return
	end

	self.showing = mode

	if mode == "charts" then
		self:showCharts()
		return
	end

	self:showCollections()
end

function Lists:showCollections()
	local game = self.game
	local assets = self.assets

	local config = self.game.configModel.configs.settings.select

	local loc_in_collections = false
	if self.showing == "locations" then
		loc_in_collections = true
	elseif self.showing == "collections" then
		loc_in_collections = config.locations_in_collections
		self.showing = loc_in_collections and "locations" or "directories"
	end

	if config.locations_in_collections ~= loc_in_collections then
		config.locations_in_collections = loc_in_collections
		self.selectModel.collectionLibrary:load(loc_in_collections)
	end

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
		self.selectModel:noDebouncePullNoteChartSet()
		self.pullNoteChart = false
		return
	end

	local game = self.game
	local assets = self.assets

	local configs = game.configModel.configs
	local select_config = configs.select
	local settings_select = configs.settings.select

	local sort = select_config.sortFunction
	local showing_modded_charts = settings_select.chartdiffs_list

	if sets[sort] and not showing_modded_charts then
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
		self.list.focus = self.mouseOver
		self.list.totalW = self.parent.totalW
		self.list:update(dt)

		if self.list.state == "item_selected" then
			self.view:select()
		end
	end
end

function Lists:lock()
	if self.list then
		self.list.state = "locked"
	end
end

function Lists:unlock()
	if self.list then
		self.list.state = "idle"
	end
end

function Lists:wheelUp()
	if self.list then
		self.list:mouseScroll(-1)
	end
	return true
end

function Lists:wheelDown()
	if self.list then
		self.list:mouseScroll(1)
	end
	return true
end

function Lists:draw()
	if self.list then
		self.list:draw(self.parent.totalW, self.parent.totalH)
	end
end

return Lists
