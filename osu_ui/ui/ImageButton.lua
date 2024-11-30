local Component = require("ui.Component")
local HoverState = require("ui.HoverState")

local ui = require("osu_ui.ui")

---@alias osu.ui.ImageButtonParams { idleImage: love.Image, animationImage: love.Image[], framerate: number?, hoverImage: love.Image?, hoverWidth: number, hoverHeight: number, hoverSound: audio.Source?, clickSound: audio.Source?, onClick: function? }

---@class osu.ui.ImageButton : ui.Component
---@overload fun(table: osu.ui.ImageButtonParams): osu.ui.ImageButton
---@field private idleImage love.Image?
---@field private animationImage love.Image[]?
---@field private frameCount number?
---@field private framerate number?
---@field private hoverImage love.Image?
---@field private imageType "image" | "animation"
---@field private hoverWidth number
---@field private hoverHeight number
---@field private hoverSound audio.Source?
---@field private clickSound audio.Source?
---@field private onClick function
local ImageButton = Component + {}

function ImageButton:load()
	self.onClick = self.onClick or function ()
		print("Useless button: " .. self.id)
	end
	self.hoverState = HoverState("quadout", 0.15)
	self.imageType = self.animationImage and "animation" or "image"

	if self.imageType == "image" then
		if not self.idleImage then
			error(debug.traceback("No idle image was provided to ImageButton"))
		end

		self.width, self.height = self.idleImage:getDimensions()

		if self.hoverImage then
			local w, h = self.hoverImage:getDimensions()
			self.width, self.height = math.max(w, self.width), math.max(h, self.height)
		end

		self.draw = self.drawImage
	else
		self:assert(self.animationImage[1], "No animation was provided")
		self.width, self.height = self.animationImage[1]:getDimensions()
		self.frameCount = #self.animationImage
		self.framerate = self.framerate == -1 and self.frameCount or self.framerate
		self.draw = self.drawAnimation
	end

	self.hoverWidth = self.hoverWidth or self.width
	self.hoverHeight = self.hoverHeight or self.height
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
	self.mouseOver = self.hoverState:checkMouseFocus(self.hoverWidth, self.hoverHeight, mx, my)
end

function ImageButton:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

local gfx = love.graphics

function ImageButton:drawAnimation()
	local r, g, b, a = gfx.getColor()
	local frame = 1 + math.floor((love.timer.getTime() * self.framerate) % self.frameCount)
	local img = self.animationImage[frame]
	local c = ui.lighten({ r, g, b, a }, self.hoverState.progress * 0.3)
	gfx.setColor(c[1], c[2], c[3], c[4])
	gfx.draw(img)
end

function ImageButton:drawImage()
	local r, g, b, a = gfx.getColor()
	if self.hoverImage then
		gfx.draw(self.idleImage)
		gfx.setColor(r, g, b, a * self.hoverState.progress)
		gfx.draw(self.hoverImage)
		return
	end

	local c = ui.lighten({ r, g, b, a }, self.hoverState.progress * 0.3)
	gfx.setColor(c[1], c[2], c[3], c[4])
	gfx.draw(self.idleImage)
end

return ImageButton
