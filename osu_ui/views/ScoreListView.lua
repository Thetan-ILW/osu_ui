local Component = require("ui.Component")
local StencilComponent = require("ui.StencilComponent")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Image = require("ui.Image")

local ScoreEntryView = require("osu_ui.views.ScoreEntryView")
local Scoring = require("osu_ui.Scoring")

local getModifierString = require("osu_ui.views.modifier_string")
local math_util = require("math_util")
local flux = require("flux")

---@alias osu.ui.ScoreListViewParams { game: sphere.GameController }

---@class osu.ui.ScoreListView : ui.Component
---@overload fun(params: osu.ui.ScoreListViewParams): osu.ui.ScoreListView
---@field scores osu.ui.ScrollAreaContainer
---@field selectApi game.SelectAPI
---@field onOpenScore fun(index: integer)
---@field screen "select" | "result"
local ScoreListView = Component + {}

ScoreListView.panelHeight = 58
ScoreListView.panelSpacing = 53
ScoreListView.panelSlideInDelay = 0.08

function ScoreListView:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.scene = scene
	self.selectApi = scene.ui.selectApi
	self.playerProfile = scene.ui.pkgs.playerProfile

	local stencil_x = 0
	local stencil_y = 0
	local stencil_h = 0
	if self.screen == "select" then
		self.rows = 8
		self.recentIconSide = "right"
		stencil_x = 0
		stencil_y = -64
		stencil_h = self.height + 64
	elseif self.screen == "result" then
		self.rows = 5
		self.recentIconSide = "left"
		stencil_x = -200
		stencil_y = 0
		stencil_h = self.height
	else
		error("Not implemented")
	end

	self:addChild("noScores", Image({
		x = self.width / 2, y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		image = scene.assets:loadImage("selection-norecords"),
		alpha = 0
	}))

	local stencil = self:addChild("stencil", StencilComponent({
		stencilFunction = function ()
			love.graphics.rectangle("fill", stencil_x, stencil_y, self.width + 300, stencil_h)
		end
	}))

	local min_x = -80
	local max_x = self.height
	self.scores = stencil:addChild("scores", ScrollAreaContainer({
		width = self.width,
		height = self.height,
		drawChildren = function(this)
			love.graphics.translate(0, -this.scrollPosition)
			for i = #this.childrenOrder, 1, -1 do
				local child = this.children[this.childrenOrder[i]]
				if child.y > this.scrollPosition + min_x and child.y < this.scrollPosition + max_x then
					love.graphics.push("all")
					child:drawTree()
					love.graphics.pop()
				end
			end
		end
	}))
end

local function commaValue(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local grade_images = {
	SS = "ranking-X-small",
	S = "ranking-S-small",
	A = "ranking-A-small",
	B = "ranking-B-small",
	C = "ranking-C-small",
	D = "ranking-D-small"
}

---@param score_index integer
---@param score table
---@param source string
---@return boolean added
function ScoreListView:addProfileScore(score_index, score, source)
	local player_score = self.playerProfile:getScore(score.id)

	if not player_score then
		return false
	end

	local mods_line = getModifierString(score.modifiers)

	if score.rate ~= 1 and score.rate ~= 0 then
		mods_line = ("%s %0.02fx"):format(mods_line, score.rate)
	end

	---@type string
	local score_str = ("Score: %s (%ix)"):format(commaValue(math.floor(player_score.osuScore)), score.max_combo)

	local acc = 0
	local grade ---@type string
	if source == "osuv1" then
		acc = player_score.osuAccuracy
		grade = Scoring.getGrade("osuLegacy", acc)
	elseif source == "osuv2" then
		acc = player_score.osuv2Accuracy
		grade = Scoring.getGrade("osuMania", acc)
	elseif source == "etterna" then
		acc = player_score.etternaAccuracy
		grade = Scoring.getGrade("etterna", acc)
	elseif source == "quaver" then
		acc = player_score.quaverAccuracy
		grade = Scoring.getGrade("quaver", acc)
	end

	self.scores:addChild(tostring(score_index), ScoreEntryView({
		y = self.panelSpacing * (score_index - 1),
		rank = score_index,
		gradeImageName = grade_images[Scoring.convertGradeToOsu(grade)],
		username = "Player",
		score = score_str,
		accuracy = ("%0.02f%%"):format(acc * 100),
		mods = mods_line,
		improvement = "-",
		slideInDelay = self.panelSlideInDelay * (score_index - 1),
		z = 1 - (score_index * 0.0001),
		time = score.time,
		recentIconSide = self.recentIconSide,
		slide = self.screen == "select",
		onClick = function()
			self:openScore(score_index)
		end
	}))

	return true
end

---@param score_index integer
---@param score table
---@return boolean added
function ScoreListView:getSoundsphereScore(score_index, score)
	local mods_line = getModifierString(score.modifiers)

	if score.rate ~= 1 and score.rate ~= 0 then
		mods_line = ("%s,%0.02fx"):format(mods_line, score.rate)
	end

	local grade = grade_images.D

	local score_num = score.score
	if score_num > 9800 then
		grade = grade_images.SS
	elseif score_num > 8000 then
		grade = grade_images.S
	elseif score_num > 7000 then
		grade = grade_images.A
	elseif score_num > 6000 then
		grade = grade_images.B
	elseif score_num > 5000 then
		grade = grade_images.C
	end

	self.scores:addChild(tostring(score_index), ScoreEntryView({
		y = self.panelSpacing * (score_index - 1),
		rank = score_index,
		gradeImageName = grade,
		username = "Player",
		score = ("Score: %s (%ix)"):format(commaValue(math_util.round(score_num, 1)), score.max_combo),
		accuracy = ("%0.02fNS"):format(score.accuracy * 1000),
		mods = mods_line,
		improvement = "-",
		slideInDelay = self.panelSlideInDelay * (score_index - 1),
		z = 1 - (score_index * 0.0001),
		time = score.time,
		recentIconSide = self.recentIconSide,
		slide = self.screen == "select",
		onClick = function()
			self:openScore(score_index)
		end
	}))

	return true
end

function ScoreListView:update(dt)
	self:loadScores()
end

function ScoreListView:loadScores()
	local items = self.selectApi:getScores()
	if self.items == items then
		return
	end

	self.items = items

	local score_container = self.scores
	score_container.children = {}
	score_container.childrenOrder = {}
	score_container.scrollPosition = 0

	local source = self.selectApi:getScoreSource()

	local score_index = 1
	for _, score in ipairs(self.items) do
		local added = false
		if source == "local" or source == "online" then
			added = self:getSoundsphereScore(score_index, score)
		else
			added = self:addProfileScore(score_index, score, source)
		end

		if added then
			score_index = score_index + 1
		end
	end

	local prev_score_count = self.scoreCount
	self.scoreCount = score_index - 1

	if prev_score_count ~= self.scoreCount and self.screen == "select" then
		local no_scores_img = self.children.noScores
		if self.noScoresTween then
			self.noScoresTween:stop()
		end
		if self.scoreCount > 0 then
			self.noScoresTween = flux.to(no_scores_img, 0.5, { alpha = 0 }):ease("quadout")
		else
			self.noScoresTween = flux.to(no_scores_img, 0.5, { alpha = 1 }):ease("quadout")
		end
	end

	local h = self.panelHeight
	self.scores.scrollLimit = math.max(0, (self.scoreCount - self.rows) * h)
end

---@param id integer
function ScoreListView:openScore(id)
	self.onOpenScore(id)
end

return ScoreListView
