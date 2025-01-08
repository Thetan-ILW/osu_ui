---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local gp = configs.settings.gameplay
	local g = configs.settings.graphics

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text
	local play_context = scene.ui.selectApi:getPlayContext()

	section:group(text.Options_Audio_Offset, function(group)
		group:slider({
			label = text.Options_Input_InputOffset,
			min = -300,
			max = 300,
			step = 1,
			key = { gp.offset, "input" }
		})

		group:slider({
			label = text.Options_Input_VisualOffset,
			min = -300,
			max = 300,
			step = 1,
			key = { gp.offset, "visual" }
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

	section:group(text.Options_Input_Other, function(group)
		group:checkbox({
			label = text.Options_Input_ThreadedInput,
			key = { g, "asynckey" }
		})

		group:checkbox({
			label = text.Options_Input_TaikoNoteHandler,
			key = { play_context, "single" }
		})
	end)
end
