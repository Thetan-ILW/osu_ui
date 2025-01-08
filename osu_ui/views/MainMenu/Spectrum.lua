local Component = require("ui.Component")

local beatValue = require("osu_ui.views.beat_value")

---@class osu.ui.Spectrum : ui.Component
---@operator call: osu.ui.Spectrum
---@field emptyFft number[]
---@field smoothedFft number[]
---@field audio audio.Source?
local Spectrum = Component + {}

local radius = 253
local smoothing_factor = 0.2
local fft_size = 64
local repeats = 4
local bars = fft_size * repeats

function Spectrum:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local img = scene.assets:loadImage("menu-vis")

	self.spriteBatch = love.graphics.newSpriteBatch(img)
	self.rotation = 0
	self.smoothedFft = {}
	self.emptyFft = {}
	self.emptyFft[0] = 0

	for _ = 1, bars do
		self.spriteBatch:add(0, 0)
	end

	for i = 1, 64 do
		self.smoothedFft[i] = 0
		self.emptyFft[i] = 0
	end

	self.barWidth, self.barHeight = img:getDimensions()
end

local next_time = -math.huge

function Spectrum:update(dt)
	if love.timer.getTime() < next_time then
		return
	end

	next_time = love.timer.getTime() + 0.012

	local audio = self.audio
	local bar_h = self.barHeight

	local current_fft = (audio and audio.getFft) and audio:getFft() or self.emptyFft
	local beat = beatValue(current_fft)
	local smoothed_fft = self.smoothedFft

	local rotation = self.rotation + (beat * 100) * dt
	self.rotation = rotation

	for i = 1, fft_size do
		smoothed_fft[i] = smoothed_fft[i] * (1 - smoothing_factor)
		smoothed_fft[i] = smoothed_fft[i] + current_fft[(i - math.floor(rotation * 70)) % fft_size] * smoothing_factor * 2

		for r = 0, repeats - 1 do
			local angle = (r * fft_size + i - 1) * (2 * math.pi / bars)
			local x = radius * math.cos(angle)
			local y = radius * math.sin(angle)
			self.spriteBatch:set(r * fft_size + i, x, y, angle, smoothed_fft[i], 0.5, 0, bar_h)
		end
	end
end

function Spectrum:draw()
	love.graphics.draw(self.spriteBatch)
end


return Spectrum
