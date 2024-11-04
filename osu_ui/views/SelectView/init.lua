local ScreenView = require("osu_ui.views.ScreenView")

local actions = require("osu_ui.actions")
local ui = require("osu_ui.ui")

local InputMap = require("osu_ui.views.SelectView.InputMap")
local DisplayInfo = require("osu_ui.views.SelectView.DisplayInfo")
local View = require("osu_ui.views.SelectView.View")

---@class osu.ui.SelectView: osu.ui.ScreenView
---@operator call: osu.ui.SelectView
---@field prevChartViewId number
local SelectView = ScreenView + {}

SelectView.groups = {
	"charts",
	"locations",
	"directories",
}

function SelectView:load()
	self.game.selectController:load()
	self.selectModel = self.game.selectModel
	self.configs = self.game.configModel.configs

	self.selectedGroup = self.groups[1]

	self.screenshot = love.graphics.newImage("screenshot206.png")
	self.inputMap = InputMap(self)
	self.displayInfo = DisplayInfo(self)
	self:reloadView()
	self:notechartChanged()

	actions.enable()
end

function SelectView:beginUnload()
	self.game.selectController:beginUnload()
end

function SelectView:unload()
	self.game.selectController:unload()
end

---@param dt number
function SelectView:update(dt)
	ScreenView.update(self, dt)
	self.game.selectController:update()

	local chartview_i = self.selectModel.chartview_index
	local chartview_set_i = self.selectModel.chartview_set_index

	if chartview_i ~= self.prevChartViewIndex or chartview_set_i ~= self.prevChartViewSetIndex then
		self.prevChartViewIndex = chartview_i
		self.prevChartViewSetIndex = chartview_set_i
		self:notechartChanged()
	end
end

local path_util = require("path_util")
function SelectView:reloadView()
	local view = love.filesystem.load(path_util.join(self.ui.mountPath, "osu_ui/views/SelectView/View.lua"))()

	local sc = self.gameView.screenContainer

	if sc:getChild("view") then
		sc:removeChild("view")
	end

	local success, result = pcall(sc.addChild, sc, "view", view({ selectView = self, depth = 0.1 }))
	if not success then
		print(result)
	end

	self.view = sc:getChild("view")

	self.gameView.screenContainer:build()
end

function SelectView:notechartChanged()
	self.displayInfo:load()
end

---@param mode string
---@param binds table
local function shouldBindKeys(mode, binds)
	if not binds or not binds[1] then
		return true
	end

	local ks = mode:split("key")
	local ss = ks[2]:split("scratch")
	local keys = tonumber(ks[1])
	local scratches = tonumber(ss[1]) or 0
	if keys + scratches ~= #binds then
		return true
	end

	for _, column in ipairs(binds) do
		if #column == 0 then
			return true
		end
	end
	return false
end

function SelectView:play()
	if not self.game.selectModel:notechartExists() then
		return
	end

	local multiplayer_model = self.game.multiplayerModel
	if multiplayer_model.room and not multiplayer_model.isPlaying then
		multiplayer_model:pushNotechart()
		self:changeScreen("multiplayerView")
		return
	end

	local mode = tostring(self.game.selectController.state.inputMode)
	local binds = self.game.configModel.configs.input[mode]

	if shouldBindKeys(mode, binds) then
		self:openModal("osu_ui.views.modals.Inputs")
		self.popupView:add("You need to bind keys first.", "purple")
		return
	end

	self.assets.sounds.menuHit:stop()
	self.assets.sounds.menuHit:play()

	self:changeScreen("gameplayView")
end

function SelectView:edit()
	if not self.game.selectModel:notechartExists() then
		return
	end
	self:changeScreen("editorView")
end

function SelectView:result()
	if self.game.selectModel:isPlayed() then
		self:changeScreen("resultView")
	end
end

function SelectView:changeTimeRate(delta)
	if self.modalActive then
		return
	end

	local configs = self.game.configModel.configs
	local g = configs.settings.gameplay

	local time_rate_model = self.game.timeRateModel

	---@type table
	local range = time_rate_model.range[g.rate_type]

	---@type number
	local new_rate = time_rate_model:get() + range[3] * delta

	if new_rate ~= time_rate_model:get() then
		self.game.modifierSelectModel:change()
		time_rate_model:set(new_rate)
		self.viewConfig:updateInfo(self)
	end
end

local events = {
	keypressed = function(self, event)
		if event[2] == "r" then
			self:reloadView()
		end

		if self.inputMap:call("music") then
			return
		end

		if self.inputMap:call("view") then
			return
		end

		if self.inputMap:call("selectModals") then
			return
		end

		if self.modal then
			return
		end

		self.inputMap:call("select")
	end,
	directorydropped = function(self, event)
		self:openModal("osu_ui.views.modals.LocationImport", event[1])
	end
}

function SelectView:receive(event)
	self.game.selectController:receive(event)

	local f = events[event.name]
	if f then
		f(self, event)
	end
end

---@param back_button_click boolean?
function SelectView:quit(back_button_click)
	if self.settingsView.state ~= "hidden" then
		self.settingsView:processState("hide")
		return
	end

	if self.search ~= "" then
		local config = self.game.configModel.configs.select
		self.search = ""
		config.filterString = ""
		self.game.selectModel:debouncePullNoteChartSet()

		if not back_button_click then
			return
		end
	end

	if not back_button_click then
		ui.playSound(self.assets.sounds.menuBack)
	end

	self:changeScreen("mainMenuView")
end

function SelectView:resolutionUpdated()
	self:reloadView()
end

---@return string
function SelectView:getScoreSource()
	return self.configs.osu_ui.songSelect.scoreSource
end
---@return string[]
function SelectView:getScoreSources()
	local profile_sources = self.ui.playerProfile.scoreSources
	self.scoreSources = { "local" }
	if profile_sources then
		for i, v in ipairs(profile_sources) do
			table.insert(self.scoreSources, v)
		end
	end
	table.insert(self.scoreSources, "online")
	return self.scoreSources
end
---@param index integer
function SelectView:setScoreSource(index)
	local score_source = self.scoreSources[index]
	self.configs.osu_ui.songSelect.scoreSource = score_source
	if score_source == "online" then
		self.configs.select.scoreSourceName = "online"
		self.game.selectModel:pullScore()
		return
	end
	self.configs.select.scoreSourceName = "local"
	self.game.selectModel:pullScore()
end

---@return string
function SelectView:getSortFunction()
	return self.configs.select.sortFunction
end
---@return string[]
function SelectView:getSortFunctionNames()
	local new = {}
	for _, v in ipairs(self.game.selectModel.sortModel.names) do
		table.insert(new, v)
	end
	table.remove(new, 1)
	table.remove(new, #new - 1)
	return new
end
---@param index integer
function SelectView:setSortFunction(index)
	local name = self:getSortFunctionNames()[index]
	if name then
		self.game.selectModel:setSortFunction(name)
	end
end

---@return string
function SelectView:getGroup()
	return self.selectedGroup
end
---@return string[]
function SelectView:getGroups()
	return self.groups
end
---@param index integer
function SelectView:setGroup(index)
	self.selectedGroup = self.groups[index]
end

function SelectView:getProfileInfo()
	local profile = self.ui.playerProfile

	local username = self.configs.online.user.name or "Guest"
	local pp = profile.pp
	local accuracy = profile.accuracy
	local level = profile.osuLevel
	local level_percent = profile.osuLevelPercent
	local rank = profile.rank

	local chartview = self.game.selectModel.chartview
	if chartview then
		local regular, ln = profile:getDanClears(chartview.chartdiff_inputmode)
		if regular ~= "-" or ln ~= "-" then
			username = ("%s [%s/%s]"):format(username, regular, ln)
		end
	end

	return {
		username = username,
		firstRow = ("Performance: %ipp"):format(pp),
		secondRow = ("Accuracy: %0.02f%%"):format(accuracy * 100),
		level = level,
		levelPercent = level_percent,
		rank = rank
	}

end

return SelectView
