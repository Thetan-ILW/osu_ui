local math_util = require("math_util")

local easing = {}

---@param time number
---@param interval number
function easing.linear(time, interval)
	local t = math.min(love.timer.getTime() - time, interval)
	local progress = t / interval
	return math_util.clamp(progress * progress, 0, 1)
end

---@param time number
---@param interval number
---@return number
function easing.outCubic(time, interval)
	local t = math.min(love.timer.getTime() - time, interval)
	local progress = t / interval
	return math_util.clamp(1 - math.pow(1 - progress, 3), 0, 1)
end

---@param time number,
---@param interval number
function easing.elasticOutHalf(time, interval)
	local t = math.min(love.timer.getTime() - time, interval)
	local a = (2 * math.pi) / 6
	if t == 0 or t == 1 then
		return t
	end
	return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * a) + 1
end

return easing
