local class = require("class")

local actions = require("osu_ui.actions")
local AssetModel = require("osu_ui.models.AssetModel")

local GameView = require("osu_ui.views.GameView")
local SelectView = require("osu_ui.views.SelectView")
local GameplayView = require("osu_ui.views.GameplayView")
local ResultView = require("osu_ui.views.ResultView")
local MainMenuView = require("osu_ui.views.MainMenuView")
local PlayerStatsView = require("osu_ui.views.PlayerStatsView")
local EditorView = require("ui.views.EditorView")

---@class osu.ui.UserInterface
---@operator call: osu.ui.UserInterface
local UserInterface = class()

---@param game sphere.GameController
---@param mount_path string
function UserInterface:new(game, mount_path)
	game.persistence:openAndReadThemeConfig("osu_ui", mount_path)
	self.assetModel = AssetModel(game.persistence.configModel, mount_path)

	self.gameView = GameView(game, self)
	self.mainMenuView = MainMenuView(game)
	self.selectView = SelectView(game)
	self.resultView = ResultView(game)
	self.gameplayView = GameplayView(game)
	self.playerStatsView = PlayerStatsView(game)
	self.editorView = EditorView(game)

	self.game = game
end

function UserInterface:getMods()
	local package_manager = self.game.packageManager
	local player_profile_pkg = package_manager:getPackage("player_profile")

	local player_profile

	if player_profile_pkg then
		player_profile = self.game.playerProfileModel
	end

	if not player_profile or (player_profile and player_profile.version ~= 1) then
		player_profile = {
			notInstalled = true,
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
			end,
			getActivity = function ()
				return nil
			end,
			getAvailableDans = function ()
				return nil
			end,
			getDanTable = function (_self, mode, type)
				return nil
			end,
			getOverallStats = function ()
				return nil
			end,
			getModeStats = function ()
				return nil
			end
		}
	end

	self.playerProfile = player_profile

	local minacalc_pkg = package_manager:getPackage("msd_calculator")
	local etterna_msd = minacalc_pkg and require("minacalc.etterna_msd") or {
		getMsdFromData = function ()
			return nil
		end,
		simplifySsr = function ()
			return "minacalc not installed"
		end
	}

	self.etternaMsd = etterna_msd

	local manip_factor_pkg = package_manager:getPackage("manip_factor")
	self.manipFactor = manip_factor_pkg and require("manip_factor") or nil
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
