local Component = require("ui.Component")

---@alias AlignX "left" | "center" | "right"
---@alias AlignY "top" | "center" | "bottom"
---@alias ui.LabelParams { text: string | table, font: ui.Font, color: Color?, alignX?: AlignX, alignY?: AlignY, shadow: boolean?, boxWidth: number?, boxHeight: number? }

---@class ui.Label : ui.Component
---@overload fun(params: ui.LabelParams): ui.Label
---@field text string | table
---@field font ui.Font
---@field shadow boolean
---@field posX number
---@field poxY number
---@field label love.Text
---@field alignX AlignX
---@field alignY AlignY
---@field boxWidth number?
---@field boxHeight number?
local Label = Component + {}

---@param params table?
function Label:new(params)
	Component.new(self, params)
end

function Label:load()
	self:assert(self.font, "No font was provided")

	self:updateSizeAndPos()
	self.label = love.graphics.newText(self.font.instance, self.text)
	self.color = self.color or { 1, 1, 1, 1 }
	self.alignX = self.alignX or "left"
	self.alignY = self.alignY or "top"
	self.shadow = self.shadow or false
	self.shadowOffset = self.shadowOffset or 0.6
end

function Label:updateSizeAndPos()
	local text_scale = 1 / self.font.dpiScale
	local text = self.text
	local font = self.font.instance

	local text_width = 0
	local text_height = 0

	if type(text) == "string" then
		if self.boxWidth then
			local width, wrapped_text = font:getWrap(text, self.boxWidth / text_scale)
			self.text = table.concat(wrapped_text, "\n")
			text_width = width * text_scale
			text_height = #wrapped_text * font:getHeight() * text_scale
		else
			local _, new_lines = text:gsub("\n", "")
			text_width = font:getWidth(text) * text_scale
			text_height = (font:getHeight() * (new_lines + 1)) * text_scale
		end
	elseif type(text) == "table" then
		local max_w = 0
		local lines = 1
		for i, v in ipairs(text) do
			if type(v) == "string" then
				max_w = math.max(max_w, font:getWidth(v))
				local _, new_lines = v:gsub("\n", "")
				lines = lines + new_lines
			end
		end
		text_width = max_w * text_scale
		text_height = lines * font:getHeight() * text_scale
	end

	self.textScale = text_scale

	local x = 0
	local y = 0

	if self.boxWidth then
		self.width = self.boxWidth
		if self.alignX == "center" then
			x = (self.boxWidth - text_width) / 2
		elseif self.alignX == "right" then
			x = self.boxWidth - text_width
		end
	else
		self.width = text_width
	end

	if self.boxHeight then
		self.height = self.boxHeight
		if self.alignY == "center" then
			y = self.boxHeight / 2 - text_height / 2
		elseif self.alignY == "bottom" then
			y = self.boxHeight - text_height
		end
	else
		self.height = text_height
	end

	self.posX, self.posY = x, y
end

---@return number
function Label:getWidth()
	return math.max(self.boxWidth or 0, self.width)
end

---@return number
function Label:getHeight()
	return math.max(self.boxHeight or 0, self.height)
end

---@param text string | table
function Label:replaceText(text)
	if type(text) == "string" and self.text == text then
		return
	end
	self.text = text
	self:updateSizeAndPos()
	self.label:set(self.text)
end

local gfx = love.graphics

function Label:draw()
	gfx.translate(self.posX, self.posY)
	gfx.scale(1 / self.font.dpiScale)

	local r, g, b, a = gfx.getColor()

	if self.shadow then
		local shadow_offset = self.shadowOffset
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
