local Modal = require("osu_ui.views.modals.Modal")
local ViewConfig = require("osu_ui.views.modals.SkinSettings.ViewConfig")

---@class osu.ui.SkinSettigsModal : osu.ui.Modal
---@operator call: osu.ui.SkinSettigsModal
local SkinSettigsModal = Modal + {}

SkinSettigsModal.name = "Skin settings"

function SkinSettigsModal:new(game, assets)
	self.game = game
	self.inputMode = tostring(self.game.selectController.state.inputMode)
	self.skin = self.game.noteSkinModel:getNoteSkin(self.inputMode)
	self.viewConfig = ViewConfig(game, assets, self)
end

return SkinSettigsModal
