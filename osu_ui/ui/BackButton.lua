local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")
local Label = require("osu_ui.ui.Label")

local ui = require("osu_ui.ui")

---@alias BackButtonParams { hoverWidth: number, hoverHeight: number, assets: osu.ui.OsuAssets, text: string }

---@class osu.ui.BackButton : osu.ui.UiElement
---@overload fun(params: BackButtonParams): osu.ui.BackButton
---@field private assets osu.ui.OsuAssets
---@field private text string
---@field private label osu.ui.Label
---@field private arrowImage love.Image
---@field private clickSound audio.Source
---@field private hoverSound audio.Source
---@field private canvas love.Canvas
---@field private canvasScale number
---@field private onClick function
local BackButton = UiElement + {}

local inactive_color = { 238 / 255, 51 / 255, 153 / 255 }
local active_color = { 187 / 255, 17 / 255, 119 / 255 }

function BackButton:load()
	self.arrowImage = self.assets:loadImage("menu-back-arrow")
	self.layerImage = self.assets:loadImage("back-button-layer")
	self.clickSound = self.assets:loadAudio("menuback")
	self.hoverSound = self.assets:loadAudio("menuclick")

	self.hoverState = HoverState("elasticout", 0.7)
	self.totalW = 93
	self.totalH = 45

	self.label = Label({
		alignY = "center",
		totalH = self.totalH,
		text = self.text,
		textScale  = self.parent.textScale,
		font = self.assets:loadFont("Regular", 20)
	})
	self.label:load()

	UiElement.load(self)
end

function BackButton:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
end

function BackButton:justHovered()
	ui.playSound(self.hoverSound)
end

function BackButton:mousePressed()
	if self.mouseOver then
		self.onClick()
		ui.playSound(self.clickSound)
		return true
	end
	return false
end

local gfx = love.graphics

function BackButton:draw()
	local progress = self.hoverState.progress

	gfx.push()
	gfx.translate(42 * progress - 64, 0)
	gfx.setColor(inactive_color[1], inactive_color[2], inactive_color[3], self.alpha)
	gfx.draw(self.layerImage)
	gfx.pop()

	gfx.push()
	gfx.translate(28 * progress - 124, 0)
	gfx.setColor(
		inactive_color[1] - (inactive_color[1] - active_color[1]) * progress,
		inactive_color[2] - (inactive_color[2] - active_color[2]) * progress,
		inactive_color[3] - (inactive_color[3] - active_color[3]) * progress,
		self.alpha
	)
	gfx.draw(self.layerImage)
	gfx.pop()

	gfx.setColor(1, 1, 1)
	gfx.push()
	gfx.translate(34 * progress + 40, 1)
	self.label:draw()
	gfx.pop()

	gfx.setColor(1, 1, 1, self.alpha)

	local iw, ih = self.arrowImage:getDimensions()
	gfx.draw(self.arrowImage, 12 * progress + 14, self.totalH / 2, 0, 1, 1, iw / 2, ih / 2)
end

return BackButton
