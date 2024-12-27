local Component = require("ui.Component")
local PauseScreen = require("osu_ui.views.Gameplay.PauseScreen")
local Image = require("ui.Image")
local Rectangle = require("ui.Rectangle")
local math_util = require("math_util")

local GameplayAssets = require("osu_ui.OsuGameplayAssets")

---@class osu.ui.UiLayerView : ui.Component
---@operator call: osu.ui.UiLayerView
local UiLayer = Component + {}

function UiLayer:loadAssets(asset_model)
	local configs = self.selectApi:getConfigs()
	local input_mode = self.selectApi:getCurrentInputMode()
	local path = configs.settings.gameplay[("noteskin%s"):format(tostring(input_mode))]
	if path and type(path) == "string" then
		path = path:match("^(.*/)") or ""
	else
		path = "no skin UwU"
	end

	if path == self.previousSkinPath then
		return
	end

	self.previousSkinPath = path
	self.gameplayAssets = GameplayAssets(asset_model, path)
	self.gameplayAssets:load()
	self.gameplayAssets:updateVolume(configs)
end

function UiLayer:introSkipped()
	self.playSound(self.skipSound)
	self.fadeRect.skipTime = love.timer.getTime()
end

function UiLayer:load()
	local width, height = self.parent:getDimensions()

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local select_api = scene.ui.selectApi
	local gameplay_api = scene.ui.gameplayApi
	self.selectApi = select_api
	self.gameplayApi = gameplay_api

	self:loadAssets(scene.ui.assetModel)

	self.skipSound = self.gameplayAssets:loadAudio("menuhit")
	self.skipImage = self:addChild("skipImage", Image({
		x = width, y = height,
		origin = { x = 1, y = 1 },
		image = self.gameplayAssets:loadImage("play-skip"),
		z = 0.1,
		update = function(this, dt)
			this.alpha = math_util.clamp(this.alpha + (gameplay_api:canSkipIntro() and dt * 3 or -dt * 6), 0, 1)
			if gameplay_api:getTimeToStart() > 0 then
				this:kill()
			end
		end
	}))

	---@class osu.ui.Gameplay.FadeRect : ui.Component
	---@field skipTime number
	---@field restartProgress number
	self.fadeRect = self:addChild("fadeRect", Rectangle({
		width = width,
		height = height,
		color = { 0, 0, 0, 1 },
		alpha = 0,
		skipTime = -math.huge,
		restartProgress = 0,
		---@param this osu.ui.Gameplay.FadeRect
		update = function(this)
			local skip_alpha = 1 - math_util.clamp((love.timer.getTime() - this.skipTime) * 2, 0, 1)
			this.alpha = skip_alpha + this.restartProgress
		end
	}))

	self.pause = self:addChild("pause", PauseScreen({
		width = width,
		height = height,
		alpha = 0,
		disabled = true,
		z = 0.5,
	}))
end

return UiLayer
