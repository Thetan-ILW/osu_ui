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

	self.game = game
end

function UserInterface:getMods()
	local player_profile = self.game.playerProfileModel

	if not player_profile or (player_profile and player_profile.version ~= 1) then
		player_profile = {
			pp = 0,
			accuracy = 0,
			osuLevel = 0,
			osuLevelPercent = 0,
			rank = 69,
			getScore = function ()
				return nil
			end,
			getDanClears = function ()
				return "-", "-"
			end,
			isDanIsCleared = function ()
				return false, false
			end
		}
	end

	self.playerProfile = player_profile

	local success, result = pcall(require, "minacalc.etterna_msd")

	print(success and "minacalc installed" or "minacalc not installed")

	local etterna_msd = success and result or {
		getMsdFromData = function ()
			return nil
		end
	}

	self.etternaMsd = etterna_msd
end

function UserInterface:load()
	self:getMods()
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
