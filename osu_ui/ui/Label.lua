local UiElement = require("osu_ui.ui.UiElement")

local ui = require("osu_ui.ui")

---@alias LabelParams { text: string, font: love.Font, color: Color?, widthLimit: number?, heightLimit: number?, ax?: AlignX, ay?: AlignY, onClick: function }

---@class osu.ui.Label : osu.ui.UiElement
---@overload fun(params: LabelParams): osu.ui.Label
---@field text string
---@field font love.Font
---@field widthLimit number
---@field heightLimit number
---@field label love.Text
---@field align AlignX
---@field hoverSound audio.Source
---@field onClick function?
local Label = UiElement + {}

---@param assets osu.ui.OsuAssets
function Label:load()
	self.label = love.graphics.newText(self.font, self.text)
	self.color = self.color or { 1, 1, 1, 1 }
	self.ax = self.ax or "left"
	self.ay = self.ay or "top"

	self.totalW = self.widthLimit or self.label:getWidth() * math.min(ui.getTextScale(), 1)
	self.totalH = self.label:getHeight() * math.min(ui.getTextScale(), 1)

	if self.widthLimit then
		self.totalW = self.widthLimit
	end
	if self.heightLimit then
		self.totalH = self.heightLimit
	end

	UiElement.load(self)
end

local gfx = love.graphics

function Label:justHovered()
	ui.playSound(self.hoverSound)
end

function Label:update()
	if self.mouseOver and ui.mousePressed(1) then
		if self.onClick then
			self.onClick()
		end
	end
end

function Label:draw()
	local c = self.color
	gfx.setColor(c[1], c[2], c[3], c[4] * self.alpha)
	ui.textFrame(self.label, 0, 0, self.totalW, self.totalH, self.ax, self.ay)
	gfx.translate(0, self.totalH)
end

return Label
