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
	local img = assets.images
	local snd = assets.sounds

	local all_fonts = assets.localization.fontGroups
	local text, font = assets.localization:get("songSelect")
	assert(text and font)

	local width, height = self.parent.totalW, self.parent.totalH

	local top = self:addChild("topContainer", Container({ totalW = width, totalH = height, depth = 0.5 }))
	local bottom = self:addChild("bottomContainer", Container({ depth = 0.6 }))
	---@cast top osu.ui.Container
	---@cast bottom osu.ui.Container

	local tabs = top:addChild("tabContainer", Container({ depth = 0.5 }))
	---@cast tabs osu.ui.Container

	--[[
	local screenshot = self:addChild("screenshot", Image({
		image = select_view.screenshot,
		depth = 1,
	}))
	function screenshot:update(dt)
		Image.update(self, dt)
		local mx, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
		screenshot.alpha = mx / width
	end]]

	----------- TOP -----------

	top:addChild("background", Image({
		image = img.panelTop,
		wrap = "clamp",
		quad = love.graphics.newQuad(0, 0, width, img.panelTop:getHeight(), img.panelTop),
	}))

	top:addChild("statusIcon", Image({
		x = 5, y = 5,
		image = img.rankedIcon,
		depth = 0.9
	}))

	top:addChild("chartName", DynamicText({
		x = 38, y = -5,
		font = font.chartName,
		depth = 0.9,
		value = function ()
			return display_info.chartName
		end
	}))

	top:addChild("chartSource", DynamicText({
		x = 40, y = 20,
		font = font.chartedBy,
		depth = 0.9,
		value = function ()
			return display_info.chartSource
		end
	}))

	top:addChild("chartInfoFirstRow", DynamicText({
		x = 5, y = 39,
		font = font.infoTop,
		depth = 0.9,
		value = function ()
			return display_info.chartInfoFirstRow
		end
	}))

	top:addChild("chartInfoSecondRow", DynamicText({
		x = 5, y = 59,
		font = font.infoCenter,
		depth = 0.9,
		value = function ()
			return display_info.chartInfoSecondRow
		end
	}))

	top:addChild("chartInfoThirdRow", DynamicText({
		x = 4, y = 76,
		font = font.infoBottom,
		depth = 0.9,
		value = function ()
			return display_info.chartInfoThirdRow
		end
	}))

	top:addChild("scoreSource", Combo({
		x = 8, y = 117,
		totalW = 308,
		totalH = 34,
		font = font.dropdown,
		borderColor = { 0.08, 0.51, 0.7, 1 },
		hoverColor = { 0.08, 0.51, 0.7, 1 },
		depth = 0.9,
		getValue = function ()
			return select_view.selectedScoreSource, select_view.scoreSources
		end,
		onChange = function (value)
			select_view.selectedScoreSource = value
		end,
	}))

	top:addChild("chartWebPage", ImageButton({
		x = 330, y = 117,
		idleImage = img.forum,
		depth = 0.5,
		onClick = function ()
			select_view.game.selectController:openWebNotechart()
			--view.notificationView:show("Opening the link. Check your browser.")
		end
	}))

	local sort_combo = top:addChild("sortCombo", Combo({
		x = width - 16, y = 28,
		origin = { x = 1, y = 0 },
		totalW = 193,
		totalH = 34,
		font = font.dropdown,
		borderColor = { 0.68, 0.82, 0.54, 1 },
		hoverColor = { 0.68, 0.82, 0.54, 1 },
		depth = 0.9,
		getValue = function ()
			return select_view.selectedScoreSource, select_view.scoreSources
		end,
		onChange = function (value)
			select_view.selectedScoreSource = value
		end,
	}))

	local sort_text = top:addChild("sortText", Label({
		x = sort_combo.x - sort_combo.totalW - 6, y = 24,
		origin = { x = 1, y = 0 },
		ax = "right",
		text = text.sort,
		font = font.groupSort,
		color = { 0.68, 0.82, 0.54, 1 },
		depth = 0.5,
	}))

	local group_combo = top:addChild("groupCombo", Combo({
		x = sort_text.x - sort_text.totalW - 16, y = 28,
		origin = { x = 1, y = 0 },
		totalW = 193,
		totalH = 34,
		font = font.dropdown,
		borderColor = { 0.57, 0.76, 0.9, 1 },
		hoverColor = { 0.57, 0.76, 0.9, 1 },
		depth = 0.9,
		getValue = function ()
			return select_view.selectedScoreSource, select_view.scoreSources
		end,
		onChange = function (value)
			select_view.selectedScoreSource = value
		end,
	}))

	top:addChild("groupText", Label({
		x = group_combo.x - group_combo.totalW - 6, y = 24,
		origin = { x = 1, y = 0 },
		ax = "right",
		text = text.group,
		font = font.groupSort,
		color = { 0.57, 0.76, 0.9, 1 },
		depth = 0.5,
	}))

	--- TABS ---
	local tab_y = 54
	local no_grouping = tabs:addChild("noGrouping", TabButton({
		x = width - 15, y = tab_y,
		origin = { x = 1, y = 0 },
		image = img.tab,
		label = text.noGrouping,
		font = font.tabs,
		depth = 0.5,
		onClick = function ()
			self:selectTab("noGrouping")
		end
	}))

	local by_difficulty = tabs:addChild("byDifficulty", TabButton({
		x = no_grouping.x - no_grouping.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = img.tab,
		label = text.byDifficulty,
		font = font.tabs,
		depth = 0.4,
		onClick = function ()
			self:selectTab("byDifficulty")
		end
	}))

	local by_artist = tabs:addChild("byArtist", TabButton({
		x = by_difficulty.x - by_difficulty.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = img.tab,
		label = text.byArtist,
		font = font.tabs,
		depth = 0.3,
		onClick = function ()
			self:selectTab("byArtist")
		end
	}))

	local recently_played = tabs:addChild("recentlyPlayed", TabButton({
		x = by_artist.x - by_artist.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = img.tab,
		label = text.recent,
		font = font.tabs,
		depth = 0.2,
		onClick = function ()
			self:selectTab("recentlyPlayed")
		end
	}))

	tabs:addChild("collections", TabButton({
		x = recently_played.x - recently_played.totalW + 25, y = tab_y,
		origin = { x = 1, y = 0 },
		image = img.tab,
		label = text.collections,
		font = font.tabs,
		depth = 0.1,
		onClick = function ()
			self:selectTab("collections")
		end
	}))

	----------- BOTTOM -----------

	bottom:addChild("background", Image({
		y = height,
		origin = { x = 0, y = 1 },
		image = img.panelBottom,
		totalW = width
	}))

	bottom:addChild("backButton", BackButton({
		y = height - 58,
		font = all_fonts.misc.backButton,
		text = "back",
		arrowImage = img.menuBackArrow,
		clickSound = snd.menuBack,
		hoverSound = snd.hoverOverRect,
		hoverWidth = 93,
		hoverHeight = 58,
		depth = 0.9,
		onClick = function ()
			select_view:quit()
		end
	}))

	local selected_mode_index = 4
	local small_icons = {
		img.osuSmallIcon,
		img.taikoSmallIcon,
		img.fruitsSmallIcon,
		img.maniaSmallIcon,
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
		idleImage = img.modeButton,
		hoverImage = img.modeButtonOver,
		depth = 0.3,
		onClick = function ()
			selected_mode_index = 1 + (selected_mode_index % #small_icons)
			mode_icon:replaceImage(small_icons[selected_mode_index])
		end
	}))

	bottom:addChild("modsSelection", ImageButton({
		x = 316, y = height,
		origin = { x = 0, y = 1 },
		idleImage = img.modsButton,
		hoverImage = img.modsButtonOver,
		depth = 0.3,
	}))

	bottom:addChild("randomButton", ImageButton({
		x = 393, y = height,
		origin = { x = 0, y = 1 },
		idleImage = img.randomButton,
		hoverImage = img.randomButtonOver,
		depth = 0.3,
	}))

	bottom:addChild("beatmapOptionsButton", ImageButton({
		x = 470, y = height,
		origin = { x = 0, y = 1 },
		idleImage = img.optionsButton,
		hoverImage = img.optionsButtonOver,
		depth = 0.3,
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
