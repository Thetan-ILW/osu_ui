local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.SelectViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.SelectViewConfig
---@field private assets osu.ui.OsuAssets
local ViewConfig = IViewConfig + {}

local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")
local time_util = require("time_util")
local math_util = require("math_util")
local table_util = require("table_util")
local Format = require("sphere.views.Format")

local getBeatValue = require("osu_ui.views.beat_value")
local getModifierString = require("osu_ui.views.modifier_string")

local ImageButton = require("osu_ui.ui.ImageButton")
local Combo = require("osu_ui.ui.Combo")
local BackButton = require("osu_ui.ui.BackButton")
local HoverState = require("osu_ui.ui.HoverState")
local TabButton = require("osu_ui.ui.TabButton")

local ScoreListView = require("osu_ui.views.SelectView.ScoreListView")

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@type table<string, love.Image>
local img
---@type table<string, audio.Source>
local snd

local gfx = love.graphics

---@type love.Image
local avatar
---@type love.Image
local top_panel_quad
---@type love.Shader
local brighten_shader

local has_focus = true
local combo_focused = false

local chart_name = ""
local charter_row = ""
local chart_is_dan = false
local this_dan_cleared = false
local length_str = ""
local bpm_str = ""
local objects_str = ""
local ln_count_str = ""
local note_count_str = ""
local columns_str = ""
local difficulty_str = ""
local od_str = ""
local hp_str = ""
local username = ""
local scroll_speed_str = ""
local mods_str = ""
local current_time = 0
local update_time = 0
local has_scores = false
local beat = 0

---@alias ScoreSource "local" | "online" | "osuv1" | "osuv2" | "etterna" | "quaver" 
---@type ScoreSource[]
local score_sources = {}
---@type ScoreSource
local score_source

---@type "circles" | "taiko" | "fruits" | "mania"
local selected_mode = "mania"
---@type {[string]: love.Image}
local small_icons
---@type osu.ui.HoverState
local player_profile_hover

local pp = 0
local accuracy = 0
local level = 0
local level_percent = 0
local rank = 0

local white = { 1, 1, 1, 1 }

local groupAlias = {}
local function formatGroupSort(s)
	return groupAlias[s] or ("You forgor " .. s)
end

local function setFormat()
	groupAlias = {
		charts = text.byCharts,
		locations = text.byLocations,
		directories = text.byDirectories,
		id = text.byId,
		title = text.byTitle,
		artist = text.byArtist,
		difficulty = text.byDifficulty,
		level = text.byLevel,
		duration = text.byDuration,
		bpm = text.byBpm,
		modtime = text.byModTime,
		["set modtime"] = text.bySetModTime,
		["last played"] = text.byLastPlayed,
	}
end

---@type osu.ui.BackButton?
local back_button
---@type osu.ui.HoverState
local osu_logo_button

---@type table<string, osu.ui.ImageButton>
local buttons = {}
---@type table<string, osu.ui.Combo>
local combos = {}

---@type {[string]: osu.ui.TabButton}
local tabs = {}

local ranking_options = {
	["local"] = "Local Ranking",
	online = "Online Ranking",
	osuv1 = "Local osu!mania V1",
	osuv2 = "Local osu!mania V2",
	etterna = "Local Etterna J4",
	quaver = "Local Quaver"
}

local function setScoreSource(v, configs)
	score_source = v
	configs.osu_ui.songSelect.scoreSource = v
	if v == "online" then
		configs.select.scoreSourceName = "online"
		return
	end
	configs.select.scoreSourceName = "local"
end

function ViewConfig:updateTabs()
	for i, v in pairs(tabs) do
		v.active = false
	end

	local select_config = self.view.game.configModel.configs.select
	local sort = select_config.sortFunction
	if self.view.lists.showing ~= "charts" then
		tabs.collections.active = true
	elseif sort == "last played" then
		tabs.recent.active = true
	elseif sort == "artist" then
		tabs.artist.active = true
	elseif sort == "difficulty" then
		tabs.difficulty.active = true
	else
		tabs.noGrouping.active = true
	end
end

---@param view osu.ui.SelectView
function ViewConfig:createUI(view)
	local assets = self.assets

	if assets.backButtonType == "image" then
		buttons.back = ImageButton(assets, {
			idleImage = img.menuBack,
			oy = 1,
			hoverArea = { w = 200, h = 90 },
			clickSound = assets.sounds.menuBack,
		}, function()
			view:quit(true)
		end)
	elseif assets.backButtonType == "animation" then
		buttons.back = ImageButton(assets, {
			animationImage = assets.animations.menuBack,
			framerate = assets.params.animationFramerate,
			oy = 1,
			hoverArea = { w = 200, h = 90 },
			clickSound = assets.sounds.menuBack,
		}, function()
			view:quit(true)
		end)
	else
		back_button = BackButton(assets, { w = 93, h = 90 }, function()
			view:quit(true)
		end)
	end

	buttons.mode = ImageButton(assets, {
		idleImage = img.modeButton,
		hoverImage = img.modeButtonOver,
		oy = 1,
		hoverArea = { w = 88, h = 90 },
	}, function()
		local s = selected_mode
		if s == "mania" then
			s = "circles"
		elseif s == "circles" then
			s = "taiko"
		elseif s == "taiko" then
			s = "fruits"
		else
			s = "mania"
		end
		selected_mode = s
	end)

	buttons.mods = ImageButton(assets, {
		idleImage = img.modsButton,
		hoverImage = img.modsButtonOver,
		oy = 1,
		hoverArea = { w = 74, h = 90 },
	}, function()
		view:openModal("osu_ui.views.modals.Modifiers")
	end)

	buttons.random = ImageButton(assets, {
		idleImage = img.randomButton,
		hoverImage = img.randomButtonOver,
		oy = 1,
		hoverArea = { w = 74, h = 90 },
	}, function()
		view.selectModel:scrollRandom()
		view.lists.list:followSelection()
	end)

	buttons.chartOptions = ImageButton(assets, {
		idleImage = img.optionsButton,
		hoverImage = img.optionsButtonOver,
		oy = 1,
		hoverArea = { w = 74, h = 90 },
	}, function()
		view:openModal("osu_ui.views.modals.ChartOptions")
	end)

	combos.scoreSource = Combo(assets, {
		font = font.dropdown,
		pixelWidth = 328,
		pixelHeight = 34,
		borderColor = { 0.08, 0.51, 0.7, 1 },
		hoverColor = { 0.08, 0.51, 0.7, 1 },
	}, function()
		return score_source, score_sources
	end, function(v)
		setScoreSource(v, view.game.configModel.configs)
		view.game.selectModel:pullScore()
		self.scoreListView:reloadItems(v)
	end, function(v)
		return ranking_options[v]
	end)

	local sort_model = view.game.selectModel.sortModel
	local select_config = view.game.configModel.configs.select

	combos.sort = Combo(assets, {
		font = font.dropdown,
		pixelWidth = 214,
		pixelHeight = 34,
		borderColor = { 0.68, 0.82, 0.54, 1 },
		hoverColor = { 0.68, 0.82, 0.54, 1 },
	}, function()
		return select_config.sortFunction, sort_model.names
	end, function(v)
		local index = table_util.indexof(sort_model.names, v)
		local name = sort_model.names[index]

		if name then
			view.game.selectModel:setSortFunction(name)
		end
	end, formatGroupSort)

	combos.group = Combo(assets, {
		font = font.dropdown,
		pixelWidth = 214,
		pixelHeight = 34,
		borderColor = { 0.57, 0.76, 0.9, 1 },
		hoverColor = { 0.57, 0.76, 0.9, 1 },
	}, function()
		return view.lists.showing, view.lists.groups
	end, function(v)
		self.selectedGroup = v
		view.lists:show(v)
	end, formatGroupSort)

	osu_logo_button = HoverState("quadout", 0.15)
	small_icons = {
		circles = img.osuSmallIcon,
		taiko = img.taikoSmallIcon,
		fruits = img.fruitsSmallIcon,
		mania = img.maniaSmallIcon,
	}

	player_profile_hover = HoverState("quadout", 0.2)

	local tab_y = 54
	local tab_font = font.tabs
	tabs.collections = TabButton(assets, { label = text.collections, font = tab_font, transform = ui.ts(739, tab_y) }, function ()
		self.view.lists:show("collections")
	end)
	tabs.recent = TabButton(assets, { label = text.recent, font = tab_font, transform = ui.ts(857, tab_y)}, function ()
		view.game.selectModel:setSortFunction("last played")
		self.view.lists:show("charts")
	end)
	tabs.artist = TabButton(assets, { label = text.artist, font = tab_font, transform = ui.ts(975, tab_y)}, function ()
		view.game.selectModel:setSortFunction("artist")
		self.view.lists:show("charts")
	end)
	tabs.difficulty = TabButton(assets, { label = text.difficulty, font = tab_font, transform = ui.ts(1093, tab_y) }, function ()
		view.game.selectModel:setSortFunction("difficulty")
		self.view.lists:show("charts")
	end)
	tabs.noGrouping = TabButton(assets, { label = text.noGrouping, font = tab_font, transform = ui.ts(1211, tab_y)}, function ()
		view.game.selectModel:setSortFunction("title")
		self.view.lists:show("charts")
	end)
end

---@param view osu.ui.SelectView
---@param _assets osu.ui.OsuAssets
function ViewConfig:new(view, assets)
	self.view = view
	local game = view.game
	self.assets = assets
	avatar = assets.images.avatar
	brighten_shader = assets.shaders.brighten
	img = assets.images
	snd = assets.sounds

	text = assets.localization.textGroups.songSelect
	font = assets.localization.fontGroups.songSelect

	setFormat()

	self.scoreListView = ScoreListView(game, assets)

	update_time = current_time
	self.scoreListView.scoreUpdateTime = love.timer.getTime()

	local configs = view.game.configModel.configs
	local osu = configs.osu_ui

	local profile_sources = view.ui.playerProfile.scoreSources
	score_sources = { "local" }

	if profile_sources then
		for i, v in ipairs(profile_sources) do
			table.insert(score_sources, v)
		end
	end

	table.insert(score_sources, "online")
	setScoreSource(osu.songSelect.scoreSource, configs)

	local w, h = Layout:move("base")
	top_panel_quad = gfx.newQuad(0, 0, w, img.panelTop:getHeight(), img.panelTop)
	self:createUI(view)
end

---@param chartview table
---@return number
local function getOD(chartview)
	if chartview.osu_od then
		return chartview.osu_od
	end

	---@type string
	local format = chartview.format

	if format == "sm" or format == "ssc" then
		return 9
	elseif format == "ojn" then
		return 7
	else
		return 8
	end
end

function ViewConfig:updateInfo(view, chart_changed)
	local chartview = view.game.selectModel.chartview
	---@type number
	local rate = view.game.playContext.rate

	if not chartview then
		return
	end

	chart_name = string.format("%s - %s [%s]", chartview.artist, chartview.title, chartview.name)
	local chart_format = chartview.format

	if chart_format == "sm" then
		charter_row = (text.from):format(chartview.set_dir)
	else
		charter_row = (text.mappedBy):format(chartview.creator)
	end

	local note_count = chartview.notes_count or 0
	local ln_count = chartview.long_notes_count or 0

	length_str = time_util.format((chartview.duration or 0) / rate)
	bpm_str = ("%i"):format((chartview.tempo or 0) * rate)
	objects_str = tostring(note_count + ln_count)
	note_count_str = tostring(note_count or 0)
	ln_count_str = tostring(ln_count or 0)

	columns_str = Format.inputMode(chartview.chartdiff_inputmode)

	---@type string
	local diff_column = view.game.configModel.configs.settings.select.diff_column

	if diff_column == "msd_diff" and chartview.msd_diff_data then
		local etterna_msd = view.ui.etternaMsd
		local msd = etterna_msd.getMsdFromData(chartview.msd_diff_data, rate)

		if msd then
			local difficulty = msd.overall
			local pattern = etterna_msd.simplifySsr(etterna_msd.getFirstFromMsd(msd), chartview.chartdiff_inputmode)
			difficulty_str = ("%0.02f %s"):format(difficulty, pattern)
		end
	elseif diff_column == "enps_diff" then
		difficulty_str = ("%0.02f ENPS"):format((chartview.enps_diff or 0) * rate)
	elseif diff_column == "osu_diff" then
		difficulty_str = ("%0.02f*"):format((chartview.osu_diff or 0) * rate)
	else
		difficulty_str = ("%0.02f"):format((chartview.user_diff or 0) * rate)
	end

	od_str = tostring(getOD(chartview))
	hp_str = tostring(chartview.osu_hp or 8)

	username = view.game.configModel.configs.online.user.name or "Guest"

	local speed_model = view.game.speedModel
	local gameplay = view.game.configModel.configs.settings.gameplay
	scroll_speed_str = ("%g (fixed)"):format(speed_model.format[gameplay.speedType]:format(speed_model:get()))

	if chart_changed then
		update_time = current_time
		self.scoreListView:reloadItems(score_source)
		self.scoreListView.scoreUpdateTime = love.timer.getTime()
	end

	local profile = view.ui.playerProfile

	pp = profile.pp
	accuracy = profile.accuracy
	level = profile.osuLevel
	level_percent = profile.osuLevelPercent
	rank = profile.rank

	local regular, ln = profile:getDanClears(chartview.chartdiff_inputmode)

	if regular ~= "-" or ln ~= "-" then
		username = ("%s [%s/%s]"):format(username, regular, ln)
	end

	---@type string
	local input_mode = view.game.selectController.state.inputMode
	chart_is_dan, this_dan_cleared = profile:isDanIsCleared(chartview.hash, tostring(input_mode))
end

---@param time number
---@param interval number
local function animate(time, interval)
	local t = math.min(current_time - time, interval)
	local progress = t / interval
	return math_util.clamp(progress * progress, 0, 1)
end


local function rainbow(x, a)
	local r = math.abs(math.sin(x * 2 * math.pi))
	local g = math.abs(math.sin((x + 1 / 3) * 2 * math.pi))
	local b = math.abs(math.sin((x + 2 / 3) * 2 * math.pi))
	return { r, g, b, a }
end

function ViewConfig:chartInfo()
	local w, h = Layout:move("base")

	local a = animate(update_time, 0.2)

	gfx.setColor(1, 1, 1, a)

	gfx.translate(5, 5)
	gfx.draw(chart_is_dan and img.danIcon or img.rankedIcon)
	gfx.translate(-5, -5)

	if this_dan_cleared then
		gfx.setColor(rainbow(love.timer.getTime() * 0.35, a))
	end

	gfx.setFont(font.chartName)
	gfx.translate(38, -5)
	ui.text(chart_name, w, "left")

	gfx.setFont(font.chartedBy)
	gfx.translate(2, -5)
	ui.text(charter_row, w, "left")

	w, h = Layout:move("base")
	gfx.setFont(font.infoTop)

	gfx.translate(5, 38)
	a = animate(update_time, 0.3)
	gfx.setColor(1, 1, 1, a)
	ui.text(text.chartInfoFirstRow:format(length_str, bpm_str, objects_str), w, "left")

	a = animate(update_time, 0.4)
	gfx.setColor(1, 1, 1, a)
	gfx.translate(0, 1)
	gfx.setFont(font.infoCenter)
	ui.text(text.chartInfoSecondRow:format(note_count_str, ln_count_str, "0"))

	a = animate(update_time, 0.5)
	gfx.translate(0, -2)
	gfx.setColor(1, 1, 1, a)
	gfx.setFont(font.infoBottom)
	ui.text(text.chartInfoThirdRow:format(columns_str, od_str, hp_str, difficulty_str))
end

---@param to_text boolean
local function moveToSort(to_text)
	local w, h = Layout:move("base")
	local text_x = font.groupSort:getWidth(text.sort) * ui.getTextScale() + 5
	gfx.translate(w - 220 - (to_text and text_x or 0), 0)
end

---@param to_text boolean
local function moveToGroup(to_text)
	moveToSort(true)
	local text_x = font.groupSort:getWidth(text.group) * ui.getTextScale() + 5
	gfx.translate(-210 - (to_text and text_x or 0), 0)
end

local tab_order = {"noGrouping", "difficulty", "artist", "recent", "collections"}

function ViewConfig:top()
	local w, h = Layout:move("base")

	local prev_shader = gfx.getShader()

	gfx.setShader(brighten_shader)
	gfx.setColor(white)
	gfx.draw(img.panelTop, top_panel_quad)
	gfx.setShader(prev_shader)

	gfx.setFont(font.groupSort)

	moveToSort(true)
	gfx.translate(10, 24)
	gfx.setColor({ 0.68, 0.82, 0.54, 1 })
	ui.text(text.sort)

	moveToGroup(true)
	gfx.translate(12, 24)
	gfx.setColor({ 0.57, 0.76, 0.9, 1 })
	ui.text(text.group)

	w, h = Layout:move("base")

	if has_focus then
		for i, v in ipairs(tab_order) do
			local tab = tabs[v]
			if tab:mouse() then
				break
			end
		end
	end

	gfx.setFont(font.tabs)
	self:updateTabs()
	tabs.collections:draw()
	tabs.recent:draw()
	tabs.artist:draw()
	tabs.difficulty:draw()
	tabs.noGrouping:draw()
end

---@param view osu.ui.SelectView
function ViewConfig:topUI(view)
	local w, h = Layout:move("base")
	gfx.translate(-2, 113)
	gfx.push()
	combos.scoreSource:update(has_focus)
	combos.scoreSource:drawBody()
	gfx.pop()

	w, h = Layout:move("base")
	gfx.setColor(white)
	gfx.translate(331, 117)
	gfx.draw(img.forum)

	if ui.isOver(23, 23) and ui.mousePressed(1) then
		view.game.selectController:openWebNotechart()
		view.notificationView:show("Opening the link. Check your browser.")
	end

	w, h = Layout:move("base")
	gfx.setColor({ 1, 1, 1, 0.5 })
	gfx.setFont(font.scrollSpeed)
	ui.frame(scroll_speed_str, -15, 0, w, h, "right", "top")

	w, h = Layout:move("base")
	moveToSort(false)
	gfx.translate(0, 24)
	gfx.push()
	combos.sort:update(has_focus)
	combos.sort:drawBody()
	gfx.pop()

	moveToGroup(false)
	gfx.translate(0, 24)
	combos.group:update(has_focus)
	combos.group:drawBody()
end

local function drawBottomButton(id)
	local button = buttons[id]
	button:update(has_focus)
	button:draw()
end

---@param view osu.ui.SelectView
function ViewConfig:bottom(view)
	local w, h = Layout:move("base")

	gfx.setColor(white)

	local iw, ih = img.panelBottom:getDimensions()

	local prev_shader = gfx.getShader()

	gfx.setShader(brighten_shader)
	gfx.translate(0, h - ih)
	gfx.draw(img.panelBottom, 0, 0, 0, w / iw, 1)
	gfx.setShader(prev_shader)

	w, h = Layout:move("base")
	gfx.translate(630, 693)

	local over, alpha, just_hovered = player_profile_hover:check(330, 86, 0, 0, has_focus)

	if over and ui.mousePressed(1) then
		if not view.ui.playerProfile.notInstalled then
			view:changeScreen("playerStatsView")
		end
	end

	gfx.push()

	gfx.setFont(font.rank)
	gfx.setColor({ 1, 1, 1, 0.17 })
	ui.frame(("#%i"):format(rank), -1, 10, 322, 78, "right", "top")

	iw, ih = avatar:getDimensions()
	gfx.setColor(white)
	gfx.draw(avatar, 0, 0, 0, 74 / iw, 74 / ih)

	gfx.translate(79, -4)

	gfx.setFont(font.username)
	ui.text(username)
	gfx.setFont(font.belowUsername)

	gfx.translate(0, -1)
	ui.text(("Performance: %ipp\nAccuracy: %0.02f%%\nLv%i"):format(pp, accuracy * 100, level))

	gfx.translate(42, 27)

	gfx.setColor(0.15, 0.15, 0.15, 1)
	gfx.rectangle("fill", 0, 0, 197, 10, 8, 8)

	gfx.setLineWidth(1)

	if level_percent > 0.03 then
		gfx.setColor(0.83, 0.65, 0.17, 1)
		gfx.rectangle("fill", 0, 0, 196 * level_percent, 10, 8, 8)
		gfx.rectangle("line", 0, 1, 196 * level_percent, 8, 6, 6)
	end

	gfx.setColor(0.4, 0.4, 0.4, 1)
	gfx.rectangle("line", 0, 0, 197, 10, 6, 6)

	gfx.pop()
	gfx.setColor(1, 1, 1, alpha * 0.2)
	gfx.rectangle("fill", -2, -2, 322, 78, 5, 5)

	w, h = Layout:move("base")
	local hover, animation, just_hovered = osu_logo_button:check(200, 90, w - 200, h - 90, has_focus)
	iw, ih = img.osuLogo:getDimensions()

	if just_hovered then
		ui.playSound(snd.hoverOverRect)
	end

	if hover and ui.mousePressed(1) then
		view:play()
	end

	gfx.setColor(white)
	local logo_scale = 0.45 * (1 + beat * (1 - animation)) + (animation * 0.08)
	gfx.draw(img.osuLogo, w - 70, h - 50, 0, logo_scale, logo_scale, iw / 2, ih / 2)

	w, h = Layout:move("base")
	gfx.translate(0, h)

	if self.assets.backButtonType ~= "none" then
		drawBottomButton("back")
	else
		gfx.translate(0, -58)
		back_button:update(has_focus)
		back_button:draw()
		gfx.translate(0, 58)
	end

	gfx.translate(224, 0)
	drawBottomButton("mode")

	local small_icon = small_icons[selected_mode]
	iw, ih = small_icon:getDimensions()
	gfx.setColor(white)
	gfx.setBlendMode("add")
	gfx.draw(small_icon, 46, -56, 0, 1, 1, iw / 2, ih / 2)
	gfx.setBlendMode("alpha")

	gfx.translate(92, 0)
	drawBottomButton("mods")

	gfx.translate(77, 0)
	drawBottomButton("random")

	gfx.translate(77, 0)
	drawBottomButton("chartOptions")
end

function ViewConfig:list(view)
	local w, h = Layout:move("base")

	local no_focus = false or combo_focused

	view.lists.focus = not no_focus and has_focus
	view.lists:draw(w, h)
end

---@param view osu.ui.SelectView
function ViewConfig:scores(view)
	local list = self.scoreListView

	local no_focus = false or combo_focused

	list.focus = not no_focus and has_focus

	local prev_canvas = gfx.getCanvas()
	local canvas = ui.getCanvas("osuScoreList")
	gfx.setCanvas({ canvas, stencil = true })
	gfx.clear()

	Layout:move("base")

	gfx.setBlendMode("alpha", "alphamultiply")

	if score_source == "online" then
		list:reloadItems("online")
	end

	has_scores = #list.items ~= 0

	if not has_scores then
		gfx.translate(20, 298)
		gfx.setColor(1, 1, 1, 1)
		gfx.draw(img.noScores)
	else
		gfx.translate(8, 154)
		list:updateAnimations()
		list:updateTimeSinceScore()
		list:draw(440, 420, true)
	end

	gfx.setCanvas(prev_canvas)

	gfx.origin()
	gfx.setBlendMode("alpha", "premultiplied")
	local a = animate(list.updateTime or 0, 0.3)
	gfx.setColor(a, a, a, a)
	gfx.draw(canvas)
	gfx.setBlendMode("alpha")

	if list.openResult then
		list.openResult = false
		view:result()
	end
end

---@param view osu.ui.SelectView
function ViewConfig:mods(view)
	local w, h = Layout:move("base")

	gfx.translate(104, 633)
	gfx.setColor({ 1, 1, 1, 0.75 })
	gfx.setFont(font.mods)
	ui.text(mods_str)
end

---@param view osu.ui.SelectView
function ViewConfig:updateOtherInfo(view)
	local modifiers = view.game.playContext.modifiers
	mods_str = getModifierString(modifiers)

	local rate = view.game.playContext.rate
	local rate_type = view.game.configModel.configs.settings.gameplay.rate_type
	local time_rate_model = view.game.timeRateModel

	if rate ~= 1 then
		local rate_str

		if rate_type == "linear" then
			rate_str = ("%gx"):format(time_rate_model:get())
		else
			rate_str = ("%iQ"):format(time_rate_model:get())
		end

		mods_str = rate_str .. " " .. mods_str
	end
end

function ViewConfig:modeLogo()
	local w, h = Layout:move("base")
	local image = img.maniaIcon
	local iw, ih = image:getDimensions()

	gfx.translate(w / 2 - iw / 2, h / 2 - ih / 2)
	gfx.setColor(1, 1, 1, 0.2)
	gfx.draw(image)
end

local search_width = 364

function ViewConfig:searchBackground()
	local insert_mode = actions.isInsertMode()
	local w, h = Layout:move("base")
	gfx.translate(w - search_width, 82)
	gfx.setColor({ 0, 0, 0, 0.2 })
	gfx.rectangle("fill", 0, 0, search_width, 35)

	gfx.translate(15, 5)
	gfx.setColor({ 0.68, 1, 0.18, 1 })
	gfx.setFont(font.search)

	local label = insert_mode and text.searchInsert or text.search
	ui.text(label)
end

---@param view osu.ui.SelectView
function ViewConfig:search(view)
	local insert_mode = actions.isInsertMode()
	local w, h = Layout:move("base")
	gfx.translate(w - search_width, 82)

	local label = insert_mode and text.searchInsert or text.search
	gfx.translate(20 + font.search:getWidth(label) * ui.getTextScale(), 5)

	gfx.setFont(font.search)
	gfx.setColor(white)

	if view.search == "" then
		ui.text(text.typeToSearch)
	else
		ui.text(view.search)
	end
end

---@param view osu.ui.SelectView
function ViewConfig:chartPreview(view)
	local prevCanvas = love.graphics.getCanvas()
	local canvas = ui.getCanvas("chartPreview")

	gfx.setCanvas(canvas)
	gfx.clear()
	view.chartPreviewView:draw()
	gfx.setCanvas({ prevCanvas, stencil = true })

	gfx.origin()
	gfx.setColor({ 1, 1, 1, 1 })
	gfx.draw(canvas)
end

function ViewConfig:noChartsText(view)
	local chart_count = #view.selectModel.noteChartSetLibrary.items

	if chart_count == 0 then
		local w, h = Layout:move("base")
		gfx.setFont(font.noCharts)
		gfx.setColor(0, 0, 0, 0.8)
		gfx.rectangle("fill", 0, 768 / 2 - 300 / 2, w, 300)
		gfx.setColor(1, 1, 1)
		ui.frame(text.noCharts, 0, 0, w, h, "center", "center")
	end

end

---@param view osu.ui.SelectView
function ViewConfig:resolutionUpdated(view)
	local w, h = Layout:move("base")
	top_panel_quad = gfx.newQuad(0, 0, w, img.panelTop:getHeight(), img.panelTop)

	self:createUI(view)
end

function ViewConfig:setFocus(value)
	has_focus = value
end

---@param view osu.ui.SelectView
local function updateBeat(view)
	---@type audio.bass.BassSource
	local audio = view.game.previewModel.audio

	if audio and audio.getFft then
		beat = getBeatValue(audio:getFft())
	end
end

local function checkFocus()
	combo_focused = false

	for _, combo in pairs(combos) do
		combo_focused = combo_focused or combo:isFocused()
	end
end

---@param view osu.ui.SelectView
function ViewConfig:draw(view)
	checkFocus()
	updateBeat(view)

	current_time = love.timer.getTime()

	local a = math_util.clamp((1 - ui.easeOutCubic(update_time, 1)) * 0.15, 0, 0.10)
	brighten_shader:send("amount", a)

	self:updateOtherInfo(view)

	self:chartPreview(view)
	self:modeLogo()

	self:list(view)

	self:scores(view)

	if view.lists.showing == "charts" then
		self:searchBackground()
	end

	self:top()
	self:bottom(view)
	self:chartInfo()

	if view.lists.showing == "charts" then
		self:search(view)
		self:noChartsText(view)
	end

	self:topUI(view)
	self:mods(view)
end

return ViewConfig
