local Component = require("ui.Component")
local HoverState = require("ui.HoverState")

local ui = require("osu_ui.ui")

---@alias osu.ui.ImageButtonParams { idleImage: love.Image, animationImage: love.Image[], framerate: number?, hoverImage: love.Image?, hoverWidth: number, hoverHeight: number, hoverSound: audio.Source?, clickSound: audio.Source?, onClick: function? }

---@class osu.ui.ImageButton : ui.Component
---@overload fun(table: osu.ui.ImageButtonParams): osu.ui.ImageButton
---@field private idleImage love.Image?
---@field private hoverImage love.Image?
---@field private imageType "image" | "animation"
---@field private hoverWidth number
---@field private hoverHeight number
---@field private hoverSound audio.Source?
---@field private clickSound audio.Source?
---@field private onClick function
local ImageButton = Component + {}

function ImageButton:load()
	self:assert(self.idleImage, "No idle image was provided to ImageButton")
	self.onClick = self.onClick or function ()
		print("Useless button: " .. self.id)
	end

	self.blockMouseFocus = true
	self.hoverState = HoverState("quadout", 0.15)

	self.width, self.height = self.idleImage:getDimensions()

	if self.hoverImage then
		local w, h = self.hoverImage:getDimensions()
		self.width, self.height = math.max(w, self.width), math.max(h, self.height)
	end
end

function ImageButton:justHovered()
	self.playSound(self.hoverSound)
end

---@param event table
function ImageButton:mousePressed(event)
	if self.mouseOver then
		self.playSound(self.clickSound)
		self.onClick()
		return true
	end
	return false
end

function ImageButton:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width, self.height, mx, my)
end

function ImageButton:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

local gfx = love.graphics

function ImageButton:draw()
	local r, g, b, a = gfx.getColor()

	if self.hoverImage then
		gfx.draw(self.idleImage)
		gfx.setColor(r, g, b, a * self.hoverState.progress)
		gfx.draw(self.hoverImage)
		return
	end

	local p = self.hoverState.progress
	local c = ui.lighten({ r, g, b }, p * 0.3)
	gfx.setColor(c[1], c[2], c[3], math.min(1, a + a * (p * 1.2)))
	gfx.draw(self.idleImage)
end

return ImageButton
