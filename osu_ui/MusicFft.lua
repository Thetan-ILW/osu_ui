local EmptyComponent = require("ui.EmptyComponent")

local ffi = require("ffi")
local fft = require("aqua.bass.fft")
local beatValue = require("osu_ui.views.beat_value")

---@class osu.ui.MusicFft : ui.EmptyComponent
---@operator call: osu.ui.MusicFft
local MusicFft = EmptyComponent + {}

function MusicFft:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.selectApi = scene.ui.selectApi

	self.fft = ffi.new("float[?]", 1024)
	self.fftFlag = fft.BASS_DATA_FFT2048
	self.available = false

	self.beat = 0
end

local next_time = -math.huge

---@param dt number
function MusicFft:update(dt)
	if love.timer.getTime() < next_time then
		return
	end

	next_time = love.timer.getTime() + 0.012

	local audio = self.selectApi:getPreviewAudioSource()

	if not (audio and audio.getFft) then
		self.available = false
		return
	end

	audio:getFft(self.fft, self.fftFlag)
	self.beat = beatValue(self.fft)
	self.available = true
end

return MusicFft
