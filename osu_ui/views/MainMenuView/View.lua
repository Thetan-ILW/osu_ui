local Component = require("ui.Component")
local StencilComponent = require("ui.StencilComponent")
local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")
local Rectangle = require("ui.Rectangle")
local Image = require("ui.Image")
local Spectrum = require("osu_ui.views.MainMenuView.Spectrum")

local flux = require("flux")
local math_util = require("math_util")

---@class osu.ui.MainMenuContainer : ui.Component
---@operator call: osu.ui.MainMenuContainer
---@field mainMenu osu.ui.MainMenuView
---@field menu "closed" | "first" | "second"
local View = Component + {}

function View:viewportResized()
	self:clearTree()
	self:load()
end

function View:logoClicked()
	if self.menu == "closed" then
		flux.to(self, 0.35, { slide = 1 }):ease("quadout")
		self.menu = "first"
	elseif self.menu == "first" then
		self.menu = "second"
	elseif self.menu == "second" then
		self.locked = true
		self.menu = "closed"
		flux.to(self, 0.35, { slide = 0 }):ease("quadout")
		self:toSongSelect()
	end
end

function View:toSongSelect()
	local scene = self.mainMenu.gameView.scene

	if scene:getChild("selectView") then
		if self.transitionTween then
			self.transitionTween:stop()
		end
		self.transitionTween = flux.to(self, 0.6, { alpha = 0 }):ease("quadout"):oncomplete(function ()
			self.disabled = true
		end)
		self.mainMenu:toSongSelect()
		return true

	end

	local background = scene:getChild("background")
	if background then
		---@cast background osu.ui.ParallaxBackground
		background.parallax = 0
		background.dim = 0.3
	end
	flux.to(self, 0.6, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self.mainMenu:toSongSelect()
		self.disabled = true
	end)
end

function View:transitIn()
	if self.transitionTween then
		self.transitionTween:stop()
	end
	self.disabled = false
	self.locked = false
end

function View:load()
	local assets = self.shared.assets

	self.width, self.height = self.parent:getDimensions()
	self.locked = false
	self.menu = "closed"
	self.slide = 0

	self.stencil = self:addChild("backgroundStencil", StencilComponent({
		width = self.width,
		height = self.height,
		compareMode = "less",
		compareValue = 1,
		stencilFunction = function()
			love.graphics.circle("fill", self.width / 2 - (self.slide * 180), self.height / 2, 200 + ((1 - self.alpha) * 768))
		end
	}))
	self.stencil:addChild("background", ParallaxBackground({
		image = assets:loadImage("menu-background"),
		z = 0,
	}))

	local top = self:addChild("topLayer", Component({ z = 0.5 }))
	top:addChild("header", Rectangle({
		width = self.width,
		height = 86,
		color = { 0, 0, 0, 0.4 }
	}))

	top:addChild("footer", Rectangle({
		y = self.height,
		origin = { y = 1 },
		width = self.width,
		height = 86,
		color = { 0, 0, 0, 0.4 }
	}))

	local logo_x = self.width / 2
	local logo_y = self.height / 2
	local logo_img = assets:loadImage("menu-osu-logo")
	local logo_w, logo_h = logo_img:getDimensions()
	self.logo = self:addChild("logo", Image({
		x = logo_x, y = logo_y,
		origin = { x = 0.5, y = 0.5, },
		image = logo_img,
		hoverScale = 0,
		clickScale = 0,
		slide = 0,
		z = 0.1,
		setMouseFocus = function(this, mx, my)
			mx, my = love.graphics.inverseTransformPoint(mx, my)
			local dx = logo_w / 2 - mx
			local dy = logo_h / 2 - my
			local distance = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
			this.mouseOver = distance < 255
		end,
		update = function(this, dt)
			local mx, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
			this.x = logo_x + (logo_x - mx) * 0.008 + (self.slide * -180)
			this.y = logo_y + (logo_y - my) * 0.008

			this.hoverScale = math_util.clamp(this.hoverScale + (this.mouseOver and dt * 0.5 or -dt * 0.5), 0, 0.05)
			local total_scale = this.hoverScale + this.clickScale
			this.scaleX = 1 + total_scale
			this.scaleY = 1 + total_scale
		end,
		mousePressed = function(this)
			if self.locked then
				return false
			end
			if not this.mouseOver then
				return false
			end
			if this.clickTween then
				this.clickTween:stop()
			end
			this.clickTween = flux.to(this, 0.04, { clickScale = -0.05 }):ease("quadout"):oncomplete(function ()
				this.clickTween = flux.to(this, 0.2, { clickScale = 0 }):ease("quadout")
			end)
			self:logoClicked()
			return true
		end
	}))

	self.logo:addChild("spectrum", Spectrum({
		x = logo_w / 2, y = logo_h / 2,
		alpha = 0.2,
		update = function(this, dt)
			this.audio = self.mainMenu.game.previewModel.audio
			Spectrum.update(this, dt)
		end,
	}))
end

return View
