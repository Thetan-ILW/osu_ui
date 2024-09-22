local IViewConfig = require("osu_ui.views.IViewConfig")
local ui = require("osu_ui.ui")
local just = require("just")
local msd_util = require("osu_ui.msd_util")
local flux = require("flux")

local getPP = require("osu_ui.osu_pp")
local getModifierString = require("osu_ui.views.modifier_string")
local erfunc = require("libchart.erfunc")
local Format = require("sphere.views.Format")

local Layout = require("osu_ui.views.OsuLayout")
local ImageValueView = require("osu_ui.views.ResultView.ImageValueView")
local Scoring = require("osu_ui.views.ResultView.Scoring")
local HitGraph = require("osu_ui.views.ResultView.HitGraph")

local ImageButton = require("osu_ui.ui.ImageButton")
local BackButton = require("osu_ui.ui.BackButton")

---@class osu.ui.ResultViewConfig : osu.ui.IViewConfig
local ViewConfig = IViewConfig + {}

---@type table<string, love.Image>
local img

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

local isOnlineScore = false

local judge
local counterNames

local counters
local score_num
local combo_num

local marvelousValue
local perfectValue
local greatValue
local goodValue
local badValue
local missValue

local comboValue
local accuracyValue
local scoreValue

local timeRate = 1
local timeFormatted = ""
local setDirectory = ""
local creator = ""
local difficultyFormatted = ""

local grade = ""
local tooltip = ""
local show_hit_graph = false
local show_pp = false
local show_diff_and_rate  = false

local ppFormatted = ""
local username = ""

local gfx = love.graphics

---@type love.Image[]
local modifierIconImages = {}

---@type osu.ui.ImageButton
local back_image_button
---@type osu.ui.BackButton
local back_button
---@type osu.ui.ImageButton
local retry_button
---@type osu.ui.ImageButton
local replay_button

---@type osu.ui.ImageButton
local show_chat_button
---@type osu.ui.ImageButton
local show_player_button

---@type osu.ui.ImageButton
local online_ranking_button

local scroll = 0

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
---@param after_gameplay boolean
---@param view osu.ui.ResultView
function ViewConfig:new(game, assets, after_gameplay, view)
	self.assets = assets
	img = assets.images
	text, font = assets.localization:get("result")
	assert(text and font)

	local overlap = assets.params.scoreOverlap

	local score_font = assets.imageFonts.scoreFont

	marvelousValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%ix",
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	perfectValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%ix",
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	greatValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%ix",
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	goodValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%ix",
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	badValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%ix",
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	missValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%ix",
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	comboValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%ix",
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	accuracyValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "left",
		format = "%0.02f%%",
		multiplier = 100,
		scale = 1.1,
		overlap = overlap,
		files = score_font,
	})

	scoreValue = ImageValueView({
		x = 0,
		y = 0,
		oy = 0.5,
		align = "center",
		format = "%07d",
		multiplier = 1,
		scale = 1.3,
		overlap = overlap,
		files = score_font,
	})

	marvelousValue:load()
	perfectValue:load()
	greatValue:load()
	goodValue:load()
	badValue:load()
	missValue:load()

	comboValue:load()
	accuracyValue:load()
	scoreValue:load()

	if after_gameplay then
		assets.sounds.applause:play()
	end

	local configs = view.game.configModel.configs
	local osu = configs.osu_ui
	show_pp = osu.result.pp
	show_hit_graph = osu.result.hitGraph
	show_diff_and_rate = osu.result.difficultyAndRate

	self:createUI(view)
end

---@param view osu.ui.ResultView
function ViewConfig:createUI(view)
	local assets = self.assets
	if assets.hasBackButton then
		back_image_button = ImageButton(assets, {
			idleImage = img.menuBack,
			oy = 1,
			hoverArea = { w = 200, h = 90 },
			clickSound = assets.sounds.menuBack,
		}, function()
			view:quit()
		end)
	else
		back_button = BackButton(assets, { w = 93, h = 90 }, function()
			view:quit()
		end)
	end

	retry_button = ImageButton(assets, {
		idleImage = img.retry,
		ox = 1,
		hoverArea = { w = 411, h = 95 },
		clickSound = assets.sounds.menuHit,
	}, function()
		view:play("retry")
	end)

	replay_button = ImageButton(assets, {
		idleImage = img.replay,
		ox = 1,
		hoverArea = { w = 411, h = 122 },
		clickSound = assets.sounds.menuHit,
	}, function()
		view:play("replay")
	end)

	show_chat_button = ImageButton(assets, {
		idleImage = img.overlayChat,
		ox = 1,
		oy = 1,
		hoverArea = { w = 89, h = 22 },
	}, function ()
		view.notificationView:show("Not implemented")
	end)

	show_player_button = ImageButton(assets, {
		idleImage = img.overlayOnline,
		ox = 1,
		oy = 1,
		hoverArea = { w = 89, h = 22 },
	}, function ()
		view.notificationView:show("Not implemented")
	end)

	online_ranking_button = ImageButton(assets, {
		idleImage = img.onlineRanking,
		ox = 0.5,
		oy = 1,
		hoverArea = { w = 621, h = 77 },
	}, function ()
		view.notificationView:show("Not implemented")
	end)
end

function ViewConfig:unload()
	self.assets.sounds.applause:stop()
end

---@param view table
---@return boolean
local function showLoadedScore(view)
	local scoreEntry = view.game.playContext.scoreEntry
	local scoreItem = view.game.selectModel.scoreItem
	if not scoreEntry or not scoreItem then
		return false
	end
	return scoreItem.id == scoreEntry.id
end

function ViewConfig:scoreRevealAnimation()
	local v = self.scoreReveal

	scoreValue.value = score_num * v

	marvelousValue.value = math.ceil(counters[counterNames[1]] * v)
	perfectValue.value = math.ceil(counters[counterNames[2]] * v)
	missValue.value = math.ceil(counters["miss"] * v)

	local counters_count = #counterNames

	if counters_count >= 4 then
		greatValue.value = math.ceil(counters[counterNames[3]] * v)
		goodValue.value = math.ceil(counters[counterNames[4]] * v)
	end

	if counters_count >= 5 then
		badValue.value = math.ceil(counters[counterNames[5]] * v)
	end

	comboValue.value = math.ceil(combo_num * v)

	if judge.accuracy then
		accuracyValue.value = judge.accuracy * v
	end
end

function ViewConfig:stopAnimations()
	if self.scoreRevealTween then
		self.scoreRevealTween:stop()
	end
	self.scoreReveal = 1
	self:scoreRevealAnimation()
end

function ViewConfig:loadScore(view)
	isOnlineScore = view.game.configModel.configs.select.scoreSourceName == "online"

	if isOnlineScore or view.noScore then
		missValue.value = 9999999999
		return
	end

	local chartview = view.game.selectModel.chartview

	judge = view.judgement
	counterNames = judge.orderedCounters

	counters = judge.counters
	local base = view.game.rhythmModel.scoreEngine.scoreSystem["base"]
	combo_num = base.maxCombo
	score_num = judge.score or view.judgements["osu!legacy OD9"].score or 0

	self.scoreReveal = 0
	self.scoreRevealTween = flux.to(self, 1, { scoreReveal = 1 }):ease("cubicout"):onupdate(function()
		self:scoreRevealAnimation()
	end)

	timeRate = view.game.playContext.rate

	timeFormatted = os.date("%d/%m/%Y %H:%M:%S.", view.game.selectModel.scoreItem.time)
	setDirectory = chartview.set_dir
	creator = chartview.creator

	local chartdiff = view.game.playContext.chartdiff
	local diff_column = view.game.configModel.configs.settings.select.diff_column
	local time_rate = view.game.playContext.rate

	local difficulty = (chartview.difficulty or 0) * time_rate
	local patterns = chartview.level and "Lv." .. chartview.level or ""

	difficultyFormatted = ("[%0.02f*]"):format(difficulty)

	if diff_column == "msd_diff" and chartdiff.msd_diff_data then
		local msd = msd_util.getMsdFromData(chartdiff.msd_diff_data, time_rate)

		if msd then
			difficulty = msd.overall
			patterns = msd_util.getFirstFromMsd(msd)
		end

		patterns = msd_util.simplifySsr(patterns)
		difficultyFormatted = ("[%0.02f %s]"):format(difficulty, patterns)
	end

	local scoreSystemName = judge.scoreSystemName

	grade = Scoring.getGrade(scoreSystemName, judge.accuracy)
	local od = view.currentJudge

	if scoreSystemName ~= "osuMania" or scoreSystemName ~= "osuLegacy" then
		grade = Scoring.convertGradeToOsu(grade)
		od = 9
	end

	ppFormatted = ("%i PP"):format(getPP(judge.notes, chartdiff.osu_diff * timeRate, od, score_num))

	local playContext = view.game.playContext
	local timings = playContext.timings

	local earlyNoteMiss = math.abs(timings.ShortNote.miss[1])
	local lateNoteMiss = timings.ShortNote.miss[2]
	local earlyReleaseMiss = math.abs(timings.LongNoteEnd.miss[1])
	local lateReleaseMiss = timings.LongNoteEnd.miss[2]

	HitGraph.maxEarlyTiming = math.max(earlyNoteMiss, earlyReleaseMiss)
	HitGraph.maxLateTiming = math.max(lateNoteMiss, lateReleaseMiss)
	HitGraph.judge = judge
	HitGraph.counterNames = counterNames
	HitGraph.scoreSystemName = scoreSystemName

	local show = showLoadedScore(view)

	local scoreItem = view.game.selectModel.scoreItem
	local rhythmModel = view.game.rhythmModel
	local scoreEngine = rhythmModel.scoreEngine
	local normalscore = rhythmModel.scoreEngine.scoreSystem.normalscore
	local mean = show and normalscore.normalscore.mean or scoreItem.mean

	local selectModel = view.game.selectModel
	local modifiers = view.game.playContext.modifiers
	if not showLoadedScore(view) and selectModel.scoreItem then
		modifiers = selectModel.scoreItem.modifiers
	end

	username = view.game.configModel.configs.online.user.name or text.guest

	modifierIconImages = {}

	for _, mod in ipairs(modifiers) do
		local id = mod.id

		if id == 9 then
			table.insert(modifierIconImages, img.noLongNote)
		elseif id == 11 then
			table.insert(modifierIconImages, img[("automap%i"):format(mod.value)])
		elseif id == 16 then
			table.insert(modifierIconImages, img.mirror)
		elseif id == 17 then
			table.insert(modifierIconImages, img.random)
		end
	end

	if timeRate == 1.5 then
		table.insert(modifierIconImages, img.doubleTime)
	elseif timeRate == (1.5 * 1.5) then
		table.insert(modifierIconImages, img.doubleTime)
		table.insert(modifierIconImages, img.doubleTime)
	elseif timeRate == 0.75 then
		table.insert(modifierIconImages, img.halfTime)
	end

	local ratingHitTimingWindow = view.game.configModel.configs.settings.gameplay.ratingHitTimingWindow
	local ss_score = not show and scoreItem.score
		or erfunc.erf(ratingHitTimingWindow / (normalscore.accuracyAdjusted * math.sqrt(2))) * 10000

	if ss_score ~= ss_score then
		ss_score = 0
	end

	local ss_accuracy_value = show and normalscore.accuracyAdjusted or scoreItem.accuracy
	local ss_accuracy = Format.accuracy(ss_accuracy_value)

	local const = show and playContext.const or scoreItem.const
	local scroll = "X"
	if const then
		scroll = "Const"
	end

	local mods = getModifierString(modifiers)

	if mods == "" then
		mods = "No mods"
	else
		mods = "Mods:" .. mods
	end

	tooltip = ("Accuracy: %s | Score: %i\nMean: %0.02f ms | Max error: %i ms\nSpam: %ix\n\nScroll speed: %s\n%s"):format(
		ss_accuracy,
		ss_score,
		mean * 1000,
		scoreEngine.scoreSystem.misc.maxDeltaTime * 1000,
		scoreEngine.scoreSystem.base.earlyHitCount,
		scroll,
		mods
	)
end

function ViewConfig:title(view)
	local w, h = Layout:move("base")

	gfx.setColor({ 0, 0, 0, 0.8 })
	gfx.rectangle("fill", 0, 0, w, 96)

	gfx.setColor({ 1, 1, 1, 1 })

	local iw, ih = img.title:getDimensions()
	gfx.draw(img.title, w - 32, 0, 0, 1, 1, iw, 0)

	local chartview = view.game.selectModel.chartview

	if not chartview then
		return
	end

	local title = ("%s - %s"):format(chartview.artist, chartview.title)

	if show_diff_and_rate then
		if chartview.name and timeRate == 1 then
			title = ("%s [%s]"):format(title, chartview.name)
		elseif chartview.name and timeRate ~= 1 then
			title = ("%s [%s %0.02fx]"):format(title, chartview.name, timeRate)
		else
			title = ("%s [%s %0.02fx]"):format(title, timeRate)
		end

		title = title .. " " .. difficultyFormatted
	else
		title = ("%s [%s]"):format(title, chartview.name)
	end

	local second_row = text.chartFrom:format(setDirectory)

	if chartview.format ~= "sm" then
		second_row = text.chartBy:format(creator)
	end

	local playInfo = text.playedBy:format(username, timeFormatted)

	gfx.setColor(1, 1, 1, 1)
	gfx.setFont(font.title)
	ui.frame(title, 5, 0, math.huge, h, "left", "top")

	gfx.setFont(font.creator)
	ui.frame(second_row, 5, 33, math.huge, h, "left", "top")

	gfx.setFont(font.playInfo)
	ui.frame(playInfo, 5, 54, math.huge, h, "left", "top")
end

local function judgeCentered(image, x, y)
	local w, h = image:getDimensions()
	gfx.draw(image, x, y, 0, 0.5, 0.5, w / 2, h / 2)
end

local function judgeValue(value_view, x, y)
	gfx.push()
	gfx.translate(x, y)
	value_view:draw()
	gfx.pop()
end

local function valueView(value_view, x, y)
	gfx.push()
	gfx.translate(x, y)
	value_view:draw()
	gfx.pop()
end

local ppy = 1.6

local score_x = 220 * ppy
local score_y = 94 * ppy

local img_x1 = 40 * ppy
local img_x2 = 240 * ppy
local text_x1 = 80 * ppy
local text_x2 = 280 * ppy

local row1 = 160 * ppy
local row2 = 220 * ppy
local row3 = 280 * ppy
local row4 = 320 * ppy

local combo_x = text_x1 - 65 * ppy
local combo_y = row4 + 38
local acc_x = text_x2 - 86 * ppy
local acc_y = row4 + 38

function ViewConfig:panel()
	local w, h = Layout:move("base")

	gfx.setColor(1, 1, 1)
	gfx.draw(img.panel, 0, 102, 0)

	gfx.setColor(1, 1, 1, self.scoreReveal * 0.5 + 0.5)
	valueView(scoreValue, score_x, score_y)

	judgeCentered(img.judgeMarvelous, img_x2, row1)
	judgeCentered(img.judgePerfect, img_x1, row1)
	judgeCentered(img.judgeGreat, img_x1, row2)
	judgeCentered(img.judgeGood, img_x2, row2)
	judgeCentered(img.judgeBad, img_x1, row3)
	judgeCentered(img.judgeMiss, img_x2, row3)

	judgeValue(marvelousValue, text_x2, row1)
	judgeValue(perfectValue, text_x1, row1)
	judgeValue(greatValue, text_x1, row2)
	judgeValue(goodValue, text_x2, row2)
	judgeValue(badValue, text_x1, row3)
	judgeValue(missValue, text_x2, row3)

	gfx.draw(img.maxCombo, 8, 480)
	gfx.draw(img.accuracy, 291, 480)

	valueView(comboValue, combo_x, combo_y)
	valueView(accuracyValue, acc_x, acc_y)
end

local overlay_rotation = 0

function ViewConfig:grade()
	local image = img["grade" .. grade]

	if not image then
		return
	end

	local overlay = img.backgroundOverlay

	local w, h = Layout:move("base")
	local iw, ih = image:getDimensions()
	local ow, oh = overlay:getDimensions()

	overlay_rotation = (overlay_rotation + love.timer.getDelta() * 0.5) % (math.pi * 2)

	local additional_s = (1 - self.scoreReveal) * 0.2
	gfx.setColor(1, 1, 1, self.scoreReveal)
	gfx.draw(overlay, w - 200, 320, overlay_rotation, 1, 1, ow / 2, oh / 2)
	gfx.draw(image, w - 192, 320, 0, 1 + additional_s, 1 + additional_s, iw / 2, ih / 2)
end

local function rightSideButtons(view)
	local w, h = Layout:move("base")

	gfx.translate(w, 515)

	retry_button.alpha = 0.5
	retry_button:update(true)
	retry_button:draw()

	gfx.translate(0, 96)
	replay_button.alpha = 0.5
	replay_button:update(true)
	replay_button:draw()
end

---@param view table
local function hitGraph(view)
	Layout:move("base")
	local w, h = 301, 160

	gfx.translate(256, 608)
	gfx.setColor({ 1, 1, 1, 1 })

	gfx.draw(img.graph)

	if show_hit_graph then
		h = h * 0.9
		gfx.translate(0, 5)
		HitGraph.hitGraph.game = view.game
		HitGraph.hitGraph:draw(w, h - 3)
		HitGraph.earlyHitGraph.game = view.game
		HitGraph.earlyHitGraph:draw(w, h - 3)
		HitGraph.missGraph.game = view.game
		HitGraph.missGraph:draw(w, h - 3)
	else
		gfx.translate(9, 9)
		view.hpGraph:draw()
	end

	if just.is_over(w, h) then
		ui.tooltip = tooltip
	end
end

local function backButton(view)
	local w, h = Layout:move("base")
	gfx.translate(0, h)

	if back_image_button then
		back_image_button:update(true)
		back_image_button:draw()
	else
		gfx.translate(0, -58)
		back_button:update(true)
		back_button:draw()
		gfx.translate(0, 58)
	end
end

local function mods()
	local w, h = Layout:move("base")

	if #modifierIconImages == 0 then
		return
	end

	local iw, ih = modifierIconImages[1]:getDimensions()

	gfx.translate(w - 64, 416)
	gfx.setColor({ 1, 1, 1, 1 })

	for _, image in ipairs(modifierIconImages) do
		iw, ih = image:getDimensions()
		gfx.draw(image, 0, 0, 0, 1, 1, iw / 2, ih / 2)
		gfx.translate(-iw / 2, 0)
	end
end

local function fakeButtons()
	local w, h = Layout:move("base")

	gfx.push()
	gfx.translate(w - 3, h + 1)
	show_chat_button:update(true)
	show_chat_button:draw()

	gfx.translate(-96, 0)
	show_player_button.alpha = 0.5
	show_player_button:update(true)
	show_player_button:draw()
	gfx.pop()

	gfx.translate(w / 2, h)
	online_ranking_button:update(true)
	online_ranking_button:draw()
end

---@param view osu.ui.ResultView
function ViewConfig:resolutionUpdated(view)
	self:createUI(view)
end

---@param view osu.ui.ResultView
function ViewConfig:draw(view)
	if isOnlineScore then
		return
	end

	gfx.push()
	self:panel()
	rightSideButtons(view)
	self:grade()
	backButton(view)
	mods()
	hitGraph(view)
	fakeButtons()
	gfx.pop()

	self:title(view)

	local w, h = Layout:move("base")
	gfx.setColor(1, 1, 1)
	gfx.rectangle("fill", w - 13, 99, 10, 330)

	if show_pp then
		local w, h = gfx.getDimensions()
		gfx.origin()
		gfx.setFont(font.pp)
		ui.frame(ppFormatted, -10, -30, w, h, "right", "bottom")
	end
end

return ViewConfig
