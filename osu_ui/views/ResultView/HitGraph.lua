local Component = require("ui.Component")
local CanvasComponent = require("ui.CanvasComponent")
local TimingValuesFactory = require("sea.chart.TimingValuesFactory")
local Label = require("ui.Label")
local Scoring = require("osu_ui.Scoring")

---@class osu.ui.HitGraph : ui.CanvasComponent
---@operator call: osu.ui.HitGraph
---@field score_engine sphere.ScoreEngine
---@field timings sea.Timings
---@field subtimings sea.Subtimings
local HitGraph = CanvasComponent + {}

function HitGraph:load()
	CanvasComponent.load(self)
	self.redrawEveryFrame = false

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager
	local timing_values = TimingValuesFactory():get(self.timings, self.subtimings)
	if not timing_values then
		return
	end

	local min = timing_values.ShortNote.hit[1]
	local max = timing_values.ShortNote.hit[2]

	if self.displayLabels then
		self:addChild("early", Label({
			x = 2, y = 2,
			font = fonts:loadFont("Regular", 12),
			text = ("Early(%ims)"):format(min * 1000),
			z = 1,
		}))

		self:addChild("late", Label({
			x = 2, y = -2,
			boxHeight = self.height,
			alignY = "bottom",
			font = fonts:loadFont("Regular", 12),
			text = ("Late(%ims)"):format(max * 1000),
			z = 1,
		}))
	end

	self:addChild("points", Component({
		draw = function()
			local sequence = self.score_engine.sequence
			local judges_source = self.score_engine.judgesSource
			---@cast judges_source -sphere.IJudgesSource, +sphere.ScoreSystem
			local max_time = sequence[#sequence].base.currentTime ---@type number
			local range = math.abs(min) + max
			local y_compress = 2
			local x_scale = (self.width - 2) / self.width
			local y_scale = (self.height - y_compress) / self.height

			for _, slice in ipairs(sequence) do
				local dt = slice.misc.deltaTime ---@type number
				local time = slice.base.currentTime ---@type number
				local judge = judges_source.judge_windows:get(dt)
				local x = (time / max_time) * self.width
				local y = ((math.abs(min) + dt) / range) * self.height
				local color = Scoring.judgeColors[self.timings.name][judge] or { 1, 0, 0, 1 }
				if slice.base.isMiss or slice.base.isEarlyMiss then
					color = { 1, 0, 0, 1 }
				end
				love.graphics.setColor(color)
				love.graphics.circle("fill", x * x_scale, y * y_scale + y_compress / 2, 1.5)
			end
		end
	}))
end

return HitGraph
