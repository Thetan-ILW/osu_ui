local UiElement = require("osu_ui.ui.UiElement")

local Label = require("osu_ui.ui.Label")

local ui = require("osu_ui.ui")

---@alias TabButtonParams { text: string, font: love.Font, image: love.Image, hoverSound: audio.Source?, clickSound: audio.Source? }

---@class osu.ui.TabButton : osu.ui.UiElement
---@overload fun(params: TabButtonParams): osu.ui.TabButton
---@field image love.Image
---@field hoverSound audio.Source?
---@field clickSound audio.Source?
---@field label osu.ui.Label
---@field text string
---@field font love.Font
---@field onClick function
---@field hoverState osu.ui.HoverState
---@field active boolean
local TabButton = UiElement + {}

function TabButton:load()
	self.totalW, self.totalH = self.image:getDimensions()
	self.active = false

	self.label = Label({
		text = self.text,
		font = self.font,
		textScale = self.parent.textScale,
		alignX = "center",
		alignY = "center",
		totalW = self.totalW,
		totalH = self.totalH
	})
	self.label:load()
	UiElement.load(self)
end

function TabButton:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
end

function TabButton:justHovered()
	ui.playSound(self.hoverSound)
end

function TabButton:mousePressed()
	if self.mouseOver then
		ui.playSound(self.clickSound)
		self.onClick()
		return true
	end
	return false
end

local gfx = love.graphics

local inactive = { 0.86, 0.08, 0.23 }
local active = { 1, 1, 1 }

local text_inactive = { 1, 1, 1 }
local text_active = { 0, 0, 0 }

function TabButton:draw()
	local c = self.active and active or inactive
	gfx.setColor(c[1], c[2], c[3], self.alpha)
	gfx.draw(self.image)

	local tc = self.active and text_active or text_inactive
	gfx.setColor(tc[1], tc[2], tc[3], self.alpha)
	self.label:draw()
end

return TabButton
