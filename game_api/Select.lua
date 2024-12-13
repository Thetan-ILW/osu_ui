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
	return self.selectModel:getBackgroundPath()
end

---@return sphere.Configs
function Select:getConfigs()
	return self.game.configModel.configs
end

---@return ncdk2.Chart?
function Select:getChart()
	return self.selectModel:loadChartAbsolute()
end


return Select
