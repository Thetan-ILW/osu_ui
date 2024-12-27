local CanvasScreen = require("osu_ui.views.CanvasScreen")
local Playfield = require("osu_ui.views.Gameplay.Playfield")
local UiLayer = require("osu_ui.views.Gameplay.UiLayer")
local flux = require("flux")

---@class osu.ui.GameplayViewContainer : osu.ui.CanvasScreen
---@operator call: osu.ui.GameplayViewContainer
---@field gameplayApi game.GameplayAPI
---@field state "play" | "pausing" | "pause" | "unpausing"
local View = CanvasScreen + {}

function View:setPauseAlpha(a)
	if self.pauseTween then
		self.pauseTween:stop()
	end
	self.pauseTween = flux.to(self.pause, 0.4, { alpha = a }):ease("quadout")
end

---@param game_state "play" | "pause" | "force_play"
function View:processGameState(game_state)
	if self.state == "play" then
		if game_state == "pause" then
			self.state = "pausing"
			self:setPauseAlpha(1)
		end
	elseif self.state == "pausing" then
		if self.pause.alpha == 1 then
			self.state = "pause"
		end
	elseif self.state == "pause" then
		if game_state == "force_play" or game_state == "play" then
			self:setPauseAlpha(0)
			self.state = "unpausing"
		end
	elseif self.state == "unpausing" then
		if self.pause.alpha == 0 then
			self.state = "play"
		end
	end
end

function View:transitIn()
	self.uiLayer:reload()

	local showcase = self.scene:getChild("chartShowcase") ---@cast showcase osu.ui.ChartShowcase
	if showcase then
		showcase:hide(1)
	end

	self.alpha = 0
	flux.to(self, 0.5, { alpha = 1 }):ease("quadout")
	flux.to(self.scene.background, 1, { dim = 0.8 }):ease("quadout")

	self.gameplayApi:start()
	self.disabled = false
	self.handleEvents = true
	self.introSkipped = false
end

function View:quit()
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
			gameplay_audio:setVolume(volume * 0.5)
			preview_audio:setPosition(gameplay_audio:getPosition())
		end
		if preview_audio then
			preview_audio:setVolume(volume * 0.5)
		end
		self.gameplayApi:stop()
	end

	if self.gameplayApi:hasResult() then
		self:transitOut({
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
	self:getViewport():listenForResize(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.scene = scene

	self.selectApi = scene.ui.selectApi
	self.gameplayApi = scene.ui.gameplayApi
	local configs = self.selectApi:getConfigs()
	self.configs = configs

	self.state = "play"
	self.introSkipped = false

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

	self.uiLayer = self:addChild("uiLayer", UiLayer({ z = 0.2 }))
end

function View:update(dt)
	self.gameplayApi:update(dt)
	if self.gameplayApi.chartEnded then
		self:quit()
	end
end

function View:draw()
	local a = self.alpha
	love.graphics.setColor(a, a, a, a)
	love.graphics.draw(self.canvas)
end

function View:keyPressed(event)
	local key = event[2]
	local shift = love.keyboard.isScancodeDown("lshift")

	if key == "escape" and shift then
		self:quit()
		return true
	elseif key == "space" and not self.introSkipped then
		if self.gameplayApi:canSkipIntro() then
			self.introSkipped = true
			self.gameplayApi:skipIntro()
			self.uiLayer:introSkipped()
		end
		local showcase = self.scene:getChild("chartShowcase") ---@cast showcase osu.ui.ChartShowcase
		if showcase then
			showcase:hide(0)
		end
	end
end

return View
