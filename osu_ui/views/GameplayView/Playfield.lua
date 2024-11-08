local UiElement = require("osu_ui.ui.UiElement")

---@alias PlayfieldParams { configModel: sphere.ConfigModel, sequenceView: sphere.SequenceView }

---@class osu.ui.Playfield : osu.ui.UiElement
---@overload fun(PlayfieldParams): osu.ui.Playfield
---@field configs sphere.ConfigModel
---@field sequenceView sphere.SequenceView
local Playfield = UiElement + {}

local native_res_w = 0
local native_res_h = 0
local native_res_x = 0
local native_res_y = 0
local base_get_dimensions = love.graphics.getDimensions
local base_get_width = love.graphics.getWidth
local base_get_height = love.graphics.getHeight
local new_get_dimensions = function ()
	return native_res_w, native_res_h
end
local new_get_width = function ()
	return native_res_w
end
local new_get_height = function ()
	return native_res_h
end

function Playfield:load()
	local osu = self.configModel.configs.osu_ui
	self.renderAtNativeResolution = osu.gameplay.nativeRes

	self.draw = self.drawFull

	if self.renderAtNativeResolution then
		native_res_w, native_res_h = osu.gameplay.nativeResSize.width, osu.gameplay.nativeResSize.height
		native_res_x, native_res_y = osu.gameplay.nativeResX, osu.gameplay.nativeResY
		self.totalW  = native_res_w
		self.totalH = native_res_h
		self.canvas = love.graphics.newCanvas(self.totalW, self.totalH)
		self.draw = self.drawNative
	end

	UiElement.load(self)
end

function Playfield:update()
	self.x = (love.graphics.getWidth() - native_res_w) * native_res_x
	self.y = (love.graphics.getHeight() - native_res_h) * native_res_y
	self:applyTransform()
	return true
end

local gfx = love.graphics

function Playfield:drawNative()
	local prev_canvas = gfx.getCanvas()
	gfx.setCanvas(self.canvas)
	gfx.clear()
	gfx.setBlendMode("alpha", "alphamultiply")

	gfx.push()
	gfx.getDimensions = new_get_dimensions
	gfx.getWidth = new_get_width
	gfx.getHeight = new_get_height
	self.sequenceView:draw()
	gfx.getDimensions = base_get_dimensions
	gfx.getWidth = base_get_width
	gfx.getHeight = base_get_height
	gfx.pop()

	gfx.setCanvas(prev_canvas)
	gfx.setColor(1, 1, 1)
	local wh = gfx.getHeight()
	local _, iwh = gfx.inverseTransformPoint(0, wh)
	gfx.scale(iwh / self.totalH)
	gfx.draw(self.canvas)
end

function Playfield:drawFull()
	self.sequenceView:draw()
end

return Playfield
