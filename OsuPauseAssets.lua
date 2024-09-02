local Assets = require("osu_ui.models.AssetModel.Assets")

---@class osu.ui.OsuPauseAssets : osu.ui.Assets
---@operator call: osu.ui.OsuPauseAssets
---@field skinPath string
---@field images table<string, love.Image>
---@field sounds table<string, audio.Source?>
local OsuPauseAssets = Assets + {}

---@param path string
function OsuPauseAssets:new(path)
	self.defaultsDirectory = "osu_ui/assets/"

	self.images = {
		overlay = self:loadImageOrDefault(path, "pause-overlay"),
		overlayFail = self:loadImageOrDefault(path, "fail-background"),
		continue = self:loadImageOrDefault(path, "pause-continue"),
		retry = self:loadImageOrDefault(path, "pause-retry"),
		back = self:loadImageOrDefault(path, "pause-back"),
	}

	self.sounds = {
		loop = self:loadAudioOrDefault(path, "pause-loop"),
		continueClick = self:loadAudioOrDefault(path, "pause-continue-click"),
		retryClick = self:loadAudioOrDefault(path, "pause-retry-click"),
		backClick = self:loadAudioOrDefault(path, "pause-back-click"),
	}
end

return OsuPauseAssets
