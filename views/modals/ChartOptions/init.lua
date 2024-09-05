local Modal = require("osu_ui.views.modals.Modal")

local ViewConfig = require("osu_ui.views.modals.ChartOptions.ViewConfig")

---@class osu.ui.ChartOptionsModal : osu.ui.Modal
---@operator call: osu.ui.ChartOptionsModal
local ChartOptionsModal = Modal + {}

ChartOptionsModal.name = "Chart options"

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ChartOptionsModal:new(game, assets)
	self.game = game
	self.viewConfig = ViewConfig(game, self, assets)
	self.viewConfig:resolutionUpdated()
end

return ChartOptionsModal
