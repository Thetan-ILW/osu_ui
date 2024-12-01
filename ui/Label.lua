local Component = require("ui.Component")

---@alias ui.LabelParams { text: string | table, font: ui.Font, color: Color?, alignX?: AlignX, alignY?: AlignY, shadow: boolean? }

---@class ui.Label : ui.Component
---@overload fun(params: ui.LabelParams): ui.Label
---@field text string | table
---@field font ui.Font
---@field shadow boolean
---@field posX number
---@field poxY number
---@field label love.Text
---@field align AlignX
local Label = Component + {}

---@param params table?
function Label:new(params)
	if params then
		self.initialWidth = params.width
		self.initialHeight = params.height
	end
	Component.new(self, params)
end

function Label:load()
	self:assert(self.font, "No font was provided")
	self.label = love.graphics.newText(self.font.instance, self.text)
	self.color = self.color or { 1, 1, 1, 1 }
	self.alignX = self.alignX or "left"
	self.alignY = self.alignY or "top"
	self.shadow = self.shadow or false
	self:updateSizeAndPos()
end

function Label:updateSizeAndPos()
	local text_scale = 1 / self.font.dpiScale
	local tw, th = self.label:getDimensions()
	tw, th = tw * text_scale, th * text_scale
	self.width = self.initialWidth or tw
	self.height = self.initialHeight or th
	self.textScale = text_scale

	local x = 0
	local y = 0
	local w = self.width
	local h = self.height

	if self.alignX == "center" then
		x = w / 2 - tw / 2
	elseif self.alignX == "right" then
		x = w - tw
	end

	if self.alignY == "center" then
		y = h / 2 - th / 2
	elseif self.alignY == "bottom" then
		y = h - th
	end

	self.posX, self.posY = x, y

end

---@param text string | table
function Label:replaceText(text)
	if self.initialWidth then
		local _, wrapped_text = self.font.instance:getWrap(text, self.initialWidth / (1 / self.font.dpiScale))
		self.text = table.concat(wrapped_text, "\n")
	else
		self.text = text
	end

	if type(text) == "table" then
		self.label:setf(text, math.huge, "left")
	else
		self.label:set(self.text)
	end

	self:updateSizeAndPos()
end

local gfx = love.graphics

local shadow_offset = 0.6

function Label:draw()
	gfx.translate(self.posX, self.posY)
	gfx.scale(1 / self.font.dpiScale)

	local r, g, b, a = gfx.getColor()

	if self.shadow then
		gfx.setColor(0.078, 0.078, 0.078, 0.64 * a)
		gfx.draw(self.label, -shadow_offset, -shadow_offset)
		gfx.draw(self.label, shadow_offset, -shadow_offset)
		gfx.draw(self.label, -shadow_offset, shadow_offset)
		gfx.draw(self.label, shadow_offset, shadow_offset)
	end

	local c = self.color
	gfx.setColor(c[1], c[2], c[3], c[4] * a)
	gfx.draw(self.label)
end

return Label
