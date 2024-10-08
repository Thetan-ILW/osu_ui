local Layout = require("ui.views.GameplayView.Layout")
local Background = require("ui.views.GameplayView.Background")
local ScreenView = require("osu_ui.views.ScreenView")
local SequenceView = require("sphere.views.SequenceView")
local RectangleProgressView = require("sphere.views.GameplayView.RectangleProgressView")

local OsuPauseScreen = require("osu_ui.views.GameplayView.OsuPauseScreen")
local OsuPauseAssets = require("osu_ui.OsuPauseAssets")

local just = require("just")
local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")

---@class osu.ui.GameplayView: osu.ui.ScreenView
---@operator call: osu.ui.GameplayView
local GameplayView = ScreenView + {}

---@param game sphere.GameController
function GameplayView:new(game)
	self.game = game
	self.sequenceView = SequenceView()
end

function GameplayView:load()
	actions.disable()

	self.game.rhythmModel.observable:add(self.sequenceView)
	self.game.gameplayController:load()

	self.subscreen = ""
	self.failed = false

	local sequence_view = self.sequenceView

	local note_skin = self.game.noteSkinModel.noteSkin

	sequence_view.game = self.game
	sequence_view.subscreen = "gameplay"
	sequence_view:setSequenceConfig(note_skin.playField)
	sequence_view:load()

	local root = note_skin.path:match("(.+/)") or ""
	local assets = OsuPauseAssets(self.ui.assetModel, root)
	assets:load()
	self.pauseScreen = OsuPauseScreen(assets)

	self.pauseProgressBar =  RectangleProgressView({
		x = 0, y = 0, w = 1920, h = 20,
		color = {1, 1, 1, 1},
		transform = {0, 0, 0, {1 / 1920, 0}, {0, 1 / 1080}, 0, 0, 0, 0},
		direction = "left-right",
		mode = "+",
		getCurrent = function() return self.game.pauseModel.progress end,
	})

	self.cursor.alpha = 0
end

function GameplayView:unload()
	self.pauseScreen:unload()
	self.game.gameplayController:unload()
	self.game.rhythmModel.observable:remove(self.sequenceView)
	self.sequenceView:unload()
end

function GameplayView:retry()
	self.game.gameplayController:retry()
	self.sequenceView:unload()
	self.sequenceView:load()
	self.pauseScreen:hide()
	self.cursor.alpha = 0
end

function GameplayView:draw()
	just.container("screen container", true)
	self:keypressed()
	self:keyreleased()

	Layout:draw()
	if self.subscreen == "pause" then
		local prev_canvas = love.graphics.getCanvas()
		local game_canvas = ui.getCanvas("playfield")

		love.graphics.setCanvas(game_canvas)
		love.graphics.clear()
		Background(self)
		self.sequenceView:draw()
		love.graphics.setCanvas(prev_canvas)

		self.pauseScreen:draw(self, game_canvas)
	else
		Background(self)
		self.sequenceView:draw()
	end

	self.pauseProgressBar:draw()

	just.container()

	local state = self.game.pauseModel.state
	local multiplayerModel = self.game.multiplayerModel
	local isPlaying = multiplayerModel.room and multiplayerModel.isPlaying
	if
		not love.window.hasFocus()
		and state ~= "pause"
		and not self.game.rhythmModel.logicEngine.autoplay
		and not isPlaying
		and self.game.rhythmModel.inputManager.mode ~= "internal"
	then
		self.game.gameplayController:pause()
		self.pauseScreen:show()
	end
end

---@param dt number
function GameplayView:update(dt)
	self.game.gameplayController:update(dt)

	local state = self.game.pauseModel.state
	if state == "play" then
		self.subscreen = ""
	elseif state == "pause" then
		if self.subscreen == "" then
			self.pauseScreen:show()
		end
		self.subscreen = "pause"
	end

	if self.game.pauseModel.needRetry then
		self.failed = false
		self:retry()
	end

	local timeEngine = self.game.rhythmModel.timeEngine
	if timeEngine.currentTime >= timeEngine.maxTime + 1 then
		self:quit()
	end

	local actionOnFail = self.game.configModel.configs.settings.gameplay.actionOnFail
	local failed = self.game.rhythmModel.scoreEngine.scoreSystem.hp:isFailed()
	if failed and not self.failed then
		if actionOnFail == "pause" then
			self.game.gameplayController:changePlayState("pause")
			self.failed = true
		elseif actionOnFail == "quit" then
			self:quit()
		end
	end

	local multiplayerModel = self.game.multiplayerModel
	if multiplayerModel.room and not multiplayerModel.isPlaying then
		self:quit()
	end

	self.sequenceView:update(dt)
end

---@param event table
function GameplayView:receive(event)
	self.game.gameplayController:receive(event)
	self.sequenceView:receive(event)
end

function GameplayView:quit()
	if self.game.gameplayController:hasResult() then
		self:changeScreen("resultView")
	elseif self.game.multiplayerModel.room then
		self:changeScreen("multiplayerView")
	else
		self:changeScreen("selectView")
	end
end

function GameplayView:keypressed()
	local input = self.game.configModel.configs.settings.input
	local gameplayController = self.game.gameplayController

	local kp = just.keypressed
	if kp(input.skipIntro) then
		gameplayController:skipIntro()
	elseif kp(input.offset.decrease) then
		gameplayController:increaseLocalOffset(-0.001)
	elseif kp(input.offset.increase) then
		gameplayController:increaseLocalOffset(0.001)
	elseif kp(input.offset.reset) then
		gameplayController:resetLocalOffset()
	elseif kp(input.playSpeed.decrease) then
		gameplayController:increasePlaySpeed(-1)
	elseif kp(input.playSpeed.increase) then
		gameplayController:increasePlaySpeed(1)
	end

	local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	local state = self.game.pauseModel.state
	if state == "play" then
		if kp(input.pause) and not shift then
			gameplayController:changePlayState("pause")
		elseif kp(input.pause) and shift then
			self:quit()
		elseif kp(input.quickRestart) then
			gameplayController:changePlayState("retry")
		end
	elseif state == "pause" then
		if kp(input.pause) and not shift then
			gameplayController:changePlayState("play")
			self.pauseScreen:hide()
		elseif kp(input.pause) and shift then
			self:quit()
		elseif kp(input.quickRestart) then
			gameplayController:changePlayState("retry")
		end
	elseif state == "pause-play" and kp(input.pause) then
		gameplayController:changePlayState("pause")
		self.pauseScreen:show()
	end
end

function GameplayView:keyreleased()
	local state = self.game.pauseModel.state
	local input = self.game.configModel.configs.settings.input
	local gameplayController = self.game.gameplayController

	local kr = just.keyreleased
	if state == "play-pause" and kr(input.pause) then
		gameplayController:changePlayState("play")
	elseif state == "pause-retry" and kr(input.quickRestart) then
		gameplayController:changePlayState("pause")
	elseif state == "play-retry" and kr(input.quickRestart) then
		gameplayController:changePlayState("play")
	end
end

return GameplayView
