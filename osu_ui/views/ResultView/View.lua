local Container = require("osu_ui.ui.Container")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local ui = require("osu_ui.ui")
local Label = require("osu_ui.ui.Label")
local Image = require("osu_ui.ui.Image")
local ImageButton = require("osu_ui.ui.ImageButton")
local ImageValueView = require("osu_ui.ui.ImageValueView")
local Button = require("osu_ui.ui.Button")
local BackButton = require("osu_ui.ui.BackButton")
local HpGraph = require("osu_ui.views.ResultView.HpGraph")

---@class osu.ui.ResultViewContainer : osu.ui.Container
---@operator call: osu.ui.ResultViewContainer
local View = Container + {}

local gfx = love.graphics

---@param result_view osu.ui.ResultView
function View:load(result_view)
	local display_info = result_view.displayInfo
	local assets = result_view.assets
	local img = assets.images
	local snd = assets.sounds

	local text, font = assets.localization:get("result")
	assert(text and font)

	---- HEADER ----
	self:addChild("headerBackground", Container.drawFunction(function ()
		gfx.setColor(0, 0, 0, 0.8)
		gfx.rectangle("fill", 0, 0, ui.layoutW, 96)
	end, 0.95))

	self:addChild("chartName", Label(assets, {
		text = display_info.chartName,
		font = font.title,
		depth = 1,
		transform = love.math.newTransform(5, 0)
	}))

	self:addChild("chartSource", Label(assets, {
		text = display_info.chartSource,
		font = font.creator,
		depth = 1,
		transform = love.math.newTransform(5, 33)
	}))

	self:addChild("playInfo", Label(assets, {
		text = display_info.playInfo,
		font = font.playInfo,
		depth = 1,
		transform = love.math.newTransform(5, 54)
	}))

	self:addChild("titleImage", Image({
		image = img.title,
		ox = 1,
		depth = 0.98,
		transform = love.math.newTransform(ui.layoutW - 32, 0)
	}))

	local area = self:addChild("scrollArea", ScrollAreaContainer(nil, nil, 768 / 2, 1368, 768 * 2))

	---- PANEL ----
	area:addChild("statsPanel", Image({ image = img.panel, depth = 0.5, transform = love.math.newTransform(0, 102) }))

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

	area:addChild("score", ImageValueView({
		files = score_font,
		overlap = overlap,
		align = "center",
		format = "%08d",
		oy = 0.5,
		scale = 1.3,
		depth = 0.55,
		transform = love.math.newTransform(score_x, score_y),
	}, function ()
		return math.ceil(result_view.scoreReveal * display_info.score)
	end))

	area:addChild("marvelousImage", Image({
		image = img.judgeMarvelous,
		ox = 0.5,
		oy = 0.5,
		depth = 0.54,
		transform = love.math.newTransform(img_x2, row1, 0, 0.5, 0.5)
	}))

	area:addChild("marvelousCount", ImageValueView({
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		oy = 0.5,
		scale = 1.1,
		depth = 0.55,
		transform = love.math.newTransform(text_x2, row1),
	}, function ()
		return math.ceil(result_view.scoreReveal * display_info.marvelous)
	end))

	area:addChild("perfectImage", Image({
		image = img.judgePerfect,
		ox = 0.5,
		oy = 0.5,
		depth = 0.54,
		transform = love.math.newTransform(img_x1, row1, 0, 0.5, 0.5)
	}))

	area:addChild("perfectCount", ImageValueView({
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		oy = 0.5,
		scale = 1.1,
		depth = 0.55,
		transform = love.math.newTransform(text_x1, row1),
	}, function ()
		return math.ceil(result_view.scoreReveal * display_info.perfect)
	end))

	if display_info.great then
		area:addChild("greatImage", Image({
			image = img.judgeGreat,
			ox = 0.5,
			oy = 0.5,
			depth = 0.54,
			transform = love.math.newTransform(img_x1, row2, 0, 0.5, 0.5)
		}))

		area:addChild("greatCount", ImageValueView({
			files = score_font,
			overlap = overlap,
			format = judge_format,
			align = "left",
			oy = 0.5,
			scale = 1.1,
			depth = 0.55,
			transform = love.math.newTransform(text_x1, row2),
		}, function ()
			return math.ceil(result_view.scoreReveal * display_info.great)
		end))
	end

	if display_info.good then
		area:addChild("goodImage", Image({
			image = img.judgeGood,
			ox = 0.5,
			oy = 0.5,
			depth = 0.54,
			transform = love.math.newTransform(img_x2, row2, 0, 0.5, 0.5)
		}))

		area:addChild("goodCount", ImageValueView({
			files = score_font,
			overlap = overlap,
			format = judge_format,
			align = "left",
			oy = 0.5,
			scale = 1.1,
			depth = 0.55,
			transform = love.math.newTransform(text_x2, row2),
		}, function ()
			return math.ceil(result_view.scoreReveal * display_info.good)
		end))
	end

	if display_info.bad then
		area:addChild("badImage", Image({
			image = img.judgeBad,
			ox = 0.5,
			oy = 0.5,
			depth = 0.54,
			transform = love.math.newTransform(img_x1, row3, 0, 0.5, 0.5)
		}))

		area:addChild("badCount", ImageValueView({
			files = score_font,
			overlap = overlap,
			format = judge_format,
			align = "left",
			oy = 0.5,
			scale = 1.1,
			depth = 0.55,
			transform = love.math.newTransform(text_x1, row3),
		}, function ()
			return math.ceil(result_view.scoreReveal * display_info.bad)
		end))
	end

	area:addChild("missImage", Image({
		image = img.judgeMiss,
		ox = 0.5,
		oy = 0.5,
		depth = 0.54,
		transform = love.math.newTransform(img_x2, row3, 0, 0.5, 0.5)
	}))

	area:addChild("missCount", ImageValueView({
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		oy = 0.5,
		scale = 1.1,
		depth = 0.55,
		transform = love.math.newTransform(text_x2, row3),
	}, function ()
		return math.ceil(result_view.scoreReveal * display_info.miss)
	end))

	area:addChild("combo", ImageValueView({
		files = score_font,
		overlap = overlap,
		format = judge_format,
		align = "left",
		oy = 0.5,
		scale = 1.1,
		depth = 0.55,
		transform = love.math.newTransform(combo_x, combo_y),
	}, function ()
		return math.ceil(result_view.scoreReveal * display_info.combo)
	end))

	area:addChild("accuracy", ImageValueView({
		files = score_font,
		overlap = overlap,
		format = "%0.02f%%",
		align = "left",
		multiplier = 100,
		oy = 0.5,
		scale = 1.1,
		depth = 0.55,
		transform = love.math.newTransform(acc_x, acc_y),
	}, function ()
		return result_view.scoreReveal * display_info.accuracy
	end))

	area:addChild("comboText", Image({ image = img.maxCombo, depth = 0.54, transform = love.math.newTransform(8, 480)}))
	area:addChild("accuracyText", Image({ image = img.accuracy, depth = 0.54, transform = love.math.newTransform(291, 480)}))

	---- GRAPH ----
	local score_system = result_view.game.rhythmModel.scoreEngine.scoreSystem
	area:addChild("graph", Image({ image = img.graph, depth = 0.5, transform = love.math.newTransform(256, 608)}))
	area:addChild("hpGraph", HpGraph({
		w = 300,
		h = 135,
		points = score_system.sequence,
		hpScoreSystem = score_system.hp,
		depth = 0.55,
		transform = love.math.newTransform(265, 617)
	}))

	---- GRADE ----
	local overlay_rotation = 0
	local overlay = area:addChild("backgroundOverlay", Image({
		image = img.backgroundOverlay,
		ox = 0.5,
		oy = 0.5,
		depth = 0,
		transform = love.math.newTransform(ui.layoutW - 200, 320)
	}))
	function overlay:updateTransform()
		overlay_rotation = (overlay_rotation + love.timer.getDelta() * 0.5) % (math.pi * 2)
		self.transform:rotate(overlay_rotation)
	end

	local grade = area:addChild("grade", Image({
		image = img["grade" .. display_info.grade],
		ox = 0.5,
		oy = 0.5,
		depth = 0.5,
		transform = love.math.newTransform(ui.layoutW - 192, 320)
	}))
	function grade:updateTransform()
		local additional_s = (1 - result_view.scoreReveal) * 0.2
		self.transform:scale(1 + additional_s, 1 + additional_s)
	end

	---- BUTTONS ----
	area:addChild("retryButton", ImageButton(assets, {
		idleImage = img.retry,
		ox = 1,
		oy = 0.5,
		hoverArea = { w = 380, h = 95 },
		clickSound = assets.sounds.menuHit,
		alpha = 0.5,
		depth = 0.6,
		transform = love.math.newTransform(ui.layoutW, 576)
	}, function()
		result_view:play("retry")
	end))

	area:addChild("watchReplayButton", ImageButton(assets, {
		idleImage = img.replay,
		ox = 1,
		oy = 0.5,
		hoverArea = { w = 380, h = 95 },
		clickSound = assets.sounds.menuHit,
		alpha = 0.5,
		depth = 0.6,
		transform = love.math.newTransform(ui.layoutW, 672)
	}, function()
		result_view:play("replay")
	end))

	---- FAKE BUTTONS ----
	self:addChild("showChat", ImageButton(assets, {
		idleImage = img.overlayChat,
		ox = 1,
		oy = 1,
		hoverArea = { w = 89, h = 22 },
		depth = 0.4,
		transform = love.math.newTransform(ui.layoutW - 3, ui.layoutH + 1)
	},  function ()
		result_view.notificationView:show("Not implemented")
	end))

	self:addChild("onlineUsers", ImageButton(assets, {
		idleImage = img.overlayOnline,
		ox = 1,
		oy = 1,
		hoverArea = { w = 89, h = 22 },
		alpha = 0.5,
		depth = 0.4,
		transform = love.math.newTransform(ui.layoutW - 99, ui.layoutH + 1)
	},  function ()
		result_view.notificationView:show("Not implemented")
	end))

	area:addChild("onlineRanking", Button(assets, {
		text = "▼ Online Ranking ▼",
		font = font.onlineRanking,
		pixelWidth = 320,
		pixelHeight = 48,
		color = { 0.46, 0.09, 0.8, 1 },
		depth = 0.95,
		transform = love.math.newTransform(ui.layoutW / 2 - 160, ui.layoutH - 41.6)
	}, function ()
		result_view.notificationView:show("Not implemented")
	end))

	area:addChild("backButton", BackButton(assets, {
		hoverArea = { w = 93, h = 90 },
		depth = 1,
		transform = love.math.newTransform(0, ui.layoutH - 58)
	}, function ()
		result_view:quit()
	end))

	local customizations = assets.customViews.resultView
	if customizations then
		local success, error = pcall(customizations, assets, display_info, self)
		if not success then
			result_view.popupView:add(error, "error")
		end
	end

	self:sortChildren()
	area:sortChildren()
end

return View
