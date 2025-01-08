local audio = require("audio")
local formats = { "osu", "qua", "sm", "ksh" }

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local settings = configs.settings
	local a = settings.audio
	local g = settings.gameplay
	local m = settings.miscellaneous
	local osu = configs.osu_ui ---@cast osu osu.ui.OsuConfig
	local vol = a.volume
	---@type {[string]: number}
	local of = g.offset_format
	---@type {[string]: number}
	local oam = g.offset_audio_mode

	----- there is no log volume type in osu
	a.volumeType = "linear"

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	local function formatVolume(v)
		return ("%i%%"):format(v * 100)
	end
	local function formatMs(v)
		return ("%dms"):format(v * 1000)
	end

	section:group(text.Options_Audio_Volume, function (group)
		group:slider({ label = text.Options_Audio_Master, min = 0, max = 1, step = 0.01,
			getValue = function()
				return vol.master
			end,
			setValue = function(v)
				vol.master = v
			end,
			format = formatVolume
		})
		group:slider({ label = text.Options_Audio_Music, min = 0, max = 1, step = 0.01,
			getValue = function()
				return vol.music
			end,
			setValue = function(v)
				vol.music = v
			end,
			format = formatVolume
		})
		group:slider({ label = text.Options_Audio_Effect, min = 0, max = 1, step = 0.01,
			getValue = function()
				return vol.effects
			end,
			setValue = function(v)
				vol.effects = v
			end,
			format = formatVolume
		})
		group:slider({ label = text.Options_Audio_UserInterface, min = 0, max = 1, step = 0.01,
			getValue = function()
				return osu.uiVolume
			end,
			setValue = function(v)
				osu.uiVolume = v
			end,
			format = formatVolume
		})

		local mode = a.mode
		local pitch = mode.primary == "bass_sample" and true or false

		group:checkbox({ label = text.Options_Audio_RateChangesPitch, tooltip = text.Options_Audio_RateChangesPitch_Tooltip,
			getValue = function()
				pitch = mode.primary == "bass_sample" and true or false
				return pitch
			end,
			clicked = function()
				local audio_mode = not pitch and "bass_sample" or "bass_fx_tempo"
				mode.primary = audio_mode
				mode.secondary = audio_mode
			end
		})

		group:checkbox({ label = text.Options_Audio_AutoKeySound, tooltip = text.Options_Audio_AutoKeySound_Tooltip,
			getValue = function()
				return g.autoKeySound
			end,
			clicked = function()
				g.autoKeySound = not g.autoKeySound
			end
		})

		group:checkbox({ label = text.Options_Audio_MidiConstantVolume,
			getValue = function()
				return a.midi.constantVolume
			end,
			clicked = function()
				a.midi.constantVolume = not a.midi.constantVolume
			end
		})

		group:checkbox({ label = text.Options_Audio_MuteOnUnfocus,
			getValue = function()
				return a.muteOnUnfocus
			end,
			clicked = function()
				a.muteOnUnfocus = not a.muteOnUnfocus
			end
		})
	end)

	section:group(text.Options_Audio_Device, function (group)
		group:slider({ label = text.Options_Audio_UpdatePeriod, min = 1, max = 50, step = 1,
			getValue = function()
				return a.device.period
			end,
			setValue = function(v)
				a.device.period = v
			end,
		})

		group:slider({ label = text.Options_Audio_BufferLength, min = 1, max = 50, step = 1,
			getValue = function()
				return a.device.buffer
			end,
			setValue = function(v)
				a.device.buffer = v
			end,
		})

		group:slider({ label = text.Options_Audio_AdjustRate, min = 0, max = 1, step = 0.01,
			getValue = function()
				return a.adjustRate
			end,
			setValue = function(v)
				a.adjustRate = v
			end,
			format = function(v)
				return ("%0.02f"):format(v)
			end
		})

		group:button({ label = text.General_Apply, onClick = function()
			audio.setDevicePeriod(a.device.period)
			audio.setDeviceBuffer(a.device.buffer)
			audio.reinit()
		end})

		group:button({ label = text.General_Reset, onClick = function()
			a.device.period = audio.default_dev_period
			a.device.buffer = audio.default_dev_buffer
			audio.setDevicePeriod(a.device.period)
			audio.setDeviceBuffer(a.device.buffer)
			audio.reinit()
		end})
	end)

	section:group(text.Options_Audio_Offset, function (group)
		group:slider({ label = text.OptionsOffsetWizard_UniversalOffset, min = -0.3, max = 0.3, step = 0.001,
			getValue = function()
				return a.mode.primary == "bass_sample" and oam.bass_sample or oam.bass_fx_tempo
			end,
			setValue = function(v)
				if a.mode.primary == "bass_sample" then
					oam.bass_sample = v
				else
					oam.bass_fx_tempo = v
				end
			end,
			format = formatMs
		})
	end)

	section:group(text.Options_Audio_ChartFormatOffsets, function (group)
		for _, format in ipairs(formats) do
			group:slider({ label = format, min = -0.3, max = 0.3, step = 0.001,
				getValue = function()
					return of[format]
				end,
				setValue = function(v)
					of[format] = v
				end,
				format = formatMs
			})
		end
	end)
end
