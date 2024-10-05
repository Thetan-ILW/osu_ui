local InputMap = require("osu_ui.InputMap")

---@class osu.ui.ResultInputMap : osu.ui.InputMap
---@operator call: osu.ui.ResultInputMap
local ResultInputMap = InputMap + {}

function ResultInputMap:createBindings(view)
	self.view = {
		["retry"] = function()
			view:play("retry")
		end,
		["watchReplay"] = function()
			view:play("replay")
		end,
		["submitScore"] = function()
			view:submitScore()
		end,
		["quit"] = function()
			view:sendQuitSignal()
		end,
		["increaseVolume"] = function()
			view.ui.globalEvents:changeVolume(1)
		end,
		["decreaseVolume"] = function()
			view.ui.globalEvents:changeVolume(-1)
		end,
	}
end

return ResultInputMap
