local Component = require("ui.Component")
local StencilComponent = require("ui.StencilComponent")
local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")
local Rectangle = require("ui.Rectangle")
local Image = require("ui.Image")
local Label = require("ui.Label")
local Spectrum = require("osu_ui.views.MainMenu.Spectrum")
local LogoButton = require("osu_ui.views.MainMenu.LogoButton")

local flux = require("flux")
local math_util = require("math_util")

---@class osu.ui.MainMenuView : ui.Component
---@operator call: osu.ui.MainMenuView
---@field menu "closed" | "first" | "second"
---@field selectApi game.SelectAPI
local View = Component + {}

local logo_slide = 200
local play_intro = true

function View:reload()
	if not self.playingIntro then
		self:clearTree()
		self:load()
	end
end

function View:logoClicked()
	if self.locked then
		return
	end

	if self.menu == "closed" then
		flux.to(self, 0.35, { slide = 1 }):ease("quadout")
		self:openFirstMenu()
	elseif self.menu == "first" then
		self:openSecondMenu()
	elseif self.menu == "second" then
		self:toNextView("select")
	end
end

function View:openFirstMenu()
	if self.locked then
		return
	end
	flux.to(self.firstMenu, 0.35, { alpha = 1 }):ease("quadout")
	flux.to(self.secondMenu, 0.35, { alpha = 0 }):ease("quadout")
	self.playSound(self.logoHitSound)
	self.menu = "first"

	for _, v in pairs(self.secondMenu.children) do
		v.handleEvents = false
	end
	for _, v in pairs(self.firstMenu.children) do
		v.handleEvents = true
	end
end

function View:openSecondMenu()
	if self.locked then
		return
	end
	flux.to(self.firstMenu, 0.25, { alpha = 0 }):ease("quadout")
	flux.to(self.secondMenu, 0.35, { alpha = 1 }):ease("quadout")
	self.playSound(self.playClickSound)
	self.menu = "second"

	for _, v in pairs(self.firstMenu.children) do
		v.handleEvents = false
	end
	for _, v in pairs(self.secondMenu.children) do
		v.handleEvents = true
	end
end

---@param screen_name "select" | "lobbyList" | "editor" | "osuDirect"
function View:toNextView(screen_name)
	if self.locked then
		return
	end

	if screen_name == "select" then
		self.playSound(self.freeplayClickSound)
	end

	self:quit()

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene

	if scene:getChild(screen_name) then
		scene:transitInScreen(screen_name)
		return true
	end

	local background = self.scene.background
	background.parallax = 0
	background.dim = 0.3

	flux.to(self.scene.cursor, 0.6, { alpha = 0 }):ease("quadout")
	self.transitionTween = flux.to(self, 0.6, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		scene:transitInScreen(screen_name)
		self.disabled = true
	end)
end

function View:transitIn()
	if self.transitionTween then
		self.transitionTween:stop()
	end
	self.disabled = false
	self.locked = false
	self.handleEvents = true
	self.transitionTween = flux.to(self, 0.5, { alpha = 1 }):ease("quadout")
end

function View:quit()
	self.locked = true
	self.menu = "closed"
	flux.to(self, 0.35, { slide = 0 }):ease("quadout")
	flux.to(self.firstMenu, 0.25, { alpha = 0 }):ease("quadout")
	flux.to(self.secondMenu, 0.25, { alpha = 0 }):ease("quadout")

	self.scene.options:fade(0)

	for _, v in pairs(self.firstMenu.children) do
		v.handleEvents = false
	end
	for _, v in pairs(self.secondMenu.children) do
		v.handleEvents = false
	end

	if self.transitionTween then
		self.transitionTween:stop()
	end

	self.handleEvents = false
	self.transitionTween = flux.to(self, 0.5, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self.disabled = true
	end)
end

function View:keyPressed(event)
	if event[2] == "return" then
		self:logoClicked()
		self.logo:clickAnimation()
		return true
	elseif event[2] == "f9" then
		local scene = self.shared.scene
		local chat = scene:getChild("chat") ---@cast chat osu.ui.ChatView
		if chat then
			chat:toggle()
		end
	end
end

function View:introSequence()
	self.locked = true
	self.handleEvents = false
	self.playingIntro = true
	self.playSound(self.welcomeSound)
	self.playSound(self.welcomePianoSound)
	self.introPercent = 0

	local logo = self.logo
	local stencil = self.stencil ---@cast stencil ui.StencilComponent
	local top = self:getChild("topLayer")
	local rect = self:getChild("blackRect")
	local welcome = self.welcomeText
	local spectrum = self:getChild("spectrum")

	logo.alpha = 0
	stencil.compareValue = 2
	top.alpha = 0
	rect.alpha = 1
	welcome.disabled = false
	spectrum.color = {love.math.colorFromBytes(0, 78, 155, 255)}

	flux.to(self, --[[2]]0.1, { introPercent = 1 }):ease("linear"):oncomplete(function ()
		flux.to(logo, 0.2, { alpha = 1 }):ease("quadout"):oncomplete(function ()
			stencil.compareValue = 1
		end)
		flux.to(top, 0.2, { alpha = 1 }):ease("quadout")
		flux.to(rect, 0.4, { alpha = 0 }):ease("quadout")
		spectrum.color = { 1, 1, 1, 1 }
		self.locked = false
		self.playingIntro = false
		self.handleEvents = true
		self.selectApi:loadController()
	end)
	flux.to(welcome, 2, { scaleX = 1, scaleY = 1, alpha = 1 }):ease("sineout"):oncomplete(function ()
		flux.to(welcome, 0.2, { alpha = 0 }):oncomplete(function ()
			welcome.disabled = true
		end)
	end)
end

function View:update()
	self.selectApi:updateController()
end

function View:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager
	self.scene = scene
	self.selectApi = scene.ui.selectApi

	self.width, self.height = self.parent:getDimensions()
	self:getViewport():listenForResize(self)
	self.locked = self.locked or false
	self.menu = "closed"
	self.slide = 0

	self.welcomePianoSound = assets:loadAudio("welcome")
	self.welcomeSound = assets:loadAudio("welcome_piano")
	self.logoHitSound = assets:loadAudio("menuhit")
	self.playClickSound = assets:loadAudio("menu-play-click")
	self.freeplayClickSound = assets:loadAudio("menu-freeplay-click")

	self.stencil = self:addChild("backgroundStencil", StencilComponent({
		width = self.width,
		height = self.height,
		compareMode = "less",
		compareValue = 1,
		stencilFunction = function()
			love.graphics.circle("fill", self.width / 2 - (self.slide * logo_slide), self.height / 2, 200 + ((1 - self.alpha) * self.width / 2))
		end
	}))
	self.background = self.stencil:addChild("background", ParallaxBackground({
		image = assets:loadImage("menu-background"),
		z = 0,
		draw = function(this)
			love.graphics.setColor(1, 1, 1, 1)
			ParallaxBackground.draw(this)
		end
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

	local secret = "LOVE YOURSELF LOVE YOUR PARENTS LOVE YOUR FRIENDS LOVE EVERYONE HATE ME HATE ME HATE ME HATE ME HATE ME HATE ME HATE ME HATE ME HATE ME HATE ME"
	local char_set = [[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+{}|:./"]]
	top:addChild("heart", Image({
		x = self.width - 32, y = self.height - 48,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("menu-subscriber"),
		clicks = 0,
		z = 0.5,
		mousePressed = function(this, event)
			if this.mouseOver then
				this.clicks = this.clicks + 1
			end
			if this.clicks == 7 then
				this.clicks = 9999999
				local ily = scene:addChild("ily", Component({ z = 0.5, alpha = 0 }))
				this.ily = ily:addChild("loveyourself", Rectangle({
					width = self.width,
					height = self.height,
					color = { 0, 0, 0, 0.8 },
					blockMouseFocus = true,
				}))
				this.label = ily:addChild("lovelovelovelovelove", Label({
					x = 5, y = 5,
					width = self.width - 5,
					font = fonts:loadFont("Regular", 18),
					text = secret,
					z = 0.1
				}))
				flux.to(ily, 0.5, { alpha = 1 }):ease("quadout")
			end
		end,
		keyPressed = function(this, event)
			if event[2] ~= "escape" then
				return
			end
			if this.ily then
				flux.to(this.ily, 0.5, { alpha = 0 }):ease("quadout"):oncomplete(function ()
					scene:removeChild("ily")
				end)
			end
		end,
		update = function(this)
			this.alpha = 0.25 + (0.75 * (1 + math.sin(love.timer.getTime())) / 2)
			if not this.ily then
				return
			end
			this.label.alpha = this.ily.alpha
			for i = 1, 5 do
				local index = math.random(1, #char_set)
				local char = char_set:sub(index, index)
				secret = secret .. char
			end
			this.label:replaceText(secret)
		end
	}))

	top:addChild("bat", Image({
		x = self.width - 80, y = self.height - 48,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("menu-bat"),
		z = 0.5,
		update = function(this)
			this.alpha = 0.25 + (0.75 * (1 + math.sin(love.timer.getTime())) / 2)
		end
	}))

	local logo_x = self.width / 2
	local logo_y = self.height / 2
	local logo_img = assets:loadImage("menu-osu-logo")
	local logo_w, logo_h = logo_img:getDimensions()
	self.logo = self:addChild("logo", Image({
		x = logo_x, y = logo_y,
		origin = { x = 0.5, y = 0.5, },
		image = logo_img,
		blockMouseFocus = true,
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
			this.x = logo_x + (logo_x - mx) * 0.008 + (self.slide * -logo_slide)
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
			this:clickAnimation()
			self:logoClicked()
			return true
		end,
		clickAnimation = function(this)
			if this.clickTween then
				this.clickTween:stop()
			end
			this.clickTween = flux.to(this, 0.04, { clickScale = -0.05 }):ease("quadout"):oncomplete(function ()
				this.clickTween = flux.to(this, 0.2, { clickScale = 0 }):ease("quadout")
			end)
		end
	}))

	self:addChild("spectrum", Spectrum({
		alpha = 0.2,
		z = 0.02,
		update = function(this, dt)
			this.audio = self.selectApi:getPreviewAudioSource()
			if self.playingIntro then
				this.audio = self.welcomeSound
			end
			this.transform = self.logo.transform:clone()
			this.transform:translate(logo_w / 2, logo_h / 2)
			Spectrum.update(this, dt)
		end,
	}))

	self.menus = self:addChild("menus", StencilComponent({
		x = self.width / 2,
		y = self.height / 2 - 500 / 2,
		stencilFunction = function()
			love.graphics.rectangle("fill", 0, 0, 800, 500)
		end,
		z = 0.09,
		update = function(this)
			local mx, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
			this.x = self.width / 2 -  self.slide * logo_slide + ((logo_x - mx) * 0.008)
			this.y = self.height / 2 - 500 / 2 + (logo_y - my) * 0.008
		end
	}))

	self.firstMenu = self.menus:addChild("firstMenu", Component({
		z = 0.5,
		alpha = 0,
		update = function(this)
			this.x = -280 + 300 * this.alpha
		end
	}))
	self.firstMenu:addChild("play", LogoButton({
		x = 0, y = 48,
		idleImage = assets:loadImage("menu-button-play"),
		hoverImage = assets:loadImage("menu-button-play-over"),
		onClick = function()
			self:openSecondMenu()
		end
	}))
	self.firstMenu:addChild("edit", LogoButton({
		x = 0, y = 152,
		idleImage = assets:loadImage("menu-button-edit"),
		hoverImage = assets:loadImage("menu-button-edit-over"),
		clickSound = assets:loadAudio("menu-edit-click"),
		onClick = function() end
	}))
	self.firstMenu:addChild("options", LogoButton({
		x = 0, y = 257,
		idleImage = assets:loadImage("menu-button-options"),
		hoverImage = assets:loadImage("menu-button-options-over"),
		clickSound = assets:loadAudio("menuhit"),
		onClick = function()
			self.scene.options:toggle()
		end
	}))
	self.firstMenu:addChild("exit", LogoButton({
		x = 0, y = 360,
		idleImage = assets:loadImage("menu-button-exit"),
		hoverImage = assets:loadImage("menu-button-exit-over"),
		clickSound = assets:loadAudio("menuhit"),
		onClick = function() end
	}))

	self.secondMenu = self.menus:addChild("secondMenu", Component({
		z = 0.4,
		alpha = 0,
		update = function(this)
			this.x = -280 + 300 * this.alpha
		end
	}))
	self.secondMenu:addChild("freeplay", LogoButton({
		x = 0, y = 105,
		idleImage = assets:loadImage("menu-button-freeplay"),
		hoverImage = assets:loadImage("menu-button-freeplay-over"),
		onClick = function()
			self:toNextView("select")
		end
	}))
	self.secondMenu:addChild("multiplayer", LogoButton({
		x = 0, y = 205,
		idleImage = assets:loadImage("menu-button-multiplayer"),
		hoverImage = assets:loadImage("menu-button-multiplayer-over"),
		clickSound = assets:loadAudio("menu-multiplayer-click"),
		onClick = function()
			self:toNextView("lobbyList")
		end
	}))
	self.secondMenu:addChild("back", LogoButton({
		x = 0, y = 305,
		idleImage = assets:loadImage("menu-button-back"),
		hoverImage = assets:loadImage("menu-button-back-over"),
		clickSound = assets:loadAudio("menuhit"),
		onClick = function()
			self:openFirstMenu()
		end
	}))

	self:addChild("blackRect", Rectangle({
		width = self.width,
		height = self.height,
		color = { 0, 0, 0, 1 },
		alpha = 0,
		z = 0.01
	}))

	self.welcomeText = self:addChild("welcomeText", Image({
		x = self.width / 2, y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		scale = 0.75,
		image = assets:loadImage("welcome_text"),
		alpha = 0,
		disabled = true,
		z = 1,
	}))

	if play_intro then
		self:introSequence()
		play_intro = false
	end
end

return View
