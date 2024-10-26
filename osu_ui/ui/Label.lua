local UiElement = require("osu_ui.ui.UiElement")

---@alias LabelParams { text: string, font: love.Font, color: Color?, alignX?: AlignX, alignY?: AlignY, shadow: boolean?, textScale: number?, onClick: function }

---@class osu.ui.Label : osu.ui.UiElement
---@overload fun(params: LabelParams): osu.ui.Label
---@field text string
---@field font love.Font
---@field shadow boolean
---@field posX number
---@field poxY number
---@field label love.Text
---@field align AlignX
---@field onClick function?
local Label = UiElement + {}

---@param assets osu.ui.OsuAssets
function Label:load()
	self.label = love.graphics.newText(self.font, self.text)
	self.color = self.color or { 1, 1, 1, 1 }
	self.alignX = self.alignX or "left"
	self.alignY = self.alignY or "top"
	self.shadow = self.shadow or false

	local text_scale = self.textScale or self.parent.textScale
	local tw, th = self.label:getDimensions()
	tw, th = tw * text_scale, th * text_scale
	self.totalW = self.totalW or tw
	self.totalH = self.totalH or th
	self.textScale = text_scale

	local x = 0
	local y = 0
	local w = self.totalW
	local h = self.totalH

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

	UiElement.load(self)
end

local gfx = love.graphics

local shadow_offset = 0.6

function Label:draw()
	gfx.translate(self.posX, self.posY)
	gfx.scale(self.textScale)

	if self.shadow then
		gfx.setColor(0.078, 0.078, 0.078, 0.64)
		gfx.draw(self.label, -shadow_offset, -shadow_offset)
		gfx.draw(self.label, shadow_offset, -shadow_offset)
		gfx.draw(self.label, -shadow_offset, shadow_offset)
		gfx.draw(self.label, shadow_offset, shadow_offset)
	end

	gfx.setColor(self.color)
	gfx.draw(self.label)
end

return Label
