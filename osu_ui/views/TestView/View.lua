local Container = require("osu_ui.ui.Container")

local Image = require("osu_ui.ui.Image")

---@class TestViewContainer : osu.ui.Container
---@operator call: TestViewContainer
---@field assets osu.ui.OsuAssets
local View = Container + {}

function View:load()
	Container.load(self)
	local assets = self.assets

	local bg = self:addChild("background", Image({
		image = assets.images.osuLogo,
	}))

	self:build()
end

return View
