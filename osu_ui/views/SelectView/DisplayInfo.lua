local class = require("class")

local Scoring = require("osu_ui.Scoring")
local time_util = require("time_util")
local Format = require("sphere.views.Format")
local Msd = require("osu_ui.Msd")
local ui = require("osu_ui.ui")

---@class osu.ui.SelectViewDisplayInfo
---@operator call: osu.ui.SelectViewDisplayInfo
local DisplayInfo = class()

---@param localization Localization
---@param select_api game.SelectAPI
function DisplayInfo:new(localization, select_api)
	self.text = localization.text
	self.selectApi = select_api
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
		max = 0,
		firstPattern = "No patterns",
		secondPattern = "",
	}
	self.lnPercent = 0
	self.lnPercentColor = { 1, 1, 1, 1 }
	self.formatLevel = ""
end

---@param msd osu.ui.Msd
---@param time_rate number
---@param key_mode string
function DisplayInfo:setMsd(msd, time_rate, key_mode)
	local sorted = msd:getSorted(time_rate)

	local second = false
	local max = sorted[1][2]

	self.msd.max = max

	for i, v in ipairs(sorted) do
		local pattern = v[1]
		local num = v[2]
		if pattern ~= "overall" then
			if num >= max * 0.93 then
				if not second then
					self.msd.firstPattern = msd.getPatternName(pattern, key_mode):upper()
				else
					self.msd.secondPattern = msd.getPatternName(pattern, key_mode):upper()
				end
			end

			if second then
				return
			end
			second = true
		end
	end
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

	if chart_format ~= "sm" then
		self.chartSource = (text.SongSelection_BeatmapInfoCreator):format(creator)
	else
		self.chartSource = (text.SongSelection_BeatmapInfoPack):format(creator, chartview.set_dir)
	end

	local note_count = chartview.notes_count or 0
	local ln_count = chartview.long_notes_count or 0
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

	---@type string
	local diff_column = self.selectApi:getSelectedDiffColumn()
	local difficulty = "-9999"
	local diff_hue = 0

	---@type osu.ui.Msd?
	local msd

	if chartview.msd_diff_data then
		pcall(function ()
			msd = Msd(chartview.msd_diff_data)
		end)
		if msd then
			self:setMsd(msd, rate, chartview.chartdiff_inputmode)
		end
	end

	if diff_column == "msd_diff" and msd then
		local sorted = msd:getSorted(rate)
		local overall = msd.getFromTable("overall", sorted)
		local pattern = msd.simplifyName(sorted[2][1], chartview.chartdiff_inputmode)
		difficulty = ("%0.02f %s"):format(overall, pattern)
		diff_hue = ui.convertDiffToHue((math.min(overall, 40) / 40) / 1.3)
		self.difficultyShowcase = difficulty
	elseif diff_column == "enps_diff" then
		local enps = (chartview.enps_diff or 0) * rate
		difficulty = ("%0.02f ENPS"):format(enps)
		diff_hue = ui.convertDiffToHue(math.min(enps, 35) / 35)
		self.difficultyShowcase = difficulty
	elseif diff_column == "osu_diff" then
		local osu_diff = (chartview.osu_diff or 0) * rate ---@type number
		difficulty = ("%0.02f*"):format(osu_diff)
		diff_hue = ui.convertDiffToHue(math.min(10, osu_diff) / 10)
		self.difficultyShowcase = ("%0.02f "):format((chartview.osu_diff or 0) * rate)
	else
		difficulty = ("%0.02f"):format((chartview.user_diff or 0) * rate)
		self.difficultyShowcase = ("%0.02f"):format((chartview.user_diff or 0) * rate)
	end

	local length_hue = ui.convertDiffToHue(math.min(self.lengthNumber * 0.8, 420) / 420)
	local od = tostring(Scoring.getOD(chartview.format, chartview.osu_od))
	local hp = tostring(chartview.osu_hp or 8)
	self.difficulty = difficulty
	self.difficultyColor = ui.HSV(diff_hue, 0.7, 1)
	self.lengthColor = ui.HSV(length_hue, 0.7, 1)
	self.lnPercentColor = ui.HSV(ui.convertDiffToHue(math.min(self.lnPercent * 1.3)), self.lnPercent, 1)
	self.chartInfoFirstRow = text.SongSelection_BeatmapInfo:format(self.length, bpm, objects)
	self.chartInfoSecondRow = text.SongSelection_BeatmapInfo2:format(note_count_str, ln_count_str, "0")
	self.chartInfoThirdRow = text.SongSelection_BeatmapInfo3:format(columns_str, od, hp, difficulty)

	local format = chartview.format or "NONE"
	if format == "bms" or format == "ksh" or format == "ojn" then
		self.formatLevel = ("%s LV.%i"):format(format:upper(), chartview.level or 1)
	else
		self.formatLevel = format:upper()
	end
end

return DisplayInfo
