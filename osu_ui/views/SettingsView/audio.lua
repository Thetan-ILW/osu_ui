local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")

local audio = require("audio")

local formats = { "osu", "qua", "sm", "ksh" }
local audio_modes = { "bass_sample", "bass_fx_tempo" }

local function formatMs(v)
	return ("%dms"):format(v)
end

---@param assets osu.OsuAssets
---@param view osu.SettingsView
---@return osu.SettingsView.GroupContainer?
return function(assets, view)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local configs = view.game.configModel.configs
	local settings = configs.settings
	local a = settings.audio
	local g = settings.gameplay
	local m = settings.miscellaneous
	local osu = configs.osu_ui
	local vol = a.volume
	---@type table<string, number>
	local of = g.offset_format
	---@type table<string, number>
	local oam = g.offset_audio_mode

	local c = GroupContainer(text.audio, assets, font, assets.images.audioTab)

	----- there is no log volume type in osu
	a.volumeType = "linear"

	Elements.assets = assets
	Elements.currentContainer = c
	local checkbox = Elements.checkbox
	local slider = Elements.slider
	local button = Elements.button

	--------------- VOLUME ---------------
	c:createGroup("volume", text.volume)
	Elements.currentGroup = "volume"

	local linear_volume = { min = 0, max = 1, increment = 0.01 }

	Elements.sliderPixelWidth = 340

	local volume_format = function(v)
		return ("%i%%"):format(v * 100)
	end

	slider(text.master, 0.2, nil, function()
		return vol.master, linear_volume
	end, function(v)
		vol.master = v
		assets:updateVolume(view.game.configModel)
	end, volume_format)

	slider(text.music, 1, nil, function()
		return vol.music, linear_volume
	end, function(v)
		vol.music = v
	end, volume_format)

	slider(text.effect, 1, nil, function()
		return vol.effects, linear_volume
	end, function(v)
		vol.effects = v
	end, volume_format)

	slider(text.ui, 0.4, nil, function()
		return osu.uiVolume, linear_volume
	end, function(v)
		osu.uiVolume = v
		assets:updateVolume(view.game.configModel)
	end, volume_format)

	local mode = a.mode
	local pitch = mode.primary == "bass_sample" and true or false

	checkbox(text.rateChangesPitch, false, text.rateChangesPitchTip, function()
		pitch = mode.primary == "bass_sample" and true or false
		return pitch
	end, function()
		local audio_mode = not pitch and "bass_sample" or "bass_fx_tempo"
		mode.primary = audio_mode
		mode.secondary = audio_mode
	end)

	checkbox(text.autoKeySound, false, text.autoKeySoundTip, function()
		return g.autoKeySound
	end, function()
		g.autoKeySound = not g.autoKeySound
	end)

	checkbox(text.midiConstantVolume, false, nil, function()
		return a.midi.constantVolume
	end, function()
		a.midi.constantVolume = not a.midi.constantVolume
	end)

	checkbox(text.muteOnUnfocus, false, nil, function()
		return a.muteOnUnfocus
	end, function()
		a.muteOnUnfocus = not a.muteOnUnfocus
	end)

	c:createGroup("device", text.device)
	Elements.currentGroup = "device"

	Elements.sliderPixelWidth = 290

	local period_and_buffer = { min = 1, max = 50, increment = 1 }
	slider(text.updatePeriod, 10, nil, function()
		return a.device.period, period_and_buffer
	end, function(v)
		a.device.period = v
	end, formatMs)

	slider(text.bufferLength, 40, nil, function()
		return a.device.buffer, period_and_buffer
	end, function(v)
		a.device.buffer = v
	end, formatMs)

	slider(text.adjustRate, 0.1, nil, function()
		return a.adjustRate, { min = 0, max = 1, increment = 0.01 }
	end, function(v)
		a.adjustRate = v
	end, function(v)
		return ("%0.02f"):format(v)
	end)

	button(text.apply, function()
		audio.setDevicePeriod(a.device.period)
		audio.setDeviceBuffer(a.device.buffer)
		audio.reinit()
	end)
	button(text.reset, function()
		a.device.period = audio.default_dev_period
		a.device.buffer = audio.default_dev_buffer
		audio.setDevicePeriod(a.device.period)
		audio.setDeviceBuffer(a.device.buffer)
		audio.reinit()
	end)

	Elements.sliderPixelWidth = nil

	c:createGroup("offsetAdjustment", text.offsetAdjustment)
	Elements.currentGroup = "offsetAdjustment"

	local offset = { min = -300, max = 300, increment = 1 }

	if mode.primary == "bass_sample" then
		slider(text.universalOffset, 0, nil, function()
			return oam.bass_sample, offset
		end, function(v)
			oam.bass_sample = v
		end, formatMs)
	else
		slider(text.universalOffset, 0, nil, function()
			return oam.bass_fx_tempo, offset
		end, function(v)
			oam.bass_fx_tempo = v
		end, formatMs)
	end

	c:createGroup("chartFormatOffsets", text.chartFormatOffsets)
	Elements.currentGroup = "chartFormatOffsets"

	Elements.sliderPixelWidth = 360

	for _, format in ipairs(formats) do
		slider(("%s:"):format(format), 0, nil, function()
			return of[format], offset
		end, function(v)
			of[format] = v
		end, formatMs)
	end

	Elements.sliderPixelWidth = nil
	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
