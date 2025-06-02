local class = require("class")
local ModifierModel = require("sphere.models.ModifierModel")

---@class game.ResultAPI
---@operator call: game.ResultAPI
local Result = class()

---@param game sphere.GameController
function Result:new(game)
	self.game = game
	self.controllerLoaded = false
end

function Result:loadController()
	if self.controllerLoaded then
		print("Result controller is already loaded")
		return
	end
	self.game.resultController:load()
	self.controllerLoaded = true
end

function Result:unloadController()
	if not self.controllerLoaded then
		print("Result controller is already unloaded")
		return
	end
	self.game.resultController:unload()
	self.controllerLoaded = false
end

---@param mode string
function Result:replayNotechartAsync(mode)
	self.game.resultController:replayNoteChartAsync(mode, self.game.selectModel.scoreItem)
end

---@return table
function Result:getChartdiffFromScore()
	return self.game.rhythmModel.chartdiff
end

---@return table
function Result:getScoreItem()
	return self.game.selectModel.scoreItem
end

---@return sphere.ScoreEngine
function Result:getScoreEngine()
	return self.game.rhythmModel.scoreEngine
end

---@return ncdk2.Chart?
function Result:getChart()
	return self.game.selectModel:loadChartAbsolute()
end

---@return ncdk2.Chart?
function Result:getChartWithMods()
	local chart = self.game.selectModel:loadChartAbsolute(self.game.gameplayController:getImporterSettings())
	if chart then
		ModifierModel:apply(self.game.replayBase.modifiers, chart)
	end
	return chart
end

---@param chart ncdk2.Chart
function Result:exportOsuReplay(chart)
	self.game.replayModel:saveOsr(chart.chartmeta)
end

---@return sea.ComputeContext
function Result:getComputeContext()
	return self.game.resultController.computeContext
end

return Result
