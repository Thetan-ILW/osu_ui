local class = require("class")

local time_util = require("time_util")
local Format = require("sphere.views.Format")

---@class osu.ui.SelectViewDisplayInfo
---@operator call: osu.ui.SelectViewDisplayInfo
local DisplayInfo = class()

---@param select_view osu.ui.SelectView
function DisplayInfo:new(select_view)
	self.game = select_view.game
	local text = select_view.localization.text
	assert(text)
	self.text = text
end

function DisplayInfo:load()
	self.chartview = self.game.selectModel.chartview
	self.playContext = self.game.playContext

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

function DisplayInfo:setChartInfoDefaults()
	self.chartName = "No chart name - No chart name"
	self.chartSource = "No chart source"
	self.chartInfoFirstRow = "-"
	self.chartInfoSecondRow = "-"
	self.chartInfoThirdRow = "-"
end

function DisplayInfo:setChartInfo()
	local chartview = self.chartview
	local text = self.text

	self.chartName = string.format("%s - %s [%s]", chartview.artist, chartview.title, chartview.name)
	local chart_format = chartview.format

	if chart_format == "sm" then
		self.chartSource = (text.SongSelection_BeatmapInfoCreator):format(chartview.set_dir)
	else
		self.chartSource = (text.SongSelection_BeatmapInfoPack):format(chartview.creator)
	end

	local note_count = chartview.notes_count or 0
	local ln_count = chartview.long_notes_count or 0
	local rate = self.playContext.rate

	local length = time_util.format((chartview.duration or 0) / rate)
	local bpm = ("%i"):format((chartview.tempo or 0) * rate)
	local objects = tostring(note_count + ln_count)
	local note_count_str = tostring(note_count or 0)
	local ln_count_str = tostring(ln_count or 0)

	local columns_str = Format.inputMode(chartview.chartdiff_inputmode)

	---@type string
	local diff_column = self.game.configModel.configs.settings.select.diff_column
	local difficulty = "-9999"

	if diff_column == "msd_diff" and chartview.msd_diff_data then
		local etterna_msd = self.game.ui.etternaMsd
		local msd = etterna_msd.getMsdFromData(chartview.msd_diff_data, rate)
		if msd then
			local overall = msd.overall
			local pattern = etterna_msd.simplifySsr(etterna_msd.getFirstFromMsd(msd), chartview.chartdiff_inputmode)
			difficulty = ("%0.02f %s"):format(overall, pattern)
		end
	elseif diff_column == "enps_diff" then
		difficulty = ("%0.02f ENPS"):format((chartview.enps_diff or 0) * rate)
	elseif diff_column == "osu_diff" then
		difficulty = ("%0.02f*"):format((chartview.osu_diff or 0) * rate)
	else
		difficulty = ("%0.02f"):format((chartview.user_diff or 0) * rate)
	end

	local od = tostring(getOD(chartview))
	local hp = tostring(chartview.osu_hp or 8)

	self.chartInfoFirstRow = text.SongSelection_BeatmapInfo:format(length, bpm, objects)
	self.chartInfoSecondRow = text.SongSelection_BeatmapInfo2:format(note_count_str, ln_count_str, "0")
	self.chartInfoThirdRow = ("Keys: %s OD:%s HP:%i Star rate: %s"):format(columns_str, od, hp, difficulty)
end

return DisplayInfo
