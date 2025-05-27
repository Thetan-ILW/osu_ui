local Timings = require("sea.chart.Timings")
local Subtimings = require("sea.chart.Subtimings")
local TimingValuesFactory = require("sea.chart.TimingValuesFactory")

---@param section osu.ui.OptionsSection
return function(section)
	local config = section.options:getConfigs()
	local settings = config.settings
	local g = settings.gameplay
	local gf = settings.graphics
	local dim = gf.dim
	local time = g.time
	local osu = config.osu_ui ---@type osu.ui.OsuConfig
	local timings_config = settings.timings

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text
	local select_api = scene.ui.selectApi

	local gucci = scene.ui.pkgs.gucci
	local speed_model = scene.ui.game.speedModel
	local replay_base = select_api:getReplayBase()

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

			group:slider({
				label = text.FunSpoiler_BackgroundDim,
				min = 0,
				max = 1,
				step = 0.01,
				key = { dim, "gameplay" },
				format = function(v)
					return ("%i%%"):format(v * 100)
				end
			})
		end
	end)

	section:group(text.Options_Gameplay_ScrollSpeed, function(group)
		group:combo({
			label = text.Options_Gameplay_ScrollSpeedType,
			items = speed_model.types,
			getValue = function ()
				return g.speedType
			end,
			setValue = function(index)
				g.speedType = speed_model.types[index]
				group:load()
				section.options:recalcPositions()
			end,
			format = function(v)
				if v == "osu" then
					return "osu!"
				end
				return gucci and "gucci!mania" or "soundsphere"
			end
		})

		local tempo_factors = { "average", "primary", "minimum", "maximum" }
		group:combo({
			label = text.Options_Gameplay_TempoFactor,
			items = tempo_factors,
			getValue = function ()
				return g.tempoFactor
			end,
			setValue = function(index)
				g.tempoFactor = tempo_factors[index]
				group:load()
				section.options:recalcPositions()
			end,
			format = function(v)
				if v == "average" then
					return text.Options_Gameplay_Average
				elseif v == "primary" then
					return text.Options_Gameplay_Primary
				elseif v == "minimum" then
					return text.Options_Gameplay_Minimum
				else
					return text.Options_Gameplay_Maximum
				end
			end
		})

		if g.tempoFactor == "primary" then
			group:slider({
				label = text.Options_Gameplay_PrimaryTempo,
				min = 60,
				max = 240,
				step = 1,
				key = { g, "primaryTempo" },
			})
		end

		local speed_range = speed_model.range[g.speedType]
		group:slider({
			label = text.Options_Gameplay_ScrollSpeedLol,
			min = speed_range[1],
			max = speed_range[2],
			step = g.speedType == "osu" and 1 or 0.01,
			getValue = function ()
				return speed_model:get()
			end,
			setValue = function(v)
				return speed_model:set(v)
			end,
			format = function(v)
				return ("%0.02f"):format(v)
			end
		})

		group:checkbox({
			label = text.Options_Gameplay_ConstantScrollSpeed,
			key = { replay_base, "const" }
		})

		group:checkbox({
			label = "Taiko SV",
			getValue = function()
				return g.swapVelocityType
			end,
			clicked = function()
				g.swapVelocityType = not g.swapVelocityType
				g.eventBasedRender = g.swapVelocityType
				g.scaleSpeed = g.swapVelocityType
				group:load()
				section.options:recalcPositions()
			end
		})

		if not g.swapVelocityType then
			group:checkbox({
				label = text.Options_Gameplay_ScaleScrollSpeedWithRate,
				key = { g, "scaleSpeed" }
			})
		end
	end)

	section:group(text.Options_Gameplay_Scoring, function(group)
		group:checkbox({
			label = text.Options_Gameplay_OverrideScoreSystem,
			getValue = function ()
				return not settings.replay_base.auto_timings
			end,
			clicked = function ()
				settings.replay_base.auto_timings = not settings.replay_base.auto_timings
				group:reload()
				section.options:recalcPositions()
			end
		})

		local metadatas = select_api:getScoreSystemMetadatas()
		local meta = select_api:getScoreSystemMetadataFrom(replay_base.timings, replay_base.subtimings)

		group:combo({
			label = text.Options_Gameplay_ScoreSystem,
			items = metadatas,
			locked = settings.replay_base.auto_timings,
			getValue = function ()
				if settings.replay_base.auto_timings then
					return "Chart specific score system"
				end
				local timings = replay_base.timings
				local subtimings = replay_base.subtimings
				return select_api:getScoreSystemMetadataFrom(timings, subtimings) or "Unknown"
			end,
			setValue = function (index)
				local meta = metadatas[index]
				replay_base.timings = Timings(meta.timings_name, meta.timings_data_default or meta.timings_data_min)

				if meta.subtimings_name then
					replay_base.subtimings = Subtimings(meta.subtimings_name, meta.subtimings_data)
				else
					replay_base.subtimings = nil
				end

				if replay_base.timings ~= "arbitrary" then
					replay_base.timing_values = assert(TimingValuesFactory:get(replay_base.timings, replay_base.subtimings))
				end

				section:getViewport():triggerEvent("event_modsChanged")
				group:load()
				section.options:recalcPositions()
			end,
			format = function(v)
				return v.display_name
			end
		})

		if not meta then
			return
		end

		if settings.replay_base.auto_timings then
			return
		end

		if meta.timings_data_type == "number" then
			group:slider({
				label = text.Options_Gameplay_Judgement,
				min = meta.timings_data_min,
				max = meta.timings_data_max,
				step = meta.timings_data_step,
				getValue = function ()
					return replay_base.timings.data
				end,
				setValue = function (v)
					if meta.transformTimingData then
						v = meta.transformTimingData(v)
					end
					replay_base.timings = Timings(replay_base.timings.name, v)
					replay_base.timing_values = assert(TimingValuesFactory:get(replay_base.timings, replay_base.subtimings))
					timings_config[replay_base.timings.name] = v
					section:getViewport():triggerEvent("event_modsChanged")
				end
			})
		elseif meta.timings_data_type == "string" then
			group:combo({
				label = text.Options_Gameplay_Judgement,
				items = meta.timings_data_list,
				getValue = function ()
					return meta.timings_data_list[replay_base.timings.data + 1]
				end,
				setValue = function (index)
					index = index - 1
					replay_base.timings = Timings(replay_base.timings.name, index)
					replay_base.timing_values = assert(TimingValuesFactory:get(replay_base.timings, replay_base.subtimings))
					timings_config[replay_base.timings.name] = index
					section:getViewport():triggerEvent("event_modsChanged")
				end
			})
		end
	end)

	section:group(text.Options_Gameplay_Timings, function(group)
		local formatTime = function (v)
			return text.Options_Gameplay_TimeFormat:format(v)
		end
		group:slider({
			label = text.Options_Gameplay_PreparationTime,
			min = 0.5, max = 3, step = 0.1,
			key = { time, "prepare" },
			format = formatTime
		})

		time.pauseRetry = time.playRetry
		group:slider({
			label = text.Options_Gameplay_TimeBeforeRestart,
			min = 0, max = 3, step = 0.1,
			format = formatTime,
			getValue = function ()
				return time.playRetry
			end,
			setValue = function(v)
				time.playRetry = v
				time.pauseRetry = v
			end,
		})

		group:slider({
			label = text.Options_Gameplay_TimeBeforePause,
			min = 0, max = 3, step = 0.1,
			key = { time, "playPause" },
			format = formatTime,
		})
	end)

	section:group(text.Options_Gameplay_Health, function(group)
		local action_on_fail_list = { "none", "pause", "quit" }
		group:combo({
			label = text.Options_Gameplay_ActionOnFail,
			items = action_on_fail_list,
			key = { g, "actionOnFail" },
			format = function(v)
				if v == "none" then
					return text.Options_Gameplay_ActionNone
				elseif v == "pause" then
					return text.Options_Gameplay_ActionPause
				else
					return text.Options_Gameplay_ActionQuit
				end
			end
		})

		group:slider({
			label = text.Options_Gameplay_MaxHealth,
			min = 1,
			max = 100,
			step = 1,
			key = { g.hp, "notes" }
		})

		group:checkbox({
			label = text.Options_Gameplay_AutoShift,
			key = { g.hp, "shift" }
		})
	end)
end
