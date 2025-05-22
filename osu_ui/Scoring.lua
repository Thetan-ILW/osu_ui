--local osuMania = require("sphere.models.RhythmModel.ScoreEngine.OsuManiaScoring")
--local osuLegacy = require("sphere.models.RhythmModel.ScoreEngine.OsuLegacyScoring")
--local etterna = require("sphere.models.RhythmModel.ScoreEngine.EtternaScoring")
--local lr2 = require("sphere.models.RhythmModel.ScoreEngine.LunaticRaveScoring")
--local timings = require("sphere.models.RhythmModel.ScoreEngine.timings")
--local ScoreSystemContainer = require("sphere.models.RhythmModel.ScoreEngine.ScoreSystemContainer")

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

---@param score_system_name string
---@param judgement number
---@return table?
function Scoring.getTimings(score_system_name, judgement)
	for _, score_system in ipairs(ScoreSystemContainer.modules) do
		if score_system.name == score_system_name then
			return score_system.getTimings(nil, judgement)
		end
	end
end

---@param score_system string
---@return boolean
function Scoring.isOsu(score_system)
	if score_system == "osuLegacy" then
		return true
	elseif score_system == "osuMania" then
		return true
	end
	return false
end

---@param score_system_name string
---@param direction 1 | -1
---@return string score_system_name
function Scoring.scrollScoreSystem(score_system_name, direction)
	local s = {}

	local score_systems = ScoreSystemContainer.modules
	for i, score_system in ipairs(score_systems) do
		if score_system.getTimings then
			table.insert(s, score_system)
			print(score_system.name)
		end
	end

	for i, score_system in ipairs(s) do
		if score_system_name == score_system.name then
			return s[math_util.clamp(i + direction, 1, #s)].name
		end
	end

	return s[1]
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
