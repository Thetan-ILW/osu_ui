local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@class osu.ui.Label : osu.ui.UiElement
---@operator call: osu.ui.Label
---@field label love.Text
---@field color number[]
---@field align "left" | "center" | "right"
---@field private totalW number
---@field private totalH number
---@field private hover boolean
---@field private onChange function?
---@field private hoverSound audio.Source
---@field private hoverState osu.ui.HoverState
local Label = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param params { text: string, font: love.Font, color: number[]?, pixelWidth: number, pixelHeight: number?, align?: "left" | "center" | "right" }
---@param on_change function?
function Label:new(assets, params, on_change)
	self.assets = assets
	self.label = love.graphics.newText(params.font, params.text)
	self.color = params.color or { 1, 1, 1, 1 }
	self.align = params.align or "center"
	self.totalW = params.pixelWidth
	self.onChange = on_change
	self.hoverSound = self.assets.sounds.hoverOverRect
	self.hoverState = HoverState("linear", 0)

	if params.pixelHeight then
		self.totalH = params.pixelHeight
		return
	end

	self.totalH = self.label:getHeight() * math.min(ui.getTextScale(), 1)
end

local gfx = love.graphics

---@param has_focus boolean
function Label:update(has_focus)
	local animation, just_focused = 0, false
	self.hover, animation, just_focused = self.hoverState:check(self.totalW, self.totalH, 0, 0, has_focus)

	if just_focused then
		ui.playSound(self.hoverSound)
	end

	if self.hover and ui.mousePressed(1) then
		if self.onChange then
			self.onChange()
			self.changeTime = -math.huge
		end
	end
end

function Label:draw()
	gfx.setColor(self.color)
	ui.textFrame(self.label, 0, 0, self.totalW, self.totalH, self.align, "center")
	gfx.translate(0, self.totalH)
end

return Label
