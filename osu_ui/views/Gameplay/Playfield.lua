local Component = require("ui.Component")

---@alias PlayfieldParams { configModel: sphere.ConfigModel, sequenceView: sphere.SequenceView }

---@class osu.ui.Playfield : ui.Component
---@overload fun(PlayfieldParams): osu.ui.Playfield
---@field configs table
---@field sequenceView sphere.SequenceView
---@field renderAtNativeResolution boolean
local Playfield = Component + {}

local native_res_w = 0
local native_res_h = 0
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
	if self.renderAtNativeResolution then
		self.canvas = love.graphics.newCanvas(self.width, self.height)
		native_res_w = self.width
		native_res_h = self.height
		self.draw = self.drawNative
	end
end

local gfx = love.graphics

function Playfield:drawNative()
	local prev_canvas = gfx.getCanvas()
	gfx.setCanvas(self.canvas)
	gfx.clear()
	gfx.setBlendMode("alpha", "alphamultiply")

	gfx.push("all")
	gfx.getDimensions = new_get_dimensions
	gfx.getWidth = new_get_width
	gfx.getHeight = new_get_height
	self.sequenceView:draw()
	gfx.getDimensions = base_get_dimensions
	gfx.getWidth = base_get_width
	gfx.getHeight = base_get_height
	gfx.pop()

	gfx.setCanvas(prev_canvas)

	gfx.origin()
	gfx.translate(self.x, self.y)
	gfx.draw(self.canvas)
end

function Playfield:draw()
	self.sequenceView:draw()
end

return Playfield
