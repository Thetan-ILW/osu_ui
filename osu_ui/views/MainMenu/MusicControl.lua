local Component = require("ui.Component")
local Label = require("ui.Label")
local Rectangle = require("ui.Rectangle")

local math_util = require("math_util")

---@class osu.ui.MusicControl : ui.Component
---@operator call: osu.ui.MusicControl
local MusicControl = Component + {}

function MusicControl:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	local select_api = scene.ui.selectApi
	local notification = scene.notification

	local click_sound = assets:loadAudio("click-short-confirm")

	local function setMusicPosition(p)
		local audio = select_api:getPreviewAudioSource()
		if audio then
			audio:setPosition(p * audio:getDuration())
		end
	end

	local button_spacing = 31.5
	self:addChild("prevTrack", Label({
		text = "",
		font = fonts:loadFont("Awesome", 18),
		mousePressed = function(this)
			if this.mouseOver then
				select_api:setNotechartSetIndex(select_api:getSelectedNoteChartSetIndex() - 1)
				notification:show("<< Prev")
				self.playSound(click_sound)
				return true
			end
		end
	}))

	self:addChild("play", Label({
		x = button_spacing,
		text = "",
		font = fonts:loadFont("Awesome", 18),
	}))

	self:addChild("pause", Label({
		x = button_spacing * 2,
		text = "",
		font = fonts:loadFont("Awesome", 18),
		mousePressed = function(this)
			if this.mouseOver then
				select_api:pausePreview()
				self.playSound(click_sound)
				return true
			end
		end
	}))

	self:addChild("stop", Label({
		x = button_spacing * 3,
		text = "",
		font = fonts:loadFont("Awesome", 18),
		mousePressed = function(this)
			if this.mouseOver then
				select_api:pausePreview()
				self.playSound(click_sound)
				return true
			end
		end
	}))

	self:addChild("nextTrack", Label({
		x = button_spacing * 4,
		text = "",
		font = fonts:loadFont("Awesome", 18),
		mousePressed = function(this)
			if this.mouseOver then
				select_api:setNotechartSetIndex(select_api:getSelectedNoteChartSetIndex() + 1)
				notification:show(">> Next")
				self.playSound(click_sound)
				return true
			end
		end
	}))

	self:addChild("info", Label({
		x = button_spacing * 5 + 4,
		text = "",
		font = fonts:loadFont("Awesome", 18),
	}))

	self:addChild("songs", Label({
		x = button_spacing * 6,
		text = "",
		font = fonts:loadFont("Awesome", 18),
	}))

	local progress_width = 214
	self:addChild("progress", Rectangle({
		x = -6,
		y = 25,
		width = 0,
		height = 5,
		alpha = 0.4,
		z = 0.1,
		update = function(this)
			local audio = select_api:getPreviewAudioSource()
			if audio then
				this.width = (audio:getPosition() / audio:getDuration()) * progress_width
			end

		end,
	}))

	self:addChild("progressBackground", Rectangle({
		x = -6,
		y = 25,
		width = progress_width,
		height = 5,
		clicked = false,
		alpha = 0.2,
		update = function(this)
			if this.clicked then
				this.clicked = false
				local mx, _ = love.graphics.inverseTransformPoint(love.mouse.getPosition())
				local position = math_util.clamp(mx / progress_width, 0, 1)
				setMusicPosition(position)
			end
		end,
		mousePressed = function(this)
			if not this.mouseOver then
				return false
			end
			this.clicked = true
			return true
		end
	}))

	self:autoSize()
end

return MusicControl
