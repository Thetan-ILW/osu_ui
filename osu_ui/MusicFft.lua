local EmptyComponent = require("ui.EmptyComponent")

local ffi = require("ffi")
local fft = require("aqua.bass.fft")

---@class osu.ui.MusicFft : ui.EmptyComponent
---@operator call: osu.ui.MusicFft
---@field customSource audio.Source?
local MusicFft = EmptyComponent + {}

local frame_aim_time = 1 / 60

function MusicFft:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.selectApi = scene.ui.selectApi

	self.sampleSize = 1024
	self.data = ffi.new("float[?]", self.sampleSize)
	self.fftFlag = fft.BASS_DATA_FFT2048

	self.decay = 0.95
	self.decayCutoff = 0.01

	self.beatValue = 0
	self.beatSmoothed = {} ---@type number[]
	self.beatPeaks = {} ---@type number[]

	for i = 1, 14 do
		table.insert(self.beatSmoothed, 0)
		table.insert(self.beatPeaks, 0)
	end
end

local SMOOTH_FACTOR = 0.05
local BEAT_DECAY = 0.7
local BEAT_THRESHOLD = 1.05

---@return number
function MusicFft:calcBeat()
	for i = 1, 14 do
		self.beatSmoothed[i] = self.beatSmoothed[i] + (self.data[i - 1] - self.beatSmoothed[i]) * SMOOTH_FACTOR
	end

	local total_energy = 0
	for i = 1, 14 do
		if self.beatSmoothed[i] > self.beatPeaks[i] then
			self.beatPeaks[i] = self.beatSmoothed[i]
		else
			self.beatPeaks[i] = self.beatPeaks[i] * BEAT_DECAY
		end

		if self.beatSmoothed[i] > self.beatPeaks[i] * BEAT_THRESHOLD then
			total_energy = total_energy + (self.beatSmoothed[i] - self.beatPeaks[i] * BEAT_THRESHOLD)
		end
	end

	self.beatValue = self.beatValue + total_energy * 0.08
	self.beatValue = self.beatValue * BEAT_DECAY
end

---@param dt number
function MusicFft:update(dt)
	---@type audio.Source?
	local audio

	if self.customSource then
		audio = self.customSource
	else
		audio = self.selectApi:getPreviewAudioSource()
	end

	self:calcBeat()

	if audio and audio.getFft then
		audio:getFft(self.data, self.fftFlag)
		return
	end

	local decay_factor = math.pow(self.decay, dt / frame_aim_time)

	for i = 0, self.sampleSize - 1 do
		if self.data[i] < self.decayCutoff then
			self.data[i] = 0
		else
			self.data[i] = self.data[i] * decay_factor
		end
	end
end

return MusicFft
