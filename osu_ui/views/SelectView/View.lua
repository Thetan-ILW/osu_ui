local Container = require("osu_ui.ui.Container")

local Image = require("osu_ui.ui.Image")
local ImageButton = require("osu_ui.ui.ImageButton")
local DynamicText = require("osu_ui.ui.DynamicText")
local BackButton = require("osu_ui.ui.BackButton")
local Label = require("osu_ui.ui.Label")
local Combo = require("osu_ui.ui.Combo")
local TabButton = require("osu_ui.ui.TabButton")

---@class osu.ui.SelectViewContainer : osu.ui.Container
---@operator call: osu.ui.SelectViewContainer
---@field selectView osu.ui.SelectView
local View = Container + {}

function View:load()
	Container.load(self)

	local select_view = self.selectView
	local display_info = select_view.displayInfo
	local assets = select_view.assets

	local text = select_view.localization.text

	local width, height = self.parent.totalW, self.parent.totalH

	local top = self:addChild("topContainer", Container({ totalW = width, totalH = height, depth = 0.5 }))
	local bottom = self:addChild("bottomContainer", Container({ depth = 0.6 }))
	---@cast top osu.ui.Container
	---@cast bottom osu.ui.Container

	local tabs = top:addChild("tabContainer", Container({ depth = 0.5 }))
	---@cast tabs osu.ui.Container

	local screenshot = self:addChild("screenshot", Image({
		image = select_view.screenshot,
		blockMouseFocus = false,
		alpha = 0,
		depth = 1,
	}))
	function self:wheelUp()
		screenshot.alpha = math.min(1, screenshot.alpha + 0.1)
		return true
	end
	function self:wheelDown()
		screenshot.alpha = math.max(0, screenshot.alpha - 0.1)
		return true
	end
	self:bindEvent(self, "wheelUp")
	self:bindEvent(self, "wheelDown")

	----------- TOP -----------

	local img = assets:loadImage("songselect-top")
	top:addChild("background", Image({
		image = img,
		wrap = "clamp",
		quad = love.graphics.newQuad(0, 0, width, img:getHeight(), img),
	}))

	top:addChild("statusIcon", Image({
		x = 19, y = 19,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage("selection-ranked"),
		depth = 0.9
	}))

	top:addChild("chartName", DynamicText({
		x = 38, y = -5,
		font = assets:loadFont("Regular", 25),
		depth = 0.9,
		value = function ()
			return display_info.chartName
		end
	}))

	top:addChild("chartSource", DynamicText({
		x = 40, y = 20,
		font = assets:loadFont("Regular", 16),
		depth = 0.9,
		value = function ()
			return display_info.chartSource
		end
	}))

	top:addChild("chartInfoFirstRow", DynamicText({
		x = 5, y = 39,
		font = assets:loadFont("Bold", 16),
		depth = 0.9,
		value = function ()
			return display_info.chartInfoFirstRow
		end
	}))

	top:addChild("chartInfoSecondRow", DynamicText({
		x = 5, y = 59,
		font = assets:loadFont("Regular", 16),
		depth = 0.9,
		value = function ()
			return display_info.chartInfoSecondRow
		end
	}))

	top:addChild("chartInfoThirdRow", DynamicText({
		x = 4, y = 76,
		font = assets:loadFont("Regular", 11),
		depth = 0.9,
		value = function ()
			return display_info.chartInfoThirdRow
		end
	}))

	local ranking_options = {
		["local"] = text.SongSelection_Rank_Local,
		online = text.SongSelection_Rank_Top,
		osuv1 = "osu!mania V1",
		osuv2 = "osu!mania V2",
		etterna = "Etterna J4",
		quaver = "Quaver"
	}
	local score_sources = select_view:getScoreSources()
	top:addChild("scoreSource", Combo({
		x = 8, y = 117,
		totalW = 308,
		totalH = 34,
		font = assets:loadFont("Regular", 18),
		borderColor = { 0.08, 0.51, 0.7, 1 },
		hoverColor = { 0.08, 0.51, 0.7, 1 },
		items = score_sources,
		assets = assets,
		depth = 0.9,
		getValue = function ()
			return select_view:getScoreSource()
		end,
		onChange = function (index)
			select_view:setScoreSource(index)
		end,
		format = function (value)
			return ranking_options[value] or ""
		end
	}))

	top:addChild("chartWebPage", ImageButton({
		x = 330, y = 117,
		idleImage = assets:loadImage("rank-forum"),
		depth = 0.5,
		onClick = function ()
			select_view.game.selectController:openWebNotechart()
			--view.notificationView:show("Opening the link. Check your browser.")
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
		totalW = 193,
		totalH = 34,
		font = assets:loadFont("Regular", 18),
		borderColor = { 0.68, 0.82, 0.54, 1 },
		hoverColor = { 0.68, 0.82, 0.54, 1 },
		items = select_view:getSortFunctionNames(),
		assets = assets,
		depth = 0.9,
		getValue = function ()
			return select_view:getSortFunction()
		end,
		onChange = function (index)
			select_view:setSortFunction(index)
		end,
		format = function (value)
			return sort_group_format[value] or value
		end
	}))

	local sort_text = top:addChild("sortText", Label({
		x = sort_combo.x - sort_combo.totalW - 6, y = 24,
		origin = { x = 1, y = 0 },
		alignX = "right",
		text = text.SongSelection_Sort,
		font = assets:loadFont("Light", 29),
		color = { 0.68, 0.82, 0.54, 1 },
		depth = 0.5,
	}))

	local group_combo = top:addChild("groupCombo", Combo({
		x = sort_text.x - sort_text.totalW - 16, y = 28,
		origin = { x = 1, y = 0 },
		totalW = 193,
		totalH = 34,
		font = assets:loadFont("Regular", 18),
		borderColor = { 0.57, 0.76, 0.9, 1 },
		hoverColor = { 0.57, 0.76, 0.9, 1 },
		items = select_view:getGroups(),
		assets = assets,
		depth = 0.9,
		getValue = function ()
			return select_view:getGroup()
		end,
		onChange = function (index)
			select_view:setGroup(index)
		end,
		format = function (value)
			return sort_group_format[value] or value
		end
	}))

	top:addChild("groupText", Label({
		x = group_combo.x - group_combo.totalW - 6, y = 24,
		origin = { x = 1, y = 0 },
		ax = "right",
		text = text.SongSelection_Group,
		font = assets:loadFont("Light", 29),
		color = { 0.57, 0.76, 0.9, 1 },
		depth = 0.5,
	}))

	--- TABS ---
	local tab_img = assets:loadImage("selection-tab")
	local tab_y = 54
	local tab_font = assets:loadFont("Regular", 13)
	local no_grouping = tabs:addChild("noGrouping", TabButton({
		x = width - 15, y = tab_y,
		origin = { x = 1, y = 0 },
		image = tab_img,
		text = text.SongSelection_NoGrouping,
		font = tab_font,
		depth = 0.5,
		onClick = function ()
			self:selectTab("noGrouping")
		end
	}))

	local by_difficulty = tabs:addChild("byDifficulty", TabButton({
		x = no_grouping.x - no_grouping.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = tab_img,
		text = text.SongSelection_ByDifficulty,
		font = tab_font,
		depth = 0.4,
		onClick = function ()
			self:selectTab("byDifficulty")
		end
	}))

	local by_artist = tabs:addChild("byArtist", TabButton({
		x = by_difficulty.x - by_difficulty.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = tab_img,
		text = text.SongSelection_ByArtist,
		font = tab_font,
		depth = 0.3,
		onClick = function ()
			self:selectTab("byArtist")
		end
	}))

	local recently_played = tabs:addChild("recentlyPlayed", TabButton({
		x = by_artist.x - by_artist.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = tab_img,
		text = text.SongSelection_RecentlyPlayed,
		font = tab_font,
		depth = 0.2,
		onClick = function ()
			self:selectTab("recentlyPlayed")
		end
	}))

	tabs:addChild("collections", TabButton({
		x = recently_played.x - recently_played.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = tab_img,
		text = text.SongSelection_Collections,
		font = tab_font,
		depth = 0.1,
		onClick = function ()
			self:selectTab("collections")
		end
	}))

	----------- BOTTOM -----------

	bottom:addChild("background", Image({
		y = height,
		origin = { x = 0, y = 1 },
		image = assets:loadImage("songselect-bottom"),
		totalW = width
	}))

	bottom:addChild("backButton", BackButton({
		y = height - 58,
		assets = assets,
		font = assets:loadFont("Regular", 20),
		text = "back",
		hoverWidth = 93,
		hoverHeight = 58,
		depth = 0.9,
		onClick = function ()
			select_view:quit()
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
		blockMouseFocus = false,
		depth = 0.4
	}))
	---@cast mode_icon osu.ui.Image

	bottom:addChild("modeSelection", ImageButton({
		x = 224, y = height,
		origin = { x = 0, y = 1 },
		idleImage = assets:loadImage("selection-mode"),
		hoverImage = assets:loadImage("selection-mode-over"),
		depth = 0.3,
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
		depth = 0.3,
	}))

	bottom:addChild("randomButton", ImageButton({
		x = 393, y = height,
		origin = { x = 0, y = 1 },
		idleImage = assets:loadImage("selection-random"),
		hoverImage = assets:loadImage("selection-random-over"),
		depth = 0.3,
	}))

	bottom:addChild("beatmapOptionsButton", ImageButton({
		x = 470, y = height,
		origin = { x = 0, y = 1 },
		idleImage = assets:loadImage("selection-options"),
		hoverImage = assets:loadImage("selection-options-over"),
		depth = 0.3,
	}))

	bottom:addChild("osuLogo", Image({
		x = width - 40, y = height - 40,
		origin = { x = 0.5, y = 0.5 },
		scale = 0.4,
		image = assets:loadImage("menu-osu-logo"),
		depth = 0.1
	}))

	tabs:build()
	top:build()
	bottom:build()
	self:build()
end

---@alias TabNames "noGrouping" | "byDifficulty" | "byArtist" | "recentlyPlayed" | "collections"
---@param selected TabNames  
function View:selectTab(selected)
	local top_container = self.children.topContainer ---@cast top_container osu.ui.Container
	local tab_container = top_container.children.tabContainer ---@cast tab_container osu.ui.Container
	local c = tab_container.children

	---@type {[TabNames]: { element: osu.ui.UiElement, depth: number, onClick: function}}
	local tabs = {
		noGrouping = {
			element = c.noGrouping,
			depth = 0.5,
			onClick = function () end
		},
		byDifficulty = {
			element = c.byDifficulty,
			depth = 0.4,
			onClick = function () end
		},
		byArtist = {
			element = c.byArtist,
			depth = 0.3,
			onClick = function () end
		},
		recentlyPlayed = {
			element = c.recentlyPlayed,
			depth = 0.2,
			onClick = function () end
		},
		collections = {
			element = c.collections,
			depth = 0.1,
			onClick = function () end
		}
	}
	---@cast tabs {[TabNames]: { element: osu.ui.TabButton, depth: number, onClick: function}}
	assert(tabs[selected], "Tab " .. selected .. " does not exist")

	for _, v in pairs(tabs) do
		v.element.depth = v.depth
		v.element.active = false
	end

	local s = tabs[selected]
	s.element.active = true
	s.element.depth = 1
	s.onClick()
	tab_container:build()
end

return View
