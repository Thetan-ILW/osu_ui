local InputMap = require("osu_ui.InputMap")

local math_util = require("math_util")

---@class osu.ui.MainMenuInputMap : osu.ui.InputMap
---@operator call: osu.ui.MainMenuInputMap
local MainMenuInputMap = InputMap + {}

---@param mv osu.ui.MainMenuView
---@param delta number
local function increaseVolume(mv, direction)
	local configs = mv.game.configModel.configs
	local settings = configs.settings
	local a = settings.audio
	local v = a.volume

	v.master = math_util.clamp(v.master + (direction * 0.05), 0, 1)

	mv.notificationView:show(("Volume: %i%%"):format(v.master * 100), true)
	mv.assetModel:updateVolume()
end

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
			increaseVolume(mv, 1)
		end,
		["decreaseVolume"] = function()
			increaseVolume(mv, -1)
		end,
		["showSettings"] = function()
			mv:toggleSettings()
		end,
		["play"] = function()
			mv.viewConfig:processLogoState(mv, "logo_click")
		end,
	}
end

return MainMenuInputMap
