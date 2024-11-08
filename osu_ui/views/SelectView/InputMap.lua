local InputMap = require("osu_ui.InputMap")
local actions = require("osu_ui.actions")

---@class osu.ui.SelectInputMap : osu.ui.InputMap
---@operator call: osu.ui.SelectInputMap
local SelectInputMap = InputMap + {}

---@param sv osu.ui.SelectView
function SelectInputMap:createBindings(sv)
	self.selectModals = {
		["showMods"] = function()
			sv:openModal("osu_ui.views.modals.Modifiers")
		end,
		["showSkins"] = function()
			sv:openModal("osu_ui.views.modals.SkinSettings")
		end,
		["showInputs"] = function()
			sv:openModal("osu_ui.views.modals.Inputs")
		end,
		["showFilters"] = function()
			sv:openModal("osu_ui.views.modals.Filters")
		end,
		["showSettings"] = function()
			sv:toggleSettings()
		end,
	}

	self.select = {
		["random"] = function()
			--sv.selectModel:scrollRandom()
			--sv.lists.list:followSelection()
		end,
		["autoPlay"] = function()
			sv.game.rhythmModel:setAutoplay(true)
			sv:play()
		end,
		["decreaseTimeRate"] = function()
			sv:changeTimeRate(-1)
		end,
		["increaseTimeRate"] = function()
			sv:changeTimeRate(1)
		end,
		["play"] = function()
			sv:play()
		end,
		["openEditor"] = function()
			sv:edit()
		end,
		["openResult"] = function()
			sv:result()
		end,
		["exportToOsu"] = function()
			sv.game.selectController:exportToOsu()
		end,
	}

	self.view = {
		["pauseMusic"] = function()
			sv.game.previewModel:stop()
		end,
		["quit"] = function()
			sv:sendQuitSignal()
		end,
	}

	self.music = {
		["pauseMusic"] = function()
			sv.game.previewModel:stop()
		end,
		["increaseVolume"] = function()
			sv.ui.globalEvents:changeVolume(1)
		end,
		["decreaseVolume"] = function()
			sv.ui.globalEvents:changeVolume(-1)
		end,
		["insertMode"] = function()
			actions.setVimMode("Insert")
		end,
		["normalMode"] = function()
			actions.setVimMode("Normal")
		end,
	}
end

return SelectInputMap
