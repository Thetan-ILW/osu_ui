local Component = require("ui.Component")
local Label = require("ui.Label")
local Image =  require("ui.Image")

local math_util = require("math_util")

---@class osu.ui.Checkbox : ui.Component
---@operator call: osu.ui.Checkbox
---@field label string
---@field toggled boolean
---@field disabled boolean
---@field clickTime number
---@field getValue fun(): boolean
---@field clicked function
local Checkbox = Component + {}

function Checkbox:load()
	local assets = self.shared.assets ---@cast assets osu.ui.OsuAssets
	local fonts = self.shared.fontManager ---@cast fonts ui.FontManager

	self.height = self.height or 37
	local x = 5

	local off_img = self:addChild("off", Image({
		x = x,
		y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("menu-checkbox-off"),
		alpha = 0,
		color = self.disabled and { 0.3, 1, 1, 1 } or { 1, 1, 1, 1 }
	}))

	local on_img = self:addChild("on", Image({
		x = x,
		y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("menu-checkbox-on"),
		alpha = 0,
		color = self.disabled and { 0.3, 1, 1, 1 } or { 1, 1, 1, 1 }
	}))

	local img = self.toggled and on_img or off_img
	img.alpha = 1

	self:addChild("label", Label({
		x = math.max(on_img:getWidth(), off_img:getWidth()),
		height = self.height,
		alignY = "center",
		text = self.label,
		font = fonts:loadFont("Regular", 16),
	}))

	self.clickTime = -9999
	self.checkOnSound = assets:loadAudio("check-on")
	self.checkOffSound = assets:loadAudio("check-off")
end

function Checkbox:mouseClick()
	if not self.mouseOver or self.disabled then
		return false
	end
	self.clicked()
	self.playSound(self.toggled and self.checkOnSound or self.checkOffSound)
	self.clickTime = love.timer.getTime()
	return true
end

function Checkbox:update()
	self.toggled = self.getValue()
	local on_img = self:getChild("on")
	local off_img = self:getChild("off")
	local img = self.toggled and on_img or off_img
	on_img.alpha = 0
	off_img.alpha = 0
	img.alpha = 1
	local scale = 0.1 + (math_util.clamp(love.timer.getTime() - self.clickTime, 0, 0.1) * 10) * 0.5
	img.scaleX, img.scaleY = scale, scale
end

return Checkbox
