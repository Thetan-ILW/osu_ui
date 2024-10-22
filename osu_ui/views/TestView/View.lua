local Container = require("osu_ui.ui.Container")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local Image = require("osu_ui.ui.Image")
local Label = require("osu_ui.ui.Label")

---@class TestViewContainer : osu.ui.Container
---@operator call: TestViewContainer
---@field assets osu.ui.OsuAssets
local View = Container + {}

function View:updateTransform()
	self:forEachChild(function(child)
		child.alpha = (1 + math.sin(love.timer.getTime() * 3)) / 2
	end)
end

function View:load()
	Container.load(self)
	local assets = self.assets

	local scroll = self:addChild("scroll", ScrollAreaContainer({
		scrollLimit = self.parent.totalH * 0.5,
		width = self.parent.totalW,
		height = self.parent.totalH * 1.5
	}))
	---@cast scroll osu.ui.ScrollAreaContainer

	scroll:addChild("background", Image({
		image = assets.images.osuLogo,
	}))

	scroll:addChild("img", Image({
		image = assets.images.generalTab,
		depth = 0.1,
		blockMouseFocus = true
	}))

	local label = scroll:addChild("label", Label({
		text = "Hello, World!",
		font = assets.localization.fontGroups.songSelect.chartName,
		hoverSound = assets.sounds.hoverOverRect,
		depth = 0.5,
		blockMouseFocus = true,
		transform = love.math.newTransform(200, 0)
	}))

	function label:updateTransform()
		label:resetTransform()
		label.transform:apply(love.math.newTransform(math.sin(love.timer.getTime()) * 200, 0))
	end

	scroll:build()
	self:build()
end

return View
