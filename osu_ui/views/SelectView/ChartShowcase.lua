local Component = require("ui.Component")

local Image = require("ui.Image")
local Label = require("ui.Label")
local Blur = require("ui.Blur")
local StencilComponent = require("ui.StencilComponent")

local flux = require("flux")

---@class osu.ui.ChartShowcase : ui.Component
---@operator call: osu.ui.ChartShowcase
local ChartShowcase = Component + {}

function ChartShowcase:load()
	self.width, self.height = self.parent:getDimensions()
	self.chartName = self.chartName or "chartName"
	self.chartInfo = self.chartInfo or "chartInfo"

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	local ratio = 21 / 9
	local c_width = 342 * ratio
	local c_height = 342
	self.stencilContainer = self:addChild("stencil", StencilComponent({
		x = self.width / 2,
		origin = { x = 0.5, y = 0.5 },
		width = c_width,
		height = c_height,
		z = 0.5,
		stencilFunction = function ()
			love.graphics.rectangle("fill", 0, 0, c_width, c_height, 16, 16)
		end
	}))

	if self.image then
		self.stencilContainer:addChild("image", Image({
			x = self.stencilContainer:getWidth() / 2,
			y = self.stencilContainer:getHeight() / 2,
			origin = { x = 0.5, y = 0.5 },
			scale = self.stencilContainer:getWidth() / self.image:getWidth(),
			image = self.image,
			z = 0.5
		}))
	end

	local chart_name_font = fonts:loadFont("Bold", 56)
	local name_scale = math.min(1, (self.width - 40) / chart_name_font:getWidth(self.chartName))
	self.chartNameLabel = self:addChild("chartName", Label({
		y = self.height / 2 + 130,
		origin = { x = 0.5, y = 0 },
		scale = name_scale,
		font = chart_name_font,
		text = self.chartName or "chartName",
		z = 0.5,
	}))

	self.chartInfoLabel = self:addChild("chartInfo", Label({
		y = self.height / 2 + 200,
		origin = { x = 0.5, y = 0 },
		font = fonts:loadFont("Regular", 32),
		text = self.chartInfo or "chartInfo",
		z = 0.5,
	}))

	self:addChild("blur", Blur({
		percent = 0.4,
	}))
end

function ChartShowcase:show(chart_name, chart_info, image)
	self.chartName = chart_name
	self.chartInfo = chart_info
	self.image = image
	self:clearTree()
	self:load()

	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.4, { alpha = 1 }):ease("quadout")
end

---@param delay number?
function ChartShowcase:hide(delay)
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.4, { alpha = 0 }):ease("quadout"):delay(delay or 0):oncomplete(function ()
		self:kill()
	end)
end

function ChartShowcase:update()
	self.stencilContainer.y = (self.height / 2 - 80) * self.alpha
	self.chartNameLabel.x = (self.width / 2) * self.alpha
	self.chartInfoLabel.x = self.width - (self.width / 2) * self.alpha
end

return ChartShowcase
