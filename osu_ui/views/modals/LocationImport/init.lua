local Modal = require("osu_ui.views.modals.Modal")
local ViewConfig = require("osu_ui.views.modals.LocationImport.ViewConfig")

---@class osu.ui.LocationImportModal : osu.ui.Modal
---@operator call: osu.ui.LocationImportModal
---@field path string
local LocationImportModal = Modal + {}

LocationImportModal.name = "LocationImport"

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function LocationImportModal:new(game, assets, path)
	self.game = game
	self.path = path
	self.processing = false

	local cache_model = game.cacheModel
	local locationManager = cache_model.locationManager
	local locations = locationManager.locations

	for i, v in ipairs(locations) do
		if v.path == path then
			self.locationId = v.id
			break
		end
	end

	self.viewConfig = ViewConfig(self, assets)
end

function LocationImportModal:update(dt)
	Modal.update(self, dt)

	if not self.processing then
		return
	end

	if self.game.cacheModel.isProcessing then
		return
	end

	self:quit()

	local cache_model = self.game.cacheModel
	local location_manager = cache_model.locationManager
	location_manager:selectLocation(1)
	self.game.selectModel:scrollCollection(nil, -math.huge)
	self.game.ui.gameView:reloadView()
end

return LocationImportModal
