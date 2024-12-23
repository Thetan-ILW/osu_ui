local Component = require("ui.Component")
local Label = require("ui.Label")
local flux = require("flux")
local math_util = require("math_util")

---@class osu.ui.TooltipView : ui.Component
---@operator call: osu.ui.TooltipView
---@field fonts {[string]: love.Font}
---@field text string
---@field width number
---@field height number
---@field state "hidden" | "fade_in" | "visible" | "fade_out"
---@field tween table?
---@field alpha number
local TooltipView = Component + {}

function TooltipView:load()
	self.text = ""
	self.state = "hidden"

	self:getViewport():listenForResize(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local label = self:addChild("label", Label({
		font = scene.fontManager:loadFont("Regular", 14),
		text = ""
	})) ---@cast label ui.Label
	self.label = label
end

---@private
function TooltipView:fadeIn()
	self.state = "fade_in"
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.2, { alpha = 1 }):ease("quadout")
end

---@private
function TooltipView:fadeOut()
	self.state = "fade_out"
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.2, { alpha = 0 }):ease("quadout")
end

function TooltipView:setText(text)
	self.text = text
end

---@param state ui.FrameState
function TooltipView:updateTree(state)
	local mx, my = love.graphics.inverseTransformPoint(state.mouseX, state.mouseY)
	local w, h = self:getDimensions()
	local sw, sh = self.parent:getDimensions()
	self.x = math_util.clamp(mx + 10, 2, sw - 2 - w)
	self.y = math_util.clamp(my + 10, 0, sh - 2 - h)
	Component.updateTree(self, state)
end

function TooltipView:update()
	local state = self.state
	local text = self.text

	if text and text ~= self.label.text then
		self.label:replaceText(text)
		self.width, self.height = self.label:getDimensions()
	end

	if state == "hidden" then
		if text then
			self:fadeIn()
		end
	elseif state == "fade_in" then
		if self.alpha == 1 then
			self.state = "visible"
		end
		if not text then
			self:fadeOut()
		end
	elseif state == "visible" then
		if not text then
			self:fadeOut()
		end
	elseif state == "fade_out" then
		if self.alpha == 0 then
			self.state = "hidden"
		end
		if text then
			self:fadeIn()
		end
	end

	self.text = nil

end

local gfx = love.graphics

function TooltipView:draw()
	if self.alpha == 0 then
		return
	end

	local _, _, _, a = love.graphics.getColor()
	local w, h = self:getDimensions()
	gfx.setColor(0, 0, 0, a)
	gfx.rectangle("fill", -3, 0, w + 6, h, 4, 4)

	gfx.setColor(1, 1, 1, 0.5 * a)
	gfx.setLineWidth(1)
	gfx.rectangle("line", -3, 0, w + 6, h, 4, 4)
end

return TooltipView
