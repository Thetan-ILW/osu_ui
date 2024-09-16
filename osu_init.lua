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

---@param game sphere.GameController
---@param mount_path string
function UserInterface:new(game, mount_path)
	self.assetModel = AssetModel(game.persistence.configModel, mount_path)

	self.gameView = GameView(game, self)
	self.mainMenuView = MainMenuView(game)
	self.selectView = SelectView(game)
	self.resultView = ResultView(game)
	self.gameplayView = GameplayView(game)
	self.editorView = EditorView(game)
end

function UserInterface:load()
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

local events = {
	inputchanged = function(event)
		actions.inputChanged(event)
	end,
	textinput = function(event)
		actions.textInputEvent(event[1])
	end,
	keypressed = function(event)
		actions.keyPressed(event)
		if event[2] == "backspace" then
			actions.textInputEvent("backspace")
		end
	end,
	focus = function()
		actions.resetInputs()
	end,
}

---@param event table
function UserInterface:receive(event)
	local f = events[event.name]

	if f then
		f(event)
	end

	self.gameView:receive(event)
end

return UserInterface
