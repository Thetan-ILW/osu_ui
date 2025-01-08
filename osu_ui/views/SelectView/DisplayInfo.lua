local class = require("class")

local time_util = require("time_util")
local math_util = require("math_util")
local Format = require("sphere.views.Format")

---@class osu.ui.SelectViewDisplayInfo
---@operator call: osu.ui.SelectViewDisplayInfo
local DisplayInfo = class()

---@param localization Localization
---@param select_api game.SelectAPI
---@param minacalc table
function DisplayInfo:new(localization, select_api, minacalc)
	self.text = localization.text
	self.selectApi = select_api
	self.minacalc = minacalc
end

function DisplayInfo:updateInfo()
	self.chartview = self.selectApi:getChartview()
	self.playContext = self.selectApi:getPlayContext()

	if self.chartview then
		self:setChartInfo()
	else
		self:setChartInfoDefaults()
	end
end

---@param chartview table
---@return number
local function getOD(chartview)
	if chartview.osu_od then
		return chartview.osu_od
	end

	---@type string
	local format = chartview.format

	if format == "sm" or format == "ssc" then
		return 9
	elseif format == "ojn" then
		return 7
	else
		return 8
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

function DisplayInfo:setChartInfoDefaults()
	self.chartName = "No chart name - No chart name"
	self.chartSource = "No chart source"
	self.chartInfoFirstRow = ""
	self.chartInfoSecondRow = ""
	self.chartInfoThirdRow = ""
	self.lengthNumber = 0
	self.length = "??:??"
	self.difficulty = "??*"
	self.difficultyLevel = 1
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

	if diff_column == "msd_diff" and chartview.msd_diff_data then
		local minacalc = self.minacalc
		local msd = minacalc.getMsdFromData(chartview.msd_diff_data, rate)
		if msd then
			local overall = msd.overall
			local pattern = minacalc.simplifySsr(minacalc.getFirstFromMsd(msd), chartview.chartdiff_inputmode)
			difficulty = ("%0.02f %s"):format(overall, pattern)
		end
	elseif diff_column == "enps_diff" then
		difficulty = ("%0.02f ENPS"):format((chartview.enps_diff or 0) * rate)
	elseif diff_column == "osu_diff" then
		local osu_diff = (chartview.osu_diff or 0) * rate ---@type number
		difficulty = ("%0.02f*"):format(osu_diff)
		if osu_diff < 3 then
			self.difficultyLevel = 1
		elseif osu_diff < 5 then
			self.difficultyLevel = 2
		else
			self.difficultyLevel = 3
		end
	else
		difficulty = ("%0.02f"):format((chartview.user_diff or 0) * rate)
	end

	local od = tostring(getOD(chartview))
	local hp = tostring(chartview.osu_hp or 8)
	self.difficulty = difficulty
	self.chartInfoFirstRow = text.SongSelection_BeatmapInfo:format(self.length, bpm, objects)
	self.chartInfoSecondRow = text.SongSelection_BeatmapInfo2:format(note_count_str, ln_count_str, "0")
	self.chartInfoThirdRow = ("Keys: %s OD:%s HP:%i Star rate: %s"):format(columns_str, od, hp, difficulty)
end

return DisplayInfo
