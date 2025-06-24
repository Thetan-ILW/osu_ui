local class = require("class")

local time_util = require("time_util")
local Format = require("sphere.views.Format")
local ui = require("osu_ui.ui")
local Timings = require("sea.chart.Timings")
local Msd = require("osu_ui.Msd")
local dan_list = require("sea.dan.dan_list")
local string_util = require("string_util")

---@class osu.ui.SelectViewDisplayInfo
---@operator call: osu.ui.SelectViewDisplayInfo
local DisplayInfo = class()

---@type {[string]: boolean}
local dan_hashes = {}
for _, dan in pairs(dan_list) do
	local hash = dan.chartmeta_keys[#dan.chartmeta_keys].hash
	dan_hashes[hash] = true
end

---@param localization Localization
---@param select_api game.SelectAPI
function DisplayInfo:new(localization, select_api)
	self.text = localization.text
	self.selectApi = select_api
	self.configs = select_api:getConfigs()
end

function DisplayInfo:updateInfo()
	self.chartview = self.selectApi:getChartview()
	self.replayBase = self.selectApi:getReplayBase()
	self:setChartInfoDefaults()

	if self.chartview then
		self:setChartInfo()
	end
end

function DisplayInfo:setChartInfoDefaults()
	self.chartName = "No chart name - No chart name"
	self.chartSource = "No chart source"
	self.chartInfoFirstRow = ""
	self.chartInfoSecondRow = ""
	self.chartInfoThirdRow = ""
	self.lengthNumber = 0
	self.length = "??:??"
	self.difficulty = "??*"
	self.difficultyShowcase = "??"
	self.difficultyColor = { 1, 1, 1, 1 }
	self.lengthColor = { 1, 1, 1, 1 }
	self.msd = {
		overall = 0,
		firstPattern = { name = "No patterns", difficulty = 0 },
		secondPattern = nil,
	}
	self.lnPercent = 0
	self.lnPercentColor = { 1, 1, 1, 1 }
	self.formatLevel = ""
	self.rankedType = "unknown" ---@type "unknown" | "ranked" | "dan"
end

---@param timings sea.Timings
---@return string
function DisplayInfo:getJudgeString(timings)
	local n = timings.name
	local v = timings.data

	if n == "osuod" then
		return ("OD:%g"):format(v)
	elseif n == "etternaj" then
		return ("J%i"):format(v)
	elseif n == "quaver" then
		return ("QuaverSTD")
	elseif n == "bmsrank" then
		if v == 0 then
			return ("LR2 Easy")
		elseif v == 1 then
			return ("LR2 Normal")
		elseif v == 2 then
			return ("LR2 Hard")
		elseif v == 3 then
			return ("LR2 Very hard")
		end
	end

	return n:upper()
end

function DisplayInfo:setChartInfo()
	local chartview = self.chartview
	local text = self.text

	self.chartName = string.format("%s - %s [%s]", chartview.artist, chartview.title, chartview.name)
	local chart_format = chartview.format
	local creator = chartview.creator

	if creator == "" then
		creator = "Unknown"
	end

	if chart_format ~= "stepmania" then
		self.chartSource = (text.SongSelection_BeatmapInfoCreator):format(creator)
	else
		local pack = self.chartview.set_dir or "Not in a pack" ---@type string
		local s = string_util.split(pack, "/")
		self.chartSource = (text.SongSelection_BeatmapInfoPack):format(creator, s[#s])
	end

	local note_count = chartview.notes_count or 0
	local ln_count = (chartview.judges_count or 0) - note_count
	local rate = self.replayBase.rate

	self.lengthNumber = (chartview.duration or 0) / rate
	self.length = time_util.format((chartview.duration or 0) / rate)
	local bpm = ("%i"):format((chartview.tempo or 0) * rate)
	local objects = tostring(note_count + ln_count)
	local note_count_str = tostring(note_count or 0)
	local ln_count_str = tostring(ln_count or 0)

	local columns_str = Format.inputMode(chartview.chartdiff_inputmode)

	if note_count ~= 0 then
		self.lnPercent = ln_count / note_count
	else
		self.lnPercent = 0
	end

	local inputmode = chartview.chartdiff_inputmode ---@type string
	local msd = Msd(chartview.msd_diff_data, chartview.msd_diff_rates)
	local msd_overall = 0

	if msd.valid then
		local msd_patterns = msd:getPatterns(rate, inputmode)
		msd_overall = msd:getOverall(rate)
		if msd_overall ~= msd_overall then
			msd_overall = 0
		end
		self.msd.overall = msd_overall
		self.msd.firstPattern = msd_patterns[1]

		if msd_patterns[2].difficulty > msd_patterns[1].difficulty * 0.93 then
			self.msd.secondPattern = msd_patterns[2]
		end
	end

	---@type string
	local diff_column = self.selectApi:getSelectedDiffColumn()
	local difficulty = "-9999"
	local diff_hue = 0
	local calc = ""

	if diff_column == "msd_diff" then
		local short_pattern = msd.simplifyName(self.msd.firstPattern.name)
		calc = "MSD"
		difficulty = ("%0.02f %s"):format(msd_overall, short_pattern)
		diff_hue = ui.convertDiffToHue((math.min(msd_overall, 40) / 40) / 1.3)
		self.difficultyShowcase = difficulty
	elseif diff_column == "enps_diff" then
		local enps = (chartview.enps_diff or 0) * rate
		calc = "ENPS"
		difficulty = ("%0.02f"):format(enps)
		diff_hue = ui.convertDiffToHue(math.min(enps, 35) / 35)
		self.difficultyShowcase = difficulty
	elseif diff_column == "osu_diff" then
		local osu_diff = (chartview.osu_diff or 0) * rate ---@type number
		calc = "Star rate"
		difficulty = ("%0.02f*"):format(osu_diff)
		diff_hue = ui.convertDiffToHue(math.min(10, osu_diff) / 10)
		self.difficultyShowcase = ("%0.02f "):format((chartview.osu_diff or 0) * rate)
	else
		calc = "Diff"
		difficulty = ("%0.02f"):format((chartview.user_diff or 0) * rate)
		self.difficultyShowcase = ("%0.02f"):format((chartview.user_diff or 0) * rate)
	end

	local timings ---@type sea.Timings

	if not self.configs.settings.replay_base.auto_timings then
		timings = self.replayBase.timings or Timings.decode(self.chartview.chartmeta_timings)
	else
		if chartview.format == "osu" then
			timings = Timings.decode(self.chartview.chartmeta_timings)
		elseif chartview.format then
			local ft = self.configs.settings.format_timings
			timings = Timings(
				ft[chartview.format][1],
				ft[chartview.format][2]
			)
		else
			timings = Timings("simple")
		end
	end

	local length_hue = ui.convertDiffToHue(math.min(self.lengthNumber * 0.8, 420) / 420)
	local hp = tostring(chartview.osu_hp or 8)
	self.difficulty = difficulty
	self.difficultyColor = ui.HSV(diff_hue, 0.7, 1)
	self.lengthColor = ui.HSV(length_hue, 0.7, 1)
	self.lnPercentColor = ui.HSV(ui.convertDiffToHue(math.min(self.lnPercent * 1.3)), self.lnPercent, 1)
	self.chartInfoFirstRow = text.SongSelection_BeatmapInfo:format(self.length, bpm, objects)
	self.chartInfoSecondRow = text.SongSelection_BeatmapInfo2:format(note_count_str, ln_count_str, "0")
	self.chartInfoThirdRow = ("Keys: %s %s HP:%g %s: %s"):format(
		columns_str,
		self:getJudgeString(timings),
		hp,
		calc,
		difficulty
	)

	local format = chartview.format or "NONE"
	if format == "bms" or format == "ksh" or format == "ojn" then
		self.formatLevel = ("%s LV.%i"):format(format:upper(), chartview.level or 1)
	else
		self.formatLevel = format:upper()
	end

	if chartview.difftable_chartmetas and #chartview.difftable_chartmetas > 0 then
		self.rankedType = "ranked"
	end

	if dan_hashes[chartview.hash] then
		self.rankedType = "dan"
	end
end

return DisplayInfo
