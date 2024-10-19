local Container = require("osu_ui.ui.Container")

local math_util = require("math_util")

---@class osu.ui.UiElement : osu.ui.Container
---@operator call: osu.ui.UiElement
---@field activeTip string?
---@field protected tip string?
---@field protected assets osu.ui.OsuAssets
---@field protected defaultValue any?
---@field protected valueChanged boolean
---@field protected changeTime number
---@field protected getValue function
---@field protected onChange function
---@field protected totalW number
---@field protected totalH number
---@field protected margin number
---@field protected hover boolean
local UiElement = Container + {}

function UiElement:getDimensions()
	return self.totalW, self.totalH
end

---@return number
function UiElement:getWidth()
	return self.totalW
end

---@return number
function UiElement:getHeight()
	return self.totalH
end

---@return boolean
function UiElement:isMouseOver()
	return self.hover
end

---@param has_focus boolean
function UiElement:update(has_focus) end
function UiElement:draw()
	error("Silly mistake")
end

local gfx = love.graphics

function UiElement:drawYellowThingIfNotDefault()
	---@type number
	self.yellowAlpha = self.yellowAlpha or 0
	local a = self.yellowAlpha

	local delta = love.timer.getDelta() * 5
	a = self.valueChanged and a + delta or a - delta
	a = math_util.clamp(a, 0, 1)
	self.yellowAlpha = a

	gfx.setColor(1, 1, 1, a)

	local img = self.assets.images.optionChanged

	gfx.draw(self.assets.images.optionChanged, 0, 0, 0, self.totalH / img:getHeight())
end

return UiElement
