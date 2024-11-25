---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local osu = configs.osu_ui ---@cast osu osu.ui.OsuConfig

	section:group("GRAPHICS", function(group)
		group:checkbox({ label = "Enable blur",
			getValue = function ()
				return osu.graphics.blur
			end,
			clicked = function ()
				osu.graphics.blur = not osu.graphics.blur
				section.options:reloadViewport()
			end
		})

		group:slider({ label = "Blur quality", min = 0.1, max = 0.7, step = 0.01,
			getValue = function()
				return osu.graphics.blurQuality
			end,
			setValue = function(v)
				osu.graphics.blurQuality = v
			end,
			format = function(v)
			end
		})
	end)
end
