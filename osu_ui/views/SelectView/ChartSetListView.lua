local WindowListView = require("osu_ui.views.WindowListView")
local math_util = require("math_util")
local ui = require("osu_ui.ui")

local Format = require("sphere.views.Format")

---@class osu.ui.ChartListView : osu.ui.WindowListView
---@operator call: osu.ui.ChartListView
local ChartSetListView = WindowListView + {}

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ChartSetListView:new(game, assets)
	self.game = game
	self.assets = assets

	self.font = self.assets.localization.fontGroups.chartSetList

	local img = self.assets.images
	self.panelImage = img.listButtonBackground
	self.maniaIcon = img.maniaSmallIconForCharts
	self.starImage = img.star
	self:reloadItems()
end

function ChartSetListView:getSelectedItemIndex()
	return self.game.selectModel.chartview_set_index
end

function ChartSetListView:getItems()
	return self.game.selectModel.noteChartSetLibrary.items
end

function ChartSetListView:reloadItems()
	WindowListView.reloadItems(self)
	self:iterOverWindow(self.applyEffects, 9999)
end

function ChartSetListView:updateSet(window_index, visual_index)
	local item = self.items[visual_index]

	local set = self.window[window_index]
	set.visualIndex = visual_index
	set.setId = item.id

	set.x = 0
	set.y = 0
	set.mouseOver = false
	set.hoverT = 0
	set.selectedT = 0
	set.slideX = 55

	set.title = item.title or "Invalid title"

	if item.format == "sm" then
		set.secondRow = ("%s // %s"):format(item.artist, item.set_dir)
	else
		set.secondRow = ("%s // %s"):format(item.artist, item.creator)
	end

	set.thirdRow = ("%s (%s)"):format(item.name, Format.inputMode(item.inputmode))
	set.stars = item.osu_diff
end

local panel_w = 500
local panel_h = 90

local hover_anim_speed = 3
local select_anim_speed = 3
local slide_anim_speed = 1.3
local slide_power = 4

function ChartSetListView:applyEffects(set, on_screen_index, window_index, dt)
	---- HOVER
	if set.mouseOver then
		set.hoverT = math.min(1, set.hoverT + dt * hover_anim_speed)
	else
		set.hoverT = math.max(0, set.hoverT - dt * hover_anim_speed)
	end

	local hover = 1 - math.pow(1 - set.hoverT, 3)

	---- SELECTED

	local selected_t = math_util.clamp(
		set.selectedT
			+ (set.visualIndex == self.selectedVisualItemIndex and dt * select_anim_speed or -dt * select_anim_speed),
		0,
		1
	)

	set.selectedT = selected_t

	local selected = 1 - math.pow(1 - math.min(1, selected_t), 3)

	---- SLIDE
	local target_slide = math.abs(set.visualIndex - (self.smoothScroll + self.windowSize / 2))

	if math.abs(target_slide) < self.windowSize / 2 then
		target_slide = (target_slide * target_slide)

		local distance = target_slide - set.slideX
		local step = distance * slide_anim_speed * dt
		local progress = math.min(math.abs(step) / math.abs(distance), 1)
		local slide_ease = 1 - (1 - progress) ^ 3
		set.slideX = set.slideX + distance * slide_ease
	end

	-- X
	local x = hover * 20 - set.slideX * slide_power
	set.x = x + (selected * 100)

	-- Y
	local scroll = (set.visualIndex - (self.smoothScroll + self.windowSize / 2)) * panel_h

	scroll = scroll + panel_h * (self.windowSize / (self.windowSize / 4)) - panel_h / 3

	set.y = scroll
end

function ChartSetListView:mouseScroll(y)
	if self.windowSize == 0 then
		return
	end
	self.scroll = self.scroll + y
	self:animateScroll()
end

function ChartSetListView:mousePress(visual_index)
	self.game.selectModel:scrollNoteChartSet(nil, visual_index)
	self.scroll = visual_index - self.windowSize / 2
	self:animateScroll()
end

function ChartSetListView:update(dt)
	if self.stateCounter ~= self.game.selectModel.noteChartSetStateCounter then
		self:reloadItems()
	end

	if self.windowSize == 0 then
		return
	end

	self.selectedVisualItemIndex = self:getSelectedItemIndex()
	self:iterOverWindow(self.applyEffects, dt)

	if self.mouseOverIndex ~= -1 then
		if ui.mousePressed(1) then
			self:mousePress(self.mouseOverIndex)
		end
	end

	self.mouseOverIndex = -1
end

local gfx = love.graphics

local inactive_panel = { 0.89, 0.3, 0.59 }
local active_panel = { 1, 1, 1 }

function ChartSetListView:drawPanels(set, on_screen_index, window_index, w, h)
	local x, y = w - set.x - 400, set.y

	gfx.push()
	gfx.translate(x, y)

	set.mouseOver = ui.isOver(panel_w, panel_h)
	if set.mouseOver then
		self.mouseOverIndex = set.visualIndex
	end

	local st = set.selectedT
	local color_mix = {
		inactive_panel[1] * (1 - st) + active_panel[1] * st,
		inactive_panel[2] * (1 - st) + active_panel[2] * st,
		inactive_panel[3] * (1 - st) + active_panel[3] * st,
	}

	local inactive_text = self.assets.params.songSelectInactiveText
	local active_text = self.assets.params.songSelectActiveText
	local color_text_mix = {
		inactive_text[1] * (1 - st) + active_text[1] * st,
		inactive_text[2] * (1 - st) + active_text[2] * st,
		inactive_text[3] * (1 - st) + active_text[3] * st,
	}

	gfx.setColor(color_mix)
	gfx.draw(self.panelImage)

	gfx.setColor(color_text_mix)
	gfx.translate(20, 12)
	gfx.draw(self.maniaIcon)

	gfx.translate(40, -4)
	gfx.setFont(self.font.title)
	ui.text(set.title)

	gfx.setFont(self.font.secondRow)
	gfx.translate(0, -2)
	ui.text(set.secondRow)
	gfx.translate(0, -2)
	gfx.setFont(self.font.thirdRow)
	ui.text(set.thirdRow)
	gfx.pop()

	gfx.push()
	local iw, ih = self.starImage:getDimensions()

	gfx.translate(60 + x, y + panel_h + 6)
	gfx.scale(0.6)

	for si = 1, 10, 1 do
		if si >= (set.stars or 0) then
			gfx.setColor(1, 1, 1, 0.3)
		end

		gfx.draw(self.starImage, 0, 0, 0, 1, 1, 0, ih)
		gfx.translate(iw, 0)
		gfx.setColor(color_text_mix)
	end

	gfx.pop()
end

function ChartSetListView:draw(w, h)
	if self.windowSize == 0 then
		return
	end

	self:iterOverWindow(self.drawPanels, w, h)
end

return ChartSetListView
