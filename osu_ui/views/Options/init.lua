local CanvasContainer = require("osu_ui.ui.CanvasContainer")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local flux = require("flux")
local Rectangle = require("osu_ui.ui.Rectangle")

---@class osu.ui.OptionsView : osu.ui.CanvasContainer
---@field fadeTween table?
local Options = CanvasContainer + {}

Options.panelWidth = 438
Options.tabsContrainerWidth = 64

function Options:fade(target_value)
	if self.fadeTween then
		self.fadeTween:stop()
	end
	self.fadeTween = flux.to(self, 0.5, { alpha = target_value }):ease("quadout")
end

function Options:drawCanvas()
	local scale = self.viewportScale
	local alpha = self.alpha
	love.graphics.setScissor(0, 0, math.max(self.tabsContrainerWidth * scale, (alpha * self.totalW)), self.totalH)
	love.graphics.draw(self.canvas)
	love.graphics.setScissor()
end

function Options:load()
	local width, height = self.parent:getDimensions()
	local viewport = self.parent:getViewport()
	self.viewportScale = viewport:getScale()

	self.totalW = (self.panelWidth + self.tabsContrainerWidth) * self.viewportScale
	self.totalH = viewport.screenH * self.viewportScale
	CanvasContainer.load(self)
	self:addTags({ "allowReload" })


	self:addChild("tabsBackground", Rectangle({
		totalW = self.tabsContrainerWidth,
		totalH = height,
		color = { 0, 0, 0, 1 }
	}))

	self:addChild("panelBackground", Rectangle({
		x = self.tabsContrainerWidth,
		totalW = self.panelWidth,
		totalH = height,
		color = { 0, 0, 0, 0.7 }
	}))

	self:addChild("panel", ScrollAreaContainer({
		x = self.tabsContrainerWidth,
		totalW = self.panelWidth,
		totalH = height,
	}))

	self:build()
end

return Options
