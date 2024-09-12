local class = require("class")
local flux = require("flux")
local math_util = require("math_util")
local ui = require("osu_ui.ui")

local Format = require("sphere.views.Format")

local ChartSetListView = class()

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

function ChartSetListView:reloadItems()
	self.items = self:getItems()
	self.itemCount = #self.items
	self.stateCounter = self.game.selectModel.noteChartSetStateCounter

	self.window = {}
	self.windowSize = math.min(16, self.itemCount) -- lists with less than 16 items exist

	if self.windowSize == 0 then
		return
	end

	local selected_index = self:getSelectedItemIndex()
	self.selectedVisualItemIndex = selected_index

	-- Visual index as float
	self.scroll = selected_index - math.floor(self.windowSize / 2)
	self.smoothScroll = self.scroll
	self.previousScroll = self.scroll

	-- scroll can be negative and greater than item count
	-- and we need make sure it's not greater than (self.itemCount - self.windowSize + 1) cuz otherwise self.last would be not where we want
	local scroll_clamped = math_util.clamp(self.scroll, 1, self.itemCount - self.windowSize + 1)
	-- Represents range
	self.first = 1 + (scroll_clamped - 1) % self.windowSize
	self.last = 1 + (scroll_clamped - 1 - 1) % self.windowSize

	self.mouseOverIndex = -1

	for _ = 1, self.windowSize do
		table.insert(self.window, {})
	end

	local start_index =
		math.min(math.max(1, selected_index - math.floor(self.windowSize / 2)), self.itemCount - self.windowSize + 1)

	self:iterOverWindow(function(s, set, on_screen_index, window_index)
		self:updateSet(window_index, start_index + on_screen_index)
	end)

	self:iterOverWindow(self.applyEffects, 9999)
end

function ChartSetListView:getSelectedItemIndex()
	return self.game.selectModel.chartview_set_index
end

function ChartSetListView:getItems()
	return self.game.selectModel.noteChartSetLibrary.items
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

	set.title = item.title or "Invalid title"

	if item.format == "sm" then
		set.secondRow = ("%s // %s"):format(item.artist, item.set_dir)
	else
		set.secondRow = ("%s // %s"):format(item.artist, item.creator)
	end

	set.thirdRow = ("%s (%s)"):format(item.name, Format.inputMode(item.inputmode))
	set.stars = item.osu_diff
end

---@param f fun(ChartSetListView, table, number, number, ...)
function ChartSetListView:iterOverWindow(f, ...)
	local window = self.window
	local first = self.first
	local size = self.windowSize

	for i = 0, size - 1 do
		local index = 1 + (first + i - 1) % size
		f(self, window[index], i, index, ...) -- ChartSetListView, set, on_screen_index, window index
	end
end

local panel_w = 500
local panel_h = 90

local hover_anim_speed = 3
local select_anim_speed = 3

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
	local slide_close_to_middle = math.abs(set.visualIndex - (self.smoothScroll + self.windowSize / 2))
	slide_close_to_middle = (slide_close_to_middle * slide_close_to_middle)

	-- X
	local x = hover * 20 - slide_close_to_middle * 6
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

	if self.scroll < -self.windowSize / 2 then
		self.scroll = -self.windowSize / 2
	end

	if self.scrollTween then
		self.scrollTween:stop()
	end

	self.scrollTween = flux.to(self, 0.2, { smoothScroll = self.scroll }):ease("quadout"):onupdate(function()
		self:loadNewSets()
	end)
end

function ChartSetListView:mousePress(visual_index)
	self.game.selectModel:scrollNoteChartSet(nil, visual_index)

	self.scroll = visual_index - self.windowSize / 2

	if self.scrollTween then
		self.scrollTween:stop()
	end

	self.scrollTween = flux.to(self, 0.2, { smoothScroll = self.scroll }):ease("quadout"):onupdate(function()
		self:loadNewSets()
	end)
end

function ChartSetListView:loadNewSets()
	if self.smoothScroll < 1 then
		return
	end

	if self.smoothScroll > self.itemCount - self.windowSize + 1 then
		return
	end

	local scroll_floored = math.floor(self.smoothScroll)

	self.first = 1 + ((scroll_floored - 1) % self.windowSize)
	self.last = 1 + ((scroll_floored - 1 - 1) % self.windowSize)

	-- Visible sets on the screen. Anything greater than that is not visible on the screen.
	-- If the scroll is millions sets per second, we would only see {self.windowSize} sets on the screen each frame
	local delta = scroll_floored - math.floor(self.previousScroll)
	local new_sets_count = math.min(math.abs(delta), self.windowSize)

	if delta >= 1 then
		self.previousScroll = self.smoothScroll
		for i = 1, new_sets_count do
			-- first - i
			local window_i = 1 + (self.first - 1 - i) % self.windowSize
			self:updateSet(window_i, scroll_floored - i + self.windowSize)
		end
	elseif delta <= -1 then
		self.previousScroll = self.smoothScroll
		for i = 1, new_sets_count do
			-- last + i
			local window_i = 1 + (self.last - 1 + i) % self.windowSize
			self:updateSet(window_i, scroll_floored - 1 + i)
		end
	end
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

	gfx.setColor(color_mix)

	gfx.draw(self.panelImage)

	gfx.setColor(self.assets.params.songSelectInactiveText)
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
		gfx.setColor(self.assets.params.songSelectInactiveText)
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
