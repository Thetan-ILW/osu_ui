local math_util = require("math_util")
local PointGraphView = require("sphere.views.GameplayView.PointGraphView")

local Scoring = require("osu_ui.views.ResultView.Scoring")

local HitGraph = {}

HitGraph.scoreSystemName = ""
HitGraph.judge = nil
HitGraph.counterNames = {}
HitGraph.showLoadedScore = nil
HitGraph.maxEarlyTiming = 0
HitGraph.maxLateTiming = 0

local hitGraphScale = 0.72

local function getPointY(y)
	local delta_time = y.misc.deltaTime

	delta_time = delta_time * 1000

	if delta_time > 0 then
		delta_time = (delta_time / HitGraph.maxLateTiming) / 1000
	else
		delta_time = (delta_time / HitGraph.maxEarlyTiming) / 1000
	end

	return math_util.clamp((delta_time * hitGraphScale) + 0.5, -1, 0.98)
end

local function getHitColor(delta_time, is_miss)
	if is_miss then
		return { 1, 0, 0, 1 }
	end

	if not HitGraph.judge.windows then
		return { 1, 1, 1, 1 }
	end

	local colors = Scoring.counterColors[HitGraph.scoreSystemName]

	delta_time = math.abs(delta_time)

	if HitGraph.scoreSystemName == "etterna" then -- this is bad, don't forget to refactor score systems PLEASE
		delta_time = delta_time * 1000
	end

	for _, key in ipairs(HitGraph.counterNames) do
		local window = HitGraph.judge.windows[key]

		if delta_time < window then
			return colors[key]
		end
	end

	return { 1, 0, 0, 1 }
end

local pointR = 3
local padding = 5
---@param self table
local function drawGraph(self, w, h)
	love.graphics.translate(pointR + padding, pointR)
	self.__index.draw(self, w - pointR - (padding * 2), h - pointR)
	love.graphics.translate(-pointR - padding, -pointR)
end

HitGraph.hitGraph = PointGraphView({
	draw = drawGraph,
	radius = pointR,
	backgroundColor = { 0, 0, 0, 0.2 },
	backgroundRadius = 6,
	point = function(self, point)
		if point.base.isMiss then
			return
		end
		local y = getPointY(point)
		local color = getHitColor(point.misc.deltaTime, false)
		return y, unpack(color)
	end,
	show = HitGraph.showLoadedScore,
})

HitGraph.earlyHitGraph = PointGraphView({
	draw = drawGraph,
	radius = pointR,
	backgroundColor = { 0, 0, 0, 1 },
	backgroundRadius = 0,
	point = function(self, point)
		if not point.base.isEarlyHit then
			return
		end
		local y = getPointY(point)
		return y, unpack(getHitColor(0, true))
	end,
	show = HitGraph.showLoadedScore,
})

HitGraph.missGraph = PointGraphView({
	draw = drawGraph,
	radius = pointR,
	backgroundColor = { 0, 0, 0, 1 },
	backgroundRadius = 0,
	point = function(self, point)
		if not point.base.isMiss then
			return
		end
		local y = getPointY(point)
		return y, unpack(getHitColor(0, true))
	end,
	show = HitGraph.showLoadedScore,
})

HitGraph.hpGraph = PointGraphView({
	draw = drawGraph,
	radius = 6,
	backgroundColor = { 0, 0, 0, 0.2 },
	backgroundRadius = 0,
	point = function(self, point)
		local value = 0
		local _hp = self.game.rhythmModel.scoreEngine.scoreSystem.hp
		local hp = point.hp
		for _, h in ipairs(hp) do
			if h.value > 0 then
				value = h.value / _hp.max
				break
			end
		end

		if value < 0.45 then
			return 1 - value, 0.76, 0, 0, 1
		end
		return 1 - value, 0.25, 0.8, 0.5, 1
	end,
	show = HitGraph.showLoadedScore,
})

return HitGraph
