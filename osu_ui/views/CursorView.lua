local Component = require("ui.Component")

---@alias CursorViewParams { assets: osu.ui.OsuAssets, osuConfig: osu.ui.OsuConfig }

---@class osu.ui.CursorView : ui.Component
---@overload fun(CursorViewParams): osu.ui.CursorView
---@field assets osu.ui.OsuAssets
---@field osuConfig osu.ui.OsuConfig
---@field cursorImage love.Image
---@field cursorMiddleImage love.Image
---@field cursorTrailImage love.Image
local CursorView = Component + {}

function CursorView:load()
	self.alpha = 1
	self.config = self.osuConfig.cursor

	local assets = self.shared.assets
	self.params = assets.params
	self.cursorImage = assets:loadImage("cursor")
	self.cursorMiddleImage = assets:loadImage("cursormiddle")
	self.cursorTrailImage = assets:loadImage("cursortrail")

	self.lastX, self.lastY = love.mouse.getPosition()
	self:updateSpriteBatch()
end

function CursorView:updateSpriteBatch()
	self.trailImageCount = self.config.trailMaxImages
	self.trailSpriteBatch = love.graphics.newSpriteBatch(self.cursorTrailImage)

	self.trailIndex = 1
	self.trailData = {}

	for i = 1, self.config.trailMaxImages do
		self.trailSpriteBatch:add(-9999, -9999)
		self.trailData[i] = { x = 0, y = 0, alpha = 0 }
	end
end

local cursor_scale = 1
local cursor_rotation = 0

function CursorView:update(dt)
	if self.params.cursorRotate then
		cursor_rotation = (cursor_rotation + 1.5 * dt) % (math.pi * 2)
	end

	if self.params.cursorExpand then
		local add = love.mouse.isDown(1) and dt or -dt
		cursor_scale = math.min(cursor_scale + add * 3, 1.25)
		cursor_scale = math.max(cursor_scale, 1)
	end

	if self.alpha == 0 or not self.config.showTrail then
		return
	end

	local cfg = self.config
	local size = cfg.size

	local trail = self.cursorTrailImage
	local tw, th = trail:getDimensions()
	local txo, tyo = tw / 2, th / 2

	local mx, my = love.mouse.getPosition()

	local dx, dy = mx - self.lastX, my - self.lastY
	local distance = math.sqrt(dx * dx + dy * dy)

	local min_distance = 31 - cfg.trailDensity
	local max_trail_images = cfg.trailMaxImages

	if distance >= min_distance then
		local steps = math.ceil(distance / min_distance)
		local step_x, step_y = dx / steps, dy / steps

		for i = 1, steps do
			local x = self.lastX + step_x * i
			local y = self.lastY + step_y * i
			local data = self.trailData[self.trailIndex]
			data.x = x
			data.y = y
			data.alpha = 1

			self.trailSpriteBatch:set(self.trailIndex, x, y, 0, size, size, txo, tyo)
			self.trailIndex = 1 + self.trailIndex % max_trail_images
		end

		self.lastX, self.lastY = mx, my
	end

	for i = 1, max_trail_images do
		local data = self.trailData[i]
		local age = (self.trailIndex - i - 1 + max_trail_images) % max_trail_images
		local alpha = math.max(0, 1 - age / max_trail_images)

		if self.config.trailStyle == "Vanishing" then
			self.trailSpriteBatch:setColor(1, 1, 1, alpha * data.alpha)
			self.trailSpriteBatch:set(i, data.x, data.y, 0, size, size, txo, tyo)
		else
			self.trailSpriteBatch:setColor(1, 1, 1, alpha)
			self.trailSpriteBatch:set(i, data.x, data.y, 0, data.alpha * size, data.alpha * size, txo, tyo)
		end

		data.alpha = math.max(0, data.alpha - dt * (11 - cfg.trailLifetime))
	end
end

local gfx = love.graphics

function CursorView:draw()
	if self.alpha == 0 then
		return
	end

	gfx.origin()
	gfx.setColor(1, 1, 1, self.alpha)

	local x, y = love.mouse.getPosition()

	local cursor = self.cursorImage
	local middle = self.cursorMiddleImage
	local cw, ch = cursor:getDimensions()
	local mw, mh = middle:getDimensions()

	local cxo, cyo = cw / 2, ch / 2
	local mxo, myo = mw / 2, mh / 2

	local cx, cy = 0, 0

	if self.params.cursorCenter == 0 then
		cx, cy = cxo, cyo
		mxo, myo = 0, 0
	end

	if self.config.showTrail then
		gfx.setBlendMode("add")
		gfx.draw(self.trailSpriteBatch)
		gfx.setBlendMode("alpha")
	end

	local s = cursor_scale * self.config.size
	gfx.draw(middle, x, y, 0, 1, 1, mxo, myo)
	gfx.draw(cursor, cx + x, cy + y, cursor_rotation, s, s, cxo, cyo)
end

return CursorView
