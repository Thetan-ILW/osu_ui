local Component = require("ui.Component")
local Image = require("ui.Image")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

---@class TestViewContainer : ui.Component
---@operator call: TestViewContainer
---@field assets osu.ui.OsuAssets
local View = Component + {}

function View:bindEvents()
	self:bindEvent("viewportResized")
	self:bindEvent("wheelUp")
end

function View:wheelUp()
	print("up!")
	return true
end

function View:viewportResized()
	self:clearTree()
	self:load()
end

function View:load()
	local assets = self.assets
	local width, height = self.parent:getDimensions()

	self.width, self.height = width, height

	local area = self:addChild("scroll", ScrollAreaContainer({
		width = width,
		height = height,
		scrollLimit = 300
	}))

	self:addChild("img", Image({
		image = love.graphics.newImage("screenshot205.png"),
		z = 0.1,
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
