local osuMania = require("sphere.models.RhythmModel.ScoreEngine.OsuManiaScoring")
local osuLegacy = require("sphere.models.RhythmModel.ScoreEngine.OsuLegacyScoring")
local etterna = require("sphere.models.RhythmModel.ScoreEngine.EtternaScoring")
local lr2 = require("sphere.models.RhythmModel.ScoreEngine.LunaticRaveScoring")
local timings = require("sphere.models.RhythmModel.ScoreEngine.timings")

local math_util = require("math_util")

local Scoring = {}

function Scoring.getGrade(scoreSystemName, accuracy)
	if scoreSystemName == "osuMania" or scoreSystemName == "osuLegacy" then
		if accuracy == 1 then
			return "SS"
		elseif accuracy > 0.95 then
			return "S"
		elseif accuracy > 0.9 then
			return "A"
		elseif accuracy > 0.8 then
			return "B"
		elseif accuracy > 0.7 then
			return "C"
		else
			return "D"
		end
	elseif scoreSystemName == "etterna" then
		if accuracy > 0.999935 then
			return "AAAAA"
		elseif accuracy > 0.99955 then
			return "AAAA"
		elseif accuracy > 0.997 then
			return "AAA"
		elseif accuracy > 0.93 then
			return "AA"
		elseif accuracy > 0.85 then
			return "A"
		elseif accuracy > 0.8 then
			return "B"
		elseif accuracy > 0.7 then
			return "C"
		else
			return "F"
		end
	elseif scoreSystemName == "quaver" then
		if accuracy == 1 then
			return "X"
		elseif accuracy > 0.99 then
			return "SS"
		elseif accuracy > 0.95 then
			return "S"
		elseif accuracy > 0.9 then
			return "A"
		elseif accuracy > 0.8 then
			return "B"
		elseif accuracy > 0.7 then
			return "C"
		elseif accuracy > 0.6 then
			return "D"
		else
			return "F"
		end
	elseif scoreSystemName == "lr2" then
		if accuracy > 0.8888 then
			return "AAA"
		elseif accuracy > 0.7777 then
			return "AA"
		elseif accuracy > 0.6666 then
			return "A"
		elseif accuracy > 0.5555 then
			return "B"
		elseif accuracy > 0.4444 then
			return "C"
		elseif accuracy > 0.3333 then
			return "D"
		elseif accuracy > 0.2222 then
			return "E"
		else
			return "F"
		end
	end

	return "-"
end

function Scoring.convertGradeToOsu(grade)
	if grade == "AAAAA" or grade == "AAAA" or grade == "AAA" or grade == "SS" then
		return "X"
	elseif grade == "AA" then
		return "S"
	elseif grade == "F" then
		return "D"
	end

	return grade
end

---@param format string
---@param osu_od number?
---@return number
function Scoring.getOD(format, osu_od)
	if osu_od then
		return math_util.round(math_util.clamp(osu_od, 0, 10), 1)
	end

	if format == "sm" or format == "ssc" then
		return 9
	elseif format == "ojn" then
		return 7
	else
		return 8
	end
end

---@param score_system string
---@param judgement number
---@return table
function Scoring.getTimings(score_system, judgement)
	if score_system == "soundsphere" then
		return timings.soundsphere
	elseif score_system == "osu!legacy" then
		return timings.osuLegacy(judgement)
	elseif score_system == "osu!mania" then
		return timings.osuMania(judgement)
	elseif score_system == "Quaver" then
		return timings.quaver
	elseif score_system == "Etterna" then
		return timings.etterna
	elseif score_system == "Lunatic rave 2" then
		return timings.lr2
	end

	error("Not implemented")
end

---@param score_system string
---@return boolean
function Scoring.isOsu(score_system)
	if score_system == "osu!legacy" then
		return true
	elseif score_system == "osu!mania" then
		return true
	end
	return false
end

local score_systems = {
	"soundsphere",
	"osu!mania",
	"osu!legacy",
	"Etterna",
	"Quaver standard",
	"Lunatic rave 2"
}

local judge_format = {
	["osu!mania"] = osuMania.metadata.name,
	["osu!legacy"] = osuLegacy.metadata.name,
	["Etterna"] = etterna.metadata.name,
	["Lunatic rave 2"] = lr2.metadata.name,
}

local judge_ranges = {
	["osu!mania"] = osuMania.metadata.range,
	["osu!legacy"] = osuLegacy.metadata.range,
	["Etterna"] = etterna.metadata.range,
	["Lunatic rave 2"] = lr2.metadata.range,
}

local lunatic_rave_judges = {
	[0] = "Easy",
	[1] = "Normal",
	[2] = "Hard",
	[3] = "Very hard",
}

function Scoring.clampJudgeNum(score_system_name, judge_num)
	local ranges = judge_ranges[score_system_name]
	if ranges then
		return math_util.clamp(judge_num, ranges[1], ranges[2])
	end
	return judge_num
end

---@param score_system_name string
---@param judge_num number
function Scoring.getJudgeName(score_system_name, judge_num)
	if score_system_name == "Lunatic rave 2" then
		return judge_format[score_system_name]:format(lunatic_rave_judges[judge_num])
	elseif judge_format[score_system_name] then
		return judge_format[score_system_name]:format(judge_num)
	end

	return score_system_name
end

function Scoring.scrollScoreSystem(score_system_name, direction)
	for i, v in ipairs(score_systems) do
		if score_system_name == v then
			return score_systems[math_util.clamp(i + direction, 1, #score_systems)]
		end
	end
	return score_systems[1]
end

Scoring.counterColors = {
	soundsphere = {
		perfect = { 1, 1, 1, 1 },
		["not perfect"] = { 1, 0.6, 0.4, 1 },
	},
	osuMania = {
		perfect = { 0.6, 0.8, 1, 1 },
		great = { 0.95, 0.796, 0.188, 1 },
		good = { 0.07, 0.8, 0.56, 1 },
		ok = { 0.1, 0.39, 1, 1 },
		meh = { 0.42, 0.48, 0.51, 1 },
	},
	osuLegacy = {
		perfect = { 0.6, 0.8, 1, 1 },
		great = { 0.95, 0.796, 0.188, 1 },
		good = { 0.07, 0.8, 0.56, 1 },
		ok = { 0.1, 0.39, 1, 1 },
		meh = { 0.42, 0.48, 0.51, 1 },
	},
	etterna = {
		marvelous = { 0.6, 0.8, 1, 1 },
		perfect = { 0.95, 0.796, 0.188, 1 },
		great = { 0.07, 0.8, 0.56, 1 },
		bad = { 0.1, 0.7, 1, 1 },
		boo = { 1, 0.1, 0.7, 1 },
	},
	quaver = {
		marvelous = { 1, 1, 0.71, 1 },
		perfect = { 1, 0.91, 0.44, 1 },
		great = { 0.38, 0.96, 0.47, 1 },
		good = { 0.25, 0.7, 0.75, 1 },
		okay = { 0.72, 0.46, 0.65, 1 },
	},
	lr2 = {
		pgreat = { 0.6, 0.8, 1, 1 },
		great = { 0.95, 0.796, 0.188, 1 },
		good = { 1, 0.69, 0.24, 1 },
		bad = { 1, 0.5, 0.24, 1 },
	},
}

Scoring.gradeColors = {
	soundsphere = {
		["-"] = { 1, 1, 1, 1 },
	},
	osuMania = {
		SS = { 0.6, 0.8, 1, 1 },
		S = { 0.95, 0.796, 0.188, 1 },
		A = { 0.07, 0.8, 0.56, 1 },
		B = { 0.1, 0.39, 1, 1 },
		C = { 0.42, 0.48, 0.51, 1 },
		D = { 0.51, 0.37, 0, 1 },
	},
	osuLegacy = {
		SS = { 0.6, 0.8, 1, 1 },
		S = { 0.95, 0.796, 0.188, 1 },
		A = { 0.07, 0.8, 0.56, 1 },
		B = { 0.1, 0.39, 1, 1 },
		C = { 0.42, 0.48, 0.51, 1 },
		D = { 0.51, 0.37, 0, 1 },
	},
	etterna = {
		AAAAA = { 1, 1, 1, 1 },
		AAAA = { 0.6, 0.8, 1, 1 },
		AAA = { 0.95, 0.796, 0.188, 1 },
		AA = { 0.07, 0.8, 0.56, 1 },
		A = { 0, 0.7, 0.32, 1 },
		B = { 0.1, 0.7, 1, 1 },
		C = { 1, 0.1, 0.7, 1 },
		F = { 0.51, 0.37, 0, 1 },
	},
	quaver = {
		X = { 0.6, 0.8, 1, 1 },
		S = { 0.95, 0.796, 0.188, 1 },
		A = { 0.95, 0.796, 0.188, 1 },
		B = { 0.07, 0.8, 0.56, 1 },
		C = { 0.1, 0.39, 1, 1 },
		D = { 0.42, 0.48, 0.51, 1 },
		F = { 0.51, 0.37, 0, 1 },
	},
	lr2 = {
		AAA = { 0.95, 0.796, 0.188, 1 },
		AA = { 0.07, 0.8, 0.56, 1 },
		A = { 0, 0.7, 0.32, 1 },
		B = { 0.1, 0.7, 1, 1 },
		C = { 1, 0.1, 0.7, 1 },
		E = { 1, 0.1, 0.7, 1 },
		F = { 0.51, 0.37, 0, 1 },
	},
}

return Scoring
