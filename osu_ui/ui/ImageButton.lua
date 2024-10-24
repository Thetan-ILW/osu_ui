local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@alias ImageButtonParams { idleImage: love.Image, animationImage: love.Image[], framerate: number?, hoverImage: love.Image?, hoverWidth: number, hoverHeight: number, hoverSound: audio.Source?, clickSound: audio.Source?, onClick: function? }

---@class osu.ui.ImageButton : osu.ui.UiElement
---@overload fun(table: ImageButtonParams): osu.ui.ImageButton
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
---@field private hoverState osu.ui.HoverState
local ImageButton = UiElement + {}

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

		self.totalW, self.totalH = self.idleImage:getDimensions()

		if self.hoverImage then
			local w, h = self.hoverImage:getDimensions()
			self.totalW, self.totalH = math.max(w, self.totalW), math.max(h, self.totalH)
		end
	else
		if not self.animationImage[1] then
			error(debug.traceback("No animation was provided to ImageButton"))
		end

		self.totalW, self.totalH = self.animationImage[1]:getDimensions()
		self.frameCount = #self.animationImage
		self.framerate = params.framerate == -1 and self.frameCount or params.framerate
	end

	self.hoverWidth = self.hoverWidth or self.totalW
	self.hoverHeight = self.hoverHeight or self.totalH
	UiElement.load(self)
end

function ImageButton:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
end

function ImageButton:justHovered()
	if self.hoverSound then
		ui.playSound(self.hoverSound)
	end
end

---@param event table
function ImageButton:mousePressed(event)
	if self.mouseOver then
		ui.playSound(self.clickSound)
		self.onClick()
		return true
	end
	return false
end

local gfx = love.graphics

function ImageButton:drawAnimation()
	local frame = 1 + math.floor((love.timer.getTime() * self.framerate) % self.frameCount)
	local img = self.animationImage[frame]
	local c = ui.lighten(self.color, self.alpha * self.hoverState.progress * 0.3)
	gfx.setColor(c[1], c[2], c[3], c[4] * self.alpha)
	gfx.draw(img)
end

function ImageButton:draw()
	if self.imageType == "animation" then
		self:drawAnimation()
		return
	end

	local c = self.color

	if self.hoverImage then
		gfx.draw(self.idleImage)
		gfx.setColor(c[1], c[2], c[3], c[4] * self.hoverState.progress * self.alpha)
		gfx.draw(self.hoverImage)
		return
	end

	c = ui.lighten(self.color, self.alpha * self.hoverState.progress * 0.3)
	gfx.setColor(c[1], c[2], c[3], c[4] * self.alpha)
	gfx.draw(self.idleImage)
end

return ImageButton
