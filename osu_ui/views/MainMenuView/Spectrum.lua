local Component = require("ui.Component")

local beatValue = require("osu_ui.views.beat_value")

local Spectrum = Component + {}

local smoothing_factor = 0.2
local radius = 253
local bars = 256
local repeats = 4

function Spectrum:load()
	local img = self.shared.assets:loadImage("menu-vis")
	self.spriteBatch = love.graphics.newSpriteBatch(img)
	self.rotation = 0
	self.smoothedFft = {}
	self.emptyFft = {}
	self.emptyFft[0] = 0

	for _ = 1, bars do
		self.spriteBatch:add()
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
	local r_bars = bars / repeats
	local smoothed_fft = self.smoothedFft

	local rotation = self.rotation + (beat * 100) * dt
	self.rotation = rotation

	for i = 1, 64 do
		smoothed_fft[i] = smoothed_fft[i] * (1 - smoothing_factor)
		smoothed_fft[i] = smoothed_fft[i] + current_fft[(i - math.floor(rotation * 70)) % 64] * smoothing_factor * 2

		for r = 0, repeats - 1 do
			local angle = (r * r_bars + i - 1) * (2 * math.pi / bars)
			local x = radius * math.cos(angle)
			local y = radius * math.sin(angle)
			self.spriteBatch:set(r * r_bars + i, x, y, angle, smoothed_fft[i], 0.5, 0, bar_h)
		end
	end
end

function Spectrum:draw()
	love.graphics.draw(self.spriteBatch)
end


return Spectrum
