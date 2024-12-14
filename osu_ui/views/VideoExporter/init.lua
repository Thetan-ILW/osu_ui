local class = require("class")
local ffi = require("ffi")
local path_util = require("path_util")
local simplifyNotechart = require("libchart.simplify_notechart")
local time_util = require("time_util")

local Viewport = require("ui.Viewport")
local ExporterView = require("osu_ui.views.VideoExporter.ExporterView")

ffi.cdef([[
	typedef struct {
	    int pid;
	    int pipe;
	} FFMPEG;
	FFMPEG *ffmpeg_start_rendering(size_t width, size_t height, size_t fps);
	void ffmpeg_end_rendering(FFMPEG *ffmpeg);
	void ffmpeg_send_frame(FFMPEG *ffmpeg, void *data, size_t width, size_t height);
	void ffmpeg_send_frame_flipped(FFMPEG *ffmpeg, void *data, size_t width, size_t height);
]])

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
	self.lib = ffi.load("bin/linux64/libmpeg.so")

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

	if self.mode == "preview_5s" then
		local preview_time = chartview.preview_time ---@type number
		self.duration = 5
		self.startTime = preview_time
	elseif self.mode == "preview_10s" then
		local preview_time = chartview.preview_time ---@type number
		self.duration = 10
		self.startTime = preview_time
	elseif self.mode == "full_chart" then
		local max_time = self.notes[#self.notes].time ---@type number
		self.duration = max_time
		self.startTime = 0
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

	---@type ffi.cdata*
	local state = self.lib.ffmpeg_start_rendering(self.canvasWidth, self.canvasHeight, self.framerate)

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
		self.lib.ffmpeg_send_frame(state, ptr, self.canvasWidth, self.canvasHeight)
		filedata:release()
	end
	love.graphics.pop()

	self.lib.ffmpeg_end_rendering(state)

	if self.mode == "preview_5s" or self.mode == "preview_10s" then
		os.execute(([[ffmpeg -y -i "%s" -ss %0.02f -t %0.02f audiocut.mp3]]):format(self.audioPath, self.startTime, self.duration))
		os.execute("ffmpeg -y -i audiocut.mp3 -i video.mp4 -c:v copy -c:a copy output.mp4")
	elseif self.mode == "full_chart" then
		os.execute(([[ffmpeg -y -i "%s" -i video.mp4 -c:v copy -c:a copy output.mp4]]):format(self.audioPath))
	end
end

return VideoExporter
