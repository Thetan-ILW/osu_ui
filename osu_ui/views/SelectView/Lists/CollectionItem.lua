local ListItem = require("osu_ui.views.SelectView.Lists.ListItem")

---@class osu.ui.CollectionItem : osu.ui.WindowListItem
---@operator call: osu.ui.CollectionItem
---@field name string
---@field chartsCount string
local CollectionItem = ListItem + {}

CollectionItem.inactivePanel = { 0.13, 0.2, 0.56 }
CollectionItem.activePanel = { 0.63, 0.94, 0.17 }

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

	if name == "/" then
		name = "All songs"
	end

	self.name = name
	self.chartsCount = ("Charts: %i"):format(item.count)
end

function CollectionItem:update(dt)
	self.y = (self.visualIndex - 1) * self.height
	if self.visualIndex > self.list:getSelectedItemIndex() then
		self.y = self.y + self.list.holeSize
	end

	if not self:isVisible() then
		return
	end

	local hover = self:applyHover(dt)
	local slide = self:applySlide(self.visualIndex, self.list:getVisualIndex() + self.list.windowSize / 2, dt)
	self:applySelect(self.visualIndex == self.list:getSelectedItemIndex(), dt)
	self:applyColor(false, dt)
	self:applyFlash(dt)

	self.x = -hover * 20 + 20 + slide
end

local gfx = love.graphics

function CollectionItem:draw()
	if not self:isVisible() then
		return
	end

	local inactive_panel = self.inactivePanel
	local active_panel = self.activePanel
	local main_color = inactive_panel

	local inactive_text = self.list.assets.params.songSelectInactiveText
	local active_text = self.list.assets.params.songSelectActiveText

	local ct = self.selectedT

	local panel_color = self.mixTwoColors(main_color, active_panel, ct)

	if self.flashColorT ~= 0 then
		panel_color = self.lighten2(panel_color, self.flashColorT * 0.3)
	end

	local text_color = self.mixTwoColors(inactive_text, active_text, ct)

	gfx.setColor(panel_color)
	gfx.draw(self.background, 0, self.height / 2, 0, 1, 1, 0, self.background:getHeight() / 2)

	local font = self.titleFont
	gfx.setFont(font.instance)
	gfx.setColor(text_color)
	local text_scale = 1 / font.dpiScale
	gfx.translate(30, self.height / 2 - (font:getHeight() * text_scale) / 2)
	gfx.scale(text_scale)
	gfx.print(self.name)
end

return CollectionItem
