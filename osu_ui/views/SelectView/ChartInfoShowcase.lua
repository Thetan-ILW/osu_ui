local Component = require("ui.Component")

local Image = require("ui.Image")
local Label = require("ui.Label")
local Blur = require("ui.Blur")

local flux = require("flux")

---@class osu.ui.ChartInfoShowcase : ui.Component
---@operator call: osu.ui.ChartInfoShowcase
---@field assets osu.ui.OsuAssets
local ChartInfoShowcase = Component + {}

function ChartInfoShowcase:viewportResized()
	self:clearTree()
	self:load()
end

function ChartInfoShowcase:load()
	self.width, self.height = self.parent:getDimensions()
	local assets = self.shared.assets
	local fonts = self.shared.fontManager

	local image = self:addChild("image", Image({
		x = self.width / 2,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("background-panel"),
		z = 0.5
	}))
	---@cast image ui.Image
	self.image = image

	function self.image:draw()
		love.graphics.draw(self.image)
	end

	self.chartName = self:addChild("chartName", Label({
		y = self.height / 2 + 130,
		origin = { x = 0.5, y = 0 },
		font = fonts:loadFont("Bold", 56),
		text = "chartName",
		z = 0.5,
	}))

	self.chartInfo = self:addChild("chartInfo", Label({
		y = self.height / 2 + 200,
		origin = { x = 0.5, y = 0 },
		font = fonts:loadFont("Regular", 32),
		text = "chartInfo",
		z = 0.5,
	}))

	self:addChild("blur", Blur({
		percent = 0.4,
	}))
end

function ChartInfoShowcase:show(chart_name, chart_info, image)
	local text_scale = math.min(1, (self.width - 40) / self.chartName.font:getWidth(chart_name))

	self.chartName.scaleX = text_scale
	self.chartName.scaleY = text_scale
	self.chartName:replaceText(chart_name)
	self.chartInfo:replaceText(chart_info)
	local scale = 253 / image:getHeight()
	self.image.scaleX = scale
	self.image.scaleY = scale
	self.image:replaceImage(image)

	self.tween = flux.to(self, 0.4, { alpha = 1 }):ease("quadout")
	self.disabled = false
end

function ChartInfoShowcase:hide()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.4, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self.disabled = true
	end)
end

function ChartInfoShowcase:update(dt, mouse_focus)
	self.image.y = (self.height / 2) * self.alpha
	self.chartName.x = (self.width / 2) * self.alpha
	self.chartInfo.x = self.width - (self.width / 2) * self.alpha
end

return ChartInfoShowcase
