local Component = require("ui.Component")

local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")

local flux = require("flux")

---@class osu.ui.ChartImport : ui.Component
---@operator call: osu.ui.ChartImport
local ChartImport = Component + {}

function ChartImport:load()
	local width, height = self.parent:getDimensions()

	self:getViewport():listenForResize(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager
	self.text = scene.localization.text
	self.locationsApi = scene.ui.locationsApi

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

	self.path = info:addChild("path", Label({
		y = self.status:getHeight() + 6,
		origin = { y = 0.5 },
		font = fonts:loadFont("Regular", 28),
		boxWidth = width,
		alignX = "center",
		text = "/"
	}))

	self.progress = info:addChild("progress", Label({
		y = self.path.y + self.path:getHeight() + 6,
		origin = { y = 0.5 },
		font = fonts:loadFont("Regular", 28),
		boxWidth = width,
		alignX = "center",
		text = "0/0 | 0%"
	}))

	info:autoSize()

	self.alpha = 0
	flux.to(self, 0.4, { alpha = 1 }):ease("quadout")

	self.state = "preparing"
	self.stack = {}

	if self.cacheAll then
		self.stack = self.locationsApi:getLocations()
	else
		table.insert(self.stack, self.locationsApi:getSelectedLocation())
	end
end

function ChartImport:preparing()
	if self.alpha == 1 then
		self.state = "caching"
		self.status:replaceText(self.text.ChartImport_Processing)
		return
	end
end

function ChartImport:caching()
	if not self.locationsApi:isProcessingCharts() then
		if #self.stack == 0 then
			self.state = "quitting"
			return
		end
		local loc = table.remove(self.stack)
		self.locationsApi:updateLocation(loc.id)
		self.path:replaceText(loc.path or "No path")
	end

	local charts, processed = self.locationsApi:getProcessingInfo()
	charts = math.max(1, charts)
	self.progress:replaceText(("%s/%s | %i%%"):format(processed, charts, (processed / charts) * 100))
end

function ChartImport:quitting()
	if self.goodbye then
		return
	end
	self.locationsApi:loadLocations()
	self.goodbye = flux.to(self, 0.2, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self:kill()
	end)
end

function ChartImport:update()
	self[self.state](self)
end

return ChartImport
