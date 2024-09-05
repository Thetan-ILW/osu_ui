local class = require("class")
local ui = require("osu_ui.ui")
local flux = require("flux")
local math_util = require("math_util")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.TooltipView
---@operator call: osu.ui.TooltipView
---@field fonts table<string, love.Font>
---@field cursor love.Image
---@field text string
---@field width number
---@field height number
---@field state "hidden" | "fade_in" | "visible" | "fade_out"
---@field tween table?
---@field alpha number
local TooltipView = class()

---@param assets osu.ui.OsuAssets
function TooltipView:load(assets)
	self.fonts = assets.localization.fontGroups.misc
	self.cursor = assets.images.cursor
	self.alpha = 0
	self.state = "hidden"
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

---@private
function TooltipView:setDimensions(text)
	local f = self.fonts.tooltip
	local _, lines = f:getWrap(text, 1000)
	self.height = f:getHeight() * #lines * ui.getTextScale() + 4
	self.width = f:getWidth(text) * ui.getTextScale() + 12
end

function TooltipView:update()
	local tooltip = ui.tooltip

	local state = self.state

	if tooltip then
		if self.text ~= tooltip then
			self:setDimensions(tooltip)
		end
		self.text = tooltip
	end

	if state == "hidden" then
		if tooltip then
			self:fadeIn()
		end
	elseif state == "fade_in" then
		if self.alpha == 1 then
			self.state = "visible"
		end
		if not tooltip then
			self:fadeOut()
		end
	elseif state == "visible" then
		if not tooltip then
			self:fadeOut()
		end
	elseif state == "fade_out" then
		if self.alpha == 0 then
			self.state = "hidden"
		end
		if tooltip then
			self:fadeIn()
		end
	end

	ui.tooltip = nil
end

local gfx = love.graphics

function TooltipView:draw()
	if self.alpha == 0 then
		return
	end

	local text = self.text

	local sw, sh = Layout:move("base")
	local mx, my = gfx.inverseTransformPoint(love.mouse.getPosition())

	local f = self.fonts.tooltip
	local w = self.width
	local h = self.height

	local x = math_util.clamp(mx - w / 2, 2, sw - 2)
	local y = math_util.clamp(my + self.cursor:getHeight() / 2, 0, sh - 2 - h)

	local a = self.alpha

	gfx.setColor(0, 0, 0, a)
	gfx.rectangle("fill", x, y, w, h, 4, 4)

	gfx.setColor(1, 1, 1, 0.5 * a)
	gfx.setLineWidth(1)
	gfx.rectangle("line", x, y, w, h, 4, 4)

	gfx.setColor(1, 1, 1, a)
	gfx.setFont(f)
	ui.frame(text, x + 4, y, w, h, "left", "center")
end

return TooltipView
