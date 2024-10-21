local Container = require("osu_ui.ui.Container")
local CanvasContainer = require("osu_ui.ui.CanvasContainer")

local Image = require("osu_ui.ui.Image")

---@class TestViewContainer : osu.ui.Container
---@operator call: TestViewContainer
---@field assets osu.ui.Assets
local View = Container + {}

function View:load()
	Container.load(self)
	local assets = self.assets


	local canvas = self:addChild("canvas", CanvasContainer({
		totalW = 300,
		totalH = 300
	}))
	---@cast canvas osu.ui.CanvasContainer

	canvas:addChild("background", Image({
		image = assets.images.osuLogo,
		transform = love.math.newTransform(0, 0),
		origin = { x = 0, y = 0 },
		depth = 0,
	}))

	canvas:addChild("img", Image({
		image = assets.images.generalTab,
		transform = love.math.newTransform(0, 0),
		depth = 0.1,
	}))

	canvas:build()
	self:build()
end

return View
