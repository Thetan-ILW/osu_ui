local class = require("class")

local Scoring = require("osu_ui.Scoring")
local time_util = require("time_util")
local Format = require("sphere.views.Format")
local Msd = require("osu_ui.Msd")

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
	self.playContext = self.selectApi:getPlayContext()
	self:setChartInfoDefaults()

	if self.chartview then
		self:setChartInfo()
	end
end

---@param h number
---@param s number
---@param v number
---@return number[]
local function HSV(h, s, v)
	if s <= 0 then return { v, v, v, 1 } end
	h = h*6
	local c = v*s
	local x = (1-math.abs((h%2)-1))*c
	local m,r,g,b = (v-c), 0, 0, 0
	if h < 1 then
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	return { r+m, g+m, b+m, 1 }
end

---@param x number
---@return number
local function convertDiffToHue(x)
	if x <= 0.5 then
		return 0.5 - x
	elseif x <= 0.75 then
		return 1 - (x - 0.5) * (1 - 0.8) / 0.25
	else
		return 0.8
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
		first = 0,
		firstPattern = "",
		firstColor = { 1, 1, 1, 1 },
		second = 0,
		secondPattern = "",
		secondColor = { 1, 1, 1, 1 }
	}
	self.lnPercent = 0
	self.lnPercentColor = { 1, 1, 1, 1 }
	self.formatLevel = ""
end

---@param msd number
---@return number
local function msdHue(msd)
	return convertDiffToHue((math.min(msd, 40) / 40) / 1.3)
end

---@param msd osu.ui.Msd
---@param time_rate number
function DisplayInfo:setMsd(msd, time_rate)
	local sorted = msd:getSorted(time_rate)

	local second = false
	local max = sorted[1][2]

	for i, v in ipairs(sorted) do
		local pattern = v[1]
		local num = v[2]
		if pattern ~= "overall" then
			if num >= max * 0.93 then
				if not second then
					self.msd.first = num
					self.msd.firstPattern = pattern:upper()
					self.msd.firstColor = HSV(msdHue(num), 1, 1)
				else
					self.msd.second = num
					self.msd.secondPattern = pattern:upper()
					self.msd.secondColor = HSV(msdHue(num), 1, 1)
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

	if chart_format ~= "sm" then
		self.chartSource = (text.SongSelection_BeatmapInfoCreator):format(chartview.creator)
	else
		self.chartSource = (text.SongSelection_BeatmapInfoPack):format(chartview.set_dir)
	end

	local note_count = chartview.notes_count or 0
	local ln_count = chartview.long_notes_count or 0
	local rate = self.playContext.rate

	self.lengthNumber = (chartview.duration or 0) / rate
	self.length = time_util.format((chartview.duration or 0) / rate)
	local bpm = ("%i"):format((chartview.tempo or 0) * rate)
	local objects = tostring(note_count + ln_count)
	local note_count_str = tostring(note_count or 0)
	local ln_count_str = tostring(ln_count or 0)

	local columns_str = Format.inputMode(chartview.chartdiff_inputmode)

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
			self:setMsd(msd, rate)
		end
	end

	if diff_column == "msd_diff" and msd then
		local sorted = msd:getSorted(rate)
		local overall = msd.getFromTable("overall", sorted)
		local pattern = msd.simplifyName(sorted[2][1], chartview.chartdiff_inputmode)
		difficulty = ("%0.02f %s"):format(overall, pattern)
		diff_hue = msdHue(overall)
		self.difficultyShowcase = difficulty
	elseif diff_column == "enps_diff" then
		local enps = (chartview.enps_diff or 0) * rate
		difficulty = ("%0.02f ENPS"):format(enps)
		diff_hue = convertDiffToHue(math.min(enps, 35) / 35)
		self.difficultyShowcase = difficulty
	elseif diff_column == "osu_diff" then
		local osu_diff = (chartview.osu_diff or 0) * rate ---@type number
		difficulty = ("%0.02f*"):format(osu_diff)
		diff_hue = convertDiffToHue(math.min(10, osu_diff) / 10)
		self.difficultyShowcase = ("%0.02f "):format((chartview.osu_diff or 0) * rate)
	else
		difficulty = ("%0.02f"):format((chartview.user_diff or 0) * rate)
		self.difficultyShowcase = ("%0.02f"):format((chartview.user_diff or 0) * rate)
	end

	local length_hue = convertDiffToHue(math.min(self.lengthNumber * 0.8, 420) / 420)
	local od = tostring(Scoring.getOD(chartview.format, chartview.osu_od))
	local hp = tostring(chartview.osu_hp or 8)
	self.difficulty = difficulty
	self.difficultyColor = HSV(diff_hue, 0.7, 1)
	self.lengthColor = HSV(length_hue, 0.7, 1)
	self.lnPercent = ln_count / note_count
	self.lnPercentColor = HSV(convertDiffToHue(math.min(self.lnPercent * 1.3)), self.lnPercent, 1)
	self.chartInfoFirstRow = text.SongSelection_BeatmapInfo:format(self.length, bpm, objects)
	self.chartInfoSecondRow = text.SongSelection_BeatmapInfo2:format(note_count_str, ln_count_str, "0")
	self.chartInfoThirdRow = text.SongSelection_BeatmapInfo3:format(columns_str, od, hp, difficulty)

	if chartview.format == "bms" or chartview.format == "ksh" or chartview.format == "ojn" then
		self.formatLevel = ("%s LV.%i"):format(chartview.format:upper(), chartview.level or 1)
	else
		self.formatLevel = chartview.format:upper()
	end
end

return DisplayInfo
