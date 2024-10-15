local Assets = require("osu_ui.models.AssetModel.Assets")

---@class osu.ui.OsuPauseAssets : osu.ui.Assets
---@operator call: osu.ui.OsuPauseAssets
---@field skinPath string
---@field images {[string]: love.Image}
---@field sounds {[string]: audio.Source}
local OsuPauseAssets = Assets + {}

local images = {
	overlay = "pause-overlay",
	overlayFail = "fail-background",
	continue = "pause-continue",
	retry = "pause-retry",
	back = "pause-back",
}

local sounds = {
	loop = "pause-loop",
	hoverOverRect = "click-short",
	continueClick = "pause-continue-click",
	retryClick = "pause-retry-click",
	backClick = "pause-back-click",
}

---@param asset_model osu.ui.AssetModel
---@param path string
function OsuPauseAssets:new(asset_model, path)
	self.assetModel = asset_model
	self:setPaths(path, "osu_ui/assets")
end

function OsuPauseAssets:load()
	self:setFileList()
	self.images = {}
	self.sounds = {}

	self:populateImages(images, self.images)
	self:populateSounds(sounds, self.sounds)
end

return OsuPauseAssets
