---@type number[]
local smoothed = {}
---@type number[]
local peaks = {}
local beat_value = 0

for i = 1, 14 do
	smoothed[i] = 0
	peaks[i] = 0
end

local SMOOTH_FACTOR = 0.15
local BEAT_DECAY = 0.6
local BEAT_THRESHOLD = 1.03

---@param fft ffi.cdata*
---@return number
return function(fft)
	for i = 1, 14 do
		smoothed[i] = smoothed[i] + (fft[i - 1 + 2] - smoothed[i]) * SMOOTH_FACTOR
	end

	local total_energy = 0
	for i = 1, 14 do
		if smoothed[i] > peaks[i] then
			peaks[i] = smoothed[i]
		else
			peaks[i] = peaks[i] * BEAT_DECAY
		end

		if smoothed[i] > peaks[i] * BEAT_THRESHOLD then
			total_energy = total_energy + (smoothed[i] - peaks[i] * BEAT_THRESHOLD)
		end
	end

	beat_value = beat_value + total_energy * 0.08
	beat_value = beat_value * BEAT_DECAY

	return beat_value
end
