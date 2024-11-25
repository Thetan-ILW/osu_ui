---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local settings = configs.settings
	local a = settings.audio
	local g = settings.gameplay
	local m = settings.miscellaneous
	local osu = configs.osu_ui
	local vol = a.volume
	---@type {[string]: number}
	local of = g.offset_format
	---@type {[string]: number}
	local oam = g.offset_audio_mode

	section:group("VOLUME", function (group)
		group:slider({label = "Master", min = 0, max = 1, step = 0.01,
			getValue = function ()
				return vol.master
			end,
			setValue = function (v)
				vol.master = v
			end
		})
	end)
end
