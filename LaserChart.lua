local simplifyNotechart = require("libchart.simplify_notechart")
local Path = require("Path")
local Msd = require("osu_ui.Msd")

---@alias Note { time: number, column: number, input: number }

local output =
[[
module <- {
formatVersion = 1
artist = @"%s"
title = @"%s"
diffName = @"%s"
originalAuthor = @"%s"
columns = %s
audio = "%s"
bg = "%s"
format = "%s"
enpsDiff = %0.2f
osuDiff = %0.2f
msdDiff = [%s] 
msdDiffData = [%s]
previewTime = %0.2f
tempo = %i
audioOffset = %0.4f
duration = %0.2f,
noteCount = %i
lnCount = %i
notes = [%s]
timingPoints = [%s]
}
]]

---@param filepath string
local function getHash(filepath)
	local filedata = love.filesystem.newFileData(filepath)
	if not filedata then
        return ""
	end
	return love.data.encode("string", "hex", love.data.hash("md5", filedata))
end

local canvas = nil

return function(chart, chartview, background_internal_path)
	local notes = simplifyNotechart(chart, {"note", "hold", "laser"})
	---@cast notes Note[]

	local objects = ""

	for _, v in ipairs(notes) do
		if v.end_time then
			objects = objects .. ("[%g,%g,%i],"):format(v.time, v.end_time, v.column - 1)
		else
			objects = objects .. ("[%g,0,%i],"):format(v.time, v.column - 1)
		end
	end

	local timing_points = {}

	for _, v in ipairs(chart.layers.main.visuals.main.points) do
		if v.point._tempo then
			table.insert(timing_points, {
				absoluteTime = v.point.absoluteTime,
				bpm = v.point._tempo.tempo
			})
		end
		if v._velocity then
			table.insert(timing_points, {
				absoluteTime = v.point.absoluteTime,
				velocity = v._velocity.currentSpeed
			})
		end
	end

	table.sort(timing_points, function(a, b)
		return a.absoluteTime < b.absoluteTime
	end)

	local timings = ""

	for _, v in ipairs(timing_points) do
		if v.bpm then
			timings = timings .. ("[%g,%g,null],"):format(v.absoluteTime, v.bpm)
		else
			timings = timings .. ("[%g,null,%g],"):format(v.absoluteTime, v.velocity)
		end
	end

	local charts_folder = Path("D:/SteamLibrary/steamapps/common/Counter-Strike Source/cstrike/custom/charts/scripts/vscripts/charts/")
	local audio_folder = Path("D:/SteamLibrary/steamapps/common/Counter-Strike Source/cstrike/custom/charts/sound/")
	local background_folder = Path("D:/SteamLibrary/steamapps/common/Counter-Strike Source/cstrike/custom/charts/materials/")

	local audio_internal_path = Path(chartview.location_dir) .. Path(chartview.audio_path)
	local audio_real_path = Path(chartview.real_dir) .. chartview.audio_path

	local audio_hash = getHash(tostring(audio_internal_path))
	local background_hash = getHash(tostring(background_internal_path))

    local background_source_path = Path(background_internal_path)
	table.remove(background_source_path.parts, 1)
	table.remove(background_source_path.parts, 1)
	table.remove(background_source_path.parts, 1)

	local chartfile_name = chartview.hash .. "_" .. chartview.index
	local audio_output_path = audio_folder .. Path(audio_hash .. ".mp3")

	local source = love.filesystem.getSource()
	local ffmpeg_path = tostring(Path(source) .. Path("bin/win64/ffmpeg.exe"))
	--local ffmpeg = io.popen(ffmpeg_path .. ([[ -y -i "%s" -ar 44100 "%s"]]):format(audio_real_path, audio_output_path))

	--ffmpeg:close()

	pcall(function (...)
		local image = love.graphics.newImage(background_internal_path)
		canvas = canvas or love.graphics.newCanvas(1024, 512)
		
		love.graphics.push("all")
		love.graphics.setCanvas(canvas)
		love.graphics.origin()
		love.graphics.clear(0, 0, 0, 1)
		local iw, ih = image:getDimensions()
		love.graphics.draw(image, 1024 / 2, 512 / 2, 0, 512 / ih, 512 / ih, iw / 2, ih / 2)
		love.graphics.pop()

		local background_filedata = canvas:newImageData():encode("png", ("nutmania_backgrounds/%s.png"):format(background_hash))
		background_filedata:release()
	end)

	local msd = Msd(chartview.msd_diff_data)

    local msd_diff = ""
    local msd_diff_data = ""
	local rates = { 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5 }

	for _, rate in ipairs(rates) do
		msd_diff = ("%s%0.2f,"):format(msd_diff, msd:get("overall", rate))
		msd_diff_data = ("%s%0.2f,%0.2f,%0.2f,%0.2f,%0.2f,%0.2f,%0.2f,"):format(
			msd_diff_data,
            msd:get("stream", rate),
            msd:get("jumpstream", rate),
            msd:get("handstream", rate),
            msd:get("stamina", rate),
            msd:get("jackspeed", rate),
            msd:get("chordjack", rate),
            msd:get("technical", rate)
		)
	end

	local file, err = io.open(("%s%s.nut"):format(charts_folder, chartfile_name), "w")

	if file then
		file:write(output:format(
			chartview.artist:gsub([["]], [[""]]),
			chartview.title:gsub([["]], [[""]]),
			chartview.name:gsub([["]], [[""]]),
			chartview.creator:gsub([["]], [[""]]),
			chart.inputMode:getColumns(),
			audio_hash,
			background_hash,
			chartview.format,
            chartview.enps_diff or 0,
            chartview.osu_diff or 0,
			msd_diff,
			msd_diff_data,
            chartview.preview_time or 0,
            chartview.tempo or 0,
			chartview.audio_offset or 0,
			chartview.duration or 0,
            chartview.notes_count or 0,
			chartview.long_notes_count or 0,
			objects,
			timings
		))

		file:close()
		print(("Exported: %s.nut"):format(chartfile_name))
	else
		print("Failed to open a file", err)
	end
end
