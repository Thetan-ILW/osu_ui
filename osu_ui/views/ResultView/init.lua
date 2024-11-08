local ScreenView = require("osu_ui.views.ScreenView")
local thread = require("thread")

local DisplayInfo = require("osu_ui.views.ResultView.DisplayInfo")
local View = require("osu_ui.views.ResultView.View")

local InputMap = require("osu_ui.views.ResultView.InputMap")
local actions = require("osu_ui.actions")
local flux = require("flux")

---@class osu.ui.ResultView: osu.ui.ScreenView
---@operator call: osu.ui.ResultView
---@field displayInfo osu.ui.ResultDisplayInfo
---@field scoreReveal number
---@field scoreRevealTween table?
local ResultView = ScreenView + {}

local loading = false
ResultView.load = thread.coro(function(self)
	if loading then
		return
	end

	loading = true

	self.game.resultController:load()

	if self.prevView == self.ui.selectView then
		self.game.resultController:replayNoteChartAsync("result", self.game.selectModel.scoreItem)
	end

	self.inputMap = InputMap(self)
	self.displayInfo = DisplayInfo(self)
	self.scoreReveal = 0

	local sc = self.gameView.screenContainer
	if sc:getChild("view") then
		sc:removeChild("view")
	end
	sc:addChild("view", View({ resultView = self, depth = 0.1 }))
	sc:build()

	self.scoreRevealTween = flux.to(self, 1, { scoreReveal = 1 }):ease("cubicout")

	loading = false

	actions.enable()
end)

---@param dt number
function ResultView:update(dt)
	if loading then
		return
	end

	local configs = self.game.configModel.configs
	local graphics = configs.settings.graphics

	self.assets:updateVolume(self.game.configModel)
end

function ResultView:resolutionUpdated()
	self.gameView.screenContainer:removeChild("view")
	self.gameView.screenContainer:addChild("view", View({ depth = 0, resultView = self }))
end

function ResultView:receive(event)
	if loading then
		return
	end

	if event.name == "keypressed" then
		self.inputMap:call("view")
	end

	if event.name == "mousepressed" then
		if self.scoreRevealTween then
			self.scoreRevealTween:stop()
		end
		self.scoreReveal = 1
	end
end

function ResultView:submitScore()
	local scoreItem = self.game.selectModel.scoreItem
	self.game.onlineModel.onlineScoreManager:submit(self.game.selectModel.chartview, scoreItem.replay_hash)
end

function ResultView:quit()
	self.game.rhythmModel.audioEngine:unload()

	if self.assets.sounds.menuBack then
		self.assets.sounds.menuBack:play()
	end

	self:changeScreen("selectView")
end

ResultView.loadScore = thread.coro(function(self, itemIndex)
	if loading then
		return
	end

	loading = true

	local scoreEntry = self.game.selectModel.scoreItem
	if itemIndex then
		scoreEntry = self.game.selectModel.scoreLibrary.items[itemIndex]
	end
	self.game.resultController:replayNoteChartAsync("result", scoreEntry)

	if itemIndex then
		self.game.selectModel:scrollScore(nil, itemIndex)
	end

	self.viewConfig:loadScore(self)

	loading = false
end)

local playing = false
ResultView.play = thread.coro(function(self, mode)
	if playing then
		return
	end

	playing = true
	local scoreEntry = self.game.selectModel.scoreItem
	local isResult = self.game.resultController:replayNoteChartAsync(mode, scoreEntry)

	if isResult then
		return self.view:reload()
	end

	self:changeScreen("gameplayView")
	playing = false
end)

return ResultView
