local class = require("class")
local SequenceView = require("sphere.views.SequenceView")

---@class game.GameplayAPI
---@operator call: game.GameplayAPI
local Gameplay = class()

---@param game sphere.GameController
function Gameplay:new(game)
	self.game = game
	self.sequenceView = SequenceView()
	self.loaded = false
	self.chartEnded = false
	self.shouldShowResult = false
end

function Gameplay:start()
	if self.loaded then
		print("Gameplay already started")
		return
	end
	self.game.rhythmModel.observable:add(self.sequenceView)
	self.game.gameplayController:load()

	local sequence_view = self.sequenceView
	local note_skin = self.game.noteSkinModel.noteSkin
	sequence_view.game = self.game
	sequence_view.subscreen = "gameplay"
	sequence_view:setSequenceConfig(note_skin.playField)
	sequence_view:load()
	self.loaded = true
	self.chartEnded = false
	self.shouldShowResult = false
	self.paused = false
end

function Gameplay:stop()
	if not self.loaded then
		print("Gameplay already stopped")
		return
	end
	self.game.gameplayController:unload()
	self.game.rhythmModel.observable:remove(self.sequenceView)
	self.sequenceView:unload()
	self.loaded = false
	self.shouldShowResult = false
end

function Gameplay:retry()
	self.game.gameplayController:retry()
	self.sequenceView:unload()
	self.sequenceView:load()
	self.chartEnded = false
end

function Gameplay:update(dt)
	if not self.loaded then
		return
	end

	self.game.gameplayController:update(dt)

	local time_engine = self.game.rhythmModel.timeEngine
	if time_engine.currentTime >= time_engine.maxTime + 1 then
		self.chartEnded = true
	end

	if time_engine.currentTime >= math.max(0, time_engine.maxTime - 5) then
		self.shouldShowResult = true
	end

	self.sequenceView:update(dt)
end

---@param event table
--- Requires 'framestarted' event every frame!!!
function Gameplay:receive(event)
	if not self.loaded then
		return
	end
	self.game.gameplayController:receive(event)
	self.sequenceView:receive(event)
end

---@return sphere.SequenceView
function Gameplay:getSequenceView()
	return self.sequenceView
end

---@return boolean
--- Plays with at least 2 note hits will return true
function Gameplay:hasResult()
	return self.game.gameplayController:hasResult()
end

---@return audio.Source
function Gameplay:getMusicAudioSource()
	local container = self.game.rhythmModel.audioEngine.backgroundContainer
	for v in pairs(container.sources) do
		return v
	end
end

function Gameplay:skipIntro()
	self.game.gameplayController:skipIntro()
end

---@return number
--- Time of the first note
function Gameplay:getTimeToStart()
	local time_engine = self.game.rhythmModel.timeEngine
	return time_engine.currentTime - time_engine.minTime
end

---@return boolean
function Gameplay:canSkipIntro()
	local time_engine = self.game.rhythmModel.timeEngine
	local skip_time = time_engine.minTime - time_engine.timeToPrepare * time_engine.timeRate
	return time_engine.currentTime < skip_time and time_engine.timer.isPlaying
end

---@return string
function Gameplay:getPlayState()
	return self.game.pauseModel.state
end

---@param state string
function Gameplay:changePlayState(state)
	self.game.gameplayController:changePlayState(state)
end

function Gameplay:play()
	self.game.gameplayController:play()
	self.paused = false
end

function Gameplay:pause()
	self.paused = true
	self.game.gameplayController:pause()
end

function Gameplay:retry()
	self.paused = false
	self.game.gameplayController:retry()
end

---@return boolean
function Gameplay:needRetry()
	return self.game.pauseModel.needRetry
end

---@param direction number
---@return string new_speed
function Gameplay:increasePlaySpeed(direction)
	self.game.gameplayController:increasePlaySpeed(direction)
	local speed_model = self.game.speedModel
	local gameplay = self.game.configModel.configs.settings.gameplay
	return speed_model.format[gameplay.speedType]:format(speed_model:get())
end

---@param delta number
---@return number new_offset
function Gameplay:increaseLocalOffset(delta)
	self.game.gameplayController:increaseLocalOffset(delta)
	return self.game.selectModel.chartview.offset
end

---@return boolean
function Gameplay:isAutoplay()
	return self.game.rhythmModel.logicEngine.autoplay
end

return Gameplay
