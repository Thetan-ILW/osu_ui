local ListView = require("osu_ui.views.ListView")
local ui = require("osu_ui.ui")
local math_util = require("math_util")
local time_util = require("time_util")

local getModifierString = require("osu_ui.views.modifier_string")

---@type table<string, string>
local text

local ScoreListView = ListView + {}

ScoreListView.rows = 8
ScoreListView.selectedScoreIndex = 1
ScoreListView.selectedScore = nil
ScoreListView.openResult = false
ScoreListView.oneClickOpen = true
ScoreListView.modLines = {}
ScoreListView.focus = false
---@type number[]
ScoreListView.animations = {}
ScoreListView.scoreUpdateTime = -math.huge

---@param game sphere.GameController
---@param assets osu.OsuAssets
function ScoreListView:new(game, assets)
	self.game = game
	self.assets = assets
	self.playerProfile = self.game.ui.playerProfile

	text, self.font = assets.localization:get("scoreList")
	assert(text and self.font)
end

function ScoreListView:getTooltip(score, mod_line)
	if mod_line == "" then
		mod_line = "No mods"
	end

	local judges = ("Perfect:%i NotPerfect:%i Miss:%i"):format(score["perfect"], score["not_perfect"], score["miss"])
	return text.tooltip:format(
		os.date("%d/%m/%Y %H:%M:%S.", score.time),
		judges,
		score.accuracy,
		mod_line
	)
end

local function commaValue(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function ScoreListView:getProfileScore(score)
	local player_score = self.playerProfile:getScore(score.id)

	if not player_score then
		return
	end

	local mods_line = getModifierString(score.modifiers)
	local tooltip = self:getTooltip(score, mods_line)

	if score.rate ~= 1 and score.rate ~= 0 then
		mods_line = ("%s [%0.02fx]"):format(mods_line, score.rate)
	end

	local img = self.assets.images
	local grade = img.smallGradeD

	local acc = player_score.osuAccuracy
	if acc == 1 then
		grade = img.smallGradeX
	elseif acc >= 0.95 then
		grade = img.smallGradeS
	elseif acc >= 0.9 then
		grade = img.smallGradeA
	elseif acc >= 0.8 then
		grade = img.smallGradeB
	elseif acc >= 0.7 then
		grade = img.smallGradeC
	end

	return {
		scoreNum = player_score.osuScore,
		secondRow = ("Score: %s (%ix)"):format(commaValue(math.floor(player_score.osuScore)), score.max_combo),
		accuracy = ("%0.02f%%"):format(player_score.osuAccuracy * 100),
		modsRow = mods_line,
		tooltip = tooltip,
		time = score.time,
		timeSince = 0,
		gradeImg = grade
	}
end

function ScoreListView:getSoundsphereScore(score)
	local mods_line = getModifierString(score.modifiers)
	local tooltip = self:getTooltip(score, mods_line)

	if score.rate ~= 1 and score.rate ~= 0 then
		mods_line = ("%s [%0.02fx]"):format(mods_line, score.rate)
	end

	local img = self.assets.images
	local grade = img.smallGradeD

	local score_num = score.score
	if score_num > 9800 then
		grade = img.smallGradeX
	elseif score_num > 8000 then
		grade = img.smallGradeS
	elseif score_num > 7000 then
		grade = img.smallGradeA
	elseif score_num > 6000 then
		grade = img.smallGradeB
	elseif score_num > 5000 then
		grade = img.smallGradeC
	end

	return {
		scoreNum = score_num,
		secondRow = ("Score: %i (%ix)"):format(score_num, score.max_combo),
		accuracy = ("%0.02f%%"):format(score.accuracy * 1000),
		modsRow = mods_line,
		tooltip = tooltip,
		time = score.time,
		timeSince = 0,
		gradeImg = grade,
		username = score.user and score.user.name or "You"
	}
end

function ScoreListView:reloadItems()
	self.stateCounter = self.game.selectModel.scoreStateCounter

	if self.scores == self.game.selectModel.scoreLibrary.items then
		return
	end

	self.scores = self.game.selectModel.scoreLibrary.items
	self.items = {}

	local score_source = "local"

	for i, score in ipairs(self.scores) do
		local item

		if score_source == "local" then
			item = self:getSoundsphereScore(score)
		elseif score_source == "profile" then
			item = self:getProfileScore(score)
		end

		if item then
			table.insert(self.items, item)
		end
	end

	self.updateTime = love.timer.getTime()
	self.nextTimeUpdateTime = -1
	self:updateTimeSinceScore()

	local i = self.game.selectModel.scoreItemIndex
	self.selectedScoreIndex = i
	self.selectedScore = self.items[i]
	self.game.selectModel:scrollScore(nil, 1)
	self.targetItemIndex = 1
end

function ScoreListView:scrollScore(delta)
	local i = self.selectedScoreIndex + delta
	local score = self.items[i]

	if not score then
		return
	end

	self:scroll(delta)
	self.selectedScore = score
	self.selectedScoreIndex = i
	self.game.selectModel:scrollScore(nil, i)
	self.openResult = true
end

local panel_w = 378

function ScoreListView:mouseClick(w, h, i)
	if not self.focus then
		return
	end

	if ui.isOver(panel_w, h, 0, 0) then
		if ui.mousePressed(1) then
			if self.selectedScoreIndex == i then
				self.openResult = true
				return
			end

			self.selectedScoreIndex = i
			self.selectedScore = self.items[i]
			self.game.selectModel:scrollScore(nil, i)

			if self.oneClickOpen then
				self.openResult = true
				return
			end
		end
	end
end

function ScoreListView:input(w, h)
	if not self.focus then
		return
	end
	local delta = ui.wheelOver(self, ui.isOver(panel_w, h))
	if delta then
		self:scroll(-delta)
		return
	end
end

local gfx = love.graphics

function ScoreListView:updateAnimations()
	for i, v in pairs(self.animations) do
		v = v - 0.009

		self.animations[i] = v

		if v < 0 then
			self.animations[i] = 0
		end
	end
end

---@param time {[string]: number}
---@return string?
local function formatTime(time)
	local days = time.days
	local hours = time.hours
	local minutes = time.minutes
	local seconds = time.seconds

	if days then
		if days > 3 then
			return
		end
		return ("%id"):format(days)
	elseif hours then
		return ("%ih"):format(hours)
	elseif minutes then
		return ("%im"):format(minutes)
	elseif seconds then
		return ("%is"):format(seconds)
	end
end

function ScoreListView:updateTimeSinceScore()
	local current_time = love.timer.getTime()
	if current_time < self.nextTimeUpdateTime then
		return
	end

	self.nextTimeUpdateTime = current_time + 1
	self.timeUpdateTime = love.timer.getTime()
	for i, score in ipairs(self.items) do
		local time = time_util.date_diff(os.time(), score.time)
		score.timeSince = formatTime(time)
	end
end

---@param i number
---@param w number
---@param h number
function ScoreListView:drawItem(i, w, h)
	local img = self.assets.images
	local item = self.items[i]

	local username = item.username
	local avatar = img.avatar

	username = ("#%i %s"):format(i, username)

	local a = self.animations[i] or 0

	if ui.isOver(panel_w, h) and self.focus then
		self.animations[i] = math_util.clamp(a + 0.05, 0, 0.5)
		ui.tooltip = item.tooltip
	end

	local background_color = { 0 + a * 0.5, 0 + a * 0.5, 0 + a * 0.5, 0.3 + a * 0.2 }

	gfx.translate((1 - ui.easeOutCubic(self.scoreUpdateTime, 0.3 + (i / 16))) * -w, 0)

	gfx.setColor(background_color)
	gfx.rectangle("fill", 0, 0, panel_w, 50)

	gfx.setColor(1, 1, 1, 1)
	if avatar then
		local ih = avatar:getHeight()
		local s = (h - 6) / ih
		gfx.draw(avatar, 2, 2, 0, s, s)
	end

	gfx.push()

	local grade = item.gradeImg

	gfx.push()
	gfx.translate(-grade:getWidth() / 2 + 67, h / 2 - (grade:getHeight() / 2) - 1)
	gfx.draw(grade)
	gfx.pop()

	gfx.translate(94, 0)
	gfx.setFont(self.font.username)
	ui.textWithShadow(username)
	gfx.setFont(self.font.score)
	ui.textWithShadow(item.secondRow)
	gfx.pop()

	gfx.setFont(self.font.rightSide)
	ui.frameWithShadow(item.modsRow, -4, 0, panel_w, 50, "right", "top")
	ui.frameWithShadow(item.accuracy, -4, 0, panel_w, 50, "right", "center")

	local improvement = "-"

	if self.items[i + 1] then
		---@type number
		local difference = item.scoreNum - self.items[i + 1].scoreNum

		if difference > 0 then
			improvement = ("+%i"):format(difference)
		end
	end

	ui.frameWithShadow(improvement, -4, 0, panel_w, 50, "right", "bottom")

	local time_since = item.timeSince
	if time_since then
		gfx.translate(panel_w + 16, 0)
		local icon = self.assets.images.recentScore
		local iw, ih = icon:getDimensions()
		gfx.setColor(1, 1, 1)
		gfx.draw(self.assets.images.recentScore, 0, h / 2, 0, 1, 1, iw / 2, ih / 2)
		ui.frameWithShadow(time_since, 16, 0, 100, h, "left", "center")
	end
end

return ScoreListView
