---@param section osu.ui.OptionsSection
return function(section)
	local config = section.options:getConfigs()
	local settings = config.settings
	local g = settings.gameplay
	local gf = settings.graphics
	local osu = config.osu_ui ---@type osu.ui.OsuConfig

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	section:group(text.Options_Screen, function(group)
		group:checkbox({
			label = text.Options_Graphics_Letterboxing,
			tooltip = text.Options_Graphics_Letterboxing_Tooltip,
			getValue = function()
				return osu.gameplay.nativeRes
			end,
			clicked = function ()
				osu.gameplay.nativeRes = not osu.gameplay.nativeRes
				group:load()
				section.options:recalcPositions()
			end
		})

		if osu.gameplay.nativeRes then
			local modes = love.window.getFullscreenModes()

			if not osu.gameplay.nativeResSize then
				osu.gameplay.nativeResSize = modes[1]
			end

			group:combo({
				label = text.Options_Graphics_SelectResolution,
				items = modes,
				key = { osu.gameplay, "nativeResSize" },
				format = function(v)
					return v.width .. "x" .. v.height
				end
			})

			group:slider({
				label = text.Options_Graphics_LetterboxPositionX,
				min = 0,
				max = 1,
				step = 0.01,
				key = { osu.gameplay, "nativeResX" },
				format = function(v)
					return ("%i%%"):format(v * 100)
				end
			})

			group:slider({
				label = text.Options_Graphics_LetterboxPositionY,
				min = 0,
				max = 1,
				step = 0.01,
				key = { osu.gameplay, "nativeResY" },
				format = function(v)
					return ("%i%%"):format(v * 100)
				end
			})
		end
	end)
end
