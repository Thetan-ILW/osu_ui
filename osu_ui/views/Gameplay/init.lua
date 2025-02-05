local CanvasScreen = require("osu_ui.views.CanvasScreen")
local Playfield = require("osu_ui.views.Gameplay.Playfield")
local UiLayer = require("osu_ui.views.Gameplay.UiLayer")
local flux = require("flux")
local math_util = require("math_util")
local delay = require("delay")

---@class osu.ui.GameplayViewContainer : osu.ui.CanvasScreen
---@operator call: osu.ui.GameplayViewContainer
---@field gameplayApi game.GameplayAPI
local View = CanvasScreen + {}

local keybinds = {}

function View:transitIn()
	self.uiLayer:reload()

	local showcase = self.scene:getChild("chartShowcase") ---@cast showcase osu.ui.ChartShowcase
	if showcase then
		showcase:hide(1)
	end

	self.alpha = 0
	self.transitInTween = flux.to(self, 0.5, { alpha = 1 }):ease("quadout")
	flux.to(self.scene.background, 1, { dim = self.backgroundDim }):ease("quadout")

	self:reload()
	self.gameplayApi:start()
	self.disabled = false
	self.handleEvents = true
	self.introSkipped = false
	love.keyboard.setKeyRepeat(false)
	self.scaleX = 1.05
	self.scaleY = 1.05
	flux.to(self, 0.8, { scaleX = 1, scaleY = 1}):ease("cubicout")
end

function View:quit()
	love.keyboard.setKeyRepeat(true)
	self.uiLayer.pause:quit()

	if self.transitInTween then
		self.transitInTween:stop()
	end

	local select_api = self.scene.ui.selectApi
	select_api:playPreview()

	local volume_cfg = select_api:getConfigs().settings.audio.volume
	local volume = volume_cfg.music * volume_cfg.master
	local gameplay_audio = self.gameplayApi:getMusicAudioSource()
	local preview_audio = select_api:getPreviewAudioSource()

	if preview_audio then
		preview_audio:setVolume(0)
	end

	local function quit()
		preview_audio = self.scene.ui.selectApi:getPreviewAudioSource()
		if preview_audio and gameplay_audio and gameplay_audio:isPlaying() then
			preview_audio:setPosition(gameplay_audio:getPosition())
		end
		if preview_audio then
			preview_audio:setVolume(volume)
		end
		self.gameplayApi:stop()
	end

	if self.gameplayApi:hasResult() and self.gameplayApi.shouldShowResult then
		self:transitOut({
			time = 0.27,
			onComplete = function ()
				quit()
				self.selectApi:unloadController()
				self.scene:transitInScreen("result")
			end
		})
	else
		self.scene:transitInScreen("select")
		self:transitOut({
			onComplete = function ()
				quit()
			end
		})
	end
end

function View:load()
	self.width, self.height = self.parent:getDimensions()
	self:createCanvas(self.width, self.height)
	self.x = self.width / 2
	self.y = self.height / 2
	self.origin = { x = 0.5, y = 0.5 }

	self:getViewport():listenForResize(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.scene = scene
	self.selectApi = scene.ui.selectApi
	self.gameplayApi = scene.ui.gameplayApi
	self.notification = scene.notification
	self.text = scene.localization.text

	local assets = scene.assets
	local configs = self.selectApi:getConfigs()
	local osu_cfg = configs.osu_ui ---@type osu.ui.OsuConfig
	self.configs = configs
	self.backgroundDim = configs.settings.graphics.dim.gameplay
	keybinds = osu_cfg.keybinds.gameplay

	local gameplay_cfg = configs.osu_ui.gameplay
	local render_at_native_res = gameplay_cfg.nativeRes

	if render_at_native_res then
		local native_res_x, native_res_y = gameplay_cfg.nativeResX, gameplay_cfg.nativeResY
		local native_res_w, native_res_h = gameplay_cfg.nativeResSize.width, gameplay_cfg.nativeResSize.height
		self:addChild("playfield", Playfield({
			x = math.floor((love.graphics.getWidth() - native_res_w) * native_res_x),
			y = math.floor((love.graphics.getHeight() - native_res_h) * native_res_y),
			width = native_res_w,
			height = native_res_h,
			renderAtNativeResolution = true,
			sequenceView = self.gameplayApi:getSequenceView(),
			z = 0.1
		}))
	else
		self:addChild("playfield", Playfield({
			width = self.width,
			height = self.height,
			renderAtNativeResoltion = false,
			sequenceView = self.gameplayApi:getSequenceView(),
			z = 0.1
		}))
	end

	local ui_layer = self:addChild("uiLayer", UiLayer({
		gameplayView = self,
		z = 0.2
	}))
	self.uiLayer = ui_layer

	local time = self.configs.settings.gameplay.time
	self.unpauseTime = time.pausePlay
	self.restartTime = time.playRetry
	self.introSkipped = false
	self.retryProgress = 0
	self.retrying = true
	self.screenFade = 0

	self.retrySound = assets:loadAudio("pause-retry-click")
	self.skipSound = assets:loadAudio("menuhit")
end

function View:pause()
	self.gameplayApi:pause()
	self.uiLayer.pause:display()
end

function View:unpause()
	self.uiLayer.pause:hide(false)
	delay.debounce(self, "unpauseDelay", self.unpauseTime, self.gameplayApi.play, self.gameplayApi)
end

function View:retry()
	self.gameplayApi:retry()
	self.uiLayer:retry()
	self.uiLayer.pause:hide(true)
	self.playSound(self.retrySound)
	self.screenFade = 1
	flux.to(self, 0.7, { screenFade = 0 }):ease("cubicout")
	self.retryProgress = 0
	self.retrying = false
	self.introSkipped = false
end

function View:update(dt)
	self.gameplayApi:update(dt)
	if self.gameplayApi.chartEnded then
		self:quit()
	end

	local restart_dt = dt / self.restartTime
	self.retryProgress = math_util.clamp(
		self.retryProgress + ((love.keyboard.isScancodeDown(keybinds.retry) and self.retrying) and restart_dt or -restart_dt),
		0, 1
	)

	if self.retryProgress == 1 then
		self:retry()
	end

	if
		not love.window.hasFocus() and
		self.gameplayApi:getPlayState() == "play" and
		not self.gameplayApi:isAutoplay()
	then
		self:pause()
	end
end

function View:draw()
	local a = self.alpha
	love.graphics.setColor(a, a, a, a)
	love.graphics.draw(self.canvas)
end

---@param event table
function View:keyPressed(event)
	local key = event[2] ---@type string
	local shift = love.keyboard.isScancodeDown("lshift") or love.keyboard.isScancodeDown("rshift")

	if key == keybinds.pause and shift then
		self:quit()
		return true
	elseif key == keybinds.skipIntro and not self.introSkipped then
		if self.gameplayApi:canSkipIntro() then
			self.playSound(self.skipSound)
			self.screenFade = 1
			flux.to(self, 0.4, { screenFade = 0 }):ease("cubicout")
			self.introSkipped = true
			self.gameplayApi:skipIntro()
		end
		local showcase = self.scene:getChild("chartShowcase") ---@cast showcase osu.ui.ChartShowcase
		if showcase then
			showcase:hide(0)
		end
		return
	elseif key == keybinds.decreaseScrollSpeed then
		local new_speed = self.gameplayApi:increasePlaySpeed(-1)
		self.scene.notification:show("Scroll speed: " .. new_speed)
	elseif key == keybinds.increaseScrollSpeed then
		local new_speed = self.gameplayApi:increasePlaySpeed(1)
		self.scene.notification:show("Scroll speed: " .. new_speed)
	elseif key == keybinds.decreaseLocalOffset and shift then
		local new_offset = self.gameplayApi:increaseLocalOffset(-0.001) * 1000
		self.scene.notification:show(("Local offset: %ims"):format(new_offset))
	elseif key == keybinds.increaseLocalOffset and shift then
		local new_offset = self.gameplayApi:increaseLocalOffset(0.001) * 1000
		self.scene.notification:show(("Local offset: %ims"):format(new_offset))
	elseif key == keybinds.decreaseLocalOffset then
		local new_offset = self.gameplayApi:increaseLocalOffset(-0.005) * 1000
		self.scene.notification:show(("Local offset: %ims"):format(new_offset))
	elseif key == keybinds.increaseLocalOffset then
		local new_offset = self.gameplayApi:increaseLocalOffset(0.005) * 1000
		self.scene.notification:show(("Local offset: %ims"):format(new_offset))
	elseif key == keybinds.pause then
		if self.gameplayApi.paused then
			self:unpause()
		else
			self:pause()
		end
	elseif key == keybinds.retry then
		self.retrying = true
	end
end

---@param event table
function View:keyReleased(event)
	local key = event[2] ---@type string

	if key == keybinds.retry then
		self.retrying = false
	end
end

return View
