local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Image = require("ui.Image")
local HoverState = require("ui.HoverState")

local flux = require("flux")

---@class osu.ui.PauseView : ui.Component
---@operator call: osu.ui.PauseView
---@field assets osu.ui.OsuAssets 
---@field gameplayController sphere.GameplayController
---@field gameplayView osu.ui.GameplayView
local View = Component + {}

function View:display()
	love.mouse.setVisible(false)

	if self.alphaTween then
		self.alphaTween:stop()
	end

	self.disabled = false
	self.handleEvents = true
	self.alphaTween = flux.to(self, 0.4, { alpha = 1 }):ease("cubicout")
	flux.to(self.scene.cursor, 0.3, { alpha = 1 }):ease("cubicout")
	self.audioLoop:play()
end

---@param instant boolean
function View:hide(instant)
	if self.alphaTween then
		self.alphaTween:stop()
	end

	self.handleEvents = false
	if instant then
		self.alpha = 0
		self.scene.cursor.alpha = 0
		self.disabled = true
		self.audioLoop:stop()
		return
	end

	self.alphaTween = flux.to(self, self.unpauseTime, { alpha = 0 }):ease("cubicout"):oncomplete(function ()
		self.disabled = true
		self.audioLoop:stop()
	end)
	flux.to(self.scene.cursor, self.unpauseTime * 0.9, { alpha = 0 }):ease("cubicout")
end

function View:quit()
	self.audioLoop:stop()
end

function View:pauseButton(x, y, image, hover_sound, click_sound, on_click)
	if hover_sound == self.emptyAudio then
		hover_sound = self.pauseHover
	end

	return Image({
		x = x, y = y,
		origin = { x = 0.5, y = 0.5 },
		image = image,
		hoverState = HoverState("cubicout", 0.12),
		z = 1,
		mousePressed = function(this)
			if this.mouseOver then
				self.playSound(click_sound)
				on_click()
				return true
			end
			return false
		end,
		keyPressed = function(this, event)
			if this.mouseOver and event[2] == "return" then
				self.playSound(click_sound)
				on_click()
				return true
			end
			return false
		end,
		update = function(this)
			this.scaleX = 1 + this.hoverState.progress * 0.1
			this.scaleY = 1 + this.hoverState.progress * 0.1
		end,
		---@param this ui.Component
		setMouseFocus = function(this, mx, my)
			this.mouseOver = this.hoverState:checkMouseFocus(this.width, this.height, mx, my)
		end,
		noMouseFocus = function(this)
			this.hoverState:loseFocus()
			this.mouseOver = false
		end,
		justHovered = function()
			self.playSound(hover_sound)
		end
	})
end

function View:moveMouse()
	local x, y = self.width / 2, 0

	if self.cursor == 1 then
		y = 224
	elseif self.cursor == 2 then
		y = 400
	elseif self.cursor == 3 then
		y = 576
	end

	love.mouse.setPosition(x * self.viewportScale, y * self.viewportScale)
end

function View:keyPressed(event)
	if event[2] == "down" then
		self.cursor = math.min(self.cursor + 1, 3)
		self:moveMouse()
	elseif event[2] == "up" then
		self.cursor = math.max(self.cursor - 1, 1)
		self:moveMouse()
	end
end

function View:load()
	local width, height = self.width, self.height

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local configs = scene.ui.selectApi:getConfigs()
	self:getViewport():listenForResize(self)
	self.scene = scene
	self.unpauseTime = configs.settings.gameplay.time.pausePlay
	self.retryTime = configs.settings.gameplay.time.pauseRetry
	self.audioLoop = assets:loadAudio("pause-loop")
	self.pauseHover = assets:loadAudio("pause-hover")
	self.emptyAudio = assets:emptyAudio()
	self.cursor = 1
	self.viewportScale = self:getViewport():getInnerScale()

	self:addChild("continueButton", self:pauseButton(
		width / 2,
		224,
		assets:loadImage("pause-continue"),
		assets:loadAudio("pause-continue-hover"),
		assets:loadAudio("pause-continue-click"),
		function ()
			self.gameplayView:unpause()
		end
	))

	self:addChild("retryButton", self:pauseButton(
		width / 2,
		400,
		assets:loadImage("pause-retry"),
		assets:loadAudio("pause-retry-hover"),
		assets:loadAudio("pause-retry-click"),
		function ()
			self.gameplayView:retry()
		end
	))

	self:addChild("backButton", self:pauseButton(
		width / 2,
		576,
		assets:loadImage("pause-back"),
		assets:loadAudio("pause-back-hover"),
		assets:loadAudio("pause-back-click"),
		function ()
			self.audioLoop:stop()
			self.gameplayView:quit()
		end
	))

	self:addChild("tint", Rectangle({
		width = width,
		height = height,
		color = { 0.05, 0.05, 0.8, 0.2 },
	}))

	self:addChild("overlay", Image({
		x = width / 2,
		y = height / 2,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("pause-overlay")
	}))
end

return View
