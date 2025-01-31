local Screen = require("osu_ui.views.Screen")
local Component = require("ui.Component")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local math_util = require("math_util")
local flux = require("flux")
local ImageButton = require("osu_ui.ui.ImageButton")
local ImageValueView = require("osu_ui.ui.ImageValueView")
local Button = require("osu_ui.ui.Button")
local BackButton = require("osu_ui.ui.BackButton")
local MenuBackAnimation = require("osu_ui.views.MenuBackAnimation")
local HpGraph = require("osu_ui.views.ResultView.HpGraph")
local PlayerInfo = require("osu_ui.views.PlayerInfoView")
local ResultScores = require("osu_ui.views.ResultView.Scores")
local RankingElement = require("osu_ui.views.ResultView.RankingElement")

local thread = require("thread")
local Rectangle = require("ui.Rectangle")
local Image = require("ui.Image")
local Label = require("ui.Label")
local ScrollBar = require("osu_ui.ui.ScrollBar")

local DisplayInfo = require("osu_ui.views.ResultView.DisplayInfo")

local VideoExporterModal = require("osu_ui.views.VideoExporter.Modal")

---@class osu.ui.ResultViewContainer : osu.ui.Screen
---@operator call: osu.ui.ResultViewContainer
local View = Screen + {}

function View:transitIn()
	self.y = 0
	self.resultApi:loadController()

	self:clearTree()
	self.alpha = 0
	local result_dim =  self.selectApi:getConfigs().settings.graphics.dim.result

	if self.scene.previousScreenId == "gameplay" then
		self.selectApi:loadController()
		self.playAnimations = true
		self.scene:showOverlay(0.5, result_dim)
		self:load(true)
		Screen.transitIn(self)
	elseif self.scene.previousScreenId == "select" then
		local f = thread.coro(function()
			self.resultApi:replayNotechartAsync("result")
			self.scene:showOverlay(0.5, result_dim)
			self:load(true)
			Screen.transitIn(self)
		end)
		f()

		self.playAnimations = false
		return
	end
end

function View:transitToSelect()
	self:receive({ name = "loseFocus" })
	self.resultApi:unloadController()

	self:transitOut({
		time = 0.5,
		ease = "quadout",
		onComplete = function ()
			self:clearTree()
			self:kill()
		end
	})

	flux.to(self, 0.5, { y = 100 }):ease("quadout")
	self.scene:transitInScreen("select")
end

function View:transitToGameplay()
	if not self.handleEvents then
		return
	end
	self.resultApi:unloadController()

	self.area:scrollToPosition(0, 0.97)
	flux.to(self.overlay, 0.2, { alpha = 0 }):ease("quadout")

	if self.transitionTween then
		self.transitionTween:stop()
	end

	self.scene:hideOverlay(0.4, 0.5, function ()
		self.scene:transitInScreen("gameplay")

		self:transitOut({
			time = 0.5,
			ease = "quadout",
			onComplete = function ()
				self:clearTree()
				self:kill()
			end
		})

		flux.to(self, 0.5, { y = 100 }):ease("quadout")
	end)
end

function View:keyPressed(event)
	if event[2] == "escape" then
		self:transitToSelect()
		return true
	elseif event[2] == "f2" then
		local chart = self.resultApi:getChart()
		if chart then
			self.resultApi:exportOsuReplay(chart)
		end
	elseif event[2] == "f6" then
		self.scene:addChild("videoExporterModal", VideoExporterModal({
			z = 0.5
		}))
	end
end

function View:mousePressed()
	if not self.loaded then
		return
	end

	for _, v in pairs(self.rankingElements.children) do
		---@cast v osu.ui.ResultView.RankingElement
		v:stopAnimation()
	end
	self.scoreTween:stop()
end

function View:reload()
	self:clearTree()
	self:load(true)
end

function View:load(score_loaded)
	self.width, self.height = self.parent:getDimensions()
	self:getViewport():listenForResize(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.scene = scene

	self.resultApi = scene.ui.resultApi
	self.selectApi = scene.ui.selectApi

	self.loaded = false
	if not score_loaded then
		return
	end
	self.loaded = true

	local display_info = DisplayInfo(scene.localization, self.selectApi, self.resultApi, scene.ui.pkgs.manipFactor)
	display_info:load()

	local assets = scene.assets
	local fonts = scene.fontManager
	local text = scene.localization.text
	self.fonts = fonts

	local configs = self.selectApi:getConfigs()
	local osu_cfg = configs.osu_ui ---@type osu.ui.OsuConfig

	local width, height = self.width, self.height

	local area = self:addChild("scrollArea", ScrollAreaContainer({
		scrollLimit = 768 - 96,
		width = width,
		height = height * 2
	}))
	---@cast area osu.ui.ScrollAreaContainer
	self.area = area

	self:addChild("scrollBar", ScrollBar({
		x = width - 13, startY = 99,
		width = 10,
		container = area,
		windowHeight = 768 - 96 - 6,
		z = 0.98,
	}))

	---- HEADER ----
	self:addChild("headerBackground", Rectangle({
		width = width,
		height = 96,
		color = { 0, 0, 0, 0.8 },
		z = 0.9
	}))

	self:addChild("chartName", Label( {
		x = 5,
		text = display_info.chartName,
		font = fonts:loadFont("Light", 30),
		z = 1,
	}))

	self:addChild("chartSource", Label({
		x = 5, y = 33,
		text = display_info.chartSource,
		font = fonts:loadFont("Regular", 22),
		z = 1,
	}))

	self:addChild("playInfo", Label({
		x = 5, y = 54,
		text = display_info.playInfo,
		font = fonts:loadFont("Regular", 22),
		z = 1,
	}))

	self:addChild("titleImage", Image({
		x = width - 32,
		origin = { x = 1, y = 0 },
		image = assets:loadImage("ranking-title"),
		z = 0.98,
	}))

	---- PANEL ----
	area:addChild("statsPanel", Image({
		y = 102,
		image = assets:loadImage("ranking-panel"),
		z = 0.5,
	}))

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
	local row4_offset = assets.useNewLayout and 32 or 12.8

	local score_font = assets.imageFonts.scoreFont

	local score = area:addChild("score", ImageValueView({
		x = score_x, y = score_y,
		origin = { x = 0.5, y = 0.5 },
		scale = assets.useNewLayout and 1.3 or 1.05,
		files = score_font,
		overlap = assets.useNewLayout and -2 or 0,
		displayValue = 0,
		constantSpacing = true,
		z = 0.55,
	}))

	local pa = self.playAnimations

	self.scoreTween = flux.to(score, 1, { displayValue = display_info.score }):ease("cubicout"):onupdate(function()
		score:setText(("%07d"):format(score.displayValue))
	end)

	if not pa then
		self.scoreTween:stop()
		score:setText(("%07d"):format(display_info.score))
	end

	local re = area:addChild("rankingElements", Component({ z = 0.55 }))

	local delay = 0.06
	re:addChild("perfect", RankingElement({
		x = img_x1, y = row1,
		imgName = "mania-hit300",
		value = display_info.perfect,
		format = "%ix",
		playAnimation = pa,
		delay = delay,
	}))

	re:addChild("marvelous", RankingElement({
		x = img_x2, y = row1,
		imgName = "mania-hit300g",
		value = display_info.marvelous,
		format = "%ix",
		playAnimation = pa,
		delay = delay * 2,
	}))

	re:addChild("great", RankingElement({
		x = img_x1, y = row2,
		imgName = "mania-hit200",
		value = display_info.great,
		format = "%ix",
		playAnimation = pa,
		delay = delay * 3,
	}))

	re:addChild("good", RankingElement({
		x = img_x2, y = row2,
		imgName = "mania-hit100",
		value = display_info.good,
		format = "%ix",
		playAnimation = pa,
		delay = delay * 4,
	}))

	re:addChild("bad", RankingElement({
		x = img_x1, y = row3,
		imgName = "mania-hit50",
		value = display_info.bad,
		format = "%ix",
		playAnimation = pa,
		delay = delay * 5,
	}))

	re:addChild("miss", RankingElement({
		x = img_x2, y = row3,
		imgName = "mania-hit0",
		value = display_info.miss,
		format = "%ix",
		playAnimation = pa,
		delay = delay * 6,
	}))

	local combo = re:addChild("comboImg", RankingElement({
		x = img_x1 - 56, y = row4 - row4_offset,
		imgName = "ranking-maxcombo",
		playAnimation = pa,
		delay = delay * 7,
		targetImageScale = 1,
	}))
	combo.image.origin = { x = 0, y = 0 }

	re:addChild("combo", RankingElement({
		x = text_x1 - 168,
		y = row4 + 16 + 25.5,
		value = display_info.combo,
		format = "%ix",
		playAnimation = pa,
		delay = delay * 7,
	}))

	if display_info.accuracy then
		local acc = re:addChild("accImg", RankingElement({
			x = img_x2 - 92.8, y = row4 - row4_offset,
			imgName = "ranking-accuracy",
			playAnimation = pa,
			delay = delay * 8,
			targetImageScale = 1,
		}))
		acc.image.origin = { x = 0, y = 0 }

		re:addChild("acc", RankingElement({
			x = text_x2 - 201.5,
			y = row4 + 16 + 25.5,
			value = display_info.accuracy * 100,
			format = "%0.2f%%",
			playAnimation = pa,
			delay = delay * 8,
			dontCeil = true,
		}))
	end

	self.rankingElements = re

	---- GRAPH ----
	local score_system = self.resultApi:getScoreSystem()
	area:addChild("graph", Image({ x = 256, y = 608, image = assets:loadImage("ranking-graph"), z = 0.5 }))

	if score_system.sequence then
		area:addChild("hpGraph", HpGraph({
			x = 265, y = 617,
			width = 300,
			height = 135,
			points = score_system.sequence,
			hpScoreSystem = score_system.hp,
			z = 0.55,
		}))
	end

	local judge_name = display_info.judgeName

	if osu_cfg.result.judgmentName then
		local judge_name_bg = area:addChild("judgeNameBackground", Rectangle({
			x = 268,
			y = 722,
			width = 240,
			height = 28,
			rounding = 5,
			color = { 0, 0, 0, 0.5 },
			z = 0.9
		}))

		local judge_name_label = area:addChild("judgeName", Label({
			x = 273,
			y = 723,
			height = 28,
			alignY = "center",
			text = judge_name,
			font = fonts:loadFont("Regular", 20),
			z = 0.91,
		}))
		judge_name_bg.width = judge_name_label:getWidth() + 10
	end

	---- GRADE ----
	local overlay = area:addChild("backgroundOverlay", Image({
		x = width - 200, y = 320,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("ranking-background-overlay"),
		z = 0,
	}))
	self.overlay = overlay
	function overlay:update(dt)
		overlay.angle = (overlay.angle + love.timer.getDelta() * 0.5) % (math.pi * 2)
		Image.update(overlay, dt)
	end

	area:addChild("grade", Image({
		x = width - 192, y = 320,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage(("ranking-%s"):format(display_info.grade)),
		z = 0.6,
	}))

	---- BUTTONS ----
	area:addChild("retryButton", ImageButton({
		x = width, y = 576,
		origin = { x = 1, y = 0.5 },
		idleImage = assets:loadImage("pause-retry"),
		alpha = 0.5,
		z = 0.6,
		onClick = function()
			if not self.selectApi:notechartExists() then
				return
			end
			self:transitToGameplay()
		end
	}))

	area:addChild("watchReplayButton", ImageButton({
		x = width, y = 672,
		origin = { x = 1, y = 0.5 },
		idleImage = assets:loadImage("pause-replay"),
		alpha = 0.5,
		z = 0.6,
		onClick = function ()
			if not self.selectApi:notechartExists() then
				return
			end
			local c = coroutine.create(function ()
				self.resultApi:replayNotechartAsync("replay")
			end)
			coroutine.resume(c)
			self:transitToGameplay()
		end
	}))

	self.modIcons = area:addChild("modIconsContainer", Component({
		x = width + 6,
		y = 416,
		origin = { x = 1 },
		z = 0.7
	}))
	local added_mods = 0

	local function addModIcon(image)
		self.modIcons:addChild(tostring(added_mods), Image({
			x = added_mods * -34,
			origin = { x = 0.5, y = 0.5 },
			image = image,
		}))
		added_mods = added_mods + 1
	end

	local mods = self.selectApi:getPlayContext().modifiers
	local empty_image = assets.emptyImage()
	for i, mod in ipairs(mods) do
		local id = mod.id
		local img_path ---@type string?

		if id == 9 then
			img_path = "selection-mod-nln"
		elseif id == 11 then
			img_path = ("selection-mod-key%i"):format(mod.value)
		elseif id == 16 then
			img_path = ("selection-mod-mirror")
		elseif id == 17 then
			img_path = ("selection-mod-random")
		elseif id == 19 and mod.value == 3 then
			img_path = ("selection-mod-fln3")
		end

		if img_path then
			local image = assets:loadImage(img_path)
			if image ~= empty_image then
				addModIcon(image)
			end
		end
	end

	if display_info.timeRate == 1.5 then
		addModIcon(assets:loadImage("selection-mod-doubletime"))
	elseif display_info.timeRate == (1.5 * 1.5) then
		local dt = assets:loadImage("selection-mod-doubletime")
		addModIcon(dt)
		addModIcon(dt)
	elseif display_info.timeRate == 0.75 then
		addModIcon(assets:loadImage("selection-mode-halftime"))
	end

	if judge_name:find("osu!mania") then
		addModIcon(assets:loadImage("selection-mod-scorev2"))
	end

	self.modIcons:autoSize()

	---@type number?
	local prev_scores_x
	if self.scores then
		prev_scores_x = self.scores.scoresX
	end
	local scores = self:addChild("scores", ResultScores({
		x = width, y = 145,
		origin = { x = 1 },
		width = 400,
		height = 220,
		scoresX = prev_scores_x,
		alwaysVisible = osu_cfg.result.alwaysDisplayScores,
		z = 1,
		onOpenScore = function(id)
			self.selectApi:setScoreIndex(id)
			self:receive({ name = "loseFocus" })
			self.handleEvents = false
			scene:hideOverlay(0.2, 0.5)
			flux.to(self, 0.3, { alpha = 0 }):ease("cubicout"):oncomplete(function ()
				local f = thread.coro(function()
					self.resultApi:replayNotechartAsync("result")
					self:reload()
					self.handleEvents = true
					scene:showOverlay(0.2, 0.35)
					flux.to(self, 0.3, { alpha = 1}):ease("cubicout")
				end)
				f()
			end)
		end
	})) ---@cast scores osu.ui.ResultScores
	self.scores = scores


	---- FAKE BUTTONS ----
	self:addChild("showChat", ImageButton({
		x = width - 4, y = height + 3,
		origin = { x = 1, y = 1 },
		idleImage = assets:loadImage("overlay-show"),
		z = 0.4,
		onClick = function ()
			self.scene.chat:fade(1)
		end
	}))

	self:addChild("onlineUsers", ImageButton({
		x = width - 100, y = height + 3,
		origin = { x = 1, y = 1 },
		idleImage = assets:loadImage("overlay-online"),
		alpha = 0.5,
		z = 0.4,
		onClick = function ()
		end
	}))

	local online_ranking = area:addChild("onlineRanking", Button({
		x = width / 2 - 160, y = height - 41.6,
		label = "▼ Online Ranking ▼",
		font = fonts:loadFont("Regular", 32),
		width = 320,
		height = 48,
		color = { 0.46, 0.09, 0.8, 1 },
		z = 0.8,
		onClick = function ()
			area:scrollToPosition(768 - 96, 0)
		end
	}))
	---@cast online_ranking osu.ui.Button
	function online_ranking:update(dt)
		local position = area.scrollPosition
		local alpha = 1 - math_util.clamp((position / area.height * 16), 0, 1)
		self.alpha = alpha
		return Button.update(self, dt)
	end

	if #assets.menuBackFrames == 0 then
		self:addChild("backButton", BackButton({
			y = height - 58,
			assets = assets,
			text = "back",
			hoverWidth = 93,
			hoverHeight = 58,
			z = 1,
			onClick = function ()
				self:transitToSelect()
			end
		}))
	else
		area:addChild("backButton", MenuBackAnimation({
			y = height,
			origin = { x = 0, y = 1 },
			onClick = function ()
				self:transitToSelect()
			end,
			z = 1
		}))
	end

	local rd_left = area:addChild("rankingDialogLeft", Image({
		image = assets:loadImage("ranking-dialog-left"),
		y = 768,
		color = { 1, 1, 1, 0.9 }
	}))

	local rd_right = area:addChild("rankingDialogRight", Image({
		image = assets:loadImage("ranking-dialog-right"),
		origin = { x = 1 },
		x = width,
		y = 768,
		color = { 1, 1, 1, 0.9 }
	}))

	local rd_middle_image = assets:loadImage("ranking-dialog-middle")
	area:addChild("rankingDialogMiddle", Image({
		x = rd_left:getWidth(),
		y = 768,
		image = rd_middle_image,
		scaleX = (width - rd_left:getWidth() - rd_right:getWidth()) / rd_middle_image:getWidth(),
		color = { 1, 1, 1, 0.9 }
	}))

	area:addChild("rankingRank", Label({
		x = 408,
		y = 768 + 12,
		font = fonts:loadFont("Light", 30),
		text = ("You achieved the #%i score on local rankings!"):format(display_info.rank),
		shadow = true,
		color = { 0.98, 0.8, 0.26, 1 },
		z = 0.05,
	}))

	area:addChild("playerInfo", PlayerInfo({
		x = 557, y = 768 + 102,
		z = 0.05,
		handleEvents = false,
		onClick = function ()
		end
	}))

	area:addChild("exportOsuReplay", Button({
		x = width - 20,
		y = 768 + 10,
		origin = { x = 1 },
		width = 250,
		height = 30,
		font = fonts:loadFont("Regular", 17),
		label = text.RankingDialog_ExportOsuReplay,
		color = { 0.05, 0.52, 0.65, 1 },
		z = 0.02,
		onClick = function()
			local chart = self.resultApi:getChart()
			if chart then
				self.resultApi:exportOsuReplay(chart)
				scene.notification:show("Exported")
			else
				scene.notification:show("Failed to export osu! replay")
			end
		end
	}))

	area:addChild("videoExport", Button({
		x = width - 20,
		y = 768 + 40,
		origin = { x = 1 },
		width = 250,
		height = 30,
		font = fonts:loadFont("Regular", 17),
		label = text.RankingDialog_ExportVideoGif,
		color = { 0.05, 0.52, 0.65, 1 },
		z = 0.02,
		onClick = function()
			scene:openModal("videoExport")
		end
	}))

	area:addChild("submitReplay", Button({
		x = width - 20,
		y = 768 + 70,
		origin = { x = 1 },
		width = 250,
		height = 30,
		font = fonts:loadFont("Regular", 17),
		label = text.RankingDialog_SubmitReplay,
		color = { 0.05, 0.52, 0.65, 1 },
		z = 0.02,
		onClick = function()
			self.resultApi:submitReplay()
		end
	}))

	self.accuracyTable = area:addChild("accuracyTable", Component({
		x = 50,
		y = 768 + 270,
		z = 0.02,
	}))
	self:addAccuracyColumn("osu!legacy", "OD", 0, 6, { 1, 0.95, 0.9, 0.8, 0.7 } )
	self:addAccuracyColumn("osu!mania", "OD",  154, 6, { 1, 0.95, 0.9, 0.8, 0.7 } )
	self:addAccuracyColumn("Etterna", "J",  (154 * 2), 3, { 1, 0.93, 0.85, 0.8, 0.7 } )
	self:addAccuracyColumn("LR2", {"Easy", "Normal", "Hard", "Very hard" }, (154 * 3), 0, { 1, 0.93, 0.85, 0.8, 0.7 } )

	self.statTable = area:addChild("statTable", Component({
		x = width - 50,
		y = 768 + 325,
		origin = { x = 1 },
		z = 0.01,
	}))
	self:addStat("pp", 0, "Performance", ("%i PP"):format(display_info.pp))
	if display_info.manipFactorPercent ~= 0 then
		self:addStat("manip", -114, "Manip", ("%0.02f%%"):format(display_info.manipFactorPercent * 100))
	else
		self:addStat("spam", -114, "Spam", ("%ix\n%i%%"):format(display_info.spam, display_info.spamPercent * 100))
	end

	self:addStat("normalScore", -(114 * 2), "NS", ("%0.02f"):format(display_info.normalScore * 1000))
	self:addStat("mean", -(114 * 3), "Mean", ("%0.02fms"):format(display_info.mean * 1000))

	self:addStat("keyMode", -(114 * 4), "Key Mode", display_info.keyMode)
	self.statTable:autoSize()

	self.msdTable = area:addChild("msdTable", Component({
		x = 50,
		y = 768 + 550,
		z = 0.02
	}))
	if display_info.msd then
		self:addMsdTable(display_info.msd, display_info.timeRate, display_info.keyMode)
	end

	self.beatmapInfoTable = area:addChild("beatmapInfoTable", Component({
		x = width - 50,
		y = 768 + 550,
		origin = { x = 1 },
		z = 0.01,
	}))
	self:addBeatmapInfo("enps", 0, "ENPS", ("%0.02f"):format(display_info.enpsDiff))
	self:addBeatmapInfo("stars", -114, "Stars", ("%0.02f*"):format(display_info.osuDiff))
	self:addBeatmapInfo("ln", -114 * 2, "LN", ("%i%%"):format(display_info.lnPercent * 100))
	self.beatmapInfoTable:autoSize()

	self.playAnimations = false
end

function View:update()
	if self.area then
		local tables_in_view = self.area.scrollPosition < 260
		self.accuracyTable.disabled = tables_in_view
		self.statTable.disabled = tables_in_view
		self.msdTable.disabled = tables_in_view
		self.beatmapInfoTable.disabled = tables_in_view
	end
end

local table_colors = {
	{ 0.6, 0.8, 1, 1 },
	{ 0.95, 0.796, 0.188, 1 },
	{ 0.07, 0.8, 0.56, 1 },
	{ 0, 0.7, 0.32, 1 },
	{ 0.1, 0.7, 1, 1 },
	{ 1, 0.1, 0.7, 1 },
}

local score_system_name_alias = {
	["osu!legacy"] = "osu!mania",
	["osu!mania"] = "osu!mania V2",
	["LR2"] = "Lunatic Rave 2"
}

local function getAccuracyColor(x, ranges)
	for i, v in ipairs(ranges) do
		if x >= v then
			return table_colors[i]
		end
	end

	return table_colors[#table_colors]
end

---@param score_system_name string
---@param score_system_postfix string | string[]
---@param x number
---@param judge_start number
---@param accuracy_ranges number[]
function View:addAccuracyColumn(score_system_name, score_system_postfix, x, judge_start, accuracy_ranges)
	local score_system = self.resultApi:getScoreSystem()
	local judgements = score_system.judgements

	if not judgements then
		return
	end

	local spacing_y = 2
	local panel_h = 36

	local scale = self.width / 1366
	x = x * scale
	local w = 150 * scale

	self.accuracyTable:addChild(score_system_name .. "Label", Label({
		x = x,
		boxWidth = w,
		alignX = "center",
		font = self.fonts:loadFont("Bold", 15),
		text = score_system_name_alias[score_system_name] or score_system_name,
		z = 0.02
	}))

	local start_y = 25

	for i = 1, 4, 1 do
		local y = start_y + ((panel_h + spacing_y) * (i - 1))
		self.accuracyTable:addChild("bg" .. score_system_name .. i, Rectangle({
			x = x, y = y,
			width = w,
			height = panel_h,
			color = { 0.16, 0.16, 0.16, 1 },
			z = 0.01
		}))

		local judge = i + judge_start
		local postfix ---@type string

		if type(score_system_postfix) == "table" then
			postfix = score_system_postfix[judge]
		else
			postfix = score_system_postfix .. judge
		end

		---@type number
		local accuracy = judgements[("%s %s"):format(score_system_name, postfix)].accuracy

		self.accuracyTable:addChild("od" .. score_system_name .. i, Label({
			x = x + 5, y = y,
			boxWidth = w,
			boxHeight = panel_h,
			alignX = "left",
			alignY = "center",
			font = self.fonts:loadFont("Regular", 15),
			text = postfix,
			shadow = true,
			z = 0.02,
		}))
		self.accuracyTable:addChild("accuracy".. score_system_name .. i, Label({
			x = x - 5, y = y,
			boxWidth = w,
			boxHeight = panel_h,
			alignX = "right",
			alignY = "center",
			font = self.fonts:loadFont("Regular", 15),
			text = ("%0.02f%%"):format(accuracy * 100),
			shadow = true,
			color = getAccuracyColor(accuracy, accuracy_ranges),
			z = 0.02,
		}))
	end
end

---@param id string
---@param x number
---@param label string
---@param value string
function View:addStat(id, x, label, value)
	local scale = self.width / 1366
	x = x * scale
	self.statTable:addChild(id .. "Bg", Rectangle({
		x = x, y = 20,
		width = 110 * scale,
		height = 45,
		color = { 0.16, 0.16, 0.16, 1 },
		z = 0.01
	}))

	self.statTable:addChild(id .. "label", Label({
		x = x,
		boxWidth = 110 * scale,
		alignX = "center",
		alignY = "center",
		font = self.fonts:loadFont("Bold", 15),
		text = label,
		shadow = true,
		z = 0.02,
	}))

	self.statTable:addChild(id .. "value", Label({
		x = x, y = 20,
		boxWidth = 110 * scale,
		boxHeight = 45,
		alignX = "center",
		alignY = "center",
		font = self.fonts:loadFont("Regular", 15),
		text = value,
		shadow = true,
		z = 0.02,
	}))
end

---@param msd osu.ui.Msd
---@param time_rate number
---@param key_mode string
function View:addMsdTable(msd, time_rate, key_mode)
	local scale = self.width / 1366
	local w = 75 * scale
	local order = msd:getOrderedByPattern(time_rate)

	for i, kv in ipairs(order) do
		local value = kv[2]
		local label = msd.simplifyName(kv[1], key_mode)

		local x = ((i - 1) * (w + 2)) * scale
		self.msdTable:addChild(label .. "Bg", Rectangle({
			x = x, y = 20,
			width = w,
			height = 36,
			color = { 0.16, 0.16, 0.16, 1 },
			z = 0.01
		}))

		self.msdTable:addChild(label .. "label", Label({
			x = x,
			boxWidth = w,
			alignX = "center",
			alignY = "center",
			font = self.fonts:loadFont("Bold", 15),
			text = label,
			shadow = true,
			z = 0.02,
		}))

		self.msdTable:addChild(label .. "value", Label({
			x = x, y = 20,
			boxWidth = w,
			boxHeight = 36,
			alignX = "center",
			alignY = "center",
			font = self.fonts:loadFont("Regular", 15),
			text = tostring(value),
			shadow = true,
			z = 0.02,
		}))
	end
end

---@param id string
---@param x number
---@param label string
---@param value string
function View:addBeatmapInfo(id, x, label, value)
	local scale = self.width / 1366
	x = x * scale
	self.beatmapInfoTable:addChild(id .. "Bg", Rectangle({
		x = x, y = 20,
		width = 110 * scale,
		height = 36,
		color = { 0.16, 0.16, 0.16, 1 },
		z = 0.01
	}))

	self.beatmapInfoTable:addChild(id .. "label", Label({
		x = x,
		boxWidth = 110 * scale,
		alignX = "center",
		alignY = "center",
		font = self.fonts:loadFont("Bold", 15),
		text = label,
		shadow = true,
		z = 0.02,
	}))

	self.beatmapInfoTable:addChild(id .. "value", Label({
		x = x, y = 20,
		boxWidth = 110 * scale,
		boxHeight = 36,
		alignX = "center",
		alignY = "center",
		font = self.fonts:loadFont("Regular", 15),
		text = value,
		shadow = true,
		z = 0.02,
	}))
end

return View
