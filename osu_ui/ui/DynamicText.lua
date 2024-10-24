local UiElement = require("osu_ui.ui.UiElement")

local ui = require("osu_ui.ui")

---@alias DynamicTextParams { font: love.Font, value: (fun(): string), alignX: AlignX?, alignY: AlignY? }

---@class osu.ui.DynamicText : osu.ui.UiElement
---@overload fun(params: DynamicTextParams): osu.ui.DynamicText
---@field value fun(): string,
---@field text string
---@field font love.Font
---@field alignX AlignX
---@field alignY AlignY
local DynamicText = UiElement + {}

function DynamicText:load()
	assert(self.font, "Font was not provided")
	self.text = ""
	self.alignX = self.alignX or "left"
	self.alignY = self.alignY or "top"
	UiElement.load(self)
end

function DynamicText:update()
	local new_text = self.value()
	if new_text ~= self.text then
		local s = ui.getTextScale()
		self.totalW, self.totalH = self.font:getWidth(new_text) * s, self.font:getHeight() * s
		self.hoverWidth, self.hoverHeight = self.totalW, self.totalH
		self.text = new_text
	end
end

function DynamicText:draw()
	love.graphics.setFont(self.font)
	ui.frame(self.text, 0, 0, self.totalW, self.totalH, self.alignX, self.alignY)
end

return DynamicText
