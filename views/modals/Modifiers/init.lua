local Modal = require("osu_ui.views.modals.Modal")
local ViewConfig = require("osu_ui.views.modals.Modifiers.ViewConfig")

---@class osu.ui.ModifierModal : osu.ui.Modal
---@operator call: osu.ui.ModifierModal
local ModifierModal = Modal + {}

ModifierModal.name = "Modifiers"

function ModifierModal:new(game, assets)
	self.game = game
	self.viewConfig = ViewConfig(game, assets, self)
end

return ModifierModal
