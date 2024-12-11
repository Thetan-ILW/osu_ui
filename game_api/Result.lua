local class = require("class")

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
	return self.game.playContext.chartdiff
end

---@return table
function Result:getScoreItem()
	return self.game.selectModel.scoreItem
end

---@return sphere.ScoreSystemContainer
function Result:getScoreSystem()
	return self.game.rhythmModel.scoreEngine.scoreSystem
end

return Result
