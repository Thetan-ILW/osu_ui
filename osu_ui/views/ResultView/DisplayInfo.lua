local class = require("class")

local Soundsphere = require("sphere.models.RhythmModel.ScoreEngine.SoundsphereScoring")
local OsuMania = require("sphere.models.RhythmModel.ScoreEngine.OsuManiaScoring")
local OsuLegacy = require("sphere.models.RhythmModel.ScoreEngine.OsuLegacyScoring")
local Etterna = require("sphere.models.RhythmModel.ScoreEngine.EtternaScoring")
local Lr2 = require("sphere.models.RhythmModel.ScoreEngine.LunaticRaveScoring")
local Quaver = require("sphere.models.RhythmModel.ScoreEngine.QuaverScoring")

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
	self.playContext = self.selectApi:getPlayContext()
	self.scoreItem = self.resultApi:getScoreItem()

	self.chartName = "No chart name - No chart name"
	self.chartSource = "No chart source"
	self.playInfo = "No play info"

	self.rank = 0
	self.score = 10000000
	self.marvelous = 0
	self.perfect = 0
	self.great = 0
	self.good = 0
	self.bad = 0
	self.miss = 0
	self.accuracy = 0
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

	self:getJudgement()

	if self.judgement then
		self:getGrade()
		self:getStats()
	end
end

function DisplayInfo:getDifficulty()
	local chartview = self.chartview
	local chartdiff = self.chartdiff
	local rate = self.playContext.rate ---@type number
	local diff_column = self.selectApi:getSelectedDiffColumn()

	local difficulty = (chartview.difficulty or 0) * rate

	self.difficulty = ("[%0.02f*]"):format(difficulty)

	self.enpsDiff = chartdiff.enps_diff
	self.osuDiff = chartdiff.osu_diff
	self.lnPercent = chartdiff.long_notes_count / chartdiff.notes_count

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
	local rate = self.playContext.rate
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
	local username = self.configs.online.user.name or text.UserProfile_Guest

	local second_row = text.SongSelection_BeatmapInfoCreator:format(set_dir)

	if chartview.format ~= "sm" then
		second_row = text.SongSelection_BeatmapInfoCreator:format(creator)
	end

	self.chartSource = second_row
	self.playInfo = text.RankingDialog_PlayedBy:format(username, time)
end

function DisplayInfo:getJudgement()
	local score_system = self.resultApi:getScoreSystem()
	local judgements = score_system.judgements

	if not judgements then
		return
	end

	local configs = self.configs
	---@type osu.ui.OsuConfig
	local osu = configs.osu_ui
	local ss = osu.scoreSystem
	local judge = osu.judgement

	local judge_name = Scoring.getJudgeName(ss, judge)

	self.judgement = judgements[judge_name]
	self.judgements = judgements
	self.judgeName = judge_name
end

function DisplayInfo:getGrade()
	local judge = self.judgement
	local scoreSystemName = judge.scoreSystemName

	self.grade = Scoring.getGrade(scoreSystemName, judge.accuracy)

	if scoreSystemName ~= "osuMania" or scoreSystemName ~= "osuLegacy" then
		self.grade = Scoring.convertGradeToOsu(self.grade)
	end
end

function DisplayInfo:getStats()
	local judge = self.judgement
	local counters = judge.counters
	local counter_names = judge.orderedCounters

	self.rank = self.scoreItem.rank
	self.marvelous = counters[counter_names[1]]
	self.perfect = counters[counter_names[2]]
	self.miss = counters["miss"]

	local counters_count = #counter_names

	if counters_count >= 4 then
		self.great = counters[counter_names[3]]
		self.good = counters[counter_names[4]]
	end

	if counters_count >= 5 then
		self.bad = counters[counter_names[5]]
	end

	local score_system = self.resultApi:getScoreSystem()
	local base = score_system["base"]
	self.combo = base.maxCombo
	self.accuracy = judge.accuracy
	self.score = judge.score or self.judgements["osu!legacy OD9"].score or 0
	self.judgeName = judge.judgeName

	local chartdiff = self.chartdiff
	if chartdiff then
		self.pp = osuPP(base.notesCount, chartdiff.osu_diff, 9, self.score)
		self.keyMode = Format.inputMode(chartdiff.inputmode)
	end

	self.spam = base.earlyHitCount
	self.spamPercent = base.earlyHitCount / base.notesCount

	local normalscore = score_system["normalscore"]
	self.normalScore = normalscore.accuracyAdjusted
	self.mean = normalscore.normalscore.mean

	if self.manipFactor and self.keyMode == "4K" then
		self.manipFactorPercent = self.manipFactor(score_system.hits)
	end
end

return DisplayInfo
