local ScreenView = require("osu_ui.views.ScreenView")
local thread = require("thread")

local DisplayInfo = require("osu_ui.views.ResultView.DisplayInfo")
local View = require("osu_ui.views.ResultView.View")

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

	if self.previousViewName == "select" then
		self.game.resultController:replayNoteChartAsync("result", self.game.selectModel.scoreItem)
	end

	self.displayInfo = DisplayInfo(self)
	self.scoreReveal = 0

	local viewport = self.gameView.viewport

	if not viewport:getChild("resultView") then
		viewport:addChild("resultView", View({ resultView = self, depth = 0.07 }))
		viewport:build()
	end

	local view = viewport:getChild("resultView")
	local cursor = viewport:getChild("cursor")
	local background = viewport:getChild("background")
	view.alpha = 0
	flux.to(view, 0.5, { alpha = 1 }):ease("quadout")
	flux.to(cursor, 0.5, { alpha = 1 }):ease("quadout")
	flux.to(background, 0.5, { dim = 0.3, parallax = 0.01 }):ease("quadout")

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
	local view = self.gameView.viewport:getChild("resultView")

	flux.to(view, 0.4, { alpha = 0 }):ease("quadout")
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
