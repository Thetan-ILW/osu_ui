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

	if self.game.pauseModel.needRetry then
		self.failed = false
		self:retry()
	end

	local time_engine = self.game.rhythmModel.timeEngine
	if time_engine.currentTime >= time_engine.maxTime + 1 then
		self.chartEnded = true
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

return Gameplay
