local Component = require("ui.Component")
local ScoreListView = require("osu_ui.views.ScoreListView")

---@class osu.ui.ResultScores : ui.Component
---@operator call: osu.ui.ResultScores
---@field onOpenScore fun(id: integer)
---@field scoresX number
local ResultScores = Component + {}

local scores_inactive_x = 510
local frame_aim_time = 1 / 60
local decay_factor_x_normal = 0.875

function ResultScores:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.clickSound = scene.assets:loadAudio("menuhit")

	self.scoreList = self:addChild("scoreList", ScoreListView({
		width = 385,
		height = 220,
		screen = "result",
		onOpenScore = function(id)
			self.playSound(self.clickSound)
			self.onOpenScore(id)
		end
	}))

	self.scoresX = self.scoresX or scores_inactive_x
end

function ResultScores:update(dt)
	local x_destination = self.mouseOver and 0 or scores_inactive_x
	local distance_x = x_destination - self.scoresX
	distance_x = distance_x * math.pow(decay_factor_x_normal, dt / frame_aim_time)
	self.scoresX = x_destination - distance_x
	self.scoreList.x = self.scoresX
end

return ResultScores
