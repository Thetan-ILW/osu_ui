local Modal = require("osu_ui.views.modals.Modal")
local ViewConfig = require("osu_ui.views.modals.Inputs.ViewConfig")

---@class osu.ui.InputsModal : osu.ui.Modal
---@operator call: osu.ui.InputsModal
local InputsModal = Modal + {}

InputsModal.name = "Inputs"

function InputsModal:new(game, assets)
	self.game = game
	self.inputMode = tostring(self.game.selectController.state.inputMode)
	self.viewConfig = ViewConfig(game, assets, self)
end

return InputsModal
