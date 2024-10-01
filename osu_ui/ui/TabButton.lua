local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@class osu.ui.TabButton : osu.ui.UiElement
---@operator call: osu.ui.TabButton
---@field private transform love.Transform
---@field private image love.Image
---@field private hoverSound audio.Source
---@field private clickSound audio.Source
---@field private label love.Text
---@field private onClick function
---@field private hoverState osu.ui.HoverState
---@field active boolean
local TabButton = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param params { label: string, font: love.Font, transform: love.Transform }
---@param on_click function
function TabButton:new(assets, params, on_click)
	self.transform = params.transform
	self.image = assets.images.tab
	self.label = love.graphics.newText(params.font, params.label)
	self.hoverSound =  assets.sounds.hoverOverRect
	self.clickSound =  assets.sounds.clickShortConfirm
	self.totalW, self.totalH = self.image:getDimensions()
	self.hoverState = HoverState("quadout", 0.3)
	self.active = false
	self.onClick = on_click
end

local gfx = love.graphics

function TabButton:mouse()
	gfx.push()
	gfx.applyTransform(self.transform)
	local hover ---@type boolean
	local alpha
	local just_hovered ---@type boolean
	hover, alpha, just_hovered = self.hoverState:check(self.totalW, self.totalH)
	gfx.pop()

	if just_hovered then
		ui.playSound(self.hoverSound)
	end

	if hover and ui.mousePressed(1) then
		ui.playSound(self.clickSound)
		self.onClick()
		return true
	end

	return false
end

local inactive = { 0.86, 0.08, 0.23 }
local active = { 1, 1, 1 }

function TabButton:draw()
	gfx.push()
	gfx.applyTransform(self.transform)
	gfx.setColor(self.active and active or inactive)
	gfx.draw(self.image)
	gfx.setColor(1, 1, 1)
	ui.textFrameShadow(self.label, 0, 2, 137, 21, "center", "center")
	gfx.pop()
end

return TabButton
