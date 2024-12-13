local Component = require("ui.Component")
local Image = require("ui.Image")
local Label = require("ui.Label")
local Rectangle = require("ui.Rectangle")
local Playfield = require("osu_ui.views.VideoExporter.Playfield")

---@class osu.ui.ExporterView : ui.Component
---@operator call: osu.ui.ExporterView
---@field videoExporter osu.ui.VideoExporter
---@field assets osu.ui.OsuAssets
---@field fontManager ui.FontManager
local View = Component + {}

function View:load()
	local assets = self.assets
	local fonts = self.fontManager
	local viewport = self:getViewport()
	self.width = viewport.scaledWidth
	self.height = viewport.scaledHeight

	local background_path = self.videoExporter.backgroundPath
	if background_path and self.videoExporter.drawBackground then
		local image = love.graphics.newImage(background_path)
		local iw, ih = image:getDimensions()
		self:addChild("background", Image({
			x = self.width / 2,
			y = self.height / 2,
			origin = { x = 0.5, y = 0.5 },
			scale = math.max(self.width / iw, self.height / ih),
			image = image,
			color = { 1, 1, 1, 0.8 },
		}))
	end

	local title_background = self:addChild("titleBackground", Rectangle({
		width = self.width,
		height = 96,
		color = { 0, 0, 0, 0.9 },
		z = 0.05,
	}))

	local info = self.videoExporter.info

	self:addChild("chartName", Label({
		x = 9, y = 9,
		font = fonts:loadFont("Regular", 33),
		text = info.chartName,
		z = 0.1,
	}))

	self:addChild("chartVersion", Label({
		x = 9, y = 50,
		font = fonts:loadFont("Regular", 28),
		text = info.chartVersion,
		z = 0.1,
	}))

	local playfield = self:addChild("playfield", Playfield({
		x = self.width - 20,
		origin = { x = 1 },
		videoExporter = self.videoExporter,
		z = 0.2,
	}))

	self:addChild("playfieldBackground", Rectangle({
		x = self.width - 20, y = title_background:getHeight(),
		width = playfield:getWidth(),
		height = self.height,
		origin = { x = 1 },
		color = { 0, 0, 0, 0.9 },
		z = 0.15
	}))

	local info_container = self:addChild("infoBackground", Rectangle({
		x = 20, y = self.height - 20,
		origin = { y = 1 },
		width = 400,
		height = 220,
		rounding = 8,
		color = { 0, 0, 0, 0.9 },
		z = 0.05,
	}))

	info_container:addChild("length", Label({
		x = 10, y = 10,
		text = ("Length: %s"):format(info.duration),
		font = fonts:loadFont("Regular", 40),
	}))

	info_container:addChild("noteCount", Label({
		x = 10, y = 54,
		text = ("Notes: %s"):format(info.noteCount),
		font = fonts:loadFont("Regular", 40),
	}))

	info_container:addChild("lnRatio", Label({
		x = 10, y = 94,
		text = ("LN%%: %i%%"):format(((info.lnCount + 1) / (info.noteCount + 1)) * 100),
		font = fonts:loadFont("Regular", 40),
	}))

	info_container:addChild("bpm", Label({
		x = 10, y = 134,
		text = ("BPM: %i"):format(info.bpm),
		font = fonts:loadFont("Regular", 40),
	}))

	info_container:addChild("bpm", Label({
		x = 10, y = 168,
		text = ("Star rate: %s"):format(info.stars),
		font = fonts:loadFont("Regular", 40),
	}))
end

return View
