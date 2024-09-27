local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.OsuLayout")

local Combo = require("osu_ui.ui.Combo")
local BackButton = require("osu_ui.ui.BackButton")

local ui = require("osu_ui.ui")
local gfx_util = require("gfx_util")
local map = require("math_util").map

local ViewConfig = IViewConfig + {}

local gfx = love.graphics

---@param view osu.ui.PlayerStatsView
function ViewConfig:new(view)
	self.view = view
	self.assets = view.assets
	self.username = view.game.configModel.configs.online.user.name or "Guest"
	self:createUI(view)
end

---@param view osu.ui.PlayerStatsView
function ViewConfig:createUI(view)
	local assets = self.assets
	local text, font = self.assets.localization:get("playerStats")
	assert(text and font)
	self.text, self.font = text, font

	self.backButton = BackButton(assets, { w = 93, h = 90 }, function()
		view:quit()
	end)

	self.typeCombo = Combo(assets, {
		font = font.dropdown,
		pixelWidth = 200,
		pixelHeight = 34,
		borderColor = { 0.57, 0.76, 0.9, 1 },
		hoverColor = { 0.57, 0.76, 0.9, 1 },
	}, function()
		return view.selectedDanType, view.dansInfo.types[view.selectedKeymode]
	end, function(v)
		view.selectedDanType = v
		view:createDanTableList()
	end, function (v)
		if v == "regular" then
			return "Regular"
		end
		return "Long note"
	end)
end

local parallax = 0.01
function ViewConfig:background()
	gfx.push()
	gfx.origin()
	local w, h = gfx.getDimensions()
	local mx, my = love.mouse.getPosition()
	local img = self.assets.images.background
	gfx.setColor(0.7, 0.7, 0.7)
	gfx_util.drawFrame(
		img,
		-map(mx, 0, w, parallax, 0) * w,
		-map(my, 0, h, parallax, 0) * h,
		(1 + 2 * parallax) * w,
		(1 + 2 * parallax) * h,
		"out"
	)
	gfx.pop()
end

function ViewConfig:activity(w, h)
	gfx.push()
	local view = self.view
	local activity_view = view.activityView
	gfx.translate(w, h)
	gfx.setColor(1, 1, 1)

	local img = self.assets.images.activityBackground
	gfx.draw(img, 0, 0, 0, 1, 1, img:getDimensions())

	gfx.translate(-activity_view.totalW - 15, -activity_view.totalH - 10)

	view.cursor.alpha = 1
	if activity_view:checkMousePos(love.mouse.getPosition()) then
		view.cursor.alpha = 0.2
	end

	activity_view:draw()
	gfx.pop()
end

function ViewConfig:activityTooltip(w, h)
	gfx.push()
	local activity = self.view.activityView
	local tw, th = activity.totalW, activity.totalH

	gfx.translate(w - tw - 15, h - th - 15 - 200)

	if activity.activeTooltip then
		gfx.setFont(self.font.activity)
		ui.frame(activity.activeTooltip, 4, -18, tw, 200, "left", "bottom")
	end
	gfx.pop()
end

local dan_table_w, dan_table_h = 370, 423

function ViewConfig:danTable(w, h)
	gfx.push()
	gfx.translate(0, 86)
	local img = self.assets.images.danClearsBackground
	gfx.setColor(1, 1, 1)
	gfx.draw(img, w, 0, 0, 1, 1, img:getWidth())

	gfx.push()
	gfx.translate(w - dan_table_w, 70)
	local dan_table = self.view.danTableView
	dan_table:update(dan_table_w, dan_table_h)
	dan_table:draw(dan_table_w, dan_table_h)
	gfx.pop()

	local overlay = self.assets.images.danClearsOverlay
	gfx.setColor(1, 1, 1)
	gfx.draw(overlay, w, 0, 0, 1, 1, overlay:getWidth())

	gfx.push()
	gfx.translate(w - 200, 15)
	self.typeCombo:update(true)
	self.typeCombo:drawBody()
	gfx.pop()
	gfx.pop()
end

function ViewConfig:userInfo(w, h)
	gfx.push()
	gfx.setColor(0, 0, 0, 0.4)
	gfx.rectangle("fill", 0, 0, w, 86)
	gfx.translate(6, 6)

	local overall_stats = self.view.overallStats
	local avatar = self.assets.images.avatar
	local font = self.font

	local iw, ih = avatar:getDimensions()
	gfx.setColor(1, 1, 1)
	gfx.draw(avatar, 0, 0, 0, 74 / iw, 74 / ih)

	gfx.setFont(font.rank)
	gfx.setColor( 1, 1, 1, 0.17)
	ui.frame(("#%i"):format(overall_stats.rank), -1, 10, 322, 78, "right", "top")

	gfx.translate(80, -4)

	gfx.setColor(1, 1, 1)
	gfx.setFont(font.username)
	ui.text(self.username)
	gfx.setFont(font.belowUsername)
	ui.text(("Playing since: %s\nKeys pressed: %s\nLv%i"):format(overall_stats.profileCreationDate, overall_stats.keysPressed, overall_stats.level))

	gfx.translate(40, 26)

	gfx.setColor(0.15, 0.15, 0.15, 1)
	gfx.rectangle("fill", 0, 0, 197, 10, 8, 8)

	gfx.setLineWidth(1)

	local level_percent = overall_stats.levelProgress
	if level_percent > 0.03 then
		gfx.setColor(0.83, 0.65, 0.17, 1)
		gfx.rectangle("fill", 0, 0, 196 * level_percent, 10, 8, 8)
		gfx.rectangle("line", 0, 1, 196 * level_percent, 8, 6, 6)
	end

	gfx.setColor(0.4, 0.4, 0.4, 1)
	gfx.rectangle("line", 0, 0, 197, 10, 6, 6)

	gfx.pop()
end

function ViewConfig:overallStats(w, h)
	gfx.push()
	gfx.translate(5, 100)
	local stats = self.view.overallStats

	gfx.setColor(1, 1, 1)
	gfx.setFont(self.font.stats)
	ui.text("Total statistics:")
	ui.text(("Charts played: %s"):format(stats.chartsPlayed))
	ui.text(("Time played: %s"):format(os.date("%H hours %M minutes", stats.timePlayed))) ---TODO: shows incorrect time
	ui.text(("Etterna J4 accuracy: %0.02f%%"):format(stats.etternaAccuracy * 100))
	ui.text(("osu!mania V1 accuracy: %0.02f%%"):format(stats.osuv1Accuracy * 100))
	ui.text(("osu!mania V2 accuracy: %0.02f%%"):format(stats.osuv2Accuracy * 100))
	gfx.pop()
end

function ViewConfig:modeStats(w, h)
	gfx.push()
	local stats = self.view.modeStats
	gfx.translate(5, 400)
	gfx.setColor(1, 1, 1)
	gfx.setFont(self.font.stats)

	ui.text(("%s statistics:"):format(self.view.selectedKeymode))
	ui.text(("Perfomance points: %i"):format(stats.pp))
	ui.text(("Avg. Star rating: %0.2f*"):format(stats.avgStarRate))
	ui.text(("Avg. ENPS: %0.2f"):format(stats.avgEnps))
	ui.text(("Avg. BPM: %i"):format(stats.avgTempo))

	gfx.pop()
end

function ViewConfig:draw()
	local w, h = Layout:move("base")
	self:background()
	self:userInfo(w, h)
	self:overallStats(w, h)
	self:modeStats(w, h)
	self:activity(w, h)
	self:activityTooltip(w, h)
	self:danTable(w, h)

	gfx.push()
	gfx.translate(0, h - 58)
	self.backButton:update(true)
	self.backButton:draw()
	gfx.pop()
end

return ViewConfig
