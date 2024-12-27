local Component = require("ui.Component")
local HoverState = require("ui.HoverState")
local math_util = require("math_util")

---@class osu.ui.LogoButtonView : ui.Component
---@operator call: osu.ui.LogoButtonView
---@field idleImage love.Image
---@field hoverImage love.Image
---@field clickSound audio.Source
---@field onClick function
local LogoButton = Component + {}

function LogoButton:load()
	self:assert(self.idleImage, "Provide the idle image")
	self:assert(self.hoverImage, "Provide the hover image")
	self:assert(self.onClick, "Provide the onClick function")
	self.width, self.height = self.idleImage:getDimensions()
	self.hoverState = HoverState("elasticout", 0.7)
	self.hoverImageAlpha = 0
	self.handleEvents = false

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	self.hoverSound = assets:loadAudio("menuclick")
end

function LogoButton:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width, self.height, mx, my)
end

function LogoButton:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

function LogoButton:justHovered()
	self.playSound(self.hoverSound)
end

function LogoButton:mousePressed(event)
	if not self.mouseOver or event[3] ~= 1 then
		return false
	end

	self.playSound(self.clickSound)
	self.onClick()
	return true
end

function LogoButton:update(dt)
	self.x = 10 + self.hoverState.progress * 35
	self.hoverImageAlpha = math_util.clamp(self.hoverImageAlpha + (self.mouseOver and dt * 5 or -dt * 2.5), 0, 1)
end

function LogoButton:draw()
	love.graphics.draw(self.idleImage)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a * self.hoverImageAlpha)
	love.graphics.draw(self.hoverImage)
end

return LogoButton
