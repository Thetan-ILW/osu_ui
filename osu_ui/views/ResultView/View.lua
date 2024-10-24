local Container = require("osu_ui.ui.Container")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local math_util = require("math_util")
local ImageButton = require("osu_ui.ui.ImageButton")
local ImageValueView = require("osu_ui.ui.ImageValueView")
local Button = require("osu_ui.ui.Button")
local BackButton = require("osu_ui.ui.BackButton")
local HpGraph = require("osu_ui.views.ResultView.HpGraph")

local Rectangle = require("osu_ui.ui.Rectangle")
local Image = require("osu_ui.ui.Image")
local Label = require("osu_ui.ui.Label")
local ScrollBar = require("osu_ui.ui.ScrollBar")

---@class osu.ui.ResultViewContainer : osu.ui.Container
---@operator call: osu.ui.ResultViewContainer
---@field resultView osu.ui.ResultView
local View = Container + {}

function View:load()
	Container.load(self)
	local result_view = self.resultView
	local display_info = result_view.displayInfo
	local assets = result_view.assets
	local img = assets.images
	local snd = assets.sounds

	local all_fonts = assets.localization.fontGroups
	local text, font = assets.localization:get("result")
	assert(text and font)

	local width, height = self.parent.totalW, self.parent.totalH
	local newTransform = love.math.newTransform

	local area = self:addChild("scrollArea", ScrollAreaContainer({
		scrollLimit = 768,
		width = width,
		height = height * 2
	}))
	---@cast area osu.ui.ScrollAreaContainer

	self:addChild("scrollBar", ScrollBar({
		x = width - 13, y = 99,
		totalW = 10,
		container = area,
		windowHeight = 768 - 96 - 6,
		blockMouseFocus = false,
		depth = 1,
	}))

	---- HEADER ----
	self:addChild("headerBackground", Rectangle({
		totalW = width,
		totalH = 96,
		color = { 0, 0, 0, 0.8 },
		blockMouseFocus = false,
		depth = 0.9
	}))

	self:addChild("chartName", Label( {
		x = 5,
		text = display_info.chartName,
		font = font.title,
		depth = 1,
	}))

	self:addChild("chartSource", Label({
		x = 5, y = 33,
		text = display_info.chartSource,
		font = font.creator,
		depth = 1,
	}))

	self:addChild("playInfo", Label({
		x = 5, y = 54,
		text = display_info.playInfo,
		font = font.playInfo,
		depth = 1,
	}))

	self:addChild("titleImage", Image({
		x = width - 32,
		origin = { x = 1, y = 0 },
		image = img.title,
		depth = 0.98,
	}))

	---- PANEL ----
	area:addChild("statsPanel", Image({
		y = 102,
		image = img.panel,
		depth = 0.5,
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

	local combo_x = text_x1 - 65 * ppy
	local combo_y = row4 + 38
	local acc_x = text_x2 - 86 * ppy
	local acc_y = row4 + 38

	local overlap = assets.params.scoreOverlap
	local score_font = assets.imageFonts.scoreFont
	local judge_format = "%ix"
	---@cast overlap number

	area:addChild("score", ImageValueView({
		x = score_x, y = score_y,
		origin = { x = 0.5, y = 0.5 },
		scale = 1.3,
		files = score_font,
		overlap = overlap,
		align = "center",
		format = "%08d",
		depth = 0.55,
		value = function ()
			return math.ceil(result_view.scoreReveal * display_info.score)
		end
	}))

	area:addChild("marvelousImage", Image({
		x = img_x2, y = row1,
		origin = { x = 0.5, y = 0.5 },
		scale = 0.5,
		image = img.judgeMarvelous,
		depth = 0.54,
	}))

	area:addChild("marvelousCount", ImageValueView({
		x = text_x2, y = row1,
		origin = { x = 0, y = 0.5 },
		scale = 1.1,
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		depth = 0.55,
		value = function ()
			return math.ceil(result_view.scoreReveal * display_info.marvelous)
		end
	}))

	area:addChild("perfectImage", Image({
		x = img_x1, y = row1,
		origin = { x = 0.5, y = 0.5 },
		scale = 0.5,
		image = img.judgePerfect,
		depth = 0.54,
		transform = newTransform(img_x1, row1)
	}))

	area:addChild("perfectCount", ImageValueView({
		x = text_x1, y = row1,
		origin = { x = 0, y = 0.5 },
		scale = 1.1,
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		depth = 0.55,
		value = function ()
			return math.ceil(result_view.scoreReveal * display_info.perfect)
		end
	}))

	if display_info.great then
		area:addChild("greatImage", Image({
			x = img_x1, y = row2,
			origin = { x = 0.5, y = 0.5 },
			scale = 0.5,
			image = img.judgeGreat,
			depth = 0.54,
		}))

		area:addChild("greatCount", ImageValueView({
			x = text_x1, y = row2,
			origin = { x = 0, y = 0.5 },
			scale = 1.1,
			files = score_font,
			overlap = overlap,
			format = judge_format,
			align = "left",
			depth = 0.55,
			value = function ()
				return math.ceil(result_view.scoreReveal * display_info.great)
			end
		}))
	end

	if display_info.good then
		area:addChild("goodImage", Image({
			x = img_x2, y = row2,
			origin = { x = 0.5, y = 0.5 },
			scale = 0.5,
			image = img.judgeGood,
			depth = 0.54,
		}))

		area:addChild("goodCount", ImageValueView({
			x = text_x2, y = row2,
			origin = { x = 0, y = 0.5 },
			scale = 1.1,
			files = score_font,
			overlap = overlap,
			format = judge_format,
			align = "left",
			depth = 0.55,
			value = function ()
				return math.ceil(result_view.scoreReveal * display_info.good)
			end
		}))
	end

	if display_info.bad then
		area:addChild("badImage", Image({
			x = img_x1, y = row3,
			origin = { x = 0.5, y = 0.5 },
			scale = 0.5,
			image = img.judgeBad,
			depth = 0.54,
		}))

		area:addChild("badCount", ImageValueView({
			x = text_x1, y = row3,
			origin = { x = 0, y = 0.5 },
			files = score_font,
			overlap = overlap,
			format = judge_format,
			align = "left",
			depth = 0.55,
			value = function ()
				return math.ceil(result_view.scoreReveal * display_info.bad)
			end
		}))
	end

	area:addChild("missImage", Image({
		x = img_x2, y = row3,
		origin = { x = 0.5, y = 0.5 },
		scale = 0.5,
		image = img.judgeMiss,
		depth = 0.54,
	}))

	area:addChild("missCount", ImageValueView({
		x = text_x2, y = row3,
		origin = { x = 0, y = 0.5 },
		depth = 0.55,
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		scale = 1.1,
		value = function ()
			return math.ceil(result_view.scoreReveal * display_info.miss)
		end
	}))

	area:addChild("combo", ImageValueView({
		x = combo_x, y = combo_y,
		origin = { x = 0, y = 0.5 },
		scale = 1.1,
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		depth = 0.55,
		value = function ()
			return math.ceil(result_view.scoreReveal * display_info.combo)
		end
	}))

	area:addChild("accuracy", ImageValueView({
		x = acc_x , y = acc_y,
		origin = { x = 0, y = 0.5 },
		scale = 1.1,
		files = score_font,
		overlap = overlap,
		format = "%0.02f%%",
		align = "left",
		multiplier = 100,
		depth = 0.55,
		value = function ()
			return result_view.scoreReveal * display_info.accuracy
		end
	}))

	area:addChild("comboText", Image({ x = 8, y = 480, image = img.maxCombo, depth = 0.54 }))
	area:addChild("accuracyText", Image({ x = 291, y = 480, image = img.accuracy, depth = 0.54 }))

	---- GRAPH ----
	local score_system = result_view.game.rhythmModel.scoreEngine.scoreSystem
	area:addChild("graph", Image({ x = 256, y = 608, image = img.graph, depth = 0.5 }))

	if score_system.sequence then
		area:addChild("hpGraph", HpGraph({
			x = 265, y = 617,
			totalW = 300,
			totalH = 135,
			points = score_system.sequence,
			hpScoreSystem = score_system.hp,
			depth = 0.55,
		}))
	end

	---- GRADE ----
	local overlay = area:addChild("backgroundOverlay", Image({
		x = width - 200, y = 320,
		origin = { x = 0.5, y = 0.5 },
		image = img.backgroundOverlay,
		depth = 0,
	}))
	function overlay:update(dt)
		Image.update(overlay, dt)
		overlay.rotation = (overlay.rotation + love.timer.getDelta() * 0.5) % (math.pi * 2)
		overlay:applyTransform()
	end

	local grade = area:addChild("grade", Image({
		x = width - 192, y = 320,
		origin = { x = 0.5, y = 0.5 },
		image = img["grade" .. display_info.grade],
		depth = 0.5,
	}))
	function grade:update(dt)
		Image.update(self, dt)
		grade.scale = 1 + (1 - result_view.scoreReveal) * 0.2
		grade:applyTransform()
	end

	---- BUTTONS ----
	area:addChild("retryButton", ImageButton({
		x = width, y = 576,
		origin = { x = 1, y = 0.5 },
		hoverWidth = 380,
		hoverHeight = 95,
		idleImage = img.retry,
		clickSound = assets.sounds.menuHit,
		alpha = 0.5,
		depth = 0.6,
		onClick = function()
			result_view:play("retry")
		end
	}))

	area:addChild("watchReplayButton", ImageButton({
		x = width, y = 672,
		origin = { x = 1, y = 0.5 },
		hoverWidth = 380,
		hoverHeight = 95,
		idleImage = img.replay,
		clickSound = assets.sounds.menuHit,
		alpha = 0.5,
		depth = 0.6,
		onClick = function ()
			result_view:play("replay")
		end
	}))

	---- FAKE BUTTONS ----
	self:addChild("showChat", ImageButton({
		x = width - 3, y = height + 1,
		origin = { x = 1, y = 1 },
		idleImage = img.overlayChat,
		depth = 0.4,
		onClick = function ()
			result_view.notificationView:show("Not implemented")
		end
	}))

	self:addChild("onlineUsers", ImageButton({
		x = width - 99, y = height + 1,
		origin = { x = 1, y = 1 },
		idleImage = img.overlayOnline,
		alpha = 0.5,
		depth = 0.4,
		onClick = function ()
			result_view.notificationView:show("Not implemented")
		end
	}))

	local online_ranking = area:addChild("onlineRanking", Button({
		x = width / 2 - 160, y = height - 41.6,
		text = "▼ Online Ranking ▼",
		font = font.onlineRanking,
		totalW = 320,
		totalH = 48,
		color = { 0.46, 0.09, 0.8, 1 },
		imageLeft = img.buttonLeft,
		imageMiddle = img.buttonMiddle,
		imageRight = img.buttonRight,
		depth = 0.95,
		onClick = function ()
			area:scrollToPosition(768, 0)
		end
	}))
	---@cast online_ranking osu.ui.Button
	function online_ranking:update(dt)
		Button.update(self, dt)
		local position = area.scrollPosition
		local alpha = 1 - math_util.clamp((position / area.totalH * 16), 0, 1)
		self.color[4] = alpha
	end

	area:addChild("backButton", BackButton({
		y = height - 58,
		font = all_fonts.misc.backButton,
		text = "back",
		arrowImage = img.menuBackArrow,
		clickSound = snd.menuBack,
		hoverSound = snd.hoverOverRect,
		hoverWidth = 93,
		hoverHeight = 58,
		depth = 1,
		onClick = function ()
			result_view:quit()
		end
	}))

	area:build()
	self:build()
	if true then
		return
	end

	local customizations = assets.customViews.resultView
	if customizations then
		local success, error = pcall(customizations, assets, display_info, self)
		if not success then
			result_view.popupView:add(error, "error")
		end
	end
end

return View
