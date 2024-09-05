local InputMap = require("osu_ui.InputMap")

local math_util = require("math_util")

---@class osu.ui.SelectInputMap : osu.ui.InputMap
---@operator call: osu.ui.SelectInputMap
local SelectInputMap = InputMap + {}

---@param sv osu.ui.SelectView
---@param delta number
local function increaseVolume(sv, direction)
	local configs = sv.game.configModel.configs
	local settings = configs.settings
	local a = settings.audio
	local v = a.volume

	v.master = math_util.clamp(v.master + (direction * 0.05), 0, 1)

	sv.assetModel:updateVolume()
end

---@param sv osu.ui.SelectView
function SelectInputMap:createBindings(sv)
	self.selectModals = {
		["showMods"] = function() end,
		["showSkins"] = function() end,
		["showInputs"] = function() end,
		["showFilters"] = function()
			sv:openModal("osu_ui.views.modals.Filters")
		end,
		["showSettings"] = function()
			sv:toggleSettings()
		end,
	}

	self.select = {
		["random"] = function()
			sv.selectModel:scrollRandom()
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
			sv:select()
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
		["moveScreenLeft"] = function()
			sv:changeGroup("charts")
		end,
		["moveScreenRight"] = function()
			sv:changeGroup("last_visited_locations")
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
			increaseVolume(sv, 1)
		end,
		["decreaseVolume"] = function()
			increaseVolume(sv, -1)
		end,
	}
end

return SelectInputMap
