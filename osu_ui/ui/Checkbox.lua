local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")
local math_util = require("math_util")

---@class osu.ui.Checkbox : osu.ui.UiElement
---@operator call: osu.ui.Checkbox
---@field private label love.Text
---@field private imgOn love.Image
---@field private imgOff love.Image
---@field private imageScale number
---@field private toggled boolean
---@field private changeTime number
---@field private hoverState osu.ui.HoverState
local Checkbox = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param params { text: string, font: love.Font, pixelWidth: number?, pixelHeight: number, defaultValue: boolean?, tip: string?, disabled: boolean? }
---@param get_value function
---@param on_change function
function Checkbox:new(assets, params, get_value, on_change)
	self.assets = assets
	self.label = love.graphics.newText(params.font, params.text)
	self.totalW = params.pixelWidth
	self.totalH = params.pixelHeight
	self.defaultValue = params.defaultValue
	self.valueChanged = false
	self.tip = params.tip
	self.disabled = params.disabled
	self.getValue = get_value
	self.onChange = on_change

	self.imgOn = assets.images.checkboxOn
	self.imgOff = assets.images.checkboxOff
	local ih = self.imgOff:getHeight()
	self.imageScale = self.totalH / ih

	if not self.totalW then
		self.totalW = self.imgOn:getWidth() * self.imageScale + self.label:getWidth()
	end

	self.changeTime = -math.huge
	self.hoverState = HoverState("linear", 0)
end

---@param has_focus boolean
function Checkbox:update(has_focus)
	self.toggled = self.getValue()

	if self.defaultValue ~= nil then
		self.valueChanged = self.defaultValue ~= self.toggled
	end

	local _, just_hovered = 0, false
	self.hover, _, just_hovered = self.hoverState:check(self.totalW, self.totalH, 0, 0, has_focus)

	if self.hover then
		ui.tooltip = self.tip
	end

	if self.hover and ui.mousePressed(1) and not self.disabled then
		self.onChange()
		self.changeTime = love.timer.getTime()

		local sounds = self.assets.sounds
		local sound = self.getValue() and sounds.checkOn or sounds.checkOff
		ui.playSound(sound)
	end

	if just_hovered then
		ui.playSound(self.assets.sounds.hoverOverRect)
	end
end

local gfx = love.graphics

function Checkbox:draw()
	gfx.setColor(1, 1, 1)

	local scale = 0.5 + (math_util.clamp(love.timer.getTime() - self.changeTime, 0, 0.1) * 10) * 0.5
	local image_size = self.imgOn:getHeight() * self.imageScale
	local x = image_size / 2 - (image_size * scale) / 2

	local prev_shader = gfx.getShader()
	if self.disabled then
		gfx.setShader(self.assets.shaders.gray)
	end
	if self.toggled then
		gfx.draw(self.imgOn, x / 2, x, 0, self.imageScale * scale, self.imageScale * scale)
	else
		gfx.draw(self.imgOff, x / 2, x, 0, self.imageScale * scale, self.imageScale * scale)
	end
	gfx.setShader(prev_shader)

	x = self.imgOff:getWidth() * self.imageScale
	ui.textFrame(self.label, x, 0, self.totalW - x, self.totalH, "left", "center")
	gfx.translate(0, self.totalH)
end

return Checkbox
