local ScreenView = require("osu_ui.views.ScreenView")
local thread = require("thread")

local OsuLayout = require("osu_ui.views.OsuLayout")
local DisplayInfo = require("osu_ui.views.ResultView.DisplayInfo")
local View = require("osu_ui.views.ResultView.View")

local GaussianBlurView = require("sphere.views.GaussianBlurView")
local BackgroundView = require("sphere.views.BackgroundView")
local HpGraph = require("osu_ui.views.ResultView.HpGraph")

local InputMap = require("osu_ui.views.ResultView.InputMap")
local actions = require("osu_ui.actions")
local flux = require("flux")

---@class osu.ui.ResultView: osu.ui.ScreenView
---@operator call: osu.ui.ResultView
---@field view osu.ui.ResultViewContainer
---@field displayInfo osu.ui.ResultDisplayInfo
---@field scoreReveal number
---@field scoreRevealTween table?
local ResultView = ScreenView + {}

local dim = 0
local background_blur = 0

local loading = false
local canDraw = false
ResultView.load = thread.coro(function(self)
	if loading then
		return
	end

	loading = true

	self.game.resultController:load()

	self.inputMap = InputMap(self)

	if self.prevView == self.ui.selectView then
		self.game.resultController:replayNoteChartAsync("result", self.game.selectModel.scoreItem)
	end

	self.displayInfo = DisplayInfo(self)
	self.view = View(0.98, love.math.newTransform(0, 0))
	self.view:load(self)

	canDraw = true
	loading = false

	love.mouse.setVisible(false)
	self.cursor.alpha = 1
	actions.enable()

	self.scoreReveal = 0
	self.scoreRevealTween = flux.to(self, 1, { scoreReveal = 1 }):ease("cubicout")
end)

function ResultView:unload() end

---@param dt number
function ResultView:update(dt)
	if loading then
		return
	end

	local configs = self.game.configModel.configs
	local graphics = configs.settings.graphics

	dim = graphics.dim.result
	background_blur = graphics.blur.result

	self.assets:updateVolume(self.game.configModel)
	self.view:update(dt)
end

function ResultView:resolutionUpdated()
	self.view = View(0.98, love.math.newTransform(0, 0))
	self.view:load(self)
end

function ResultView:draw()
	if not canDraw then
		return
	end

	OsuLayout:draw()
	local w, h = OsuLayout:move("base")

	GaussianBlurView:draw(background_blur)
	BackgroundView:draw(w, h, dim, 0.01)
	GaussianBlurView:draw(background_blur)

	self.view:draw()
	self.ui.screenOverlayView:draw()
end

function ResultView:receive(event)
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

	self.game.rhythmModel.audioEngine:unload()

	playing = true
	local scoreEntry = self.game.selectModel.scoreItem
	local isResult = self.game.resultController:replayNoteChartAsync(mode, scoreEntry)

	if isResult then
		return self.view:reload()
	end

	if self.assets.sounds.switchScreen then
		self.assets.sounds.switchScreen:play()
	end

	self:changeScreen("gameplayView")
	playing = false
end)

return ResultView
