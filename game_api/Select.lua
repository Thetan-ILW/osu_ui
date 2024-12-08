local class = require("class")

---@class game.SelectAPI
---@operator call: game.SelectAPI
---@field game sphere.GameController
local Select = class()

Select.groups = {
	"charts",
	"locations",
	"directories",
}

function Select:new(game)
	self.game = game
	assert(self.game)

	self.configs = self.game.configModel.configs
	self.selectModel = self.game.selectModel

	self.controllerLoaded = false
	self.prevChartViewIndex = -1
	self.prevChartViewSetIndex = -1
	self.selectedGroup = self.groups[1]

	self.notechartChangeListeners = {}
end

function Select:loadController()
	if self.controllerLoaded then
		return
	end

	self.game.selectController:load()
	self.controllerLoaded = true
end

--- Saves configs and disables the charts DB
function Select:unloadController()
	self.game.selectController:beginUnload()
	self.game.selectController:unload()
	self.controllerLoaded = false
end

function Select:updateController()
	self.game.selectController:update()

	local chartview_i = self.selectModel.chartview_index
	local chartview_set_i = self.selectModel.chartview_set_index

	if chartview_i ~= self.prevChartViewIndex or chartview_set_i ~= self.prevChartViewSetIndex then
		self.prevChartViewIndex = chartview_i
		self.prevChartViewSetIndex = chartview_set_i

		for _, f in pairs(self.notechartChangeListeners) do
			f()
		end
	end
end

---@param text string
function Select:updateSearch(text)
	local config = self.configs.select
	local prev = config.filterString

	if prev ~= text then
		config.filterString = text
		self.selectModel:debouncePullNoteChartSet()
	end
end

---@return string
function Select:getSearchText()
	local config = self.configs.select
	return config.filterString
end

---@param f function
function Select:listenForNotechartChanges(f)
	self.notechartChangeListeners[f] = f
end

---@return table
function Select:getChartview()
	return self.selectModel.chartview
end

---@return sphere.PlayContext
--- Mods, rate and timings
function Select:getPlayContext()
	return self.game.playContext
end

---@return sphere.CollectionLibrary
function Select:getCollectionLibrary()
	return self.selectModel.collectionLibrary
end

---@return number
function Select:getSelectedNoteChartSetIndex()
	return self.selectModel.chartview_set_index
end

function Select:getNotechartSets()
	return self.selectModel.noteChartSetLibrary.items
end

---@return integer
--- Returns a value that changes each time the user selects a new chart
function Select:getNotechartSetStateCounter()
	return self.selectModel.noteChartSetStateCounter
end

function Select:setNotechartSetIndex(index)
	self.selectModel:scrollNoteChartSet(nil, index)
end

---@return table
function Select:getScores()
	return self.selectModel.scoreLibrary.items
end

---@return audio.Source
function Select:getPreviewAudioSource()
	return self.game.previewModel.audio
end

---@return string
function Select:getScoreSource()
	return self.configs.osu_ui.songSelect.scoreSource
end
---@return string[]
function Select:getScoreSources()
	local profile_sources = self:getPlayerProfile().scoreSources
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
function Select:setScoreSource(index)
	local score_source = self.scoreSources[index]
	self.configs.osu_ui.songSelect.scoreSource = score_source
	if score_source == "online" then
		self.configs.select.scoreSourceName = "online"
		self.selectModel:pullScore()
		return
	end
	self.configs.select.scoreSourceName = "local"
	self.selectModel:pullScore()
end

---@return string
function Select:getSortFunction()
	return self.configs.select.sortFunction
end
---@return string[]
function Select:getSortFunctionNames()
	local new = {}
	for _, v in ipairs(self.selectModel.sortModel.names) do
		table.insert(new, v)
	end
	table.remove(new, 1)
	table.remove(new, #new - 1)
	return new
end
---@param index integer
function Select:setSortFunction(index)
	local name = self:getSortFunctionNames()[index]
	if name then
		self.selectModel:setSortFunction(name)
	end
end

---@return string
function Select:getGroup()
	return self.selectedGroup
end
---@return string[]
function Select:getGroups()
	return self.groups
end
---@param index integer
function Select:setGroup(index)
	self.selectedGroup = self.groups[index]
end

function Select:getPlayerProfile()
	return self.game.ui.pkgs.playerProfile
end

function Select:getProfileInfo()
	local profile = self:getPlayerProfile()
	local username = self.configs.online.user.name or "Guest"
	local pp = profile.pp
	local accuracy = profile.accuracy
	local level = profile.osuLevel
	local level_percent = profile.osuLevelPercent
	local rank = profile.rank

	local chartview = self.selectModel.chartview
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

---@return "enps_diff" | "osu_diff" | "msd_diff" | "user_diff"
--- Returns selected difficulty calculator in the settings
function Select:getSelectedDiffColumn()
	return self.configs.settings.select.diff_column
end

return Select
