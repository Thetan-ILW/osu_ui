local UiElement = require("osu_ui.ui.UiElement")

local ui = require("osu_ui.ui")
local HoverState = require("osu_ui.ui.HoverState")
local Label = require("osu_ui.ui.Label")

---@alias ButtonParams { text: string, font: love.Font, imageLeft: love.Image, imageMiddle: love.Image, imageRight: love.Image, hoverSound: audio.Source }

---@class osu.ui.Button : osu.ui.UiElement
---@operator call: osu.ui.Button
---@field private label osu.ui.Label
---@field private middleImgScale number
---@field private heightScale number
---@field private imageLeft love.Image
---@field private imageMiddle love.Image
---@field private imageRight love.Image
---@field private hoverSound audio.Source?
---@field private mouseDown boolean
---@field private onClick function
local Button = UiElement + {}

function Button:load()
	assert(self.imageLeft, "imageLeft was not provided")
	assert(self.imageMiddle, "imageMiddle was not provided")
	assert(self.imageRight, "imageRight was not provided")

	self.totalW = self.totalW or 737
	self.totalH = self.totalH or 65

	self.label = Label({
		totalW = self.totalW,
		totalH = self.totalH,
		text = self.text,
		font = self.font,
		shadow = true,
		alignX = "center",
		alignY = "center",
		textScale = self.parent.textScale
	})
	self.label:load()

	self.heightScale = self.totalH / self.imageMiddle:getHeight()
	local borders_width = self.imageLeft:getWidth() * self.heightScale + self.imageRight:getWidth() * self.heightScale
	self.middleImgScale = (self.totalW - borders_width) / self.imageMiddle:getWidth()

	self.hoverState = HoverState("quadout", 0.2)
	UiElement.load(self)
end

function Button:bindEvents()
	self.parent:bindEvent(self, "mouseClick")
end

function Button:justHovered()
	if self.hoverSound then
		ui.playSound(self.hoverSound)
	end
end

function Button:mouseClick()
	if self.mouseOver then
		self.onClick()
		return true
	end
	return false
end

local gfx = love.graphics

function Button:draw()
	local left = self.imageLeft
	local middle = self.imageMiddle
	local right = self.imageRight

	local amount = self.hoverState.progress * 0.3
	local c = ui.lighten(self.color, amount)

	gfx.setColor(c[1], c[2], c[3], c[4] * self.alpha)

	gfx.push()
	gfx.draw(left, 0, 0, 0, self.heightScale, self.heightScale)
	gfx.translate(left:getWidth() * self.heightScale, 0)
	gfx.draw(middle, 0, 0, 0, self.middleImgScale, self.heightScale)
	gfx.translate(middle:getWidth() * self.middleImgScale, 0)
	gfx.draw(right, 0, 0, 0, self.heightScale, self.heightScale)
	gfx.pop()

	gfx.push()
	self.label.alpha = self.alpha
	self.label:draw()
	gfx.pop()
end

return Button
