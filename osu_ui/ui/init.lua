---@class osu.ui.utils
local ui = {}

function ui.lighten(c, amount)
	return {
		math.min(1, c[1] * (1 + amount)),
		math.min(1, c[2] * (1 + amount)),
		math.min(1, c[3] * (1 + amount)),
		c[4],
	}
end

---@param h number
---@param s number
---@param v number
---@return number[]
function ui.HSV(h, s, v)
	if s <= 0 then return { v, v, v, 1 } end
	h = h*6
	local c = v*s
	local x = (1-math.abs((h%2)-1))*c
	local m,r,g,b = (v-c), 0, 0, 0
	if h < 1 then
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	return { r+m, g+m, b+m, 1 }
end

---@param x number
---@return number
function ui.convertDiffToHue(x)
	if x <= 0.5 then
		return 0.5 - x
	elseif x <= 0.75 then
		return 1 - (x - 0.5) * (1 - 0.8) / 0.25
	else
		return 0.8
	end
end

return ui
