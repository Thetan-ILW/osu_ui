local class = require("class")
local path_util = require("path_util")
local simplifyNotechart = require("libchart.simplify_notechart")
local time_util = require("time_util")
local ffi = require("ffi")

local Viewport = require("ui.Viewport")
local ExporterView = require("osu_ui.views.VideoExporter.ExporterView")

---@alias SimplifiedNoteChart { column: number, time: number, endTime: number }[]

---@class osu.ui.VideoExporter
---@operator call: osu.ui.VideoExporter
---@field notes SimplifiedNoteChart
local VideoExporter = class()

---@param assets osu.ui.OsuAssets
---@param font_manager ui.FontManager
function VideoExporter:new(assets, font_manager)
	self.assets = assets
	self.fontManager = font_manager

	self.viewport = Viewport({
		id = "videoExport",
		targetHeight = 768,
		constantSize = true,
		resize = function () end
	})

	self.mode = "preview"
end

---@param width number
---@param height number
---@param framerate number
---@param draw_background boolean?
---@param draw_info boolean?
function VideoExporter:setViewParams(width, height, framerate, draw_background, draw_info)
	self.canvasWidth = width
	self.canvasHeight = height
	self.framerate = framerate
	self.drawBackground = draw_background == nil and true or draw_background
	self.drawInfo = draw_info == nil and true or draw_info
end

---@param mode "full_chart" | "preview_5s" | "preview_10s" | "gif_preview"
function VideoExporter:setMode(mode)
	self.mode = mode
end

---@param chart ncdk2.Chart
---@param chartview table
---@param background_path string?
function VideoExporter:setChart(chart, chartview, background_path)
	self.notes = simplifyNotechart(chart, {"note", "hold", "laser"})
	self.columns = chart.inputMode:getColumns()
	self.backgroundPath = background_path
	self.audioPath = path_util.join(chartview.real_dir, chartview.audio_path)

	self.info = {
		chartName = ("%s - %s"):format(chartview.artist, chartview.title),
		chartVersion = ("(%s) by %s"):format(chartview.name, chartview.creator),
		noteCount = chartview.notes_count or 0,
		lnCount = chartview.long_notes_count or 0,
		duration = time_util.format((chartview.duration or 0)),
		bpm = ("%i"):format((chartview.tempo or 0)),
		stars = ("%0.02f*"):format((chartview.osu_diff or 0))
	}

	local video_cmd = ([[ffmpeg -loglevel verbose -y -f rawvideo -pix_fmt rgba -s %ix%i -r %i -i "-" -c:v libx264 -vb 2500k -c:a aac -ab 200k -pix_fmt yuv420p video.mp4]]):format(self.canvasWidth, self.canvasHeight, self.framerate)

	local gif_w = 16 * 20
	local gif_h = 9 * 20
	local gif_cmd = ([[ffmpeg -loglevel verbose -y -f rawvideo -pix_fmt rgba -s %ix%i -r %i -i "-" output.gif -vf fps=30,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse]]):format(gif_w, gif_h, self.framerate)

	if self.mode == "preview_5s" then
		local preview_time = chartview.preview_time ---@type number
		self.duration = 5
		self.startTime = preview_time
		self.videoCmd = video_cmd
	elseif self.mode == "preview_10s" then
		local preview_time = chartview.preview_time ---@type number
		self.duration = 10
		self.startTime = preview_time
		self.videoCmd = video_cmd
	elseif self.mode == "full_chart" then
		local max_time = self.notes[#self.notes].time ---@type number
		self.duration = max_time
		self.startTime = 0
		self.videoCmd = video_cmd
	elseif self.mode == "gif_preview" then
		local preview_time = chartview.preview_time ---@type number
		self.duration = 5
		self.startTime = preview_time
		self.videoCmd = gif_cmd
		self.canvasWidth = gif_w
		self.canvasHeight = gif_h
	else
		error(("%s mode is not implemented"):format(self.mode))
	end
end

function VideoExporter:export()
	self.viewport.width = self.canvasWidth
	self.viewport.height = self.canvasHeight
	self.viewport:load()
	self.viewport:removeChild("exporter")
	self.viewport:addChild("exporter", ExporterView({
		videoExporter = self,
		assets = self.assets,
		fontManager = self.fontManager
	}))

	local ffmpeg = io.popen(self.videoCmd, "w")

	if not ffmpeg then
		print("ERROR: Failed to open ffmpeg process")
		return
	end

	local frames = self.framerate * self.duration
	local duration = self.duration
	local start_time = self.startTime

	local dt = 1 / self.framerate

	love.graphics.push("all")
	for i = 1, frames do
		self.currentTime = (i / frames) * duration + start_time

		self.viewport:updateTree(dt)
		self.viewport:drawTree()

		local filedata = self.viewport.canvas:newImageData()
		local ptr = ffi.cast("uint8_t*", filedata:getFFIPointer())
		ffmpeg:write(ffi.string(ptr, filedata:getSize()))
		filedata:release()
	end
	love.graphics.pop()

	ffmpeg:close()

	if self.mode == "preview_5s" or self.mode == "preview_10s" then
		os.execute(([[ffmpeg -y -i "%s" -ss %0.02f -t %0.02f audiocut.mp3]]):format(self.audioPath, self.startTime, self.duration))
		os.execute("ffmpeg -y -i audiocut.mp3 -i video.mp4 -c:v copy -c:a copy output.mp4")
	elseif self.mode == "full_chart" then
		os.execute(([[ffmpeg -y -i "%s" -i video.mp4 -c:v copy -c:a copy output.mp4]]):format(self.audioPath))
	end
end

return VideoExporter
