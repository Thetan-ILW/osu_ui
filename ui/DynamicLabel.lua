local Component = require("ui.Component")

---@alias ui.DynamicLabelParams { font: love.Font, value: (fun(): string), alignX: AlignX?, alignY: AlignY?, shadow: boolean}

---@class ui.DynamicLabel : ui.Component
---@overload fun(params: ui.DynamicLabelParams): ui.DynamicLabel
---@field value fun(): string,
---@field text string
---@field font ui.Font
---@field alignX AlignX
---@field alignY AlignY
---@field widthLimit number?
---@field heightLimit number?
---@field textY number
---@field shadow boolean
local DynamicLabel = Component + {}

---@param params table?
function DynamicLabel:new(params)
	if params then
		self.initialWidth = params.width
		self.initialHeight = params.height
	end
	Component.new(self, params)
end

function DynamicLabel:load()
	self:assert(self.font, "Font was not provided")
	self.text = ""
	self.alignX = self.alignX or "left"
	self.alignY = self.alignY or "top"
	self.textY = 0
end

function DynamicLabel:update()
	local new_text = self.value()
	if new_text == self.text then
		return
	end

	self.text = new_text

	local font = self.font
	local fw, fh = font:getWidth(new_text), font:getHeight()
	local text_scale = 1 / self.font.dpiScale
	fw, fh = fw * text_scale, fh * text_scale
	local w, h = self.initialWidth or fw, self.initialHeight or fh
	self.width, self.height = w, h
	self.hoverWidth, self.hoverHeight = w, h

	if self.alignY == "center" then
		self.textY = self.height / 2 - fh / 2
	elseif self.alignY == "bottom" then
		self.textY = fh - self.height
	end
end

local gfx = love.graphics

function DynamicLabel:draw()
	local text = self.text
	local font = self.font
	local text_scale = 1 / self.font.dpiScale
	local w = self.width / text_scale
	gfx.setFont(font.instance)
	gfx.scale(text_scale)

	local r, g, b, a = gfx.getColor()

	if self.shadow then
		gfx.setColor(0.078, 0.078, 0.078, 0.64 * a)
		gfx.printf(text, -1, self.textY, w, self.alignX, 0)
		gfx.printf(text, 1, self.textY, w, self.alignX, 0)
		gfx.printf(text, 0, self.textY + 1, w, self.alignX, 0)
	end

	local c = self.color
	gfx.setColor(c[1], c[2], c[3], c[4] * a)
	gfx.printf(text, 0, self.textY, w, self.alignX, 0)
end

return DynamicLabel
