local msd_util = {}

local has_minacalc, etterna_msd = pcall(require, "libchart.libchart.etterna_msd")

---@param msd table<string, number>
function msd_util.getMaxAndSecondFromMsd(msd)
	local max_value = 0
	local second_value = 0
	local max_key = nil
	local second_key = nil

	for key, value in pairs(msd) do
		value = tonumber(value)
		if value > max_value and key ~= "overall" then
			max_value = value
			max_key = key
		end
	end

	local threshold = max_value * 0.93
	for key, value in pairs(msd) do
		value = tonumber(value)
		if value < max_value and value >= threshold and value > second_value and key ~= "overall" then
			second_value = tonumber(value)
			second_key = key
		end
	end

	local output = max_key
	if second_key then
		output = output .. "\n" .. second_key
	end

	return output
end

---@param msd table<string, number>
---@return string
function msd_util.getFirstFromMsd(msd)
	local max_key = "none"
	local max_value = 0

	for key, value in pairs(msd) do
		value = tonumber(value)
		if value > max_value and key ~= "overall" then
			max_value = value
			max_key = key
		end
	end

	return max_key
end

---@param pattern  string
---@return string
function msd_util.simplifySsr(pattern)
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

	return "NONE"
end

---@param msd_data string
---@return table<string, number>?
function msd_util.getMsdPatterns(msd_data)
	if not has_minacalc then
		return nil
	end

	---@type table?
	local ssr = etterna_msd:decode(msd_data)
	return ssr
end

---@return string[]
function msd_util.getSsrPatternNames()
	return etterna_msd.orderedSsr
end

---@param msd_data string
---@param time_rate number
---@return table<string, number>?
function msd_util.getMsdFromData(msd_data, time_rate)
	if not has_minacalc then
		return nil
	end

	---@type table?
	local msds = etterna_msd:decode(msd_data)

	if msds then
		return etterna_msd.getApproximate(msds, time_rate)
	end
end

return msd_util
