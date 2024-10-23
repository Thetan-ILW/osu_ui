local class = require("class")

local HoverState = require("osu_ui.ui.HoverState")

---@alias Color [number, number, number, number]
---@alias AlignX "left" | "center" | "right"
---@alias AlignY "top" | "center" | "bottom"
---@alias ProtoOrigin { x: number, y: number }
---@alias InputEvent "mousePressed" | "mouseReleased" | "keyPresseed" | "keyReleased" | "wheelUp" | "wheelDown"

---@class osu.ui.UiElement
---@operator call: osu.ui.UiElement
---@field parent osu.ui.Container
---@field transform love.Transform
---@field x number
---@field y number
---@field origin ProtoOrigin
---@field scale number
---@field rotation number
---@field depth number
---@field totalW number
---@field totalH number
---@field color Color
---@field alpha number
---@field hoverState osu.ui.HoverState
---@field hoverWidth number
---@field hoverHeight number
---@field mouseOver boolean
---@field blockMouseFocus boolean
local UiElement = class()

function UiElement:load()
	self.x = self.x or 0
	self.y = self.y or 0
	self.origin = self.origin or { x = 0, y = 0 }
	self.scale = self.scale or 1
	self.rotation = self.rotation or 0
	self.depth = self.depth or 0
	self.color = self.color or { 1, 1, 1, 1 }
	self.alpha = self.alpha or 1
	self.totalW, self.totalH = self.totalW or 0, self.totalH or 0
	self.hoverState = self.hoverState or HoverState("quadout", 0.4)
	self.hoverWidth = self.hoverWidth or self.totalW
	self.hoverHeight = self.hoverHeight or self.totalH
	self.mouseOver = false
	self.blockMouseFocus = self.blockMouseFocus == nil and true or self.blockMouseFocus
	self:applyTransform()
end

function UiElement:unload() end

--- Called when building (function build()) a container, UiElements with the greatest depth are bound first.
function UiElement:bindEvents() end

---@return number
---@return number
function UiElement:getOrigin()
	return self.totalW * self.origin.x, self.totalH * self.origin.y
end

function UiElement:applyTransform()
	self.transform = love.math.newTransform(self.x, self.y, self.rotation, self.scale, self.scale, self:getOrigin())
end

---@return number
---@return number
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

---@return number
---@return number
function UiElement:getPosition()
	return self.transform:transformPoint(0, 0)
end

function UiElement:justHovered() end

---@param has_focus boolean
---@return boolean blocking_focus
function UiElement:setMouseFocus(has_focus)
	if not has_focus then
		self.mouseOver = false
		self.hoverState:loseFocus()
		return true
	end

	local hw, hh = self.hoverWidth, self.hoverHeight
	local mouse_over, just_hovered = self.hoverState:check(hw, hh, 0, 0)
	self.mouseOver = mouse_over

	if just_hovered then
		self:justHovered()
	end

	return self.mouseOver and self.blockMouseFocus
end

---@param dt number
function UiElement:update(dt) end
function UiElement:draw() end

local gfx = love.graphics

function UiElement:debugDraw()
	gfx.setColor(1, 0, 0, 0.2 + self.hoverState.progress * 0.8)

	gfx.setLineWidth(2)
	gfx.rectangle("line", 0, 0, self.totalW, self.totalH)
	local ox, oy = self:getOrigin()
	gfx.circle("line", ox, oy, 5)
end

return UiElement
