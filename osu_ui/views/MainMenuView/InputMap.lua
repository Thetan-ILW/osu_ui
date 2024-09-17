local InputMap = require("osu_ui.InputMap")

local actions = require("osu_ui.actions")

---@class osu.ui.MainMenuInputMap : osu.ui.InputMap
---@operator call: osu.ui.MainMenuInputMap
local MainMenuInputMap = InputMap + {}

---@param mv osu.ui.MainMenuView
function MainMenuInputMap:createBindings(mv)
	self.view = {
		["pauseMusic"] = function()
			mv.game.previewModel:stop()
		end,
		["quit"] = function()
			mv:sendQuitSignal()
		end,
		["increaseVolume"] = function()
			mv.gameView:changeVolume(1)
		end,
		["decreaseVolume"] = function()
			mv.gameView:changeVolume(-1)
		end,
		["showSettings"] = function()
			mv:toggleSettings()
		end,
		["play"] = function()
			mv.viewConfig:processLogoState(mv, "logo_click")
		end,
		["insertMode"] = function()
			actions.setVimMode("Insert")
		end,
		["normalMode"] = function()
			actions.setVimMode("Normal")
		end,
	}
end

return MainMenuInputMap
