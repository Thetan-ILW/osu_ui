local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")
local table_util = require("table_util")

local tempo_factor_list = { "average", "primary", "minimum", "maximum" }

local osuMania = require("sphere.models.RhythmModel.ScoreEngine.OsuManiaScoring")
local osuLegacy = require("sphere.models.RhythmModel.ScoreEngine.OsuLegacyScoring")
local etterna = require("sphere.models.RhythmModel.ScoreEngine.EtternaScoring")
local lr2 = require("sphere.models.RhythmModel.ScoreEngine.LunaticRaveScoring")

local timings = require("sphere.models.RhythmModel.ScoreEngine.timings")

local score_systems = {
	"soundsphere",
	"osu!mania",
	"osu!legacy",
	"Quaver",
	"Etterna",
	"Lunatic rave 2",
}

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

---@param score_system string
local function isNearestDefault(score_system)
	local ss_timings = timings_list[score_system]
	if type(ss_timings) == "function" then
		return ss_timings(0).nearest
	else
		return ss_timings.nearest
	end
end

---@param assets osu.OsuAssets
---@param view osu.SettingsView
---@return osu.SettingsView.GroupContainer?
return function(assets, view)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local config = view.game.configModel.configs
	local settings = config.settings
	local g = settings.gameplay
	local gf = settings.graphics
	local dim = gf.dim
	local blur = gf.blur
	---@type osu.OsuConfig
	local osu = config.osu_ui
	---@type sphere.SpeedModel
	local speed_model = view.game.speedModel
	local play_context = view.game.playContext
	local note_timings = view.game.playContext.timings

	local c = GroupContainer(text.gameplay, assets, font, assets.images.gameplayTab)

	Elements.assets = assets
	Elements.currentContainer = c
	local checkbox = Elements.checkbox
	local combo = Elements.combo
	local slider = Elements.slider

	c:createGroup("scrollSpeed", text.scrollSpeed)
	Elements.currentGroup = "scrollSpeed"

	---@type number[]
	local speed_range = speed_model.range[g.speedType]
	local speed_params = { min = speed_range[1], max = speed_range[2], increment = speed_range[3] }

	combo(text.scrollSpeedType, "osu", nil, function()
		return g.speedType, speed_model.types
	end, function(v)
		g.speedType = v

		---@type number[]
		speed_range = speed_model.range[g.speedType]
		speed_params = { min = speed_range[1], max = speed_range[2], increment = speed_range[3] }
	end, function(v)
		if v == "osu" then
			return "osu!"
		end
		return "soundsphere"
	end)

	combo(text.tempoFactor, "average", text.tempoFactorTip, function()
		return g.tempoFactor, tempo_factor_list
	end, function(v)
		g.tempoFactor = v
		view:build("gameplay")
	end, function(v)
		return text[v]
	end)

	local primary_tempo_params = { min = 60, max = 240, increment = 1 }

	if g.tempoFactor == "primary" then
		Elements.sliderPixelWidth = 280
		slider(text.primaryTempo, 120, nil, function()
			return g.primaryTempo, primary_tempo_params
		end, function(v)
			g.primaryTempo = v
		end, function(v)
			return ("%iBPM"):format(v)
		end)
	end

	slider(text.scrollSpeedLower, nil, nil, function()
		return speed_model:get(), speed_params
	end, function(v)
		speed_model:set(v)
	end)

	Elements.sliderPixelWidth = nil

	checkbox(text.constScrollSpeed, false, nil, function()
		return play_context.const
	end, function()
		play_context.const = not play_context.const
	end)

	checkbox(text.taikoSV, false, nil, function()
		return g.swapVelocityType
	end, function()
		g.swapVelocityType = not g.swapVelocityType
		g.eventBasedRender = g.swapVelocityType
		g.scaleSpeed = g.swapVelocityType
		view:build("gameplay")
	end)

	if not g.swapVelocityType then
		checkbox(text.scaleScrollSpeed, false, nil, function()
			return g.scaleSpeed
		end, function()
			g.scaleSpeed = not g.scaleSpeed
		end)
	end

	c:createGroup("scoring", text.scoring)
	Elements.currentGroup = "scoring"

	combo(text.scoreSystem, "soundsphere", nil, function()
		return osu.scoreSystem, score_systems
	end, function(v)
		local new_judges = available_judges[v]
		osu.scoreSystem = v
		osu.judgement = new_judges and new_judges[1] or 0
		updateScoringOptions(v, osu.judgement, play_context)
		view:build("gameplay")
	end, function(v)
		if v == "osu!legacy" then
			return "osu!mania (scoreV1)"
		elseif v == "osu!mania" then
			return "osu!mania (scoreV2)"
		end
		return v
	end)

	local judges = available_judges[osu.scoreSystem]

	if judges then
		combo(text.judgement, nil, nil, function()
			return osu.judgement, judges
		end, function(v)
			osu.judgement = v
			updateScoringOptions(osu.scoreSystem, v, play_context)
		end, function(v)
			if osu.scoreSystem == "Lunatic rave 2" then
				return lunatic_rave_judges[v]
			end
			return v
		end)
	end

	checkbox(text.nearestInput, isNearestDefault(osu.scoreSystem), nil, function()
		return note_timings.nearest
	end, function()
		note_timings.nearest = not note_timings.nearest
	end)

	c:createGroup("health", text.health)
	Elements.currentGroup = "health"

	local action_on_fail_list = { "none", "pause", "quit" }
	combo(text.actionOnFail, "none", nil, function()
		return g.actionOnFail, action_on_fail_list
	end, function(v)
		g.actionOnFail = v
	end, function(v)
		return text[v]
	end)

	local max_hp_params = { min = 1, max = 100, increment = 1 }
	slider(text.maxHP, 20, nil, function()
		return g.hp.notes, max_hp_params
	end, function(v)
		g.hp.notes = v
	end)

	checkbox(text.autoShift, false, nil, function()
		return g.hp.shift
	end, function()
		g.hp.shift = not g.hp.shift
	end)

	c:createGroup("visuals", text.visuals)
	Elements.currentGroup = "visuals"

	Elements.sliderPixelWidth = 265

	local background_params = { min = 0, max = 1, increment = 0.01 }
	slider(text.backgroundDim, 0.8, nil, function()
		return dim.gameplay, background_params
	end, function(v)
		dim.gameplay = v
	end, function(v)
		return ("%i%%"):format(v * 100)
	end)

	local blur_params = { min = 0, max = 20, increment = 1 }

	slider(text.backgroundBlur, 0, nil, function()
		return blur.gameplay, blur_params
	end, function(v)
		blur.gameplay = v
	end, function(v)
		return ("%i%%"):format(v * 100)
	end)

	Elements.sliderPixelWidth = nil

	c:createGroup("other", text.other)
	Elements.currentGroup = "other"

	local rating_window_params = { min = -0.16, max = 0.16, increment = 0.001 }
	slider(text.ratingWindow, 0.032, nil, function()
		return g.ratingHitTimingWindow, rating_window_params
	end, function(v)
		g.ratingHitTimingWindow = v
	end, function(v)
		return ("%ims"):format(v * 1000)
	end)

	local last_mean_values_params = { min = -100, max = 100, increment = 1 }
	slider(text.lastMeanValues, 10, nil, function()
		return g.lastMeanValues, last_mean_values_params
	end, function(v)
		g.lastMeanValues = v
	end)

	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
