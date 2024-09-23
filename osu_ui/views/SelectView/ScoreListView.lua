local ListView = require("osu_ui.views.ListView")
local ui = require("osu_ui.ui")
local math_util = require("math_util")
local time_util = require("time_util")

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

	text, self.font = assets.localization:get("scoreList")
	assert(text and self.font)
end

local modOrder = {
	{ id = 19, label = "FLN%i", format = true },
	{ id = 9, label = "NLN" },
	{ id = 20, label = "MLL%0.01f", format = true },
	{ id = 23, label = "LC%i", format = true },
	{ id = 24, label = "CH%i", format = true },
	{ id = 18, label = "BS" },
	{ id = 17, label = "RND" },
	{ id = 16, label = "MR" },
	{ id = 11, label = "AM%i", format = true },
	{ id = 11, label = "ALT" },
}

function ScoreListView:getModifiers(modifiers)
	if type(modifiers) == "string" then
		return ""
	end

	if #modifiers == 0 then
		return ""
	end

	local max = 3
	local current = 0
	local modLine = ""

	for _, mod in ipairs(modOrder) do
		for _, enabledMod in ipairs(modifiers) do
			if mod.id == enabledMod.id then
				if mod.format and type(enabledMod.value) == "number" then
					modLine = modLine .. mod.label:format(enabledMod.value)
				elseif mod.format and type(enabledMod.value) == "string" then
					modLine = modLine .. mod.label:format(0)
				else
					modLine = modLine .. mod.label
				end

				modLine = modLine .. " "

				current = current + 1

				if current == max then
					return modLine
				end
			end
		end
	end

	if modLine:len() == 0 then
		modLine = text.hasMods
	end

	return modLine
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

function ScoreListView:reloadItems()
	self.stateCounter = self.game.selectModel.scoreStateCounter

	if self.items == self.game.selectModel.scoreLibrary.items then
		return
	end

	self.items = self.game.selectModel.scoreLibrary.items
	self.modLines = {}
	self.timeFormatted = {}
	self.tooltips = {}
	self.nextTimeUpdateTime = -1
	self:updateTimeSinceScore()

	for i, item in ipairs(self.items) do
		local mod_line = self:getModifiers(item.modifiers)
		self.modLines[i] = mod_line
		self.tooltips[i] = self:getTooltip(item, mod_line)
	end

	local i = self.game.selectModel.scoreItemIndex
	self.selectedScoreIndex = i
	self.selectedScore = self.items[i]
	self.game.selectModel:scrollScore(nil, i)
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
		if days > 4 then
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
		self.timeFormatted[i] = formatTime(time)
	end
end



---@param i number
---@param w number
---@param h number
function ScoreListView:drawItem(i, w, h)
	local img = self.assets.images
	local item = self.items[i]

	local source = self.game.configModel.configs.select.scoreSourceName
	local mods = self.modLines[i]
	local username = "You"
	local avatar = img.avatar

	if source == "online" then
		if not item.user then
			return
		end

		username = item.user.name
		avatar = nil
	end

	username = ("#%i %s"):format(i, username)

	local a = self.animations[i] or 0

	if ui.isOver(panel_w, h) and self.focus then
		self.animations[i] = math_util.clamp(a + 0.05, 0, 0.5)
		ui.tooltip = self.tooltips[i]
	end

	local background_color = { 0 + a * 0.5, 0 + a * 0.5, 0 + a * 0.5, 0.3 + a * 0.2 }

	gfx.translate((1 - ui.easeOutCubic(self.scoreUpdateTime, 0.3 + (i / 16))) * -w, 0)

	gfx.setColor(background_color)
	gfx.rectangle("fill", 0, 0, panel_w, 50)

	gfx.setColor({ 1, 1, 1, 1 })
	if avatar then
		local ih = avatar:getHeight()
		local s = (h - 6) / ih
		gfx.draw(avatar, 2, 2, 0, s, s)
	end



	-- const
	-- inputmode
	-- modifiers
	-- pauses
	-- perfect
	-- not_perfect

	gfx.push()

	local grade = img.smallGradeD

	if item.score > 9800 then
		grade = img.smallGradeX
	elseif item.score > 8000 then
		grade = img.smallGradeS
	elseif item.score > 7000 then
		grade = img.smallGradeA
	elseif item.score > 6000 then
		grade = img.smallGradeB
	elseif item.score > 5000 then
		grade = img.smallGradeC
	end

	gfx.push()
	gfx.translate(-grade:getWidth() / 2 + 67, h / 2 - (grade:getHeight() / 2) - 1)
	gfx.draw(grade)
	gfx.pop()

	gfx.translate(94, 0)
	gfx.setFont(self.font.username)
	ui.textWithShadow(username)

	gfx.setFont(self.font.score)
	ui.textWithShadow(("%s: %i (%ix)"):format(text.score, item.score, item.max_combo))
	gfx.pop()

	gfx.setFont(self.font.rightSide)

	if item.rate ~= 1 and item.rate ~= 0 then
		ui.frameWithShadow(("%s [%0.02fx]"):format(mods, item.rate), -4, 0, panel_w, 50, "right", "top")
	else
		ui.frameWithShadow(("%s"):format(mods), -4, 0, panel_w, 50, "right", "top")
	end

	ui.frameWithShadow(("%0.02f NS"):format(item.accuracy * 1000), -4, 0, panel_w, 50, "right", "center")

	local improvement = "-"

	if self.items[i + 1] then
		---@type number
		local difference = item.score - self.items[i + 1].score

		if difference > 0 then
			improvement = ("+%i"):format(difference)
		end
	end

	ui.frameWithShadow(improvement, -4, 0, panel_w, 50, "right", "bottom")

	local time_formatted = self.timeFormatted[i]
	if time_formatted then
		gfx.translate(panel_w + 16, 0)
		local icon = self.assets.images.recentScore
		local iw, ih = icon:getDimensions()
		gfx.setColor(1, 1, 1)
		gfx.draw(self.assets.images.recentScore, 0, h / 2, 0, 1, 1, iw / 2, ih / 2)
		ui.frameWithShadow(time_formatted, 16, 0, 100, h, "left", "center")
	end
end

return ScoreListView
