local CanvasComponent = require("ui.CanvasComponent")
local Playfield = require("osu_ui.views.Gameplay.Playfield")
local PauseScreen = require("osu_ui.views.Gameplay.PauseScreen")
local flux = require("flux")

---@class osu.ui.GameplayViewContainer : ui.CanvasComponent
---@operator call: osu.ui.GameplayViewContainer
---@field gameplayApi game.GameplayAPI
---@field state "play" | "pausing" | "pause" | "unpausing"
local View = CanvasComponent + {}

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
	local showcase = self.scene:getChild("chartShowcase") ---@cast showcase osu.ui.ChartShowcase
	showcase:hide(1)

	self.alpha = 0
	flux.to(self, 0.5, { alpha = 1 }):ease("quadout")
	flux.to(self.scene.background, 1, { dim = 0.8 }):ease("quadout")

	self.gameplayApi:start()
	self.disabled = false
	self.handleEvents = true
end

function View:quit()
	if not self.handleEvents then
		return
	end

	self.handleEvents = false

	local select_api = self.scene.ui.selectApi
	select_api:playPreview()

	local volume_cfg = select_api:getConfigs().settings.audio.volume
	local volume = volume_cfg.music * volume_cfg.master
	local gameplay_audio = self.gameplayApi:getMusicAudioSource()
	local preview_audio = select_api:getPreviewAudioSource()
	preview_audio:setVolume(0)

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
		self.selectApi:unloadController()
		flux.to(self, 0.5, { alpha = 0 }):ease("quadout"):oncomplete(function ()
			quit()
			self.disabled = true
			self.scene:transitInScreen("result")
		end)
	else
		self.scene:transitInScreen("select")
		flux.to(self, 0.5, { alpha = 0 }):ease("quadout"):oncomplete(function ()
			quit()
			self.disabled = true
		end)
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
	self.state = "play"

	local gameplay_cfg = scene.game.configModel.configs.osu_ui.gameplay
	local render_at_native_res = gameplay_cfg.nativeRes

	if render_at_native_res then
		local native_res_x, native_res_y = gameplay_cfg.nativeResX, gameplay_cfg.nativeResY
		local native_res_w, native_res_h = gameplay_cfg.nativeResSize.width, gameplay_cfg.nativeResSize.height
		local viewport_scale = self:getViewport():getInnerScale()
		self:addChild("playfield", Playfield({
			x = ((love.graphics.getWidth() - native_res_w) * viewport_scale) * native_res_x,
			y = ((love.graphics.getHeight() - native_res_h) * viewport_scale) * native_res_y,
			width = native_res_w,
			height = native_res_h,
			renderAtNativeResoltion = true,
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

	self.pause = self:addChild("pause", PauseScreen({
		width = self.width,
		height = self.height,
		alpha = 0,
		z = 0.2,
	}))
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
	end
end

return View
