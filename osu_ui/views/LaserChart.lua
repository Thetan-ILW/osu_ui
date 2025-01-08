local simplifyNotechart = require("libchart.simplify_notechart")
local path_util = require("path_util")

---@alias Note { time: number, column: number, input: number }

local output =
[[
local N = require("note")
module <- {
	artist = "%s",
	title = "%s",
	diffName = "%s",
	originalAuthor = "%s",
	columns = %s,
	audio = "%s",
	bg = "%s",
	objects = [%s]
}
]]

return function(chart, chartview)
	local notes = simplifyNotechart(chart, {"note", "hold", "laser"})
	---@cast notes Note[]

	local objects = ""

	for i, v in ipairs(notes) do
		if v.end_time then
			objects = objects .. ("N(%g,%g,%i),"):format(v.time, v.end_time, v.column)
		else
			objects = objects .. ("N(%g,0,%i),"):format(v.time, v.column)
		end
	end

	local charts_folder = "D:/SteamLibrary/steamapps/common/Team Fortress 2/tf/custom/laserchart/scripts/vscripts/laserchart/pack2/"
	local audio_folder = "D:/SteamLibrary/steamapps/common/Team Fortress 2/tf/custom/laserchart/sound/pack2"
	local bg_folder = "C:\\Users\\Thetan\\Desktop\\chartbgs\\export"
	local output_name = chartview.set_name:gsub(" ", ""):gsub("%(", ""):gsub("%)", ""):gsub("%.", ""):gsub(",", ""):gsub("'", ""):lower()

	local audio_path = path_util.join(chartview.real_dir, chartview.audio_path)
	local source = love.filesystem.getSource()
	local ffmpeg_path = path_util.join(source, "bin/win64/ffmpeg.exe")
	local ffmpeg = io.popen(ffmpeg_path .. ([[ -y -i "%s" -ar 44100 "%s/%s.mp3"]]):format(audio_path, audio_folder, output_name))

	ffmpeg:close()

	local bg_source = path_util.join(chartview.real_dir, chartview.background_path):gsub("/", "\\")
	local bg_export = path_util.join(bg_folder, ("%s%s"):format(output_name, chartview.background_path:match("^.+(%..+)$"))):gsub("/", "\\")
	local cmd = ([[copy "%s" "%s"]]):format(
		bg_source,
		bg_export
	)
	print(cmd)
	os.execute(cmd)
	local file = io.open(("%s%s.nut"):format(charts_folder, output_name), "w")

	if file then
		file:write(output:format(
			chartview.artist,
			chartview.title,
			chartview.name,
			chartview.creator,
			chart.inputMode:getColumns(),
			("%s.mp3"):format(output_name),
			("%s.vmt"):format(output_name),
			objects
		))

		file:close()
	else
		print("Failed to open a file")
	end
end
