local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@alias BackButtonParams { text: string, font: love.Font, arrowImage: love.Image, hoverWidth: number, hoverHeight: number, clickSound: audio.Source, hoverSound: audio.Source }

---@class osu.ui.BackButton : osu.ui.UiElement
---@overload fun(params: BackButtonParams): osu.ui.BackButton
---@field private label love.Text
---@field private text string
---@field private font love.Font
---@field private arrowImage love.Image
---@field private clickSound audio.Source
---@field private hoverSound audio.Source
---@field private canvas love.Canvas
---@field private canvasScale number
---@field private onClick function
local BackButton = UiElement + {}

local main_color = { 0.93, 0.2, 0.6 }
local open_color = { 0.73, 0.06, 0.47 }
local polygon1 = { -50, 0, 33, 0, 25, 45, -50, 45 }
local polygon2 = { 33, 0, 93, 0, 85, 45, 25, 45 }

function BackButton:load()
	assert(self.arrowImage, "arrowImage was not provided")
	assert(self.clickSound, "clickSound was not provided")
	assert(self.hoverSound, "hoverSound was not provided")
	assert(self.font, "font was not provided")
	self.label = love.graphics.newText(self.font, self.text or "back")
	self.hoverState = HoverState("elasticout", 0.7)
	self.totalW = 93
	self.totalH = 45
	UiElement.load(self)
end

function BackButton:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
end

function BackButton:justHovered()
	ui.playSound(self.hoverSound)
end

function BackButton:mousePressed()
	self.onClick()
	ui.playSound(self.clickSound)
	return true
end

local gfx = love.graphics

function BackButton:draw()
	local progress = self.hoverState.progress

	gfx.setColor(
		main_color[1] - (main_color[1] - open_color[1]) * progress,
		main_color[2] - (main_color[2] - open_color[2]) * progress,
		main_color[3] - (main_color[3] - open_color[3]) * progress,
		self.alpha
	)

	gfx.translate(23 * progress, 0)
	gfx.polygon("fill", polygon1)
	gfx.polygon("line", polygon1)
	gfx.setColor(main_color[1], main_color[2], main_color[3], self.alpha)
	gfx.polygon("fill", polygon2)
	gfx.polygon("line", polygon2)
	gfx.setColor(open_color[1], open_color[2], open_color[3], self.alpha)
	gfx.setLineStyle("smooth")
	gfx.setLineWidth(1)
	gfx.line(31, -1, 23, 46)

	gfx.setColor(1, 1, 1, self.alpha)

	local iw, ih = self.arrowImage:getDimensions()
	gfx.draw(self.arrowImage, 12 - (progress * 10), self.totalH / 2, 0, 1, 1, iw / 2, ih / 2)

	ui.textFrameShadow(self.label, 25, 0, 69, 45, "center", "center")
end

return BackButton
