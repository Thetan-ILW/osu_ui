local CanvasComponent = require("ui.CanvasComponent")
local Component = require("ui.Component")

local flux = require("flux")
local easing = require("osu_ui.ui.easing")
local text_input = require("ui.text_input")

local Image = require("ui.Image")
local QuadImage = require("ui.QuadImage")
local ImageButton = require("osu_ui.ui.ImageButton")
local DynamicLabel = require("ui.DynamicLabel")
local BackButton = require("osu_ui.ui.BackButton")
local Label = require("ui.Label")
local Combo = require("osu_ui.ui.Combo")
local TabButton = require("osu_ui.ui.TabButton")
local PlayerInfoView = require("osu_ui.views.PlayerInfoView")
local ScoreListView = require("osu_ui.views.SelectView.ScoreListView")
local ScrollBar = require("osu_ui.ui.ScrollBar")
local Rectangle = require("ui.Rectangle")
local ListContainer = require("osu_ui.views.SelectView.Lists.ListContainer")
local CollectionsListView = require("osu_ui.views.SelectView.Lists.CollectionsListView")

local DisplayInfo = require("osu_ui.views.SelectView.DisplayInfo")

---@class osu.ui.SelectViewContainer : ui.CanvasComponent
---@operator call: osu.ui.SelectViewContainer
---@field selectApi game.SelectAPI
local View = CanvasComponent + {}

function View:textInput(event)
	self.search = self.search .. event[1]
	self:searchUpdated()
	return true
end

function View:keyPressed(event)
	if event[2] == "escape" then
		self.search = ""
		self:searchUpdated()
		return true
	elseif event[2] == "f9" then
		local scene = self.shared.scene
		local chat = scene:getChild("chat") ---@cast chat osu.ui.ChatView
		if chat then
			chat:toggle()
		end
	end

	if event[2] ~= "backspace" then
		return false
	end

	self.search = text_input.removeChar(self.search)
	self:searchUpdated()
	return true
end

function View:searchUpdated()
	local text = self.search ~= "" and self.search or self.shared.localization.text.SongSelection_TypeToBegin
	self.searchFormat[4] = text
	self.searchLabel:replaceText(self.searchFormat)
	self.selectApi:updateSearch(self.search)
end

function View:stopTransitionTween()
	if self.transitionTween then
		self.transitionTween:stop()
	end
end

function View:transitIn()
	self.disabled = false
	self.handleEvents = true
	self.alpha = 0
	self:stopTransitionTween()
	flux.to(self, 0.7, { alpha = 1 }):ease("cubicout")
end

function View:transitToGameplay()
	local scene = self.shared.scene ---@cast scene osu.ui.SceneView
	local viewport = self:getViewport()

	local background = scene:getChild("background")
	local cursor = viewport:getChild("cursor")
	local transition = scene:getChild("gameplayTransition") ---@cast transition osu.ui.GameplayTransition
	local options = scene:getChild("options") ---@cast options osu.ui.OptionsView
	local chat = scene:getChild("chat") ---@cast chat osu.ui.ChatView

	self.handleEvents = false
	self:stopTransitionTween()
	self.transitionTween = flux.to(self, 0.5, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self.disabled = true
		scene:transitInScreen("gameplay")
	end)

	flux.to(cursor, 0.5, { alpha = 0 }):ease("quadout")
	flux.to(background, 0.2, { dim = 0.5, parallax = 0 }):ease("quadout")
	options:fade(0)
	chat:fade(0)

	transition:show(
		self.displayInfo.chartName,
		("Length: %s Difficulty: %s"):format(self.displayInfo.length, self.displayInfo.difficulty),
		self.game.backgroundModel.images[1]
	)

	self.selectApi:unloadController()
end

function View:transitToMainMenu()
	local scene = self.shared.scene ---@cast scene osu.ui.SceneView

	self.handleEvents = false
	self:stopTransitionTween()
	self.transitionTween = flux.to(self, 0.4, { alpha = 0 }):ease("quadin"):oncomplete(function ()
		self.disabled = true
	end)

	scene:transitInScreen("mainMenu")
end

function View:load()
	self.width, self.height = self.parent:getDimensions()
	self.stencil = true
	self:createCanvas(self.width, self.height)
	self:getViewport():listenForResize(self)

	self.selectApi = self.shared.selectApi
	self.displayInfo = DisplayInfo(self.shared.localization, self.selectApi, self.shared.pkgs.minacalc)
	self.displayInfo:updateInfo()
	self.notechartChangeTime = -1

	self.selectApi:listenForNotechartChanges(function()
		self.displayInfo:updateInfo()
		self.notechartChangeTime = love.timer.getTime()
	end)

	local shaders = require("osu_ui.ui.shaders")
	self.shader = shaders.lighten

	local display_info = self.displayInfo
	local assets = self.shared.assets
	local fonts = self.shared.fontManager

	local text = self.shared.localization.text

	local width, height = self.width, self.height
	local top = self:addChild("topContainer", Component({ width = width, height = height, z = 0.5 }))
	local bottom = self:addChild("bottomContainer", Component({ width = width, height = height, z = 0.6  }))
	local center = self:addChild("centerContainer", Component({ width = width, height = height, z = 0 }))
	local tabs = top:addChild("tabContainer", Component({ z = 0.5 }))

	self.searchFormat = { { 0.68, 1, 0.18, 1 }, text.SongSelection_Search .. " ", { 1, 1, 1, 1 }, text.SongSelection_TypeToBegin }
	self.search = self.selectApi:getSearchText()

	----------- TOP -----------

	local img = assets:loadImage("songselect-top")
	img:setWrap("clamp")
	top:addChild("background", QuadImage({
		image = img,
		quad = love.graphics.newQuad(0, 0, width, img:getHeight(), img),
	}))

	local st_icon = top:addChild("statusIcon", Image({
		x = 19, y = 19,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("selection-ranked"),
		z = 0.9
	}))
	function st_icon.update()
		st_icon.color[4] = easing.linear(self.notechartChangeTime, 0.2)
	end

	local chart_name = top:addChild("chartName", DynamicLabel({
		x = 38, y = -5,
		font = fonts:loadFont("Regular", 25),
		z = 0.9,
		value = function ()
			return display_info.chartName
		end
	}))

	function chart_name.update()
		---@cast chart_name ui.DynamicLabel
		chart_name.alpha = easing.linear(self.notechartChangeTime, 0.2)
		DynamicLabel.update(chart_name)
	end

	local chart_source = top:addChild("chartSource", DynamicLabel({
		x = 40, y = 20,
		font = fonts:loadFont("Regular", 16),
		z = 0.9,
		value = function ()
			return display_info.chartSource
		end
	}))
	function chart_source.update()
		---@cast chart_source ui.DynamicLabel
		chart_source.alpha = easing.linear(self.notechartChangeTime, 0.25)
		DynamicLabel.update(chart_source)
	end

	local first_row = top:addChild("chartInfoFirstRow", DynamicLabel({
		x = 5, y = 39,
		font = fonts:loadFont("Bold", 16),
		z = 0.9,
		value = function ()
			return display_info.chartInfoFirstRow
		end
	}))
	function first_row.update()
		---@cast first_row ui.DynamicLabel
		first_row.alpha = easing.linear(self.notechartChangeTime, 0.3)
		DynamicLabel.update(first_row)
	end

	local second_row = top:addChild("chartInfoSecondRow", DynamicLabel({
		x = 5, y = 59,
		font = fonts:loadFont("Regular", 16),
		z = 0.9,
		value = function ()
			return display_info.chartInfoSecondRow
		end
	}))
	function second_row.update()
		---@cast second_row ui.DynamicLabel
		second_row.alpha = easing.linear(self.notechartChangeTime, 0.4)
		DynamicLabel.update(second_row)
	end

	local third_row = top:addChild("chartInfoThirdRow", DynamicLabel({
		x = 4, y = 76,
		font = fonts:loadFont("Regular", 11),
		z = 0.9,
		value = function ()
			return display_info.chartInfoThirdRow
		end
	}))
	function third_row.update()
		---@cast third_row ui.DynamicLabel
		third_row.alpha = easing.linear(self.notechartChangeTime, 0.5)
		DynamicLabel.update(third_row)
	end

	local ranking_options = {
		["local"] = text.SongSelection_Rank_Local,
		online = text.SongSelection_Rank_Top,
		osuv1 = "osu!mania V1",
		osuv2 = "osu!mania V2",
		etterna = "Etterna J4",
		quaver = "Quaver"
	}
	local score_sources = self.selectApi:getScoreSources()
	top:addChild("scoreSource", Combo({
		x = 8, y = 117,
		width = 308,
		height = 34,
		font = fonts:loadFont("Regular", 18),
		borderColor = { 0.08, 0.51, 0.7, 1 },
		hoverColor = { 0.08, 0.51, 0.7, 1 },
		items = score_sources,
		z = 0.9,
		getValue = function ()
			return self.selectApi:getScoreSource()
		end,
		setValue = function (index)
			self.selectApi:setScoreSource(index)
		end,
		format = function (value)
			return ranking_options[value] or ""
		end
	}))

	top:addChild("chartWebPage", Image({
		x = 330, y = 117,
		image = assets:loadImage("rank-forum"),
		z = 0.5,
		mouseClick = function(this)
			if this.mouseOver then
				select_view.game.selectController:openWebNotechart()
				--view.notificationView:show("Opening the link. Check your browser.")
				return true
			end
			return false
		end
	}))

	local sort_group_format = {
		charts = text.SongSelection_ByBeatmaps,
		locations = text.SongSelection_ByGames,
		directories = text.SongSelection_ByFolders,
		id = text.byId,
		title = text.SongSelection_ByTitle,
		artist = text.SongSelection_ByArtist,
		difficulty = text.SongSelection_ByDifficulty,
		level = text.SongSelection_ByLevel,
		duration = text.SongSelection_ByLength,
		bpm = text.SongSelection_ByBPM,
		modtime = text.SongSelection_ByDateAdded,
		["set modtime"] = text.bySetModTime,
		["last played"] = text.SongSelection_ByRecentlyPlayed,
	}

	local sort_combo = top:addChild("sortCombo", Combo({
		x = width - 16, y = 28,
		origin = { x = 1, y = 0 },
		width = 193,
		height = 34,
		font = fonts:loadFont("Regular", 18),
		borderColor = { 0.68, 0.82, 0.54, 1 },
		hoverColor = { 0.68, 0.82, 0.54, 1 },
		items = self.selectApi:getSortFunctionNames(),
		z = 0.9,
		getValue = function ()
			return self.selectApi:getSortFunction()
		end,
		setValue = function (index)
			self.selectApi:setSortFunction(index)
		end,
		format = function (value)
			return sort_group_format[value] or value
		end
	}))

	local sort_text = top:addChild("sortText", Label({
		x = sort_combo.x - sort_combo.width - 6, y = 24,
		origin = { x = 1, y = 0 },
		alignX = "right",
		text = text.SongSelection_Sort,
		font = fonts:loadFont("Light", 29),
		color = { 0.68, 0.82, 0.54, 1 },
		z = 0.5,
	}))

	local group_combo = top:addChild("groupCombo", Combo({
		x = sort_text.x - sort_text.width - 16, y = 28,
		origin = { x = 1, y = 0 },
		width = 193,
		height = 34,
		font = fonts:loadFont("Regular", 18),
		borderColor = { 0.57, 0.76, 0.9, 1 },
		hoverColor = { 0.57, 0.76, 0.9, 1 },
		items = self.selectApi:getGroups(),
		assets = assets,
		z = 0.9,
		getValue = function ()
			return self.selectApi:getGroup()
		end,
		setValue = function (index)
			self.selectApi:setGroup(index)
		end,
		format = function (value)
			return sort_group_format[value] or value
		end
	}))

	top:addChild("groupText", Label({
		x = group_combo.x - group_combo.width - 6, y = 24,
		origin = { x = 1, y = 0 },
		alignX = "right",
		text = text.SongSelection_Group,
		font = fonts:loadFont("Light", 29),
		color = { 0.57, 0.76, 0.9, 1 },
		z = 0.5,
	}))

	local collection_library = self.selectApi:getCollectionLibrary()
	top:addChild("selectedCollectionName", DynamicLabel({
		x = width - 15, y = 0,
		origin = { x = 1, y = 0 },
		font = fonts:loadFont("Light", 23),
		color = { 1, 1, 1, 0.5 },
		z = 0.9,
		value = function ()
			local name = collection_library.tree.items[collection_library.root_tree.selected].name
			return name == "/" and "All songs" or name
		end
	}))

	--- TABS ---
	local tab_y = 54
	local no_grouping = tabs:addChild("noGrouping", TabButton({
		x = width - 15, y = tab_y,
		origin = { x = 1, y = 0 },
		text = text.SongSelection_NoGrouping,
		z = 0.5,
		onClick = function ()
			self:selectTab("noGrouping")
		end
	}))

	local by_difficulty = tabs:addChild("byDifficulty", TabButton({
		x = no_grouping.x - no_grouping.width + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		text = text.SongSelection_ByDifficulty,
		z = 0.4,
		onClick = function ()
			self:selectTab("byDifficulty")
		end
	}))

	local by_artist = tabs:addChild("byArtist", TabButton({
		x = by_difficulty.x - by_difficulty.width + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		text = text.SongSelection_ByArtist,
		z = 0.3,
		onClick = function ()
			self:selectTab("byArtist")
		end
	}))

	local recently_played = tabs:addChild("recentlyPlayed", TabButton({
		x = by_artist.x - by_artist.width + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		text = text.SongSelection_RecentlyPlayed,
		z = 0.2,
		onClick = function ()
			self:selectTab("recentlyPlayed")
		end
	}))

	tabs:addChild("collections", TabButton({
		x = recently_played.x - recently_played.width + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		text = text.SongSelection_Collections,
		z = 0.1,
		onClick = function ()
			self:selectTab("collections")
		end
	}))

	----------- BOTTOM -----------

	local bottom_img = assets:loadImage("songselect-bottom")
	bottom:addChild("background", Image({
		y = height,
		origin = { x = 0, y = 1 },
		image = bottom_img,
		scaleX = width / bottom_img:getWidth()
	}))

	bottom:addChild("backButton", BackButton({
		y = height - 58,
		font = fonts:loadFont("Regular", 20),
		text = "back",
		hoverWidth = 93,
		hoverHeight = 58,
		z = 0.9,
		onClick = function ()
			if self.search ~= "" then
				self.search = ""
				self:searchUpdated()
			end
			self:transitToMainMenu()
		end
	}))

	local selected_mode_index = 4
	local small_icons = {
		assets:loadImage("mode-osu-small"),
		assets:loadImage("mode-taiko-small"),
		assets:loadImage("mode-fruits-small"),
		assets:loadImage("mode-mania-small"),
	}

	local mode_icon = bottom:addChild("modeSelectionIcon", Image({
		x = 224 + 46, y = height - 56,
		origin = { x = 0.5, y = 0.5 },
		image = small_icons[4],
		z = 0.4
	}))
	---@cast mode_icon ui.Image

	bottom:addChild("modeSelection", ImageButton({
		x = 224, y = height,
		origin = { x = 0, y = 1 },
		idleImage = assets:loadImage("selection-mode"),
		hoverImage = assets:loadImage("selection-mode-over"),
		z = 0.3,
		onClick = function ()
			selected_mode_index = 1 + (selected_mode_index % #small_icons)
			mode_icon:replaceImage(small_icons[selected_mode_index])
		end
	}))

	bottom:addChild("modsSelection", ImageButton({
		x = 316, y = height,
		origin = { x = 0, y = 1 },
		idleImage = assets:loadImage("selection-mods"),
		hoverImage = assets:loadImage("selection-mods-over"),
		z = 0.3,
	}))

	bottom:addChild("randomButton", ImageButton({
		x = 393, y = height,
		origin = { x = 0, y = 1 },
		idleImage = assets:loadImage("selection-random"),
		hoverImage = assets:loadImage("selection-random-over"),
		z = 0.3,
	}))

	bottom:addChild("beatmapOptionsButton", ImageButton({
		x = 470, y = height,
		origin = { x = 0, y = 1 },
		idleImage = assets:loadImage("selection-options"),
		hoverImage = assets:loadImage("selection-options-over"),
		z = 0.3,
	}))

	local info = self.selectApi:getProfileInfo()
	bottom:addChild("playerInfo", PlayerInfoView({
		x = 624, y = height + 4,
		origin = { x = 0, y = 1 },
		username = info.username,
		firstRow = info.firstRow,
		secondRow = info.secondRow,
		level = info.level,
		levelProgress = info.levelPercent,
		rank = info.rank,
		z = 0.3,
		onClick = function () end
	}))

	bottom:addChild("osuLogo", Image({
		x = width - 65, y = height - 50,
		origin = { x = 0.5, y = 0.5 },
		scale = 0.4,
		image = assets:loadImage("menu-osu-logo"),
		z = 0.1
	}))

	local score_list = center:addChild("scoreList", ScoreListView({
		x = 5, y = 145,
		width = 385,
		height = 430,
		z = 0.1
	}))
	---@cast score_list osu.ui.ScoreListView

	function score_list.update(container, dt)
		score_list.x = (1 - self.alpha) * -450
		return ScoreListView.update(container, dt)
	end

	top:addChild("mouseBlock", Component({
		width = width,
		height = 82,
		blockMouseFocus = true,
		z = 0,
	}))

	bottom:addChild("mouseBlock", Component({
		y = height,
		origin = { x = 0, y = 1 },
		width = width,
		height = 90,
		blockMouseFocus = true,
		z = 0
	}))

	top:addChild("searchBackground", Rectangle({
		x = width, y = 82,
		origin = { x = 1, y = 0 },
		width = 364,
		height = 35,
		color = { 0, 0, 0, 0.5 },
	}))
	local search_label = top:addChild("search", Label({
		x = width + 15, y = 87,
		origin = { x = 1, y = 0 },
		width = 364,
		height = 35,
		text = self.searchFormat,
		font = fonts:loadFont("Bold", 18),
		z = 0.3,
	})) ---@cast search_label ui.Label
	self.searchLabel = search_label
	self:searchUpdated()

	local root = CollectionsListView({
		z = 1,
	})

	local list = center:addChild("list", ListContainer({
		x = width,
		origin = { x = 1, y = 0 },
		width = 600,
		height = height,
		root = root,
		z = 0,
	}))
	---@cast list osu.ui.ListContainer

	function list.update(container, dt)
		ListContainer.update(list, dt)
		container.x = width + ((1 - self.alpha) * 640)
	end

	center:addChild("scrollBarBackground", Rectangle({
		x = width - 5, y = 117,
		width = 5,
		height = 561,
		color = { 0, 0, 0, 0.5 },
		z = 0.09,
	}))

	center:addChild("scrollBar", ScrollBar({
		x = width - 5, startY = 117,
		width = 5,
		container = list,
		windowHeight = 561,
		z = 0.1,
	}))

	function top.update(container, dt)
		container.y = (1 - self.alpha) * -160
		Component.update(container, dt)
	end

	function bottom.update(container, dt)
		container.y = (1 - self.alpha) * 160
		Component.update(container, dt)
	end
end

function View:update()
	self.selectApi:updateController()
	self.shader:send("amount", 0.05 * (1 - easing.linear(self.notechartChangeTime, 0.5)))
end

function View:draw()
	love.graphics.setShader(self.shader)
	CanvasComponent.draw(self)
end

---@alias TabNames "noGrouping" | "byDifficulty" | "byArtist" | "recentlyPlayed" | "collections"
---@param selected TabNames  
function View:selectTab(selected)
	local top_container = self.children.topContainer ---@cast top_container ui.Component
	local tab_container = top_container.children.tabContainer ---@cast tab_container ui.Component
	local c = tab_container.children

	---@type {[TabNames]: { element: ui.Component, z: number, onClick: function}}
	local tabs = {
		noGrouping = {
			element = c.noGrouping,
			z = 0.5,
			onClick = function () end
		},
		byDifficulty = {
			element = c.byDifficulty,
			z = 0.4,
			onClick = function () end
		},
		byArtist = {
			element = c.byArtist,
			z = 0.3,
			onClick = function () end
		},
		recentlyPlayed = {
			element = c.recentlyPlayed,
			z = 0.2,
			onClick = function () end
		},
		collections = {
			element = c.collections,
			z = 0.1,
			onClick = function () end
		}
	}
	---@cast tabs {[TabNames]: { element: osu.ui.TabButton, z: number, onClick: function}}
	assert(tabs[selected], "Tab " .. selected .. " does not exist")

	for _, v in pairs(tabs) do
		v.element.z = v.z
		v.element.active = false
	end

	local s = tabs[selected]
	s.element.active = true
	s.element.z = 1
	s.onClick()
	tab_container.deferBuild = true
end

return View
