local IViewConfig = require("osu_ui.views.IViewConfig")

local flux = require("flux")
local ui = require("osu_ui.ui")

local ImageButton = require("osu_ui.ui.ImageButton")

---@class osu.ui.PauseViewConfig : osu.ui.IViewConfig
local PauseViewConfig = IViewConfig + {}

PauseViewConfig.tween = nil
PauseViewConfig.alpha = 0

---@type table<string, love.Image>
local img
---@type table<string, audio.Source>
local snd

local failed = false

---@param view osu.ui.GameplayView
---@param assets osu.ui.OsuPauseAssets
function PauseViewConfig:new(view, assets)
	self.view = view
	self.assets = assets
	img = assets.images
	snd = assets.sounds
	self:createUI()
end

function PauseViewConfig:createUI()
	local assets = self.assets
	local gameplayController = self.view.game.gameplayController

	local bw, bh = 380, 95

	self.continueButton = ImageButton(assets, {
		idleImage = img.continue,
		ox = 0.5,
		oy = 0.5,
		hoverArea = { w = bw, h = bh },
		clickSound = assets.sounds.continueClick,
	}, function()
		gameplayController:changePlayState("play")
		self:hide()
	end)

	self.retryButton = ImageButton(assets, {
		idleImage = img.retry,
		ox = 0.5,
		oy = 0.5,
		hoverArea = { w = bw, h = bh },
		clickSound = assets.sounds.retryClick,
	}, function()
		gameplayController:changePlayState("retry")
		self:hide()
	end)

	self.backButton = ImageButton(assets, {
		idleImage = img.back,
		ox = 0.5,
		oy = 0.5,
		hoverArea = { w = bw, h = bh },
		clickSound = assets.sounds.retryClick,
	}, function()
		self.view:quit()
	end)
end

local gfx = love.graphics

function PauseViewConfig:show()
	if self.tween then
		self.tween:stop()
	end

	self.tween = flux.to(self, 0.22, { alpha = 1 }):ease("quadout")
	snd.loop:play()
end

function PauseViewConfig:hide()
	if self.tween then
		self.tween:stop()
	end

	self.tween = flux.to(self, 0.22, { alpha = 0 }):ease("quadout")
	snd.loop:stop()
end

function PauseViewConfig:unload()
	snd.loop:stop()
end

function PauseViewConfig:overlay()
	gfx.push()
	local image = img.overlay

	if failed then
		image = img.overlayFail
	end

	local iw, ih = image:getDimensions()
	love.graphics.draw(image, ui.layoutW / 2, ui.layoutH / 2, 0, 1, 1, iw / 2, ih / 2)
	gfx.pop()
end

---@param view osu.ui.GameplayView
function PauseViewConfig:buttons()
	gfx.push()
	gfx.translate(ui.layoutW / 2, 224)
	if not failed then
		self.continueButton:update(true)
		self.continueButton:draw()
	end

	gfx.translate(0, 176)
	self.retryButton:update(true)
	self.retryButton:draw()
	gfx.translate(0, 176)
	self.backButton:update(true)
	self.backButton:draw()
	gfx.pop()
end

local next_audio_update_time = -math.huge

---@param view osu.ui.GameplayView
function PauseViewConfig:updateAudio(view)
	if self.alpha == 1 then
		return
	end

	if love.timer.getTime() < next_audio_update_time then
		return
	end

	local configs = view.game.configModel.configs
	local settings = configs.settings
	local a = settings.audio
	local volume = a.volume.master * a.volume.music

	snd.loop:setVolume(volume * self.alpha)
	next_audio_update_time = love.timer.getTime() + 0.036
end

function PauseViewConfig:resolutionUpdated()
	self:createUI()
end

---@param view osu.ui.GameplayView
function PauseViewConfig:draw(view)
	---@type boolean
	failed = view.game.rhythmModel.scoreEngine.scoreSystem.hp:isFailed()

	self:updateAudio(view)

	local prev_canvas = love.graphics.getCanvas()
	local layer = ui.getCanvas("pauseOverlay")
	love.graphics.setCanvas({ layer, stencil = true })
	love.graphics.clear()
	self:overlay()
	self:buttons()
	love.graphics.setCanvas({ prev_canvas, stencil = true })

	local a = self.alpha
	love.graphics.origin()
	love.graphics.setColor(0.1 * a, 0.1 * a, a, a * 0.1)
	love.graphics.rectangle("fill", 0, 0, ui.layoutW, ui.layoutH)
	love.graphics.setColor(a, a, a, a)
	love.graphics.draw(layer)

	view.cursor.alpha = a
end

return PauseViewConfig
