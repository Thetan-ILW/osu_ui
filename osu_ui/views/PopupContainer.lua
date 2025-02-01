local Component = require("ui.Component")
local QuadImage =  require("ui.QuadImage")
local Label = require("ui.Label")
local easing = require("osu_ui.ui.easing")
local math_util = require("math_util")

---@class osu.ui.PopupContainer : ui.Component
---@operator call: osu.ui.PopupContainer
local PopupContainer = Component + {}

PopupContainer.colors = {
	error = { 1, 0, 0, 1 },
	purple = { 0.51, 0.31, 0.8, 1 },
	green = { 0, 1, 0, 1 },
	orange = { 0.57, 0.32, 0, 1}
}

function PopupContainer:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	self.fonts = scene.fontManager

	self:getViewport():listenForResize(self)

	---@type osu.ui.PopupContainer.Popup[]
	self.list = {}
	self.index = 0
	self.image = assets:loadImage("notification")
	self.lastPopupAdditionTime = -9999

	local iw, ih = self.image:getDimensions()

	self.topQuad = love.graphics.newQuad(0, 0, iw, 13, iw, ih)
	self.middleQuad = love.graphics.newQuad(0, 13, iw, 13, iw, ih)
	self.bottomQuad = love.graphics.newQuad(0, 13 + 13, iw, 30, iw, ih)
end

---@param text string
---@param color_name string
---@param on_click function?
function PopupContainer:add(text, color_name, on_click)
	if not self.colors[color_name] then
		self:error(("No such color: `%s`"):format(color_name))
	end

	---@class osu.ui.PopupContainer.Popup : ui.Component
	---@field spawnTime number
	---@field targetY number
	local c = self:addChild(tostring(self.index), Component({
		x = self.parent:getWidth(),
		y = self.parent:getHeight() - 28,
		origin = { x = 1, y = 1 },
		spawnTime = love.timer.getTime(),
		targetY = self.parent:getHeight() - 28,
		blockMouseFocus = true,
		mouseClick = function(this)
			if not this.mouseOver then
				return false
			end
			if on_click then
				on_click()
			end
			return true
		end
	}))
	self.index = self.index + 1

	local label = c:addChild("label", Label({
		x = 9, y = 9,
		boxWidth = 225,
		font = self.fonts:loadFont("Regular", 13),
		text = text,
		z = 1,
	}))
	local middle_scale = math.max(1, label:getHeight() / 20)

	local color = self.colors[color_name]
	c:addChild("top", QuadImage({
		image = self.image,
		quad = self.topQuad,
		color = color,
	}))

	c:addChild("middle", QuadImage({
		y = 13,
		image = self.image,
		scaleY = middle_scale,
		quad = self.middleQuad,
		color = color,
	}))

	c:addChild("bottom", QuadImage({
		y = 13 + (13 * middle_scale),
		image = self.image,
		quad = self.bottomQuad,
		color = color,
	}))

	c:autoSize()

	for _, v in ipairs(self.list) do
		v.targetY = v.targetY - c:getHeight()
	end

	table.insert(self.list, c)
	self.lastPopupAdditionTime = love.timer.getTime()
end

local frame_aim_time = 1 / 60

function PopupContainer:update(dt)
	local sw = self.parent:getWidth()

	local clear_list = #self.list ~= 0

	for _, c in ipairs(self.list) do
		if c.y < 0 then
			c.disabled = true
		else
			c.x = sw + (300 * (1 - easing.elasticOutHalf(c.spawnTime, 0.8)))

			local d = c.targetY - c.y
			d = d * math.pow(0.7, dt / frame_aim_time)
			c.y = c.targetY - d

			c.alpha = math_util.clamp((c.spawnTime + 5) - love.timer.getTime(), 0, 1)

			if c.alpha > 0 then
				clear_list = false
			end
		end
	end

	if clear_list then
		self.list = {}
	end
end

return PopupContainer
