local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local Combo = require("osu_ui.ui.Combo")
local Checkbox = require("osu_ui.ui.Checkbox")
local Button = require("osu_ui.ui.Button")

local VideoExporter = require("osu_ui.views.VideoExporter.init")

local flux = require("flux")

---@class osu.ui.VideoExporterModal : ui.Component
---@operator call: osu.ui.VideoExporterModal
local Modal = Component + {}

function Modal:keyPressed(event)
	if event[2] == "escape" then
		self:close()
		return true
	end

	return true
end

function Modal:close()
	self.handleEvents = false
	flux.to(self, 0.3, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self:kill()
	end)
end

local expected_label_format = "Expected size: %0.02f MB. Frames: %i"
function Modal:guessSize()
	local duration = self.chartview.duration ---@type number
	local video_size = self.selectedResolution.size
	local fps = self.selectedResolution.fps
	local draw_background = self.drawBackground
	local draw_info = self.drawInfo
	local label = self.expectedLabel ---@cast label ui.Label

	if self.selectedVideoType.mode == "preview_5s" then
		duration = 5
	elseif self.selectedVideoType.mode == "preview_10s" then
		duration = 10
	elseif self.selectedVideoType.mode == "gif_preview" then
		label:replaceText(expected_label_format:format(0.4, fps * duration))
		return
	end

	local total = duration * (video_size / 60)
	total = draw_background and total or total * 0.9
	total = draw_info and total or total * 0.99

	label:replaceText(expected_label_format:format(total, fps * duration))
end

function Modal:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager

	self:getViewport():listenForResize(self)

	local video_types = {
		{ name = "GIF preview", mode = "gif_preview" },
		{ name = "Preview (5 seconds)", mode = "preview_5s" },
		{ name = "Preview (10 seconds)", mode = "preview_10s" },
		{ name = "Full chart", mode = "full_chart" },
	}
	self.selectedVideoType = video_types[3]

	-- Export 1 minute chart to get the size. Use solid background behind the playfield, draw background and info
	local resolutions = {
		{ name = "1280x720@30", w = 1280, h = 720, fps = 30, size = 12.1 },
		{ name = "1280x720@60", w = 1280, h = 720, fps = 60, size = 15.5 },
		{ name = "1920x1080@30", w = 1920, h = 1080, fps = 30, size = 19.1 },
		{ name = "1920x1080@60", w = 1920, h = 1080, fps = 60, size = 20.3 },
		{ name = "2560x1080@30", w = 2560, h = 1080, fps = 30, size = 19.3 },
		{ name = "2560x1080@60", w = 2560, h = 1080, fps = 60, size = 20.9 },
	}
	self.selectedResolution = resolutions[2]
	self.drawBackground = true -- decreases size by 0.9
	self.drawInfo = true -- decreases size by 0.99

	self:addChild("background", Rectangle({
		width = scene.width, height = scene.height,
		color = { 0, 0, 0, 0.784 },
		blockMouseFocus = true,
	}))

	self:addChild("label", Label({
		x = 9, y = 2,
		text = "Export a video",
		font = fonts:loadFont("Light", 33),
		z = 0.1,
	}))

	local function addVideoOptions()
		self:removeChild("videoOptions")

		if self.selectedVideoType.mode == "gif_preview" then
			return
		end

		local options = self:addChild("videoOptions", Component({ z = 0.2 }))
		options:addChild("resolutionLabel", Label({
			x = 52, y = 204,
			text = "Resolution:",
			font = fonts:loadFont("Regular", 22),
			z = 0.1,
		}))

		options:addChild("resolutionCombo", Combo({
			x = 240, y = 204,
			width = 320,
			height = 37,
			items = resolutions,
			z = 0.2,
			getValue = function ()
				return self.selectedResolution
			end,
			setValue = function(index)
				self.selectedResolution = resolutions[index]
				self:guessSize()
			end,
			format = function(value)
				return value.name
			end
		}))
	end

	self:addChild("videoTypeLabel", Label({
		x = 52, y = 160,
		text = "Video type:",
		font = fonts:loadFont("Regular", 22),
		z = 0.1,
	}))

	self:addChild("videoTypeCombo", Combo({
		x = 240, y = 160,
		width = 320,
		height = 37,
		items = video_types,
		z = 0.25,
		getValue = function ()
			return self.selectedVideoType
		end,
		setValue = function(index)
			self.selectedVideoType = video_types[index]
			addVideoOptions()
			self:guessSize()
		end,
		format = function(value)
			return value.name
		end
	}))

	addVideoOptions()

	self:addChild("drawBackground", Checkbox({
		x = 60, y = 256,
		label = "Draw background",
		large = true,
		z = 0.1,
		getValue = function()
			return self.drawBackground
		end,
		clicked = function ()
			self.drawBackground = not self.drawBackground
			self:guessSize()
		end
	}))

	self:addChild("drawInfo", Checkbox({
		x = 60, y = 308,
		label = "Draw chart information",
		large = true,
		z = 0.1,
		getValue = function()
			return self.drawInfo
		end,
		clicked = function ()
			self.drawInfo = not self.drawInfo
			self:guessSize()
		end
	}))

	local select_api = scene.ui.selectApi
	local result_api = scene.ui.resultApi
	local chart = result_api:getChartWithMods()
	self.chartview = select_api:getChartview()

	self:addChild("startGame", Button({
		x = scene.width / 2, y = 512,
		origin = { x = 0.5, y = 0.5 },
		label = "1. Export",
		color = { 0.52, 0.72, 0.12, 1 },
		font = fonts:loadFont("Regular", 42),
		z = 0.1,
		onClick = function ()
			if chart and self.chartview then
				local video = VideoExporter(scene.assets, scene.fontManager)
				video:setViewParams(
					self.selectedResolution.w,
					self.selectedResolution.h,
					self.selectedResolution.fps,
					self.drawBackground,
					self.drawInfo
				)
				video:setMode(self.selectedVideoType.mode)
				video:setChart(chart, self.chartview, select_api:getBackgroundImagePath())
				video:export()
			end
		end
	}))

	self:addChild("cancel", Button({
		x = scene.width / 2, y = 592,
		origin = { x = 0.5, y = 0.5 },
		label = "2. Cancel",
		color = { 0.42, 0.42, 0.42, 1 },
		font = fonts:loadFont("Regular", 42),
		z = 0.1,
		onClick = function ()
			self:close()
		end,
	}))

	self.expectedLabel = self:addChild("expectedLabel", Label({
		x = scene.width / 2, y = 420,
		origin = { x = 0.5, y = 0.5 },
		font = fonts:loadFont("Bold", 30),
		text = "",
		z = 0.3
	}))

	self:guessSize()

	self.alpha = 0
	flux.to(self, 0.5, { alpha = 1 }):ease("quadout")
end

return Modal
