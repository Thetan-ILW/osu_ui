local UiElement = require("osu_ui.ui.UiElement")

---@alias HpGraphParams { totalW: number, totalH: number, points: table, hpScoreSystem: table }

---@class osu.ui.HpGraph : osu.ui.UiElement
---@overload fun(params: HpGraphParams): osu.ui.HpGraph
---@field points table
---@field hpScoreSystem table
local HpGraph = UiElement + {}

local colors = {
	green = { 0.6, 0.8, 0.2 },
	red = { 1, 0, 0 }
}

function HpGraph:load()
	local w = self.totalW
	local h = self.totalH
	local points = self.points
	local hp_score_system = self.hpScoreSystem

	local low_res = {}

	for i, v in ipairs(points) do
		table.insert(low_res, v)
	end

	while #low_res > 100 do
		for i = #low_res, 1, -2 do
			table.remove(low_res, i)
		end
	end

	local va = {}

	for _, v in ipairs(low_res) do
		local x = v.base.currentTime
		local y = 0

		local hp = v.hp
		for _, something in ipairs(hp) do
			if something.value > 0 then
				y = something.value / hp_score_system.max
				break
			end
		end

		table.insert(va, {
			x = x,
			y = y
		})
	end

	self.lines = {}

	local time1 = va[1].x
	local time2 = va[#va].x
	local ratio = w / (time2 - time1)

	for i = 1, #va, 1 do
		va[i].x = math.min((va[i].x - time1) * ratio, w)
		local ok = va[i].y > 0.5
		va[i].y = math.max((1 - va[i].y) * h, 0)

		if i > 1 then
			table.insert(self.lines, {
				p1 = va[i - 1],
				p2 = va[i],
				color = ok and "green" or "red"
			})
		end
	end

	UiElement.load(self)
end

local gfx = love.graphics

function HpGraph:draw()
	gfx.setLineWidth(4)
	gfx.setLineStyle("smooth")

	local first = self.lines[1]
	gfx.setColor(colors[first.color])
	gfx.circle("fill", first.p1.x, first.p1.y, 2)

	for _, v in ipairs(self.lines) do
		gfx.setColor(colors[v.color])
		gfx.circle("fill", v.p1.x, v.p1.y, 2)
		gfx.line(v.p1.x, v.p1.y, v.p2.x, v.p2.y)
		gfx.circle("fill", v.p2.x, v.p2.y, 2)
	end
end

return HpGraph
