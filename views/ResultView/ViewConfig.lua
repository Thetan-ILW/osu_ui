local IViewConfig = require("osu_ui.views.IViewConfig")
local ui = require("osu_ui.ui")
local just = require("just")
local msd_util = require("osu_ui.msd_util")

local getPP = require("osu_ui.osu_pp")
local getModifierString = require("osu_ui.views.modifier_string")

local Layout = require("osu_ui.views.ResultView.Layout")
local ImageValueView = require("osu_ui.views.ResultView.ImageValueView")
local Scoring = require("osu_ui.views.ResultView.Scoring")
local HitGraph = require("osu_ui.views.ResultView.HitGraph")

---@class osu.ui.ResultView : osu.ui.IViewConfig
local OsuViewConfig = IViewConfig + {}

---@type osu.OsuAssets
local assets
---@type table<string, love.Image>
local img

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

local isOnlineScore = false

local judge
local judgeName
local counterNames

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
local hpGraph = false

local meanFormatted = ""
local maxErrorFormatted = ""
local scrollSpeed = ""
local modsFormatted = ""

local ppFormatted = ""
local username = ""

local gfx = love.graphics

---@type love.Shader
local buttonHoverShader

---@type love.Image[]
local modifierIconImages = {}

---@param game sphere.GameController
---@param _assets osu.OsuAssets
---@param after_gameplay boolean
function OsuViewConfig:new(game, _assets, after_gameplay)
	assets = _assets
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
		scale = 1.2,
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

	buttonHoverShader = gfx.newShader([[
	vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
		vec4 texturecolor = Texel(tex, texture_coords);
		texturecolor.rgb += 0.2;
		return texturecolor * color;
        }
	]])

	if after_gameplay then
		assets.sounds.applause:play()
	end
end

function OsuViewConfig:unload()
	assets.sounds.applause:stop()
end

function OsuViewConfig.panels() end

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

function OsuViewConfig:loadScore(view)
	isOnlineScore = view.game.configModel.configs.select.scoreSourceName == "online"

	if isOnlineScore then
		return
	end

	local chartview = view.game.selectModel.chartview
	local configs = view.game.configModel.configs
	local osu = configs.osu_ui

	local scoreSystems = view.game.rhythmModel.scoreEngine.scoreSystem
	judgeName = view.currentJudgeName
	judge = scoreSystems.judgements[judgeName]
	counterNames = judge.orderedCounters

	marvelousValue.value = judge.counters[counterNames[1]]
	perfectValue.value = judge.counters[counterNames[2]]
	missValue.value = judge.counters["miss"]

	if judgeName ~= "soundsphere" then
		greatValue.value = judge.counters[counterNames[3]]
		goodValue.value = judge.counters[counterNames[4]]
		badValue.value = judge.counters[counterNames[5]]
	end

	accuracyValue.value = judge.accuracy

	local score = judge.score or view.judgements["osu!legacy OD9"].score or 0
	scoreValue.value = score

	local base = view.game.rhythmModel.scoreEngine.scoreSystem["base"]

	comboValue.value = base.maxCombo

	timeRate = view.game.playContext.rate

	timeFormatted = os.date("%c", view.game.selectModel.scoreItem.time)
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

	ppFormatted = ("%i PP"):format(getPP(judge.notes, chartview.osu_diff * timeRate, od, score))

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

	hpGraph = osu.hpGraph

	local show = showLoadedScore(view)

	local scoreItem = view.game.selectModel.scoreItem
	local rhythmModel = view.game.rhythmModel
	local scoreEngine = rhythmModel.scoreEngine
	local normalscore = rhythmModel.scoreEngine.scoreSystem.normalscore
	local mean = show and normalscore.normalscore.mean or scoreItem.mean

	meanFormatted = ("%i ms"):format(mean * 1000)
	maxErrorFormatted = ("%i ms"):format(scoreEngine.scoreSystem.misc.maxDeltaTime * 1000)

	local const = show and playContext.const or scoreItem.const
	scrollSpeed = "X"
	if const then
		scrollSpeed = "Const"
	end

	local selectModel = view.game.selectModel
	local modifiers = view.game.playContext.modifiers
	if not showLoadedScore(view) and selectModel.scoreItem then
		modifiers = selectModel.scoreItem.modifiers
	end

	modsFormatted = getModifierString(modifiers)
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
	elseif timeRate == (1.5 * 1.5 * 1.5) then
		table.insert(modifierIconImages, img.doubleTime)
		table.insert(modifierIconImages, img.doubleTime)
		table.insert(modifierIconImages, img.doubleTime)
	elseif timeRate == 0.75 then
		table.insert(modifierIconImages, img.halfTime)
	end
end

function OsuViewConfig:title(view)
	local w, h = Layout:move("title")

	gfx.setColor({ 0, 0, 0, 0.65 })
	gfx.rectangle("fill", 0, 0, w, h)

	gfx.setColor({ 1, 1, 1, 1 })

	w, h = Layout:move("titleImage")
	local iw, ih = img.title:getDimensions()
	gfx.draw(img.title, w - iw, 0)

	w, h = Layout:move("title")

	local chartview = view.game.selectModel.chartview

	if not chartview then
		return
	end

	local title = ("%s - %s"):format(chartview.artist, chartview.title)

	if chartview.name and timeRate == 1 then
		title = ("%s [%s]"):format(title, chartview.name)
	elseif chartview.name and timeRate ~= 1 then
		title = ("%s [%s %0.02fx]"):format(title, chartview.name, timeRate)
	else
		title = ("%s [%s %0.02fx]"):format(title, timeRate)
	end

	title = title .. " " .. difficultyFormatted

	local second_row = text.chartFrom:format(setDirectory)

	if chartview.format ~= "sm" then
		second_row = text.chartBy:format(creator)
	end

	local playInfo = text.playedBy:format(username, timeFormatted)

	gfx.setColor(1, 1, 1, 1)
	gfx.setFont(font.title)
	ui.frame(title, 9, 0, math.huge, h, "left", "top")

	gfx.setFont(font.creator)
	ui.frame(second_row, 9, 37, math.huge, h, "left", "top")

	gfx.setFont(font.playInfo)
	ui.frame(playInfo, 9, 59, math.huge, h, "left", "top")
end

local function centerFrame(value, box)
	if value then
		local w, h = Layout:move(box)
		gfx.translate(w / 2, h / 2)
		value:draw()
		gfx.translate(-w / 2, -h / 2)
	end
end

local function frame(value, box, box2)
	if value then
		local w, h = Layout:move(box, box2)
		gfx.translate(0, h / 2)
		value:draw()
		gfx.translate(0, -h / 2)
	end
end

local function judgeFrame(image, box, box2)
	if image then
		local s = 0.51
		local w, h = Layout:move(box, box2)
		local iw, ih = image:getDimensions()
		gfx.draw(image, (w / 2) - ((iw * s) / 2), (h / 2) - ((ih * s) / 2) + 2, 0, s, s)
	end
end

function OsuViewConfig:panel()
	local w, h = Layout:move("panel")

	gfx.setColor({ 1, 1, 1, 1 })

	gfx.draw(img.panel, 0, 0, 0)

	centerFrame(scoreValue, "score")

	frame(perfectValue, "column2", "row1")
	frame(marvelousValue, "column4", "row1")
	frame(greatValue, "column2", "row2")
	frame(goodValue, "column4", "row2")
	frame(badValue, "column2", "row3")
	frame(missValue, "column4", "row3")

	judgeFrame(img.judgeMarvelous, "column3", "row1")
	judgeFrame(img.judgePerfect, "column1", "row1")
	judgeFrame(img.judgeGreat, "column1", "row2")
	judgeFrame(img.judgeGood, "column3", "row2")
	judgeFrame(img.judgeBad, "column1", "row3")
	judgeFrame(img.judgeMiss, "column3", "row3")

	frame(comboValue, "combo")
	frame(accuracyValue, "accuracy")

	Layout:move("comboText")
	gfx.draw(img.maxCombo)
	Layout:move("accuracyText")
	gfx.draw(img.accuracy)
end

function OsuViewConfig:grade()
	local image = img["grade" .. grade]

	if not image then
		return
	end

	Layout:move("grade")
	local iw, ih = image:getDimensions()

	local x = iw / 2
	local y = ih / 2
	gfx.draw(image, -x, -y)
end

local function rightSideButtons(view)
	local w, h = Layout:move("base", "watch")

	local iw, ih = img.replay:getDimensions()
	gfx.translate(w - iw, 0)

	local changed, _, hovered = just.button("replayButton", just.is_over(iw, ih))

	if not hovered then
		gfx.setColor(1, 1, 1, 0.7)
	end

	if changed then
		view:play("replay")
	end

	gfx.draw(img.replay, 0, 0)
	gfx.setColor(1, 1, 1, 1)
end

local function graphInfo()
	local mx, my = gfx.inverseTransformPoint(love.mouse.getPosition())
	gfx.translate(mx, my)
	gfx.setColor(0, 0, 0, 0.8)
	gfx.rectangle("fill", 0, 0, 250, 120, 4, 4)

	gfx.setColor({ 1, 1, 1, 1 })
	gfx.setFont(font.graphInfo)

	gfx.translate(5, 5)
	just.text(text.mean:format(meanFormatted))
	just.text(text.maxError:format(maxErrorFormatted))
	just.text(text.scrollSpeed:format(scrollSpeed))
	just.text(text.mods:format(modsFormatted))
end

---@param view table
local function hitGraph(view)
	local w, h = Layout:move("hitGraph")

	gfx.translate(0, 4)
	gfx.setColor({ 1, 1, 1, 1 })

	gfx.draw(img.graph)

	if hpGraph then
		h = h * 0.86
		gfx.translate(2, 6)
		HitGraph.hpGraph.game = view.game
		HitGraph.hpGraph:draw(w, h)
	else
		h = h * 0.9
		HitGraph.hitGraph.game = view.game
		HitGraph.hitGraph:draw(w, h)
		HitGraph.earlyHitGraph.game = view.game
		HitGraph.earlyHitGraph:draw(w, h)
		HitGraph.missGraph.game = view.game
		HitGraph.missGraph:draw(w, h)

		gfx.setColor(0, 0, 0, 0)
		gfx.rectangle("fill", -2, h / 2, w + 2, 4)
	end

	if just.is_over(w, h) then
		graphInfo()
	end
end

local function backButton(view)
	local w, h = Layout:move("base")

	local iw, ih = img.menuBack:getDimensions()

	gfx.translate(0, h - ih)
	local changed, _, hovered = just.button("backButton", just.is_over(iw, ih))

	local prev_shader = gfx.getShader()

	if hovered then
		gfx.setShader(buttonHoverShader)
	end

	gfx.draw(img.menuBack, 0, 0)
	gfx.setShader(prev_shader)

	if changed then
		view:quit()
	end
end

local function mods()
	local w, _ = Layout:move("mods")

	if #modifierIconImages == 0 then
		return
	end

	local iw, ih = modifierIconImages[1]:getDimensions()

	gfx.translate(w - iw, -ih / 2)
	gfx.setColor({ 1, 1, 1, 1 })

	for _, image in ipairs(modifierIconImages) do
		iw, _ = image:getDimensions()
		gfx.draw(image)
		gfx.translate(-iw / 2, 0)
	end
end

function OsuViewConfig:draw(view)
	if isOnlineScore then
		return
	end

	Layout:draw()

	self:panel()
	self:title(view)
	self:grade()
	rightSideButtons(view)
	backButton(view)
	mods()

	hitGraph(view)

	local configs = view.game.configModel.configs
	local osu = configs.osu_ui

	if not osu.showPP then
		return
	end

	local w, h = gfx.getDimensions()
	gfx.origin()

	gfx.setColor({ 1, 1, 1, 1 })
	gfx.setFont(font.pp)
	ui.frame(ppFormatted, -10, 0, w, h, "right", "bottom")
end

return OsuViewConfig
