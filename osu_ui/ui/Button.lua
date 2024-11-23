local Component = require("ui.Component")

local ui = require("osu_ui.ui")
local HoverState = require("ui.HoverState")
local Label = require("ui.Label")

---@alias osu.ui.ButtonParams { label: string, font: love.Font }

---@class osu.ui.Button : ui.Component
---@overload fun(params: osu.ui.ButtonParams): osu.ui.Button
---@field label string 
---@field font ui.Font
---@field private middleImgScale number
---@field private heightScale number
---@field private onClick function
local Button = Component + {}

function Button:load()
	local assets = self.shared.assets ---@cast assets osu.ui.OsuAssets
	self.width = self.width or 737
	self.height = self.height or 65
	self.blockMouseFocus = true

	self:addChild("buttonLabel", Label({
		width = self.width,
		height = self.height,
		text = self.label,
		font = self.font,
		shadow = true,
		alignX = "center",
		alignY = "center",
	}))

	self.imageLeft = assets:loadImage("button-left")
	self.imageMiddle = assets:loadImage("button-middle")
	self.imageRight = assets:loadImage("button-right")
	self.hoverSound = assets:loadAudio("click-short")

	self.heightScale = self.height / self.imageMiddle:getHeight()
	local borders_width = self.imageLeft:getWidth() * self.heightScale + self.imageRight:getWidth() * self.heightScale
	self.middleImgScale = (self.width - borders_width) / self.imageMiddle:getWidth()

	self.hoverState = HoverState("quadout", 0.2)
end

function Button:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width, self.height, mx, my)
end

function Button:bindEvents()
	self.parent:bindEvent(self, "mouseClick")
end

function Button:justHovered()
	ui.playSound(self.hoverSound)
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

	local r, g, b, a = gfx.getColor()
	local c = ui.lighten({ r, g, b, a }, amount)
	gfx.setColor(c[1], c[2], c[3], c[4] * self.alpha)

	gfx.push()
	gfx.draw(left, 0, 0, 0, self.heightScale, self.heightScale)
	gfx.translate(left:getWidth() * self.heightScale, 0)
	gfx.draw(middle, 0, 0, 0, self.middleImgScale, self.heightScale)
	gfx.translate(middle:getWidth() * self.middleImgScale, 0)
	gfx.draw(right, 0, 0, 0, self.heightScale, self.heightScale)
	gfx.pop()
end

return Button
