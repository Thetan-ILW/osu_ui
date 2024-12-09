local Component = require("ui.Component")
local HoverState = require("ui.HoverState")
local Label = require("ui.Label")
local Image = require("ui.Image")

---@alias osu.ui.BackButtonParams { hoverWidth: number, hoverHeight: number, assets: osu.ui.OsuAssets, text: string }

---@class osu.ui.BackButton : ui.Component
---@overload fun(params: osu.ui.BackButtonParams): osu.ui.BackButton
---@field text string
---@field onClick function
---@field hoverWidth number
---@field hoverHeight number
local BackButton = Component + {}

local inactive_color = { love.math.colorFromBytes(238, 51, 153) }
local active_color = { love.math.colorFromBytes(187, 17, 119) }

function BackButton:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	self.layerImage = assets:loadImage("back-button-layer")
	self.clickSound = assets:loadAudio("menuback")
	self.hoverSound = assets:loadAudio("menuclick")

	self.hoverState = HoverState("elasticout", 0.7)
	self.width = 93
	self.height = 45
	self.hoverWidth = self.hoverWidth or self.width
	self.hoverHeight = self.hoverHeight or self.height

	self:addChild("layerBottom", Image({
		color = inactive_color,
		image = self.layerImage,
		update = function(this)
			this.x = 42 * self.hoverState.progress - 64
		end
	}))

	self:addChild("layerTop", Image({
		image = self.layerImage,
		z = 0.2,
		update = function(this)
			local p = self.hoverState.progress
			this.x = 28 * p - 124
			this.color[1] = inactive_color[1] - (inactive_color[1] - active_color[1]) * p
			this.color[2] = inactive_color[2] - (inactive_color[2] - active_color[2]) * p
			this.color[3] = inactive_color[3] - (inactive_color[3] - active_color[3]) * p
		end
	}))

	self:addChild("label" , Label({
		height = self.height,
		alignY = "center",
		text = self.text,
		shadow = true,
		font = fonts:loadFont("Regular", 20),
		z = 1,
		update = function(this)
			this.x = 34 * self.hoverState.progress + 40
		end
	}))

	self:addChild("icon", Label({
		y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		text = "",
		font = fonts:loadFont("Awesome", 20),
		z = 0.9,
		update = function(this)
			this.x = 12 * self.hoverState.progress + 14
		end
	}))
end

function BackButton:justHovered()
	self.playSound(self.hoverSound)
end

function BackButton:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.hoverWidth, self.hoverHeight, mx, my)
end

function BackButton:mousePressed()
	if self.mouseOver then
		self.onClick()
		self.playSound(self.clickSound)
		return true
	end
	return false
end

return BackButton
