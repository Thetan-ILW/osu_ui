local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.SelectViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.SelectViewConfig
---@field private assets osu.ui.OsuAssets
local ViewConfig = IViewConfig + {}

local ui = require("osu_ui.ui")
local time_util = require("time_util")
local math_util = require("math_util")
local table_util = require("table_util")
local msd_util = require("osu_ui.msd_util")
local Format = require("sphere.views.Format")

local getBeatValue = require("osu_ui.views.beat_value")
local getModifierString = require("osu_ui.views.modifier_string")

local ImageButton = require("osu_ui.ui.ImageButton")
local Combo = require("osu_ui.ui.Combo")
local BackButton = require("osu_ui.ui.BackButton")
local HoverState = require("osu_ui.ui.HoverState")

local NoteChartSetListView = require("osu_ui.views.SelectView.NoteChartSetListView")
local CollectionListView = require("osu_ui.views.SelectView.CollectionListView")
local ScoreListView = require("osu_ui.views.SelectView.ScoreListView")

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@type table<string, love.Image>
local img

---@type osu.ui.ActionModel
local action_model

local gfx = love.graphics

---@type love.Image
local avatar
---@type love.Image
local top_panel_quad
---@type love.Shader
local brighten_shader

local has_focus = true
local combo_focused = false

local prev_chart_id = 0
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
local username = ""
local scroll_speed_str = ""
local mods_str = ""
local current_time = 0
local update_time = 0
local chart_list_update_time = 0
local has_scores = false
local beat = 0

local pp = 0
local accuracy = 0

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

local ranking_options = {
	"Local Ranking",
	"Online Ranking",
}
local ranking = ranking_options[1]

local group_options = {
	"charts",
	"locations",
	"directories",
}
local selected_group = group_options[1]

---@param view osu.ui.SelectView
function ViewConfig:createUI(view)
	local assets = self.assets

	if assets.hasBackButton then
		buttons.back = ImageButton(assets, {
			idleImage = img.menuBack,
			ay = "bottom",
			hoverArea = { w = 200, h = 90 },
			clickSound = assets.sounds.menuBack,
		}, function()
			view:changeScreen("mainMenuView")
		end)
	else
		back_button = BackButton(assets, { w = 93, h = 90 }, function()
			view:changeScreen("mainMenuView")
		end)
	end

	buttons.mode = ImageButton(assets, {
		idleImage = img.modeButton,
		hoverImage = img.modeButtonOver,
		ay = "bottom",
		hoverArea = { w = 88, h = 90 },
	}, function()
		view.notificationView:show("Not implemented")
	end)

	buttons.mods = ImageButton(assets, {
		idleImage = img.modsButton,
		hoverImage = img.modsButtonOver,
		ay = "bottom",
		hoverArea = { w = 74, h = 90 },
	}, function()
		view:openModal("osu_ui.views.modals.Modifiers")
	end)

	buttons.random = ImageButton(assets, {
		idleImage = img.randomButton,
		hoverImage = img.randomButtonOver,
		ay = "bottom",
		hoverArea = { w = 74, h = 90 },
	}, function()
		view.selectModel:scrollRandom()
	end)

	buttons.chartOptions = ImageButton(assets, {
		idleImage = img.optionsButton,
		hoverImage = img.optionsButtonOver,
		ay = "bottom",
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
		return ranking, ranking_options
	end, function(v)
		ranking = v
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
		return selected_group, group_options
	end, function(v)
		selected_group = v
		chart_list_update_time = love.timer.getTime() + 0.4
		view:changeGroup(v)
	end, formatGroupSort)

	osu_logo_button = HoverState("quadout", 0.4)
end

---@param view osu.ui.SelectView
---@param _assets osu.ui.OsuAssets
function ViewConfig:new(view, assets)
	local game = view.game
	self.assets = assets
	avatar = assets.images.avatar
	brighten_shader = assets.shaders.brighten
	img = assets.images

	action_model = view.actionModel

	text = assets.localization.textGroups.songSelect
	font = assets.localization.fontGroups.songSelect

	setFormat()

	self.noteChartSetListView = NoteChartSetListView(game, assets)
	self.collectionListView = CollectionListView(game, assets)
	self.scoreListView = ScoreListView(game, assets)

	Layout:draw()

	chart_list_update_time = love.timer.getTime() + 0.4
	update_time = current_time
	self.scoreListView.scoreUpdateTime = love.timer.getTime()

	local w, h = Layout:move("base")
	top_panel_quad = gfx.newQuad(0, 0, w, img.panelTop:getHeight(), img.panelTop)
	self:createUI(view)
end

function ViewConfig:updateInfo(view)
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
		local msd = msd_util.getMsdFromData(chartview.msd_diff_data, rate)

		if msd then
			local difficulty = msd.overall
			local pattern = msd_util.simplifySsr(msd_util.getFirstFromMsd(msd))
			difficulty_str = ("%0.02f %s"):format(difficulty, pattern)
		end
	elseif diff_column == "enps_diff" then
		difficulty_str = ("%0.02f ENPS"):format(chartview.enps_diff or 0)
	elseif diff_column == "osu_diff" then
		difficulty_str = ("%0.02f*"):format(chartview.osu_diff or 0)
	else
		difficulty_str = ("%0.02f"):format(chartview.user_diff or 0)
	end

	username = view.game.configModel.configs.online.user.name or "Guest"

	local speed_model = view.game.speedModel
	local gameplay = view.game.configModel.configs.settings.gameplay
	scroll_speed_str = ("%g (fixed)"):format(speed_model.format[gameplay.speedType]:format(speed_model:get()))

	self.noteChartSetListView:reloadItems()
	self.collectionListView:reloadItems()
	self.scoreListView:reloadItems()

	has_scores = #view.game.selectModel.scoreLibrary.items ~= 0

	if prev_chart_id ~= chartview.id then
		update_time = current_time
		self.scoreListView.scoreUpdateTime = love.timer.getTime()
	end

	---@type number
	prev_chart_id = chartview.id

	pp = 0
	accuracy = 0
end

---@param time number
---@param interval number
local function animate(time, interval)
	local t = math.min(current_time - time, interval)
	local progress = t / interval
	return math_util.clamp(progress * progress, 0, 1)
end

local function tab(label)
	gfx.setColor({ 0.86, 0.08, 0.23, 1 })
	gfx.draw(img.tab)

	gfx.setColor(white)
	ui.frame(label, 0, 2, 137, 21, "center", "center")
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

	gfx.setColor({ 1, 1, 1, a })

	gfx.translate(5, 5)
	gfx.draw(chart_is_dan and img.danIcon or img.rankedIcon)
	gfx.translate(-5, -5)

	if this_dan_cleared then
		gfx.setColor(rainbow(love.timer.getTime() * 0.35, a))
	end

	gfx.setFont(font.chartName)
	gfx.translate(39, -5)
	ui.text(chart_name, w, "left")

	gfx.setFont(font.chartedBy)
	gfx.translate(0, -5)
	ui.text(charter_row, w, "left")

	w, h = Layout:move("base")
	gfx.setFont(font.infoTop)

	gfx.translate(5, 38)
	a = animate(update_time, 0.3)
	gfx.setColor({ 1, 1, 1, a })
	ui.text(text.chartInfoFirstRow:format(length_str, bpm_str, objects_str), w, "left")

	a = animate(update_time, 0.4)
	gfx.setColor({ 1, 1, 1, a })
	gfx.setFont(font.infoCenter)
	ui.text(text.chartInfoSecondRow:format(note_count_str, ln_count_str, ""))

	a = animate(update_time, 0.5)
	gfx.setColor({ 1, 1, 1, a })
	gfx.setFont(font.infoBottom)
	ui.text(text.chartInfoThirdRow:format(columns_str, "8", "8", difficulty_str))
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
	gfx.setFont(font.tabs)
	gfx.translate(w - 632, 54)
	tab(text.collections)
	gfx.translate(118, 0)
	tab(text.recent)
	gfx.translate(118, 0)
	tab(text.artist)
	gfx.translate(118, 0)
	tab(text.difficulty)
	gfx.translate(118, 0)
	tab(text.noGrouping)
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
		love.system.openURL("https://soundsphere.xyz/notecharts")
		view.gameView.showMessage("Opening the link. Check your browser.", nil, { show_time = 3 })
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

	gfx.setFont(font.rank)
	gfx.setColor({ 1, 1, 1, 0.17 })
	ui.frame("#69", -1, 10, 322, 78, "right", "top")

	iw, ih = avatar:getDimensions()
	gfx.setColor(white)
	gfx.draw(avatar, 0, 0, 0, 74 / iw, 74 / ih)

	gfx.translate(80, -4)

	gfx.setFont(font.username)
	ui.text(username)
	gfx.setFont(font.belowUsername)

	gfx.translate(0, 1)
	ui.text(("Performance: %ipp\nAccuracy: %0.02f%%\nLv10"):format(pp, accuracy * 100))

	gfx.translate(42, 27)

	gfx.setColor({ 0.15, 0.15, 0.15, 1 })
	gfx.rectangle("fill", 0, 0, 197, 10, 8, 8)

	gfx.setLineWidth(1)
	gfx.setColor({ 0.4, 0.4, 0.4, 1 })
	gfx.rectangle("line", 0, 0, 197, 10, 6, 6)

	w, h = Layout:move("base")
	local hover, animation = osu_logo_button:check(200, 90, w - 200, h - 90, has_focus)
	iw, ih = img.osuLogo:getDimensions()
	iw, ih = iw * 0.45, ih * 0.45

	if hover and ui.mousePressed(1) then
		view:play()
	end

	gfx.setColor(white)
	gfx.translate(w - iw - (iw / 2 * (1 + beat * 1.2)) + 170, h - ih - (ih / 2 * (1 + beat * 1.2)) + 196)
	gfx.draw(img.osuLogo, 0, 0, 0, 0.45 * (1 + beat))

	w, h = Layout:move("base")
	gfx.translate(0, h)

	if self.assets.hasBackButton then
		drawBottomButton("back")
	else
		gfx.translate(0, -58)
		back_button:update(has_focus)
		back_button:draw()
		gfx.translate(0, 58)
	end

	gfx.translate(224, 0)
	drawBottomButton("mode")

	iw, ih = img.maniaSmallIcon:getDimensions()
	gfx.translate(-iw / 2 + 45, -ih / 2 - 55)
	gfx.setColor(white)
	gfx.setBlendMode("add")
	gfx.draw(img.maniaSmallIcon)
	gfx.setBlendMode("alpha")
	gfx.translate(iw / 2 - 45, ih / 2 + 55)

	gfx.translate(92, 0)
	drawBottomButton("mods")

	gfx.translate(77, 0)
	drawBottomButton("random")

	gfx.translate(77, 0)
	drawBottomButton("chartOptions")
end

function ViewConfig:chartSetList()
	local w, h = Layout:move("base")
	local list = self.noteChartSetListView

	local no_focus = false or combo_focused

	list.focus = not no_focus and has_focus

	local a = ui.easeOutCubic(chart_list_update_time, 0.7)

	gfx.translate(w - (610 * a), 82)
	list:updateAnimations()
	list:draw(610, 595, true)

	w, h = Layout:move("base")
	gfx.translate(w - 610, 82)
	ui.scrollBar(list, 610, 595)
end

---@param view osu.ui.SelectView
function ViewConfig:collectionList(view)
	local w, h = Layout:move("base")
	local list = self.collectionListView

	local no_focus = false or combo_focused

	list.focus = not no_focus and has_focus

	local a = ui.easeOutCubic(chart_list_update_time, 0.7)

	gfx.translate(w - (610 * a), 82)
	list:updateAnimations()
	list:draw(610, 595, true)

	w, h = Layout:move("base")
	gfx.translate(w - 610, 82)
	ui.scrollBar(list, 610, 595)

	if list.selected then
		view:changeGroup("charts")
		list.selected = false
	end
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

	local w, h = Layout:move("base")

	gfx.setBlendMode("alpha", "alphamultiply")

	if not has_scores then
		gfx.translate(20, 298)
		gfx.setColor({ 1, 1, 1, 1 })
		gfx.draw(img.noScores)
	else
		gfx.translate(8, 154)
		list:updateAnimations()
		list:draw(378, 420, true)
	end

	gfx.setCanvas({ prev_canvas, stencil = true })

	gfx.origin()
	gfx.setBlendMode("alpha", "premultiplied")
	local a = animate(update_time, 0.3)
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
			rate_str = ("%0.02fx"):format(time_rate_model:get())
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
	gfx.setColor({ 1, 1, 1, 0.2 })
	gfx.draw(image)
end

local search = ""

---@param view osu.ui.SelectView
function ViewConfig:search(view)
	local insert_mode = action_model.isInsertMode()
	local width = 364
	local w, h = Layout:move("base")
	gfx.translate(w - width, 82)
	gfx.setColor({ 0, 0, 0, 0.2 })
	gfx.rectangle("fill", 0, 0, width, 35)

	gfx.translate(15, 5)
	gfx.setColor({ 0.68, 1, 0.18, 1 })
	gfx.setFont(font.search)

	local label = insert_mode and text.searchInsert or text.search
	ui.text(label, font.search:getWidth(label) * ui.getTextScale())
	gfx.translate(5, 0)

	gfx.setColor(white)
	ui.sameline()

	local vim_motions = action_model.isVimMode()

	local config = view.game.configModel.configs.select
	local changed = false
	if (not vim_motions or insert_mode) and has_focus then
		changed, search = ui.textInput(config.filterString)
	end

	if search == "" then
		ui.text(text.typeToSearch)
	else
		ui.text(search)
	end

	if action_model.isEnabled() then
		if changed == "text" then
			view:updateSearch(search)
		end

		local delete_all = action_model.consumeAction("deleteLine")

		if delete_all then
			view:updateSearch("")
		end
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

---@param name "charts" | "locations" | "directories" | "last_visited_locations"
function ViewConfig:selectGroup(name)
	selected_group = name
end

---@param view osu.ui.SelectView
function ViewConfig:draw(view)
	Layout:draw()

	checkFocus()
	updateBeat(view)

	current_time = love.timer.getTime()

	local a = math_util.clamp((1 - ui.easeOutCubic(update_time, 1)) * 0.15, 0, 0.10)
	brighten_shader:send("amount", a)

	self:updateOtherInfo(view)

	self:chartPreview(view)
	self:modeLogo()

	if selected_group == "charts" then
		self:chartSetList()
	else
		self:collectionList(view)
	end

	self:scores(view)
	self:top()
	self:bottom(view)
	self:chartInfo()

	if selected_group == "charts" then
		self:search(view)
	end

	self:topUI(view)
	self:mods(view)
end

return ViewConfig
