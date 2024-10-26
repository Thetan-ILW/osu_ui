local UiElement = require("osu_ui.ui.UiElement")

---@alias DynamicTextParams { font: love.Font, value: (fun(): string), alignX: AlignX?, alignY: AlignY?, widthLimit: number?, heightLimit: number?, textScale: number? }

---@class osu.ui.DynamicText : osu.ui.UiElement
---@overload fun(params: DynamicTextParams): osu.ui.DynamicText
---@field value fun(): string,
---@field text string
---@field font love.Font
---@field alignX AlignX
---@field alignY AlignY
---@field widthLimit number?
---@field heightLimit number?
---@field textScale number
---@field textY number
local DynamicText = UiElement + {}

function DynamicText:load()
	assert(self.font, ("%s: Font was not provided"):format(self.id))
	self.text = ""
	self.alignX = self.alignX or "left"
	self.alignY = self.alignY or "top"
	self.textScale = self.textScale or self.parent.textScale
	self.textY = 0
	UiElement.load(self)
end

function DynamicText:update()
	local new_text = self.value()
	if new_text == self.text then
		return
	end

	self.text = new_text

	local font = self.font
	local fw, fh = font:getWidth(new_text), font:getHeight()
	fw, fh = fw * self.textScale, fh * self.textScale
	local w, h = self.widthLimit or fw, self.heightLimit or fh
	self.totalW, self.totalH = w, h
	self.hoverWidth, self.hoverHeight = w, h

	if self.alignY == "center" then
		self.textY = self.totalH / 2 - h / 2
	elseif self.alignY == "bottom" then
		self.textY = h - self.totalH
	end
end

function DynamicText:draw()
	local text = self.text
	local font = self.font
	local w = self.totalW / self.textScale
	love.graphics.setFont(font)
	love.graphics.scale(self.textScale)
	love.graphics.printf(text, 0, self.textY, w, self.alignX, 0)
end

return DynamicText
