local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local ScoreEntryView = require("osu_ui.views.SelectView.ScoreEntryView")
local Scoring = require("osu_ui.Scoring")

local getModifierString = require("osu_ui.views.modifier_string")
local math_util = require("math_util")
local flux = require("flux")

---@alias ScoreListViewParams { game: sphere.GameController }

---@class osu.ui.ScoreListView : osu.ui.ScrollAreaContainer
---@overload fun(params: ScoreListViewParams): osu.ui.ScoreListView
---@field assets osu.ui.OsuAssets
local ScoreListView = ScrollAreaContainer + {}

ScoreListView.panelHeight = 58
ScoreListView.panelSpacing = 53
ScoreListView.panelSlideInDelay = 0.08

function ScoreListView:load()
	ScrollAreaContainer.load(self)
	self.recentScoreIcon = self.assets:awesomeIcon("", 24)
	self.noScoresImage = self.assets:loadImage("selection-norecords")
	self.noScoresAlpha = 0
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
		mods_line = ("%s,%0.02fx"):format(mods_line, score.rate)
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

	self:addChild(tostring(score_index), ScoreEntryView({
		id = score.id,
		y = self.panelSpacing * (score_index - 1),
		rank = score_index,
		assets = self.assets,
		gradeImageName = grade_images[Scoring.convertGradeToOsu(grade)],
		username = "Player",
		score = score_str,
		accuracy = ("%0.02f%%"):format(acc * 100),
		mods = mods_line,
		improvement = "-",
		slideInDelay = self.panelSlideInDelay * (score_index - 1),
		depth = 1 - (score_index * 0.0001),
		recentScoreIcon = self.recentScoreIcon,
		time = score.time
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

	self:addChild(tostring(score_index), ScoreEntryView({
		id = score.id,
		y = self.panelSpacing * (score_index - 1),
		rank = score_index,
		assets = self.assets,
		gradeImageName = grade,
		username = "Player",
		score = ("Score: %s (%ix)"):format(commaValue(math_util.round(score_num, 1)), score.max_combo),
		accuracy = ("%0.02fNS"):format(score.accuracy * 100),
		mods = mods_line,
		improvement = "-",
		slideInDelay = self.panelSlideInDelay * (score_index - 1),
		depth = 1 - (score_index * 0.0001),
		recentScoreIcon = self.recentScoreIcon,
		time = score.time
	}))

	return true
end

function ScoreListView:update(dt, mouse_focus)
	self:loadScores()
	return ScrollAreaContainer.update(self, dt, mouse_focus)
end

function ScoreListView:loadScores()
	if self.scores == self.game.selectModel.scoreLibrary.items then
		return
	end

	self.scores = self.game.selectModel.scoreLibrary.items
	self.children = {}
	self.childrenOrder = {}
	self.scrollPosition = 0

	local source = self.game.configModel.configs.osu_ui.songSelect.scoreSource

	local score_index = 1
	for _, score in ipairs(self.scores) do
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

	if prev_score_count ~= self.scoreCount then
		if self.noScoresTween then
			self.noScoresTween:stop()
		end
		if self.scoreCount > 0 then
			self.noScoresTween = flux.to(self, 0.5, { noScoresAlpha = 0 }):ease("quadout")
		else
			self.noScoresTween = flux.to(self, 0.5, { noScoresAlpha = 1 }):ease("quadout")
		end
	end

	local h = self.panelHeight
	self.scrollLimit = math.max(0, (self.scoreCount - 8) * h)

	self:build()
end

function ScoreListView:openScore(id)
	self.game.selectModel:scrollScore(nil, id)
	self.game.ui.selectView:result()
end

local gfx = love.graphics

function ScoreListView:draw()
	if self.noScoresAlpha then
		local iw, ih = self.noScoresImage:getDimensions()
		gfx.setColor(1, 1, 1, self.alpha * self.noScoresAlpha)
		gfx.draw(self.noScoresImage, self.totalW / 2, self.totalH / 2, 0, 1, 1, iw / 2, ih / 2)
	end

	if self.scoreCount == 0 or not self.scoreCount then
		return
	end

	local first = math_util.clamp(math.floor(self.scrollPosition / self.panelHeight), 0, self.scoreCount)

	gfx.stencil(function ()
		gfx.rectangle("fill", 0, -64, self.totalW, self.totalH + 64)
	end, "replace", 1)

	gfx.setStencilTest("greater", 0)

	gfx.translate(0, -self.scrollPosition)
	for i = first + 1, self.scoreCount do
		local child = self.children[self.childrenOrder[i]]
		if child.y > self.scrollPosition + self.panelHeight * 8 then
			break
		end
		gfx.push()
		gfx.applyTransform(child.transform)
		child:draw()
		gfx.pop()
	end

	gfx.setStencilTest()
end

return ScoreListView
