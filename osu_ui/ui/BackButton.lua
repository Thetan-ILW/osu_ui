local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@class osu.ui.BackButton : osu.ui.UiElement
---@operator call: osu.ui.BackButton
---@field alpha number
---@field private hoverState osu.ui.HoverState
---@field private openAnimation number
---@field private label love.Text
---@field private onClick function
---@field private image love.Image
---@field private clickSound audio.Source
---@field private hoverSound audio.Source
---@field private canvas love.Canvas
---@field private canvasScale number
local BackButton = UiElement + {}

local main_color = { 0.93, 0.2, 0.6 }
local open_color = { 0.73, 0.06, 0.47 }
local polygon1 = { -50, 0, 33, 0, 25, 45, -50, 45 }
local polygon2 = { 33, 0, 93, 0, 85, 45, 25, 45 }

---@param assets osu.ui.OsuAssets
---@param params { hoverArea: {w: number, h: number} }
---@param on_click function
function BackButton:new(assets, params, on_click)
	UiElement.new(self, params)
	self.assets = assets
	local font = self.assets.localization.fontGroups.misc.backButton
	self.label = love.graphics.newText(font, "back")

	self.hoverW = params.hoverArea.w
	self.hoverH = params.hoverArea.h
	self.hoverState = HoverState("elasticout", 0.7)
	self.openAnimation = 0
	self.onClick = on_click
	self.canvasScale = love.graphics.getHeight() / 768
	self.totalW = 160 * self.canvasScale
	self.totalH = 45 * self.canvasScale
	self.canvas = love.graphics.newCanvas(self.totalW, self.totalH)
	self.alpha = 1
	self.image = assets.images.menuBackArrow
	self.clickSound = assets.sounds.menuBack
	self.hoverSound = assets.sounds.hoverOverRect
end

function BackButton:mouseInput(has_focus)
	local hover, animation, just_hovered = self.hoverState:check(self.hoverW, self.hoverH, 0, 0, has_focus)
	self.openAnimation = animation

	if just_hovered then
		ui.playSound(self.hoverSound)
	end

	if hover and ui.mousePressed(1) then
		self.onClick()
		ui.playSound(self.clickSound)
	end
end

local gfx = love.graphics

function BackButton:draw()
	local prev_canvas = gfx.getCanvas()

	gfx.setCanvas(self.canvas)
	gfx.push()
	gfx.origin()
	gfx.clear()
	local sx = 1 + (self.openAnimation * 0.2)
	local gs = self.canvasScale
	local s = 768 / gfx.getHeight()
	gfx.scale(sx * gs, gs)

	local a = self.openAnimation
	gfx.setColor(
		main_color[1] - (main_color[1] - open_color[1]) * a,
		main_color[2] - (main_color[2] - open_color[2]) * a,
		main_color[3] - (main_color[3] - open_color[3]) * a
	)

	gfx.translate(23 * self.openAnimation, 0)
	gfx.polygon("fill", polygon1)
	gfx.polygon("line", polygon1)
	gfx.setColor(main_color)
	gfx.polygon("fill", polygon2)
	gfx.polygon("line", polygon2)
	gfx.setColor(open_color)
	gfx.setLineStyle("smooth")
	gfx.setLineWidth(1)
	gfx.line(31, -1, 23, 46)

	gfx.pop()
	gfx.setColor(1, 1, 1)

	gfx.push()
	gfx.origin()
	gfx.scale(gs, gs)
	local _, ih = self.image:getDimensions()
	local x, y = 2 + 20 * self.openAnimation, (self.totalH * s) / 2 - ih / 2
	gfx.draw(self.image, x, y)

	gfx.scale(1, 1)
	ui.textFrameShadow(self.label, 25 + 30 * self.openAnimation, 0, 69 * sx, 45, "center", "center")
	gfx.pop()

	gfx.setCanvas({ prev_canvas, stencil = true })
	gfx.setColor(1, 1, 1, self.alpha)
	gfx.draw(self.canvas, 0, 0, 0, s, s)
end

return BackButton
