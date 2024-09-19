local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@class osu.ui.ImageButton : osu.ui.UiElement
---@operator call: osu.ui.ImageButton
---@field alpha number
---@field private idleImage love.Image?
---@field private animationImage love.Image[]?
---@field private frameCount number?
---@field private framerate number?
---@field private hoverImage love.Image?
---@field private imageType "image" | "animation"
---@field private ox number
---@field private oy number
---@field private hoverX number
---@field private hoverY number
---@field private hoverWidth number
---@field private hoverHeight number
---@field private hoverSound audio.Source
---@field private clickSound audio.Source
---@field private onClick function
---@field private hoverState osu.ui.HoverState
---@field private hoverShader love.Shader
---@field private animation number
local ImageButton = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param params { idleImage: love.Image, animationImage: love.Image[], framerate: number?, hoverImage: love.Image?, ox:number?, oy: number?, hoverArea: {w: number, h: number}, hoverSound: audio.Source?, clickSound: audio.Source? }
---@param on_click function
function ImageButton:new(assets, params, on_click)
	self.assets = assets
	self.idleImage = params.idleImage
	self.animationImage = params.animationImage
	self.hoverImage = params.hoverImage

	self.hoverWidth = params.hoverArea.w
	self.hoverHeight = params.hoverArea.h

	self.hoverSound = params.hoverSound or self.assets.sounds.hoverOverRect
	self.clickSound = params.clickSound or self.assets.sounds.clickShortConfirm
	self.onClick = on_click
	self.hoverState = HoverState("quadout", 0.15)
	self.hoverShader = assets.shaders.brighten
	self.animation = 0
	self.alpha = 1

	self.imageType = self.animationImage and "animation" or "image"

	if self.imageType == "image" then
		self.totalW, self.totalH = self.idleImage:getDimensions()

		if self.hoverImage then
			local w, h = self.hoverImage:getDimensions()
			self.totalW, self.totalH = math.max(w, self.totalW), math.max(h, self.totalH)
		end
	else
		self.totalW, self.totalH = self.animationImage[1]:getDimensions()
		self.frameCount = #self.animationImage
		self.framerate = params.framerate == -1 and self.frameCount or params.framerate
	end

	self.ox = params.ox or 0
	self.oy = params.oy or 0
end

function ImageButton:update(has_focus)
	local hw, hh = self.hoverWidth, self.hoverHeight

	local hover ---@type boolean
	local just_hovered ---@type boolean
	hover, self.animation, just_hovered = self.hoverState:check(hw, hh, -hw * self.ox, -hh * self.oy, has_focus)

	if just_hovered then
		ui.playSound(self.hoverSound)
	end

	if hover and ui.mousePressed(1) then
		ui.playSound(self.clickSound)
		self.onClick()
	end
end

local gfx = love.graphics

function ImageButton:drawAnimation()
	local frame = 1 + math.floor((love.timer.getTime() * self.framerate) % self.frameCount)
	local img = self.animationImage[frame]
	local iw, ih = img:getDimensions()

	local prev_shader = gfx.getShader()
	gfx.setShader(self.hoverShader)
	self.hoverShader:send("amount", self.alpha * self.animation * 0.3)
	gfx.draw(img, 0, 0, 0, 1, 1, self.ox * iw, self.oy * ih)
	gfx.setShader(prev_shader)
end

function ImageButton:draw()
	gfx.setColor(1, 1, 1, self.alpha)

	if self.imageType == "animation" then
		self:drawAnimation()
		return
	end

	local iiw, iih = self.idleImage:getDimensions()

	if self.hoverImage then
		local hiw, hih = self.hoverImage:getDimensions()
		gfx.draw(self.idleImage, 0, 0, 0, 1, 1, self.ox * iiw, self.oy * iih)
		gfx.setColor(1, 1, 1, self.animation * self.alpha)
		gfx.draw(self.hoverImage, 0, 0, 0, 1, 1, self.ox * hiw, self.oy * hih)
		return
	end

	local prev_shader = gfx.getShader()
	gfx.setShader(self.hoverShader)
	self.hoverShader:send("amount", self.alpha * self.animation * 0.3)
	gfx.draw(self.idleImage, 0, 0, 0, 1, 1, self.ox * iiw, self.oy * iih)
	gfx.setShader(prev_shader)
end

return ImageButton
