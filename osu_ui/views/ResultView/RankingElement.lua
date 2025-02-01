local Component = require("ui.Component")
local Image = require("ui.Image")
local ImageValueView = require("osu_ui.ui.ImageValueView")
local flux = require("flux")

---@class osu.ui.ResultView.RankingElement : ui.Component
---@operator call: osu.ui.ResultView.RankingElement
---@field imgName string?
---@field value number?
---@field format string?
---@field delay number?
---@field dontCeil boolean?
---@field targetImageScale number?
local RankingElement = Component + {}

function RankingElement:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.assets = scene.assets

	self.format = self.format or "%i"
	self.delay = self.delay or 0
	self.targetImageScale = self.targetImageScale or 0.5
	self.transitionTime = 1.2

	self.tweens = {}

	if self.imgName then
		self:addImage()
	end

	if self.value then
		self:addValue()
	end

	if not self.playAnimation then
		self:stopAnimation()
	end
end

function RankingElement:stopAnimation()
	for _, v in ipairs(self.tweens) do
		v:stop()
	end
	self.tweens = {}

	if self.imgName then
		self.image.scaleX = self.targetImageScale
		self.image.scaleY = self.targetImageScale
		self.image.alpha = 1
	end
	if self.text then
		self.text:setText(self.format:format(self.value))
		self.text.x = 64
		self.text.alpha = 1
	end
end

---@param image love.Image
function RankingElement:addImage()
	local c = self:addChild("image", Image({
		image = self.assets:loadImage(self.imgName),
		origin = { x = 0.5, y = 0.5 },
		alpha = 0,
		z = 0.1
	}))
	self.image = c

	if self.playAnimation then
		table.insert(self.tweens,
			flux.to(c, 0.3, { scaleX = self.targetImageScale, scaleY = self.targetImageScale, alpha = 1 }):delay(self.delay):ease("cubicin")
		)
	end
end

function RankingElement:addValue()
	local overlap = self.assets.params.scoreOverlap
	local score_font = self.assets.imageFonts.scoreFont
	self.text = self:addChild("text", ImageValueView({
		x = 0,
		y = self.assets.useNewLayout and -25.6 or 40,
		overlap = overlap,
		files = score_font,
		scale = 1.12,
		alpha = 0
	}))

	if self.playAnimation then
		self.displayValue = 0
		table.insert(self.tweens, flux.to(self.text, 0.3, { x = 64, alpha = 1 }):ease("cubicout"):delay(self.delay))
		self:transitionValue()
	end
end

function RankingElement:transitionValue()
	table.insert(self.tweens, flux.to(self, self.transitionTime, { displayValue = self.value }):ease("cubicout"):delay(self.delay):onupdate(function ()
		local v = self.dontCeil and self.displayValue or math.ceil(self.displayValue)
		self.text:setText(self.format:format(v))
	end))
end

function RankingElement:setValue(value)
	self:stopAnimation()
	self.delay = 0
	self.transitionTime = 0.4
	self.displayValue = self.value
	self.value = value
	self:transitionValue()
end

function RankingElement:fade(alpha)
	if self.alphaTween then
		self.alphaTween:stop()
	end
	---@type table
	self.alphaTween = flux.to(self, 0.4, { alpha = alpha }):ease("cubicout")
end

return RankingElement
