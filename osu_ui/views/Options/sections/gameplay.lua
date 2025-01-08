local table_util = require("table_util")

local osuMania = require("sphere.models.RhythmModel.ScoreEngine.OsuManiaScoring")
local osuLegacy = require("sphere.models.RhythmModel.ScoreEngine.OsuLegacyScoring")
local etterna = require("sphere.models.RhythmModel.ScoreEngine.EtternaScoring")
local lr2 = require("sphere.models.RhythmModel.ScoreEngine.LunaticRaveScoring")
local timings = require("sphere.models.RhythmModel.ScoreEngine.timings")

local function getJudges(range)
	local t = {}

	for i = range[1], range[2], 1 do
		table.insert(t, i)
	end

	return t
end

local available_judges = {
	["osu!mania"] = getJudges(osuMania.metadata.range),
	["osu!legacy"] = getJudges(osuLegacy.metadata.range),
	["Etterna"] = getJudges(etterna.metadata.range),
	["Lunatic rave 2"] = getJudges(lr2.metadata.range),
}

local judge_format = {
	["osu!mania"] = osuMania.metadata.name,
	["osu!legacy"] = osuLegacy.metadata.name,
	["Etterna"] = etterna.metadata.name,
	["Lunatic rave 2"] = lr2.metadata.name,
}

local lunatic_rave_judges = {
	[0] = "Easy",
	[1] = "Normal",
	[2] = "Hard",
	[3] = "Very hard",
}

local timings_list = {
	["soundsphere"] = timings.soundsphere,
	["osu!mania"] = timings.osuMania,
	["osu!legacy"] = timings.osuLegacy,
	["Etterna"] = timings.etterna,
	["Quaver"] = timings.quaver,
	["Lunatic rave 2"] = timings.lr2,
}

local judge_prefix = {
	["osu!mania"] = "V2 OD %i",
	["osu!legacy"] = "OD %i",
	["Etterna"] = "J%i",
}

---@param score_system string
---@param judge number
---@param play_context sphere.PlayContext
local function updateScoringOptions(score_system, judge, play_context)
	local ss_timings = timings_list[score_system]
	if type(ss_timings) == "function" then
		play_context.timings = table_util.deepcopy(ss_timings(judge))
	else
		play_context.timings = table_util.deepcopy(ss_timings)
	end
end

local function judgeToString(score_system, judge)
	local format = judge_format[score_system]
	if format then
		return format:format(judge)
	end
	return score_system
end

---@param score_system string
local function isNearestDefault(score_system)
	local ss_timings = timings_list[score_system]
	if type(ss_timings) == "function" then
		return ss_timings(0).nearest
	else
		return ss_timings.nearest
	end
end

---@param section osu.ui.OptionsSection
return function(section)
	local config = section.options:getConfigs()
	local settings = config.settings
	local g = settings.gameplay
	local gf = settings.graphics
	local dim = gf.dim
	local osu = config.osu_ui ---@type osu.ui.OsuConfig

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	local gucci = scene.ui.pkgs.gucci
	local speed_model = scene.ui.game.speedModel
	local play_context = scene.ui.selectApi:getPlayContext()

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
			key = { play_context, "const" }
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
		local score_systems = {
			"soundsphere",
			"osu!mania",
			"osu!legacy",
			"Quaver",
			"Etterna",
			"Lunatic rave 2",
		}
		group:combo({
			label = text.Options_Gameplay_ScoreSystem,
			items = score_systems,
			getValue = function()
				return osu.scoreSystem
			end,
			setValue = function(index)
				local score_system = score_systems[index]
				local new_judges = available_judges[score_system]
				osu.scoreSystem = score_system
				osu.judgement = new_judges and new_judges[1] or 0
				config.select.judgements = judgeToString(score_system, osu.judgement)
				updateScoringOptions(score_system, osu.judgement, play_context)
				group:load()
				section.options:recalcPositions()
			end,
			format = function(v)
				if v == "osu!legacy" then
					return "osu!mania (scoreV1)"
				elseif v == "osu!mania" then
					return "osu!mania (scoreV2)"
				elseif gucci and v == "soundsphere" then
					return "Normalscore V2"
				end
				return v
			end
		})

		local judges = available_judges[osu.scoreSystem]

		if judges then
			group:combo({
				label = text.Options_Gameplay_Judgement,
				items = judges,
				getValue = function ()
					return osu.judgement
				end,
				setValue = function(index)
					local judge = judges[index]
					osu.judgement = judge
					config.select.judgements = judgeToString(osu.scoreSystem, judge)
					updateScoringOptions(osu.scoreSystem, judge, play_context)
				end,
				format = function(v)
					if osu.scoreSystem == "Lunatic rave 2" then
						return lunatic_rave_judges[v]
					end
					local prefix = judge_prefix[osu.scoreSystem]
					if prefix then
						return prefix:format(v)
					end
					return v
				end
			})
		end

		if play_context.timings then -- I don't know why, but it can be nil
			group:checkbox({
				label = text.Options_Gameplay_NearestInput,
				key = { play_context.timings, "nearest" },
			})
		end
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
