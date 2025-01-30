local Component = require("ui.Component")
local Image = require("ui.Image")
local Label = require("ui.Label")
local HoverState = require("ui.HoverState")

---@class osu.ui.DiffTable : ui.Component
---@operator call: osu.ui.DiffTable
local DiffTable = Component + {}

function DiffTable:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	self.width, self.height = 375, 56

	self.hoverState = HoverState("quadout", 0.2)

	self.blockMouseFocus = true
	local bg = self:addChild("background", Image({
		scaleX = 0.55,
		scaleY = 0.555,
		image = assets:loadImage("menu-button-background"),
		color = { 0, 0, 0, 0.7 },
		---@param this ui.Image
		update = function(this)
			this.alpha = 0.7 + (self.hoverState.progress * 0.2)
		end,
	}))
	self.height = bg:getHeight() * 0.555

	self.msd = self:addChild("msd", Label({
		x = self.width - 45,
		y = self.height / 2,
		font = fonts:loadFont("QuicksandBold", 36),
		origin = { x = 0.5, y = 0.5 },
		text = "",
		z = 0.1
	}))

	self.firstPattern = self:addChild("firstPattern", Label({
		y = -11,
		font = fonts:loadFont("QuicksandBold", 20),
		boxWidth = self.width - 95,
		boxHeight = self.height,
		alignX = "right",
		alignY = "center",
		z = 0.1
	}))

	self.secondPattern = self:addChild("secondPattern", Label({
		y = 11,
		font = fonts:loadFont("QuicksandBold", 16),
		boxWidth = self.width - 95,
		boxHeight = self.height,
		alignX = "right",
		alignY = "center",
		z = 0.1
	}))

	self.lnPercentFormat = { { 1, 1, 1, 1 }, "", { 1, 1, 1, 1 }, "% LN" }
	self.lnPercent = self:addChild("lnPercent", Label({
		x = 15,
		y = -11,
		font = fonts:loadFont("QuicksandBold", 20),
		boxHeight = self.height,
		alignY = "center",
		z = 0.1
	}))

	self.formatLevel = self:addChild("formatLevel", Label({
		x = 15,
		y = 11,
		font = fonts:loadFont("QuicksandBold", 20),
		boxHeight = self.height,
		alignY = "center",
		z = 0.1
	}))

	self.updateTime = 0
end

function DiffTable:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width, self.height, mx, my)
end

function DiffTable:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

local time = 0.7
local time2 = 1 / time
function DiffTable:update()
	local t = 1 - (math.min(time, love.timer.getTime() - self.updateTime) * time2)
	t = 1 - (t * t * t)
	self.lnPercent.alpha = t
	self.formatLevel.alpha = t
	self.firstPattern.alpha = t
	self.secondPattern.alpha = t
	self.msd.alpha = t
end

---@param display_info osu.ui.SelectViewDisplayInfo
function DiffTable:updateInfo(display_info)
	self.msd:replaceText(("%0.02f"):format(display_info.msd.first))
	self.msd.color = display_info.msd.firstColor

	local s = math.min(1, 80 / self.msd:getWidth())
	self.msd.scaleX = s
	self.msd.scaleY = s

	self.firstPattern:replaceText(display_info.msd.firstPattern)

	if display_info.msd.second ~= 0 then
		self.firstPattern.y = -11
		self.secondPattern.disabled = false
		self.secondPattern:replaceText(display_info.msd.secondPattern)
	else
		self.firstPattern.y = 0
		self.secondPattern.disabled = true
	end

	self.lnPercentFormat[1] = display_info.lnPercentColor
	self.lnPercentFormat[2] = ("%i"):format(display_info.lnPercent * 100)
	self.lnPercent:replaceText(self.lnPercentFormat)
	self.formatLevel:replaceText(display_info.formatLevel)
	self.updateTime = love.timer.getTime()
end

function DiffTable:justHovered()
	self.playSound(self.hoverSound)
end

return DiffTable
