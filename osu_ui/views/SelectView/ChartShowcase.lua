local Component = require("ui.Component")

local Image = require("ui.Image")
local Label = require("ui.Label")
local Blur = require("ui.Blur")
local StencilComponent = require("ui.StencilComponent")

local flux = require("flux")
local time_util = require("time_util")

---@class osu.ui.ChartShowcase : ui.Component
---@operator call: osu.ui.ChartShowcase
local ChartShowcase = Component + {}

local y = -40

function ChartShowcase:load()
	self.width, self.height = self.parent:getDimensions()
	self.chartName = self.chartName or "chartName"
	self.chartInfo = self.chartInfo or "chartInfo"

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	local quicksand = fonts:loadFont("QuicksandSemiBold", 26)
	local awesome = fonts:loadFont("Awesome", 26)
	quicksand:addFallback(awesome.instance)

	self.upperContainer = self:addChild("upperContainer", Component({
		x = self.width / 2,
		y = y,
	}))

	self.upperContainer:addChild("chartBackground", Image({
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("showcase-bg")
	}))

	local mods_bg = self.upperContainer:addChild("modsBackground", Image({
		y = 186,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("showcase-mods"),
		color = { 0.14, 0.14, 0.14, 1 }
	}))

	self.upperContainer:addChild("label", Label({
		y = 186,
		origin = { x = 0.5, y = 0.5 },
		boxWidth = mods_bg:getWidth(),
		boxHeight = mods_bg:getHeight(),
		alignX = "center",
		alignY = "center",
		text = self.mods,
		font = quicksand,
		color = { 1, 1, 1, 1 },
		z = 1,
	}))

	local ratio = 21 / 9
	local c_height = 270
	local c_width = c_height * ratio
	local stencil = self.upperContainer:addChild("stencil", StencilComponent({
		origin = { x = 0.5, y = 0.5 },
		width = c_width,
		height = c_height,
		z = 0.5,
		stencilFunction = function ()
			love.graphics.rectangle("fill", 0, 0, c_width, c_height, 12, 12)
		end
	}))

	if self.image then
		stencil:addChild("bg", Image({
			x = stencil:getWidth() / 2,
			y = stencil:getHeight() / 2,
			origin = { x = 0.5, y = 0.5 },
			scale = stencil:getWidth() / self.image:getWidth(),
			image = self.image,
			z = 0.5
		}))
	end

	self.leftContainer = self:addChild("leftContainer", Component({
		y = self.height / 2 + 156 + y,
	}))
	local info_img = self.leftContainer:addChild("image", Image({
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("showcase-info"),
		color = self.lengthColor,
	}))
	self.leftContainer:addChild("label", Label({
		origin = { x = 0.5, y = 0.5 },
		boxWidth = info_img:getWidth(),
		boxHeight = info_img:getHeight(),
		alignX = "center",
		alignY = "center",
		text = self.length,
		font = quicksand,
		color = { 0, 0, 0, 1 },
		z = 1,
	}))

	self.rightContainer = self:addChild("rightContainer", Component({
		y = self.height / 2 + 156 + y,
	}))
	self.rightContainer:addChild("image", Image({
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("showcase-info"),
		color = self.difficultyColor,
	}))
	self.rightContainer:addChild("label", Label({
		origin = { x = 0.5, y = 0.5 },
		boxWidth = info_img:getWidth(),
		boxHeight = info_img:getHeight(),
		alignX = "center",
		alignY = "center",
		text = self.difficulty,
		font = quicksand,
		color = { 0, 0, 0, 1 },
		z = 1,
	}))

	local chart_name_font = fonts:loadFont("Bold", 56)
	local name_scale = math.min(1, (self.width - 40) / chart_name_font:getWidth(self.chartName))
	self.chartNameLabel = self:addChild("chartName", Label({
		x = self.width / 2,
		origin = { x = 0.5, y = 0.5 },
		scale = name_scale,
		font = chart_name_font,
		text = self.chartName or "chartName",
		z = 0.5,
	}))

	self:addChild("blur", Blur({
		percent = 0.4,
		z = -0.01
	}))
end

---@param chart_name string
---@param length number
---@param difficulty string
---@param diff_level 1 | 2 | 3
---@param mods string
---@param image love.Image
function ChartShowcase:show(chart_name, length, difficulty, diff_level, mods, image)
	self.chartName = chart_name
	self.length = (" %s"):format(time_util.format(length))
	self.difficulty = difficulty
	self.mods = mods
	self.image = image

	if mods == "" then
		self.mods = "No modifiers"
	end

	if length < 120 then
		self.lengthColor = { 0.4, 1, 0.38, 1}
	elseif length < 240 then
		self.lengthColor = { 1, 0.92, 0.27, 1 }
	else
		self.lengthColor = { 0.95, 0.13, 0.59, 1 }
	end

	if diff_level == 1 then
		self.difficultyColor = { 0.4, 1, 0.38, 1}
	elseif diff_level == 2 then
		self.difficultyColor = { 1, 0.92, 0.27, 1 }
	else
		self.difficultyColor = { 0.95, 0.13, 0.59, 1 }
	end

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
	self.upperContainer.y = (self.height / 2 - 100 + y) * self.alpha
	self.leftContainer.x = (self.width / 2 - 100) * self.alpha
	self.rightContainer.x = self.width - ((self.width / 2 - 100) * self.alpha)
	self.chartNameLabel.y = self.height - (140 * self.alpha)
end

return ChartShowcase
