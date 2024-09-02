local ListView = require("osu_ui.views.ListView")
local ui = require("osu_ui.ui")
local math_util = require("math_util")

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
}

function ScoreListView:getModifiers(modifiers)
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

function ScoreListView:reloadItems()
	self.stateCounter = self.game.selectModel.scoreStateCounter

	if self.items == self.game.selectModel.scoreLibrary.items then
		return
	end

	self.items = self.game.selectModel.scoreLibrary.items
	self.modLines = {}

	for i, item in ipairs(self.items) do
		self.modLines[i] = self:getModifiers(item.modifiers)
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

function ScoreListView:mouseClick(w, h, i)
	if not self.focus then
		return
	end

	if ui.isOver(w, h, 0, 0) then
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
	local delta = ui.wheelOver(self, ui.isOver(w, h))
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

	local a = self.animations[i] or 0

	if ui.isOver(w, h) and self.focus then
		self.animations[i] = math_util.clamp(a + 0.05, 0, 0.5)
	end

	local background_color = { 0 + a * 0.5, 0 + a * 0.5, 0 + a * 0.5, 0.3 + a * 0.2 }

	gfx.translate((1 - ui.easeOutCubic(self.scoreUpdateTime, 0.3 + (i / 16))) * -w, 0)

	gfx.setColor(background_color)
	gfx.rectangle("fill", 0, 0, w, 50)

	gfx.setColor({ 1, 1, 1, 1 })
	if avatar then
		local ih = avatar:getHeight()
		local s = (h - 6) / ih
		gfx.draw(avatar, 2, 2, 0, s, s)
	end

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

	if item.rate ~= 1 then
		ui.frameWithShadow(("%s [%0.02fx]"):format(mods, item.rate), -4, 0, w, 50, "right", "top")
	else
		ui.frameWithShadow(("%s"):format(mods), -4, 0, w, 50, "right", "top")
	end

	ui.frameWithShadow(("%0.02f NS"):format(item.accuracy * 1000), -4, 0, w, 50, "right", "center")

	local improvement = "-"

	if self.items[i + 1] then
		---@type number
		local difference = item.score - self.items[i + 1].score

		if difference > 0 then
			improvement = ("+%i"):format(difference)
		end
	end

	ui.frameWithShadow(improvement, -4, 0, w, 50, "right", "bottom")
end

return ScoreListView
