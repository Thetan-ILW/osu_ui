local class = require("class")

local osuPP = require("osu_ui.osu_pp")
local Format = require("sphere.views.Format")
local Scoring = require("osu_ui.Scoring")
local Msd = require("osu_ui.Msd")
local Timings = require("sea.chart.Timings")

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

function DisplayInfo:loadScoreDetails()
	local timings = self.replayBase.timings or Timings.decode(self.chartview.chartmeta_timings)
	local subtimings = self.replayBase.subtimings
	self.judgeName = Scoring.formatScoreSystemName(timings, subtimings)

	self.marvelous = 0
	self.perfect = 0
	self.great = nil ---@type number?
	self.good = nil ---@type number?
	self.bad = nil ---@type number?
	self.miss = 0
	self.accuracy = nil ---@type number?

	self:setStats()
	self:setGrade()
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

	if diff_column == "msd_diff" then
		local msd = Msd(chartdiff.msd_diff_data, chartdiff.msd_diff_rates)

		if msd.valid then
			self.msd = msd
			local inputmode = chartview.chartdiff_inputmode ---@type string
			local patterns = msd:getPatterns(rate, inputmode)
			local s = msd.simplifyName(patterns[1].name)

			if patterns[2].difficulty > patterns[1].difficulty * 0.93 then
				 s = ("%s/%s"):format(s, msd.simplifyName(patterns[2].name))
			end

			self.difficulty = ("[%0.02f %s]"):format(chartdiff.msd_diff or 0, s)
		else
			self.difficulty = ""
		end
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
	local rate = self.scoreItem.rate
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

	local time = os.date("%d/%m/%Y %H:%M:%S.", score_item.submitted_at)
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


function DisplayInfo:setGrade()
	local score_engine = self.resultApi:getScoreEngine()
	local accuracy_source = score_engine.accuracySource

	local soundsphere = score_engine:getScoreSystem("soundsphere")
	---@cast soundsphere sphere.SoundsphereScore

	local ss_judges = soundsphere:getJudges()
	local score = (ss_judges[1] * 2 + ss_judges[2])
	local max_score = (ss_judges[1] * 2 + ss_judges[2] + ss_judges[3])
	local exscore = max_score / score
	local exscore_grade = Scoring.convertGradeToOsu(Scoring.getGrade("bmsrank", exscore))

	if not accuracy_source.timings then
		self.grade = exscore_grade
		return
	end

	local timings_key = accuracy_source.timings.name ---@type sea.TimingsName
	local accuracy = accuracy_source:getAccuracy()
	self.grade = Scoring.getGrade(timings_key, accuracy)

	if timings_key ~= "osuod" then
		self.grade = Scoring.convertGradeToOsu(self.grade)
	end

	self.grade = self.grade or exscore_grade
end

function DisplayInfo:setStats()
	local score_engine = self.resultApi:getScoreEngine()
	local judges_source = score_engine.judgesSource
	local judges = judges_source:getJudges()

	self.rank = 9999--self.scoreItem.rank
	self.marvelous = judges[1]
	self.perfect = judges[2]
	self.great = judges[3]
	self.good = judges[4]
	self.bad = judges[5]
	self.miss = judges[#judges_source:getJudgeNames()]

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
