local ScreenView = require("osu_ui.views.ScreenView")
local SequenceView = require("sphere.views.SequenceView")

local OsuPauseAssets = require("osu_ui.OsuPauseAssets")

local View = require("osu_ui.views.GameplayView.View")

local flux = require("flux")
local just = require("just")

---@class osu.ui.GameplayView: osu.ui.ScreenView
---@operator call: osu.ui.GameplayView
local GameplayView = ScreenView + {}

GameplayView.name = "gameplay"

---@param game sphere.GameController
function GameplayView:new(game)
	self.game = game
	self.sequenceView = SequenceView()
end

local quitting = false

function GameplayView:load()
	self.game.rhythmModel.observable:add(self.sequenceView)
	self.game.gameplayController:load()

	self.failed = false
	quitting = false

	local sequence_view = self.sequenceView
	local note_skin = self.game.noteSkinModel.noteSkin
	sequence_view.game = self.game
	sequence_view.subscreen = "gameplay"
	sequence_view:setSequenceConfig(note_skin.playField)
	sequence_view:load()

	local root = note_skin.path:match("(.+/)") or ""
	self.pauseAssets = OsuPauseAssets(self.ui.assetModel, root)
	self.pauseAssets:load()
	self.pauseAssets.shaders = self.ui.assets.shaders

	local scene = self.gameView.scene

	scene:removeChild("gameplayView")
	local view = scene:addChild("gameplayView", View({
		gameplayView = self,
		z = 0.05,
	})) ---@cast view osu.ui.GameplayViewContainer
	self.view = view

	local background = scene:getChild("background")
	local transition = scene:getChild("gameplayTransition") ---@cast transition osu.ui.GameplayTransition
	view.alpha = 0
	flux.to(view, 0.5, { alpha = 1 }):ease("quadout")
	flux.to(background, 1, { dim = 0.8 }):ease("quadout")
	transition:hide(1)
end

function GameplayView:unload()
	self.game.gameplayController:unload()
	self.game.rhythmModel.observable:remove(self.sequenceView)
	self.sequenceView:unload()
end

function GameplayView:retry()
	self.game.gameplayController:retry()
	self.sequenceView:unload()
	self.sequenceView:load()
end

---@param dt number
function GameplayView:update(dt)
	self.game.gameplayController:update(dt)

	self.view:processGameState(self.game.pauseModel.state)
	self.pauseAssets:updateVolume(self.game.configModel.configs)

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

	local isPlaying = multiplayerModel.room and multiplayerModel.isPlaying
	if
		not love.window.hasFocus()
		and state ~= "pause"
		and not self.game.rhythmModel.logicEngine.autoplay
		and not isPlaying
		and self.game.rhythmModel.inputManager.mode ~= "internal"
	then
		self.game.gameplayController:pause()
	end

	self.sequenceView:update(dt)
	self:keypressed()
	self:keyreleased()
end

---@param event table
function GameplayView:receive(event)
	self.game.gameplayController:receive(event)
	self.sequenceView:receive(event)
end


function GameplayView:quit()
	if quitting then
		return
	end

	quitting = true

	local scene = self.gameView.scene
	local view = self.gameView.scene:getChild("gameplayView")
	local background = self.gameView.scene:getChild("background")

	if self.game.gameplayController:hasResult() then
		flux.to(view, 0.25, { alpha = 0 }):ease("quadout"):oncomplete(function ()
			scene:removeChild("gameplayView")
			self:changeScreen("resultView")
		end)
		flux.to(background, 1, { dim = 0.8, parallax = 0.01 }):ease("quadout")
	elseif self.game.multiplayerModel.room then
		flux.to(view, 0.25, { alpha = 0 }):ease("quadout")
		self:changeScreen("multiplayerView")
	else
		flux.to(view, 0.25, { alpha = 0 }):ease("quadout")
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
		elseif kp(input.pause) and shift then
			self:quit()
		elseif kp(input.quickRestart) then
			gameplayController:changePlayState("retry")
		end
	elseif state == "pause-play" and kp(input.pause) then
		gameplayController:changePlayState("pause")
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
