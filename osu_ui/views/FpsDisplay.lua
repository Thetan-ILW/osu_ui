local Component = require("ui.Component")
local Image = require("ui.Image")
local Label = require("ui.Label")

local loop = require("loop")

---@class osu.ui.FpsDisplayView : ui.Component
---@operator call: osu.ui.FpsDisplayView
local FpsDisplay = Component + {}

local colors = {
	holyCow = {love.math.colorFromBytes(255, 36, 0, 255)},
	danger = {love.math.colorFromBytes(255, 149, 24, 255)},
	warning = {love.math.colorFromBytes(255, 204, 34, 255)},
	okay = {love.math.colorFromBytes(172, 220, 25, 255)}
}

function FpsDisplay:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	self.nextUpdate = 0

	self:getViewport():listenForResize(self)

	local box_width, box_height = 65, 20

	self.latencyBox = self:addChild("latencyBox", Image({
		x = self.parent:getWidth() - 4, y = self.parent:getHeight() - 6,
		width = box_width,
		height = box_height,
		origin = { x = 1, y = 1 },
		image = assets:loadImage("fps-box"),
		color = colors.okay
	}))

	self.fpsBox = self:addChild("fpsBox", Image({
		x = self.parent:getWidth() - 4, y = self.parent:getHeight() - 10 - self.latencyBox:getHeight(),
		width = box_width,
		height = box_height,
		origin = { x = 1, y = 1 },
		image = assets:loadImage("fps-box"),
		color = colors.okay
	}))

	self.ms = self.latencyBox:addChild("ms", Label({
		boxWidth = box_width,
		boxHeight = box_height - 2,
		alignX = "center",
		alignY = "center",
		font = fonts:loadFont("MonoRegular", 14),
		text = "",
		color = { 0, 0, 0, 1 },
	}))

	self.fps = self.fpsBox:addChild("fps", Label({
		boxWidth = box_width / 2 - 4,
		boxHeight = box_height - 2,
		alignX = "right",
		alignY = "center",
		font = fonts:loadFont("MonoRegular", 14),
		text = "",
		color = { 0, 0, 0, 1 },
	}))

	self.maxFps = self.fpsBox:addChild("maxFps", Label({
		x = -3,
		y = 4,
		boxWidth = box_width,
		boxHeight = box_height,
		font = fonts:loadFont("MonoRegular", 9),
		alignX = "right",
		alignY = "center",
		color = { 0.2, 0.2, 0.2, 1 },
		text = "",
	}))

	self.dts = { 0, 0, 0, 0, 0, 0, 0 }
	self.checks = 0
end

function FpsDisplay:update()
	self.dts[self.checks] = loop.dt
	self.checks = (self.checks + 1) % 7 + 1

	if love.timer.getTime() < self.nextUpdate then
		return
	end
	self.nextUpdate = love.timer.getTime() + 0.08

	local avg_dt = 0

	for _, v in ipairs(self.dts) do
		avg_dt = avg_dt + v
	end

	avg_dt = avg_dt / 7


	local _, _, flags = love.window.getMode()
	local max_fps = loop.fpslimit

	if loop.fpslimit > 999 then
		max_fps = flags.refreshrate
		self.maxFps:replaceText(("/%ihz"):format(max_fps))
	else
		self.maxFps:replaceText(("/%ifps"):format(max_fps))
	end

	local fps = 1 / avg_dt
	self.fps:replaceText(("%i"):format(math.min(max_fps, fps)))

	local ms = avg_dt * 1000
	if ms > 10 then
		self.ms:replaceText(("%ims"):format(ms))
	elseif ms >= 1 then
		self.ms:replaceText(("%0.01fms"):format(ms))
	else
		self.ms:replaceText(("%0.02fms"):format(ms))
	end

	self.fpsBox.color = colors.okay
	self.latencyBox.color = colors.okay

	if fps < max_fps * 0.95 then
		self.fpsBox.color = colors.danger
	elseif fps < max_fps * 0.8 then
		self.fpsBox.color = colors.warning
	end

	if ms > 8 then
		self.latencyBox.color = colors.danger
	elseif ms > 16 then
		self.latencyBox.color = colors.warning
	end
end

return FpsDisplay
