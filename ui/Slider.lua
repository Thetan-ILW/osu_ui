local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local math_util = require("math_util")
local ui = require("osu_ui.ui")

---@class osu.ui.Slider : osu.ui.UiElement
---@operator call: osu.ui.Slider
---@field private label love.Text
---@field private sliderW number?
---@field private params { min: number, max: number, increment: number }
---@field private value number
---@field private dragging boolean
---@field private getValue fun(): number, { min: number, max: number, increment: number }
---@field private onChange fun(number)
---@field private format? fun(number): string
---@field private hoverState osu.ui.HoverState
---@field private lastMousePosition number
local Slider = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param params { label: string, font: love.Font, pixelWidth: number, pixelHeight: number, sliderPixelWidth: number?, defaultValue: number, tip: string? }
---@param get_value fun(): number
---@param on_change fun(number)
---@param format? fun(number): string
function Slider:new(assets, params, get_value, on_change, format)
	self.assets = assets
	self.label = love.graphics.newText(params.font, params.label)
	self.totalW = params.pixelWidth
	self.totalH = params.pixelHeight
	self.sliderW = params.sliderPixelWidth
	self.defaultValue = params.defaultValue
	self.tip = params.tip
	self.dragging = false
	self.getValue = get_value
	self.onChange = on_change
	self.format = format or function(v)
		return ("%g"):format(v)
	end
	self.hoverState = HoverState("linear", 0)
	self.lastMousePosition = 0
end

local gfx = love.graphics
local line_height = 1
local head_radius = 8
local text_indent = 15

function Slider:getPosAndWidth()
	if self.sliderW then
		local w = self.sliderW
		local x = self.totalW - w - 15
		return x, w
	end

	local x = self.label:getWidth() * ui.getTextScale()
	local w = self.totalW - x - 15 - text_indent

	return x, w
end

function Slider:playDragSound(percent)
	local sound = self.assets.sounds.sliderBar
	sound:setRate(1 + percent * 0.2)
	ui.playSound(sound)
end

function Slider:update(has_focus)
	self.value, self.params = self.getValue()

	if self.defaultValue ~= nil then
		self.valueChanged = self.defaultValue ~= self.value
	end

	if not has_focus then
		return
	end

	local _, just_hovered = 0, false
	self.hover, _, just_hovered = self.hoverState:check(self.totalW, self.totalH, 0, 0, has_focus)

	if self.hover then
		ui.tooltip = self.format(self.value)
	end

	local x, w = self:getPosAndWidth()

	w = w - head_radius * 2
	x = x + head_radius * 2

	local over_slider = ui.isOver(w + 8, self.totalH, x - 4, 0)

	if over_slider then
		if ui.mousePressed(1) then
			self.dragging = true
		end
		if ui.mousePressed(2) and self.defaultValue then
			self.onChange(self.defaultValue)
		end
		if ui.keyPressed("left") then
			local new = math.max(self.value - self.params.increment, self.params.min)
			self.onChange(new)
			local range = self.params.max - self.params.min
			self:playDragSound(new / range)
		elseif ui.keyPressed("right") then
			local new = math.min(self.value + self.params.increment, self.params.max)
			self.onChange(new)
			local range = self.params.max - self.params.min
			self:playDragSound(new / range)
		end
	end

	if self.dragging then
		local mx, _ = gfx.inverseTransformPoint(love.mouse.getPosition())

		if love.mouse.isDown(1) then
			local range = self.params.max - self.params.min
			local percent = (mx - x) / w
			local value = math_util.clamp(self.params.min + percent * range, self.params.min, self.params.max)

			if self.lastMousePosition ~= mx then
				self.onChange(math_util.round(value, self.params.increment))
				self.changeTime = -math.huge
				self:playDragSound(percent)
				self.lastMousePosition = mx
			end
		else
			self.dragging = false
		end
	end

	if just_hovered then
		ui.playSound(self.assets.sounds.hoverOverRect)
	end
end

function Slider:draw()
	gfx.setColor(1, 1, 1)
	ui.textFrame(self.label, 0, 0, self.totalW, self.totalH, "left", "center")

	local x, w = self:getPosAndWidth()

	local r2 = head_radius * 2
	local head_coordinate = (self.value - self.params.min) / (self.params.max - self.params.min)
	local head_x = head_coordinate * (w - r2)

	gfx.push()
	gfx.translate(x + text_indent, self.totalH / 2 - line_height)

	gfx.setColor(0.89, 0.47, 0.56)
	gfx.rectangle("fill", 0, 0, math.max(head_x - head_radius, 0), line_height)
	gfx.setColor(0.89, 0.47, 0.56, 0.6)
	gfx.rectangle("fill", head_x + head_radius, 0, w - head_x - r2, line_height)

	gfx.setColor(0.89, 0.47, 0.56)
	gfx.setLineWidth(1)
	gfx.circle("line", head_x, 0, head_radius)

	gfx.pop()

	gfx.translate(0, self.totalH)
end

return Slider
