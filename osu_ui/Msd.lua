local class = require("class")

local json = require("json")
local math_util = require("math_util")

---@alias osu.ui.Msd.Pattern "overall" | "stream" | "jumpstream" | "handstream" | "stamina" | "jackspeed" | "chordjack" | "technical"
---@alias osu.ui.Msd.KV [ osu.ui.Msd.Pattern, number ]

---@class osu.ui.Msd
---@operator call: osu.ui.Msd
---@field rates table<number, osu.ui.Msd.KV[]>
local Msd = class()

local MIN_RATE = 7
local MAX_RATE = 20
local PATTERN_ORDER = {
	"overall",
	"stream",
	"jumpstream",
	"handstream",
	"stamina",
	"jackspeed",
	"chordjack",
	"technical",
}

---@param encoded string
function Msd:new(encoded)
	---@type table<string, number>[]
	local decoded = json.decode(encoded)

	self.rates = {}

	for rate = MIN_RATE, MAX_RATE do
		self.rates[rate] = {}

		for i, pattern_name in ipairs(PATTERN_ORDER) do
			table.insert(self.rates[rate], {
				pattern_name, tonumber(decoded[rate - 6][i])
			})
		end
	end
end

---@param time_rate number
---@return osu.ui.Msd.KV[]
function Msd:getApproximate(time_rate)
	local floor = math_util.clamp(math.floor(time_rate * 10), MIN_RATE, MAX_RATE)
	local ceil = math_util.clamp(math.ceil(time_rate * 10), MIN_RATE, MAX_RATE)

	if floor == ceil then
		return self.rates[floor]
	end

	local lower = self.rates[floor]
	local upper = self.rates[ceil]

	---@type osu.ui.Msd.KV[]
	local t = {}

	for i, v in ipairs(lower) do
		local a = lower[i][2]
		local b = upper[i][2]
		table.insert(t, { v[1], (a + b) / 2 })
	end

	return t
end

---@param time_rate number
---@return osu.ui.Msd.KV[]
function Msd:getOrderedByPattern(time_rate)
	return self:getApproximate(time_rate)
end

---@param time_rate number
---@return osu.ui.Msd.KV[]
function Msd:getSorted(time_rate)
	local t = self:getApproximate(time_rate)
	table.sort(t, function(a, b)
		return a[2] > b[2]
	end)
	return t
end

---@param pattern osu.ui.Msd.Pattern
---@param time_rate number
---@return number
function Msd:get(pattern, time_rate)
	local t = self:getOrderedByPattern(time_rate)
	for _, v in ipairs(t) do
		if v[1] == pattern then
			return v[2]
		end
	end
	return -1
end

---@param pattern osu.ui.Msd.Pattern
---@param t osu.ui.Msd.KV[]
---@return number
function Msd.getFromTable(pattern, t)
	for _, v in ipairs(t) do
		if v[1] == pattern then
			return v[2]
		end
	end
	return -1
end

function Msd.getPatternName(pattern, key_mode)
	if pattern == "jumpstream" and key_mode ~= "4key" then
		return "chordstream"
	elseif pattern == "handstream" and key_mode ~= "4key" then
		return "bracket"
	end

	return pattern
end

---@param pattern  string
---@param key_mode string
---@return string
function Msd.simplifyName(pattern, key_mode)
	if key_mode == "4key" then
		if pattern == "stream" then
			return "STR"
		elseif pattern == "jumpstream" then
			return "JS"
		elseif pattern == "handstream" then
			return "HS"
		elseif pattern == "stamina" then
			return "STMN"
		elseif pattern == "jackspeed" then
			return "JACK"
		elseif pattern == "chordjack" then
			return "CJ"
		elseif pattern == "technical" then
			return "TECH"
		end
	else
		if pattern == "stream" then
			return "STR"
		elseif pattern == "jumpstream" then
			return "CHSTR"
		elseif pattern == "handstream" then
			return "BRKT"
		elseif pattern == "chordjack" then
			return "CJ"
		elseif pattern == "stamina" then
			return "STMN"
		elseif pattern == "jackspeed" then
			return "JACK"
		elseif pattern == "technical" then
			return "TECH"
		end
	end

	return "NONE"
end

return Msd
