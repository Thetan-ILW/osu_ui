local class = require("class")
local Timings = require("sea.chart.Timings")
local Subtimings = require("sea.chart.Subtimings")

---@class game.SelectAPI
---@operator call: game.SelectAPI
---@field game sphere.GameController
local Select = class()

Select.groups = {
	"charts",
	"locations",
	"directories",
}

Select.sets = {
	id = true,
	title = true,
	artist = true,
	["set modtime"] = true,
}

function Select:new(game)
	self.game = game
	assert(self.game)

	self.configs = self.game.configModel.configs
	self.selectModel = self.game.selectModel

	self.controllerLoaded = false
	self.prevChartViewIndex = -1
	self.prevChartViewSetIndex = -1

	---@type table<function, function>
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
	if not self.controllerLoaded then
		return
	end

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

--- Call after user changed locations to reload collections
function Select:reloadCollections()
	local config = self:getConfigs()
	self.game.selectModel.collectionLibrary:load(config.settings.select.locations_in_collections)
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

function Select:debouncePullNoteChartSet()
	self.selectModel:debouncePullNoteChartSet()
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

---@param state boolean
function Select:setAutoplay(state)
	self.game.rhythmModel:setAutoplay(state)
end

---@return sea.ReplayBase
--- Mods, rate and timings
function Select:getReplayBase()
	return self.game.replayBase
end

---@return sphere.CollectionLibrary
function Select:getCollectionLibrary()
	return self.selectModel.collectionLibrary
end

function Select:setCollectionIndex(index)
	self.game.selectModel:scrollCollection(nil, index)

	local config = self.game.configModel.configs.settings.select
	if config.locations_in_collections then -- Changing locations does not update the notechartset state counter
		self.game.selectModel:noDebouncePullNoteChartSet()
	end
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

---@return rdb.ModelRow[]
function Select:getNotechartSetChildren()
	return self.game.selectModel.noteChartLibrary.items
end

---@return integer
function Select:getNotechartSetChildrenIndex()
	return self.game.selectModel.chartview_index
end

---@param index integer
function Select:setNotechartSetChildrenIndex(index)
	self.game.selectModel:scrollNoteChart(nil, index)
end

function Select:setScoreIndex(index)
	self.game.selectModel:scrollScore(nil, index)
end

---@return table
function Select:getScores()
	return self.selectModel.scoreLibrary.items
end

function Select:playPreview()
	self.game.previewModel:loadPreview()
end

function Select:pausePreview()
	self.game.previewModel:stop()
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
	local profile_sources = self.game.ui.pkgs.playerProfile.scoreSources
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

---@param group_charts boolean
---@return string
function Select:getGroup(group_charts)
	if not group_charts then
		return self.groups[1]
	end

	local config = self.game.configModel.configs.settings.select
	local locations_in_collections = config.locations_in_collections

	if locations_in_collections then
		return self.groups[2]
	else
		return self.groups[3]
	end
end

---@return "enps_diff" | "osu_diff" | "msd_diff" | "user_diff"
--- Returns selected difficulty calculator in the settings
function Select:getSelectedDiffColumn()
	return self.configs.settings.select.diff_column
end

---@return love.Image[]
--- Returns a table of three images. There are three images cuz the game needs to switch BG's with animation.
--- The first index is the BG of the select chart. Second and third index can be nil
function Select:getBackgroundImages()
	return self.game.backgroundModel.images
end

---@return string?
function Select:getBackgroundImagePath()
	return self.game.backgroundModel.path
end

---@return sphere.Configs
function Select:getConfigs()
	return self.game.configModel.configs
end

---@return ncdk2.Chart?
function Select:getChart()
	return self.selectModel:loadChartAbsolute()
end

---@return table
function Select:getMods()
	return self.game.replayBase.modifiers
end

function Select:removeAllMods()
	local time_rate_model = self.game.timeRateModel
	local modifier_select_model = self.game.modifierSelectModel
	local modifiers = self:getPlayContext().modifiers
	for i = 1, #modifiers do
		modifier_select_model:remove(1)
	end

	self.game.modifierSelectModel:change()
	time_rate_model:set(1)
end

---@return number
function Select:getTimeRate()
	return self.game.timeRateModel:get()
end

---@return "linear" | "exp"
function Select:getTimeRateType()
	return self.game.configModel.configs.settings.gameplay.rate_type
end

---@param rate number
function Select:setTimeRate(rate)
	local time_rate_model = self.game.timeRateModel
	time_rate_model:set(rate)
	self.game.modifierSelectModel:change()
end

---@param delta number
function Select:addTimeRate(delta)
	local time_rate_model = self.game.timeRateModel
	local prev = time_rate_model:get()
	time_rate_model:increase(delta)

	if prev ~= time_rate_model:get() then
		self.game.modifierSelectModel:change()
	end
end

---@param modifier string
function Select:addMod(modifier)
	return self.game.modifierSelectModel:add(modifier)
end

---@param index integer
function Select:removeMod(index)
	return self.game.modifierSelectModel:remove(index)
end

---@param modifier string
---@return boolean
function Select:isModAdded(modifier)
	return self.game.modifierSelectModel:isAdded(modifier)
end

---@param modifier string
---@return boolean
function Select:isModOneUse(modifier)
	return self.game.modifierSelectModel:isOneUse(modifier)
end

---@return table
function Select:getSelectedMods()
	return self.game.replayBase.modifiers
end

---@return integer
function Select:getSelectedModifiersCursor()
	return self.game.modifierSelectModel.modifierIndex
end

---@param count integer
function Select:moveSelectedModifiersCursor(count)
	self.game.modifierSelectModel:scrollModifier(count)
end

---@return ncdk.InputMode
function Select:getCurrentInputMode()
	return self.game.selectController.state.inputMode
end

---@param input_mode string
---@return sphere.NoteSkin
function Select:getNoteSkin(input_mode)
	return self.game.noteSkinModel:getNoteSkin(input_mode)
end

---@param input_mode string
---@return table
function Select:getNoteSkinInfos(input_mode)
	return self.game.noteSkinModel:getSkinInfos(input_mode)
end

---@param input_mode string
---@param path string
function Select:setNoteSkin(input_mode, path)
	self.game.noteSkinModel:setDefaultNoteSkin(input_mode, path)
end

function Select:openChartDirectory()
	self.game.selectController:openDirectory()
end

function Select:exportOsuChart()
	self.game.selectController:exportToOsu()
end

---@return {[number]: table}
function Select:getNoteChartFilters()
	return self:getConfigs().filters.notechart
end

---@param group string
---@param filter string
---@return boolean
function Select:isNoteChartFilterActive(group, filter)
	return self.game.selectModel.filterModel:isActive(group, filter) or false
end

---@param group string
---@param filter string
---@param state boolean
function Select:setNoteChartFilter(group, filter, state)
	self.game.selectModel.filterModel:setFilter(group, filter, state)
end

function Select:applyNoteChartFilters()
	self.game.selectModel.filterModel:apply()
	self.game.selectModel:noDebouncePullNoteChartSet()
end

---@return boolean
function Select:notechartExists()
	return self.game.selectModel:notechartExists()
end

function Select:openWebNotechart()
	self.game.selectController:openWebNotechart()
end

---@return sphere.InputModel
function Select:getInputModel()
	return self.game.inputModel
end

return Select
