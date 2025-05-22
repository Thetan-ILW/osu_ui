local class = require("class")
local math_util = require("math_util")

local osuPP = require("osu_ui.osu_pp")
local Format = require("sphere.views.Format")

local Scoring = require("osu_ui.Scoring")
local Msd = require("osu_ui.Msd")

---@class osu.ui.ResultDisplayInfo
---@operator call: osu.ui.ResultDisplayInfo
local DisplayInfo = class()

---@param localization Localization
---@param select_api game.SelectAPI
---@param result_api game.ResultAPI
function DisplayInfo:new(localization, select_api, result_api, manip_factor)
	self.text = localization.text
	self.selectApi = select_api
	self.resultApi = result_api
	self.manipFactor = manip_factor
	self.configs = select_api:getConfigs()
end

function DisplayInfo:load()
	self.chartview = self.selectApi:getChartview()
	self.chartdiff = self.resultApi:getChartdiffFromScore()
	self.replayBase = self.selectApi:getReplayBase()
	self.scoreItem = self.resultApi:getScoreItem()

	self.chartName = "No chart name - No chart name"
	self.chartSource = "No chart source"
	self.playInfo = "No play info"

	self.rank = 0
	self.score = 10000000
	self.scoreFormat = "%07d"
	self.combo = 0
	self.grade = "D"
	self.pp = 0
	self.spam = 0
	self.spamPercent = 0
	self.normalScore = 0
	self.keyMode = "None"
	self.mean = 0
	self.msd = nil ---@type osu.ui.Msd?
	self.enpsDiff = 0
	self.osuDiff = 0
	self.lnPercent = 0
	self.manipFactorPercent = 0
	self.timeRate = 1
	self.judgeName = ""

	if self.chartview and self.chartdiff and self.scoreItem then
		self:getDifficulty()
		self:getChartInfo()
	end

	local score_system = self.resultApi:getScoreEngine()
	if self.manipFactor and self.keyMode == "4K" then
		self.manipFactorPercent = self.manipFactor(score_system.hits)
	end
end

local bms_alias = { "Easy", "Normal", "Hard", "Very hard" }

---@param timings sea.Timings?
---@param subtimings sea.Subtimings?
---@return string
local function formatScoreSystemName(timings, subtimings)
	if not timings then
		return "No timings"
	end

	if timings.name == "sphere" then
		return "soundsphere"
	elseif timings.name == "osuod" then
		---@cast subtimings -?
		return ("osu!mania V%i OD%i"):format(subtimings.data, timings.data)
	elseif timings.name == "etternaj" then
		return ("Etterna J%i"):format(timings.data)
	elseif timings.name == "quaver" then
		return "Quaver standard"
	elseif timings.name == "bmsrank" then
		return ("LR2 %s"):format(bms_alias[timings.data])
	end

	return timings.name or "Unknown"
end

function DisplayInfo:calcForJudge()
	local timings = self.replayBase.timings
	local subtimings = self.replayBase.subtimings
	self.judgeName = formatScoreSystemName(timings, subtimings)

	self.marvelous = 0
	self.perfect = 0
	self.great = nil ---@type number?
	self.good = nil ---@type number?
	self.bad = nil ---@type number?
	self.miss = 0
	self.accuracy = nil ---@type number?

	self:getStats()
end

function DisplayInfo:switchJudgeNum(direction)
end

function DisplayInfo:switchScoreSystem(direction)
end

function DisplayInfo:getDifficulty()
	local chartview = self.chartview
	local chartdiff = self.chartdiff
	local rate = self.replayBase.rate ---@type number
	local diff_column = self.selectApi:getSelectedDiffColumn()

	local difficulty = (chartview.difficulty or 0) * rate

	self.difficulty = ("[%0.02f*]"):format(difficulty)

	self.enpsDiff = chartdiff.enps_diff
	self.osuDiff = chartdiff.osu_diff
	self.lnPercent = (chartdiff.judges_count - chartdiff.notes_count) / chartdiff.notes_count

	---@type osu.ui.Msd?
	local msd

	if chartview.msd_diff_data then
		msd = Msd(chartview.msd_diff_data)
		self.msd = msd
	end

	if diff_column == "msd_diff" and msd then
		local sorted = msd:getSorted(rate)
		local overall = msd.getFromTable("overall", sorted)
		local pattern = msd.simplifyName(sorted[2][1], chartview.chartdiff_inputmode)
		self.difficulty = ("[%0.02f %s]"):format(overall, pattern)
	elseif diff_column == "enps_diff" then
		self.difficulty = ("[%0.02f ENPS]"):format((chartdiff.enps_diff or 0))
	elseif diff_column == "osu_diff" then
		self.difficulty = ("[%0.02f*]"):format((chartdiff.osu_diff or 0))
	else
		self.difficulty = ("[%0.02f]"):format((chartdiff.user_diff or 0))
	end
end

function DisplayInfo:getChartInfo()
	local chartview = self.chartview
	local score_item = self.scoreItem
	local osu = self.configs.osu_ui

	local text = self.text

	local title = ("%s - %s"):format(chartview.artist, chartview.title)
	local rate = self.replayBase.rate
	self.timeRate = rate

	if osu.result.difficultyAndRate then
		if chartview.name and rate == 1 then
			title = ("%s [%s]"):format(title, chartview.name)
		elseif chartview.name and rate ~= 1 then
			title = ("%s [%s %gx]"):format(title, chartview.name, rate)
		else
			title = ("%s [%s %gx]"):format(title, rate)
		end

		title = title .. " " .. self.difficulty
	else
		title = ("%s [%s]"):format(title, chartview.name)
	end

	self.chartName = title

	local time = os.date("%d/%m/%Y %H:%M:%S.", score_item.time)
	local set_dir = chartview.set_dir
	local creator = chartview.creator
	local username = self.configs.online.user.name or self.configs.osu_ui.offlineNickname

	local second_row = text.SongSelection_BeatmapInfoCreator:format(set_dir)

	if chartview.format ~= "sm" then
		second_row = text.SongSelection_BeatmapInfoCreator:format(creator)
	end

	self.chartSource = second_row
	self.playInfo = text.RankingDialog_PlayedBy:format(username, time)

	local chartdiff = self.chartdiff

	if chartdiff then
		self.keyMode = Format.inputMode(chartdiff.inputmode)
	end
end

function DisplayInfo:getJudgement()
	local score_system_container = self.resultApi:getScoreSystem()
	local score_system_judgements = score_system_container.judgements

	if not score_system_judgements then
		return
	end

	local configs = self.configs
	---@type osu.ui.OsuConfig
	local osu = configs.osu_ui
	local score_system_name = osu.scoreSystem
	local judge_num = osu.judgement

	judge_num = Scoring.clampJudgeNum(score_system_name, judge_num)
	local judge_name = Scoring.getJudgeName(score_system_name, judge_num)

	---@type sphere.Judge
	self.scoreSystemJudgement = score_system_judgements[judge_name]
	self.judgeName = judge_name
	self.judgeNum = judge_num
	self.scoreSystemName = score_system_name
end

function DisplayInfo:getGrade()
	local judge = self.scoreSystemJudgement
	local score_system_name = judge.scoreSystemName

	self.grade = Scoring.getGrade(score_system_name, judge.accuracy)

	if score_system_name ~= "osuMania" or score_system_name ~= "osuLegacy" then
		self.grade = Scoring.convertGradeToOsu(self.grade)
	end
end

function DisplayInfo:getStats()
	local score_engine = self.resultApi:getScoreEngine()
	local judges_source = score_engine.judgesSource
	local judges = judges_source:getJudges()

	self.rank = 9999--self.scoreItem.rank
	self.marvelous = judges[1]
	self.perfect = judges[2]
	self.great = judges[3]
	self.good = judges[4]
	self.bad = judges[5]
	self.miss = judges_source:getLastJudge()

	local combo_source = score_engine.comboSource
	self.combo = combo_source:getMaxCombo()

	local accuracy_source = score_engine.accuracySource
	self.accuracy = accuracy_source:getAccuracy()

	local score_source = score_engine.scoreSource
	self.score = score_source:getScore()

	local base = score_engine:getScoreSystem("base") ---@cast base sphere.BaseScore

	self.spam = base.earlyHitCount
	self.spamPercent = base.earlyHitCount / base.notesCount

	local normalscore = score_engine:getScoreSystem("normalscore") ---@cast normalscore sphere.NormalscoreScore
	self.normalScore = normalscore.accuracyAdjusted
	self.mean = normalscore.normalscore.mean

	local chartdiff = self.chartdiff
	self.pp = osuPP(chartdiff.notes_count, chartdiff.osu_diff, 9, self.score)
end

return DisplayInfo
