local ListItem = require("osu_ui.views.SelectView.Lists.ListItem")

local ui = require("osu_ui.ui")

---@class osu.ui.CollectionItem : osu.ui.WindowListItem
---@operator call: osu.ui.CollectionItem
---@field name string
---@field chartsCount string
local CollectionItem = ListItem + {}

CollectionItem.inactivePanel = { 0.13, 0.2, 0.56 }
CollectionItem.activePanel = { 0.63, 0.94, 0.17 }

---@param item table
---@param tree table
function CollectionItem:new(item, tree)
	if item then
		self:replaceWith(item, tree)
	end
end

---@param item table
---@param tree table
function CollectionItem:replaceWith(item, tree)
	ListItem.replaceWith(self)

	---@type string
	local name = item.name

	if item.depth == tree.depth and item.depth ~= 0 then
		name = "."
	elseif item.depth == tree.depth - 1 then
		name = ".."
	end

	self.name = name
	self.chartsCount = ("Charts: %i"):format(item.count)
end

---@param list osu.ui.ChartListView
---@param dt number
function CollectionItem:applyItemEffects(list, dt)
	local panel_h = ListItem.panelH

	local selected_visual_index = list.selectedVisualItemIndex

	local smooth_scroll = list.smoothScroll
	local window_size = list.windowSize

	local actual_visual_index = self.visualIndex

	local hover = self:applyHover(dt)
	local slide = self:applySlide(actual_visual_index, list.smoothScroll + list.windowSize / 2, dt)
	local selected = self:applySelect(self.visualIndex == selected_visual_index, dt)

	local x = hover * 20 - slide
	self.x = x + selected * 84

	local scroll = (actual_visual_index - (smooth_scroll + window_size / 2)) * panel_h
	scroll = scroll + panel_h * (window_size / (window_size / 4)) - panel_h / 3

	self.y = scroll
end

local gfx = love.graphics

function CollectionItem:drawPanel(list, panel_color, text_color)
	gfx.push()
	gfx.setColor(panel_color)
	gfx.draw(list.panelImage, 0, 52, 0, 1, 1, 0, list.panelImage:getHeight() / 2)

	gfx.setColor(text_color)
	gfx.translate(40, 8)
	gfx.setFont(list.font.title)
	ui.text(self.name)

	gfx.setFont(list.font.secondRow)
	gfx.translate(0, -2)
	ui.text(self.chartsCount)
	gfx.pop()
end

function CollectionItem:draw(list)
	local inactive_panel = CollectionItem.inactivePanel
	local active_panel = CollectionItem.activePanel
	local main_color = inactive_panel

	local ct = self.selectedT

	local color_mix = {
		main_color[1] * (1 - ct) + active_panel[1] * ct,
		main_color[2] * (1 - ct) + active_panel[2] * ct,
		main_color[3] * (1 - ct) + active_panel[3] * ct,
		main_color[4],
	}

	local inactive_text = list.assets.params.songSelectInactiveText
	local active_text = list.assets.params.songSelectActiveText
	local color_text_mix = {
		inactive_text[1] * (1 - ct) + active_text[1] * ct,
		inactive_text[2] * (1 - ct) + active_text[2] * ct,
		inactive_text[3] * (1 - ct) + active_text[3] * ct,
	}

	self:drawPanel(list, color_mix, color_text_mix)
end

return CollectionItem
