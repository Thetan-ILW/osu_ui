local class = require("class")

local actions = require("osu_ui.actions")
local AssetModel = require("osu_ui.models.AssetModel")

local GameView = require("osu_ui.views.GameView")
local SelectView = require("osu_ui.views.SelectView")
local GameplayView = require("osu_ui.views.GameplayView")
local ResultView = require("osu_ui.views.ResultView")
local MainMenuView = require("osu_ui.views.MainMenuView")
local EditorView = require("ui.views.EditorView")

---@class osu.ui.UserInterface
---@operator call: osu.ui.UserInterface
local UserInterface = class()

---@param persistence sphere.Persistence
---@param game sphere.GameController
function UserInterface:new(persistence, game)
	self.assetModel = AssetModel(persistence.configModel)

	self.gameView = GameView(game, self)
	self.mainMenuView = MainMenuView(game)
	self.selectView = SelectView(game)
	self.resultView = ResultView(game)
	self.gameplayView = GameplayView(game)
	self.editorView = EditorView(game)

	self.persistence = persistence
end

function UserInterface:load()
	actions.updateActions(self.persistence.configModel.configs.osu_ui)
	self.gameView:load()
end

function UserInterface:unload()
	self.gameView:unload()
end

---@param dt number
function UserInterface:update(dt)
	self.gameView:update(dt)
end

function UserInterface:draw()
	self.gameView:draw()
end

---@param event table
function UserInterface:receive(event)
	if event.name == "inputchanged" then
		actions.inputChanged(event)
	end

	if event.name == "keypressed" then
		actions.keyPressed(event)
	end

	if event.name == "focus" then
		actions.resetInputs()
	end

	self.gameView:receive(event)
end

return UserInterface
