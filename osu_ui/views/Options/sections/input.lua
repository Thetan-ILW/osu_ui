---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local gp = configs.settings.gameplay
	local g = configs.settings.graphics

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	section:group(text.Options_Input_Keyboard, function(group)
		group:button({
			label = text.Options_OsuManiaLayout,
			onClick = function()
				scene:openModal("inputsModal")
			end
		})

		group:checkbox({
			label = text.Options_Input_ThreadedInput,
			key = { g, "asynckey" }
		})
	end)

	section:group(text.Options_Audio_Offset, function(group)
		local formatMs = function (v)
			return ("%ims"):format(v * 1000)
		end
		group:slider({
			label = text.Options_Input_InputOffset,
			min = -0.3,
			max = 0.3,
			step = 0.001,
			key = { gp.offset, "input" },
			format = formatMs
		})

		group:slider({
			label = text.Options_Input_VisualOffset,
			min = -0.3,
			max = 0.3,
			step = 0.001,
			key = { gp.offset, "visual" },
			format = formatMs
		})

		group:checkbox({
			label = text.Options_Input_MultiplyInputOffsetByRate,
			key = { gp.offsetScale, "input" }
		})

		group:checkbox({
			label = text.Options_Input_MultiplyVisualOffsetByRate,
			key = { gp.offsetScale, "visual" }
		})
	end)
end
