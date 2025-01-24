local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local ChartList = require("osu_ui.views.SelectView.ChartTree.ChartList")
local GroupList = require("osu_ui.views.SelectView.ChartTree.GroupList")

local flux = require("flux")

---@class osu.ui.ChartTree : osu.ui.ScrollAreaContainer
---@operator call: osu.ui.ChartTree
---@field children {[string]: osu.ui.WindowList}
local ChartTree = ScrollAreaContainer + {}

function ChartTree:load()
	self.width, self.height = self.parent:getDimensions()
	ScrollAreaContainer.load(self)

	self.scrollDecelerationDefault = -0.9885

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local select_api = scene.ui.selectApi
	self.selectApi = select_api

	local configs = select_api:getConfigs()
	local osu = configs.osu_ui ---@type osu.ui.OsuConfig
	local group_charts = osu.songSelect.groupCharts

	if not configs.settings.select.collapse then
		self:fadeOut()
		configs.settings.select.collapse = true
		self.selectApi:debouncePullNoteChartSet()
	end

	self.groupCharts = group_charts

	if not group_charts then
		local sort = select_api:getSortFunction()

		local list = self:addChild("root", ChartList({
			x = self.width - 544,
			y = self.height / 2,
			groupSets = select_api.sets[sort],
			z = 0.1,
			scrollToPosition = function(position)
				self:scrollToPosition(position, 0)
			end,
			teleportToPosition = function(position)
				self.scrollPosition = position
			end
		})) ---@cast list osu.ui.OsuWindowList
		self.list = list
	else
		local list = self:addChild("root", GroupList({
			x = self.width - 544,
			y = self.height / 2,
			z = 0.1,
			scrollToPosition = function(position)
				self:scrollToPosition(position, 0)
			end,
			teleportToPosition = function(position)
				self.scrollPosition = position
			end
		})) ---@cast list osu.ui.OsuWindowList
		self.list = list
	end

	self.stateCounter = self.selectApi:getNotechartSetStateCounter()
end

function ChartTree:fadeOut()
	flux.to(self, 0.15, { alpha = 0 }):ease("cubicout")
end

function ChartTree:update()
	local new_state = self.selectApi:getNotechartSetStateCounter()
	if self.stateCounter ~= new_state then
		flux.to(self, 0.3, { alpha = 1 }):ease("cubicin")
		self.stateCounter = new_state

		if self.groupCharts then
			local list = self.list ---@cast list osu.ui.GroupList	
			if not list.loadingGroup then
				self:reload()
			end
		else
			self:reload()
		end
	end

	self.list.scrollPosition = self.scrollPosition
	self.list.scrollVelocity = self.scrollVelocity

	if self.mouseOver and love.mouse.isDown(2) then
		local scale = 768 / love.graphics.getHeight()
		local my = love.mouse.getY() * scale
		local y = math.min(math.max(0, my - 117) / 560, 1)
		self:scrollToPosition(self.scrollLimit * y)
		return true
	end

	self.scrollLimit = self.list:getHeight()
end

return ChartTree
