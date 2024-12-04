local Component = require("ui.Component")
local Label = require("ui.Label")
local Image = require("ui.Image")

---@alias osu.ui.TabButtonParams { text: string, font: love.Font?, image: love.Image }

---@class osu.ui.TabButton : ui.Component
---@overload fun(params: osu.ui.TabButtonParams): osu.ui.TabButton
---@field text string
---@field onClick function
---@field active boolean
local TabButton = Component + {}

function TabButton:load()
	local image = self.shared.assets:loadImage("selection-tab")
	self.width, self.height = image:getDimensions()
	self.active = false

	self.image = self:addChild("image", Image({
		image = image
	}))

	self.label = self:addChild("label", Label({
		width = self.width,
		height = self.height,
		alignX = "center",
		alignY = "center",
		text = self.text,
		font = self.font or self.shared.fontManager:loadFont("Regular", 13),
		z = 1,
	}))
end

function TabButton:justHovered()
	self.playSound(self.hoverSound)
end

function TabButton:mousePressed()
	if self.mouseOver then
		self.playSound(self.clickSound)
		self.onClick()
		return true
	end
	return false
end

local inactive = { 0.86, 0.08, 0.23, 1 }
local active = { 1, 1, 1, 1 }

local text_inactive = { 1, 1, 1, 1 }
local text_active = { 0, 0, 0, 1 }

function TabButton:update()
	if self.active then
		self.label.color = text_active
		self.label.shadow = true
		self.image.color = active
	else
		self.label.color = text_inactive
		self.label.shadow = false
		self.image.color = inactive
	end
end

return TabButton
