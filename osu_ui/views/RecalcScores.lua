local Component = require("ui.Component")

local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")

local flux = require("flux")

---@class osu.ui.RecalcScores : ui.Component
---@operator call: osu.ui.RecalcScores
local RecalcScores = Component + {}

function RecalcScores:load()
	local width, height = self.parent:getDimensions()

	self:getViewport():listenForResize(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager
	self.text = scene.localization.text
	self.locationsApi = scene.ui.locationsApi
	self.selectApi = scene.ui.selectApi

	self:addChild("background", Rectangle({
		width = width,
		height = height,
		color = { 0, 0, 0, 0.6 },
		blockMouseFocus = true,
	}))

	local info = self:addChild("container", Component({
		y = height / 2,
		origin = { y = 0.5 },
		z = 1,
	}))

	self.status = info:addChild("status", Label({
		origin = { y = 0.5 },
		font = fonts:loadFont("Bold", 36),
		boxWidth = width,
		alignX = "center",
		text = self.text.ChartImport_Preparation
	}))

	self.progress = info:addChild("progress", Label({
		y = self.status:getHeight() + 6,
		origin = { y = 0.5 },
		font = fonts:loadFont("Regular", 28),
		boxWidth = width,
		alignX = "center",
		text = "0/0 | 0%"
	}))

	info:autoSize()

	self.alpha = 0
	flux.to(self, 0.4, { alpha = 1 }):ease("quadout")

	scene.ui.locationsApi:recalculateScores()
	self.state = "preparing"
end

function RecalcScores:preparing()
	if self.alpha == 1 then
		self.state = "caching"
		self.status:replaceText(self.text.ChartImport_Processing)
		return
	end
end

function RecalcScores:caching()
	if not self.locationsApi:isProcessingCharts() then
		self.state = "quitting"
		return
	end

	local scores, processed = self.locationsApi:getProcessingInfo()
	scores = math.max(1, scores)
	self.progress:replaceText(("%s/%s | %i%%"):format(processed, scores, (processed / scores) * 100))
end

function RecalcScores:quitting()
	if self.goodbye then
		return
	end
	self.locationsApi:loadLocations()
	self.selectApi:reloadCollections()
	self.selectApi:debouncePullNoteChartSet()
	self.goodbye = flux.to(self, 0.2, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self:kill()
	end)
end

function RecalcScores:update()
	self[self.state](self)
end

return RecalcScores
