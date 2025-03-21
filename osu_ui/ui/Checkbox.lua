local Component = require("ui.Component")
local Label = require("ui.Label")
local Image =  require("ui.Image")

local math_util = require("math_util")

---@class osu.ui.Checkbox : ui.Component
---@operator call: osu.ui.Checkbox
---@field label string
---@field toggled boolean
---@field locked boolean?
---@field clickTime number
---@field getValue fun(): boolean
---@field clicked function
---@field font ui.Font?
---@field large boolean?
local Checkbox = Component + {}

function Checkbox:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	local x = 5

	self.height = self.height == 0 and 37 or self.height

	local off_img = self:addChild("off", Image({
		x = x,
		y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("menu-checkbox-off"),
		alpha = 0,
		color = self.locked and { 0.5, 0.5, 0.5, 1 } or { 0.92, 0.45, 0.54, 1 }
	}))

	local on_img = self:addChild("on", Image({
		x = x,
		y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("menu-checkbox-on"),
		alpha = 0,
		color = self.locked and { 0.5, 0.5, 0.5, 1 } or { 0.92, 0.45, 0.54, 1 }
	}))

	local img = self.toggled and on_img or off_img
	img.alpha = 1

	local label = self:addChild("label", Label({
		x = math.max(on_img:getWidth(), off_img:getWidth()),
		boxHeight = self.height,
		alignY = "center",
		text = self.label,
		font = self.font or fonts:loadFont("Regular", 18),
	}))

	self.clickTime = -9999
	self.checkOnSound = assets:loadAudio("check-on")
	self.checkOffSound = assets:loadAudio("check-off")
	self.width = self.width == 0 and off_img:getWidth() + label:getWidth() or self.width
	self.imageScale = self.large and 0.18 or 0.1
end

function Checkbox:mouseClick()
	if not self.mouseOver or self.locked then
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
	local scale = self.imageScale + (math_util.clamp(love.timer.getTime() - self.clickTime, 0, 0.1) * 10) * 0.5
	img.scaleX, img.scaleY = scale, scale
end

return Checkbox
