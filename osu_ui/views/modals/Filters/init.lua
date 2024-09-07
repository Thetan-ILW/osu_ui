local Modal = require("osu_ui.views.modals.Modal")
local ViewConfig = require("osu_ui.views.modals.Filters.ViewConfig")

---@class osu.ui.FiltersModal : osu.ui.Modal
---@operator call: osu.ui.FiltersModal
local FiltersModal = Modal + {}

FiltersModal.name = "Filters"

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function FiltersModal:new(game, assets)
	self.viewConfig = ViewConfig(game, self, assets)
end

return FiltersModal
