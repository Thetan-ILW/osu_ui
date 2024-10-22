local class = require("class")

local Soundsphere = require("sphere.models.RhythmModel.ScoreEngine.SoundsphereScoring")
local OsuMania = require("sphere.models.RhythmModel.ScoreEngine.OsuManiaScoring")
local OsuLegacy = require("sphere.models.RhythmModel.ScoreEngine.OsuLegacyScoring")
local Etterna = require("sphere.models.RhythmModel.ScoreEngine.EtternaScoring")
local Lr2 = require("sphere.models.RhythmModel.ScoreEngine.LunaticRaveScoring")
local Quaver = require("sphere.models.RhythmModel.ScoreEngine.QuaverScoring")

local Scoring = require("osu_ui.views.ResultView.Scoring")

---@class osu.ui.ResultDisplayInfo
---@operator call: osu.ui.ResultDisplayInfo
local DisplayInfo = class()

---@param result_view osu.ui.ResultView
function DisplayInfo:new(result_view)
	local game = result_view.game
	local localization = result_view.assets.localization

	self.game = game
	self.resultView = result_view
	self.configs = game.configModel.configs

	self.chartview = game.selectModel.chartview
	self.chartdiff = game.playContext.chartdiff
	self.playContext = game.playContext
	self.scoreItem = game.selectModel.scoreItem

	local text = localization:get("result")
	assert(text)
	self.text = text

	if self.chartview then
		self:getDifficulty()
		self:getChartInfo()
	else
		self:setDefaultChartView()
	end

	self:getJudgement()

	if self.judgement then
		self:getGrade()
		self:getStats()
	else
		self:setJudgementDefaults()
	end
end

function DisplayInfo:setDefaultChartView()
	self.chartName = "No chart name - No chart name"
	self.chartSource = "No chart source"
	self.playInfo = "No play info"
end

function DisplayInfo:setJudgementDefaults()
	self.score = 0
	self.marvelous = 0
	self.perfect = 0
	self.great = 0
	self.good = 0
	self.bad = 0
	self.miss = 0
	self.accuracy = 0
	self.combo = 0
	self.grade = "D"
end

function DisplayInfo:getDifficulty()
	local chartview = self.chartview
	local chartdiff = self.chartdiff
	local rate = self.playContext.rate
	local diff_column = self.configs.settings.select.diff_column

	local difficulty = (chartview.difficulty or 0) * rate
	local patterns = chartview.level and "Lv." .. chartview.level or ""

	self.difficulty = ("[%0.02f*]"):format(difficulty)

	if diff_column == "msd_diff" and chartview.msd_diff_data then
		local etterna_msd = self.game.ui.etternaMsd
		local msd = etterna_msd.getMsdFromData(chartview.msd_diff_data, rate)

		if msd then
			difficulty = msd.overall
			patterns = etterna_msd.getFirstFromMsd(msd)
		end

		patterns = etterna_msd.simplifySsr(patterns, chartdiff.inputmode)
		self.difficulty = ("[%0.02f %s]"):format(difficulty, patterns)
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
	local username = self.configs.online.user.name or text.guest

	local second_row = text.chartFrom:format(set_dir)

	if chartview.format ~= "sm" then
		second_row = text.chartBy:format(creator)
	end

	self.chartSource = second_row
	self.playInfo = text.playedBy:format(username, time)
end

local scoring = {
	["osu!legacy"] = OsuLegacy,
	["osu!mania"] = OsuMania,
	["Etterna"] = Etterna,
	["Quaver"] = Quaver,
	["Lunatic rave 2"] = Lr2,
	["soundsphere"] = Soundsphere,
}

function DisplayInfo:getJudgement()
	local score_system = self.game.rhythmModel.scoreEngine.scoreSystem
	local judgements = score_system.judgements

	if not judgements then
		return
	end

	local configs = self.game.configModel.configs
	local osu = configs.osu_ui
	local ss = osu.scoreSystem
	local judge = osu.judgement

	local range_alias = scoring[ss].metadata.rangeValueAlias
	if range_alias then
		judge = range_alias[judge]
	end

	local judge_name = scoring[ss].metadata.name:format(judge)

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

	local base = self.game.rhythmModel.scoreEngine.scoreSystem["base"]
	self.combo = base.maxCombo
	self.accuracy = judge.accuracy
	self.score = judge.score or self.judgements["osu!legacy OD9"].score or 0
end

return DisplayInfo
