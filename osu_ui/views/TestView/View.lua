local Component = require("ui.Component")
local Image = require("ui.Image")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Label = require("ui.Label")

---@class TestViewContainer : ui.Component
---@operator call: TestViewContainer
---@field assets osu.ui.OsuAssets
local View = Component + {}

function View:bindEvents()
	self.parent:bindEvent(self, "viewportResized")
end

function View:viewportResized()
	self.children = {}
	self:load()
end

function View:load()
	local assets = self.assets
	local viewport = self:getViewport()
	local fonts = viewport:getFontManager()
	local width, height = self.parent:getDimensions()

	self.width, self.height = width, height
	self.textScale = fonts:getTextDpiScale()
	self.blockMouseFocus = false

	local area = self:addChild("scroll", ScrollAreaContainer({
		width = width,
		height = height,
		scrollLimit = 300
	}))

	area:addChild("label", Label({
		x = width / 2, y = height / 2,
		origin = { x = 0.5, y = 0.5 },
		font = fonts:loadFont("Regular", 76),
		text = "wassup"
	}))

	area:addChild("left_top", Image({
		image = assets:loadImage("mania-hit300"),
	}))
	area:addChild("left_bottom", Image({
		y = height,
		origin = { y = 1 },
		image = assets:loadImage("mania-hit300"),
	}))
	area:addChild("right_top", Image({
		x = width,
		origin = { x = 1 },
		image = assets:loadImage("mania-hit300"),
	}))
	area:addChild("right_bottom", Image({
		x = width,
		y = height,
		origin = { x = 1, y = 1 },
		image = assets:loadImage("mania-hit300"),
	}))
end

return View
