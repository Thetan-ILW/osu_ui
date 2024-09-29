local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.OsuLayout")

local ImageButton = require("osu_ui.ui.ImageButton")
local Combo = require("osu_ui.ui.Combo")
local BackButton = require("osu_ui.ui.BackButton")

local ui = require("osu_ui.ui")
local gfx_util = require("gfx_util")
local map = require("math_util").map
local Format = require("sphere.views.Format")

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
		borderColor = { 0.68, 0.82, 0.54, 1 },
		hoverColor = { 0.68, 0.82, 0.54, 1 },
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

	self.modeCombo = Combo(assets, {
		font = font.dropdown,
		pixelWidth = 200,
		pixelHeight = 34,
		borderColor = { 0.57, 0.76, 0.9, 1 },
		hoverColor = { 0.57, 0.76, 0.9, 1 },
	}, function ()
		return view.selectedKeymode, view.dansInfo.modes
	end, function (v)
		view.selectedKeymode = v
		view:updateModeInfo()
	end, function (v)
		return Format.inputMode(v)
	end)

	local img = assets.images

	self.selectProfileButton = ImageButton(assets, {
		idleImage = img.profileSelect,
		hoverImage = img.profileSelectOver,
		oy = 1,
		hoverArea = { w = 88, h = 90 },
	}, function ()
		view.notificationView:show("Not implemented")
	end)

	self.displayOptionsButton = ImageButton(assets, {
		idleImage = img.profileDisplayOptions,
		hoverImage = img.profileDisplayOptionsOver,
		oy = 1,
		hoverArea = { w = 74, h = 90 },
	}, function ()
		view.notificationView:show("Not implemented")
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

local dan_table_w, dan_table_h = 370, 430

function ViewConfig:danTable(w, h)
	gfx.push()
	gfx.translate(0, 89)
	local img = self.assets.images.danClearsBackground
	gfx.setColor(1, 1, 1)
	gfx.draw(img, w, 0, 0, 1, 1, img:getWidth())

	gfx.push()
	gfx.translate(w - dan_table_w - 10, 75)
	local dan_table = self.view.danTableView
	dan_table:update(dan_table_w, dan_table_h)
	dan_table:draw(dan_table_w, dan_table_h)
	gfx.pop()

	local overlay = self.assets.images.danClearsOverlay
	gfx.setColor(1, 1, 1)
	gfx.draw(overlay, w, 0, 0, 1, 1, overlay:getWidth())
	gfx.pop()
end

function ViewConfig:header(w, h)
	gfx.push()
	gfx.setColor(0, 0, 0, 0.4)
	gfx.rectangle("fill", 0, 0, w, 86)

	gfx.setColor(1, 1, 1, 0.8)
	ui.frame(("Top regular: %s | Top LN: %s"):format(self.view.regularDan, self.view.lnDan), -15, 7, w, h, "right", "top")

	gfx.translate(w - 200, 40)
	gfx.push()
	self.typeCombo:update(true)
	self.typeCombo:drawBody()
	gfx.pop()

	gfx.translate(-self.font.textNearDropdown:getWidth("Dan type") * ui.getTextScale(), 0)
	gfx.setFont(self.font.textNearDropdown)
	gfx.setColor(0.68, 0.82, 0.54)
	gfx.push()
	ui.text("Dan type")
	gfx.pop()

	gfx.translate(-self.modeCombo:getWidth(), 0)
	gfx.push()
	self.modeCombo:update(true)
	self.modeCombo:drawBody()
	gfx.pop()

	gfx.translate(-self.font.textNearDropdown:getWidth("Mode") * ui.getTextScale(), 0)
	gfx.setFont(self.font.textNearDropdown)
	gfx.setColor(0.57, 0.76, 0.9)
	ui.text("Mode")
	gfx.pop()
end

function ViewConfig:userInfo(w, h)
	gfx.push()
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
	gfx.push()

	gfx.translate(338, 6)

	local stats = self.view.overallStats
	gfx.setColor(1, 1, 1)
	gfx.setFont(self.font.headerInfo)
	ui.textWithShadow(("Total Performance Points: %i"):format(stats.pp)) ---TODO: add commas
	ui.textWithShadow(("Total Play Time: %s"):format(os.date("%H hours %M minutes", stats.timePlayed))) ---TODO: shows incorrect time
	ui.textWithShadow(("Play Count: %i"):format(stats.chartsPlayed))

	gfx.pop()
end

local key_value_w = 320
local function modeKeyValue(k, v)
	gfx.push()
	ui.text(k)
	gfx.pop()
	ui.text(v, key_value_w, "right")
end

function ViewConfig:modeStats(w, h)
	gfx.push()
	local stats = self.view.modeStats
	local ov_stats = self.view.overallStats
	gfx.translate(0, 89)
	gfx.setColor(1, 1, 1)

	gfx.draw(self.assets.images.profileModePanel)

	gfx.setFont(self.font.statsModeLargeText)
	gfx.translate(20, 14)
	ui.text(("%s STATISTICS"):format(Format.inputMode(self.view.selectedKeymode)), 320, "center")

	gfx.setFont(self.font.modeStats)
	gfx.translate(0, 3)
	modeKeyValue("Performance Points:", ("%i"):format(stats.pp))
	modeKeyValue("osu!mania V1 accuracy:", ("%0.02f%%"):format(ov_stats.osuv1Accuracy * 100))
	modeKeyValue("osu!mania V2 accuracy:", ("%0.02f%%"):format(ov_stats.osuv2Accuracy * 100))
	modeKeyValue("Etterna J4 accuracy:", ("%0.02f%%"):format(ov_stats.etternaAccuracy * 100))
	gfx.translate(0, 15)
	modeKeyValue("Avg. Star Rating:", ("%0.02f*"):format(stats.avgStarRate))
	modeKeyValue("Avg. ENPS:", ("%0.2f"):format(stats.avgEnps))
	modeKeyValue("Avg. BPM:", ("%i"):format(stats.avgTempo))

	gfx.pop()
end

local ssr_colors = {
	{ 0.25, 0.79, 0.90, 1 }, -- Easy (aqua)
	{ 0.24, 0.78, 0.17, 1 }, -- Normal (green)
	{ 0.89, 0.78, 0.22, 1 }, -- Hard (yellow)
	{ 0.91, 0.15, 0.32, 1 }, -- Instane (red)
	{ 0.97, 0.20, 0.26, 1 }, -- Expert (pink)
	{ 0.90, 0.15, 0.91, 1 }, -- Very Expert (very pink)
}

local ssr_ranges = {
	{ 0, 8 },
	{ 8, 15 },
	{ 15, 23 },
	{ 23, 29 },
	{ 29, 32 },
	{ 32, 36 },
}

---@param difficulty number
---@return table
local function getSsrColor(difficulty)
	local ranges = ssr_ranges

	local colorIndex = 1
	for i = #ranges, 1, -1 do
		local range = ranges[i]
		if difficulty >= range[1] then
			colorIndex = i
			break
		end
	end

	local lowerLimit, upperLimit
	if colorIndex == 1 then
		lowerLimit = 0
		upperLimit = ranges[1][2]
	elseif colorIndex == #ssr_colors then
		return ssr_colors[#ssr_colors]
	else
		lowerLimit, upperLimit = ranges[colorIndex][1], ranges[colorIndex][2]
	end

	local color1, color2 = ssr_colors[colorIndex], ssr_colors[colorIndex + 1]

	local mixingRatio = (difficulty - lowerLimit) / (upperLimit - lowerLimit)

	return {
		color1[1] * (1 - mixingRatio) + color2[1] * mixingRatio,
		color1[2] * (1 - mixingRatio) + color2[2] * mixingRatio,
		color1[3] * (1 - mixingRatio) + color2[3] * mixingRatio,
		1,
	}
end

local function ssrKeyValue(k, v)
	gfx.push()
	gfx.setColor(1, 1, 1)
	ui.text(k)
	gfx.pop()

	gfx.setColor(getSsrColor(v))
	ui.text(("%0.02f MSD"):format(v), 320, "right")
end

function ViewConfig:ssrTable(w, h)
	local stats = self.view.modeStats

	gfx.push()
	gfx.translate(0, h - 90)
	local panel = self.assets.images.profileSsrPanel
	gfx.draw(panel, 0, 0, 0, 1, 1, 0, panel:getHeight())
	gfx.pop()
	gfx.push()

	gfx.translate(20, 488)
	for i, k in ipairs(stats.patternNames) do
		ssrKeyValue(k:upper(), stats.patterns[k])
	end
	gfx.pop()
end

function ViewConfig:bottom(w, h)
	gfx.push()
	local bottom_img = self.assets.images.profilePanelBottom
	local iw, ih = bottom_img:getDimensions()
	gfx.translate(0, h - ih)
	gfx.draw(bottom_img, 0, 0, 0, w / iw, 1)

	gfx.pop()
	gfx.push()

	gfx.translate(224, h)
	self.selectProfileButton:update(true)
	self.selectProfileButton:draw()
	gfx.translate(92, 0)
	self.displayOptionsButton:update(true)
	self.displayOptionsButton:draw()
	gfx.pop()
end

function ViewConfig:modeIcon(w, h)
	gfx.push()
	local image = self.assets.images.maniaIcon
	local iw, ih = image:getDimensions()

	gfx.translate(w / 2 - iw / 2, h / 2 - ih / 2)
	gfx.setColor(1, 1, 1, 0.2)
	gfx.draw(image)
	gfx.pop()
end

function ViewConfig:draw()
	local w, h = Layout:move("base")
	self:background()
	self:modeIcon(w, h)
	self:modeStats(w, h)
	self:ssrTable(w, h)
	self:danTable(w, h)
	self:header(w, h)
	self:userInfo(w, h)
	self:bottom(w, h)
	self:activity(w, h)
	self:activityTooltip(w, h)

	gfx.push()
	gfx.translate(0, h - 58)
	self.backButton:update(true)
	self.backButton:draw()
	gfx.pop()
end

return ViewConfig
