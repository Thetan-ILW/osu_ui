local ListItem = require("osu_ui.views.SelectView.Lists.ListItem")

local math_util = require("math_util")
local Format = require("sphere.views.Format")
local getModifierString = require("osu_ui.views.modifier_string")

---@class osu.ui.WindowListChartItem : osu.ui.WindowListItem
---@operator call: osu.ui.WindowListChartItem
---@field title string
---@field secondRow string
---@field thirdRow string
---@field stars number
---@field isChart boolean
---@field chartIndex number?
---@field maniaIcon love.Image
---@field lamp boolean
local ChartItem = ListItem + {}

---@param chart table
function ChartItem:replaceWith(chart)
	ListItem.replaceWith(self)

	self.title = chart.title

	if not self.title then
		self.title = ("%s | %s"):format(chart.chartfile_name or "", chart.set_name or "")
		self.secondRow = "PRESS F5, this chart is not cached for some reason"
		self.thirdRow = chart.dir
		self.stars = 0
		return
	end

	if chart.format == "sm" then
		self.secondRow = ("%s // %s"):format(chart.artist, chart.set_dir)
	else
		self.secondRow = ("%s // %s"):format(chart.artist, chart.creator)
	end

	local rate = chart.rate or 1
	local mods = getModifierString(chart.modifiers or {})

	if rate ~= 1 then
		self.thirdRow = ("%s %gx (%s)"):format(chart.name, rate, Format.inputMode(chart.inputmode))
	elseif mods ~= "" then
		self.thirdRow = ("%s (%s)%s"):format(chart.name, Format.inputMode(chart.inputmode), mods)
	elseif rate ~= 1 and mods ~= "" then
		self.thirdRow = ("%s %gx (%s)%s"):format(chart.name, rate, Format.inputMode(chart.inputmode), mods)
	else
		self.thirdRow = ("%s (%s)"):format(chart.name, Format.inputMode(chart.inputmode))
	end

	if self.list.showScoreDate and chart.score_time then
		self.thirdRow = ("%s %s"):format(self.thirdRow, os.date("%d.%m.%Y", chart.score_time))
	end

	self.stars = math.min(chart.osu_diff or 0, 10)
	self.lamp = chart.lamp
end

local gfx = love.graphics
local lamp_color = { 0.99, 0.98, 0.44, 1 }

function ChartItem:drawChartPanel(pc, tc)
	local r, g, b, a = gfx.getColor()

	gfx.push()
	gfx.setColor(pc[1], pc[2], pc[3], pc[4] * a)
	gfx.draw(self.background, 0, self.height / 2, 0, 1, 1, 0, self.background:getHeight() / 2)

	local preview_icon_w = self.list.previewIcon and 115 or 0
	gfx.setColor(tc[1], tc[2], tc[3], tc[4] * a)
	gfx.translate(20 + preview_icon_w, 5)
	gfx.draw(self.maniaIcon)

	local ts = 1 / self.titleFont.dpiScale
	gfx.translate(40, -4)
	gfx.setFont(self.titleFont.instance)
	gfx.print(self.title, 0, 0, 0, ts, ts)


	gfx.setFont(self.infoFont.instance)
	gfx.translate(0, 22)
	gfx.print(self.secondRow, 0, 0, 0, ts, ts)
	gfx.translate(0, 18)
	gfx.print(self.thirdRow, 0, 0, 0, ts, ts)
	gfx.pop()

	local star = self.star
	local iw, ih = star:getDimensions()

	gfx.translate(80 + preview_icon_w, self.height - 17)

	if self.lamp then
		gfx.setColor(lamp_color)
	end

	for si = 0, 10, 1 do
		if si >= self.stars then
			return
		end

		local scale = math_util.clamp(self.stars - si, 0.3, 1) * 0.6

		gfx.draw(star, 0, 0, 0, scale, scale, iw / 2, ih / 2)
		gfx.translate(iw * 0.6, 0)
	end
end


function ChartItem:draw()
	if not self:isVisible() then
		return
	end

	local inactive_panel = ChartItem.inactivePanel
	local active_panel = ChartItem.activePanel
	local inactive_text = self.list.assets.params.songSelectInactiveText
	local active_text = self.list.assets.params.songSelectActiveText

	local main_color = inactive_panel

	local ct = self.selectedT

	local panel_color = self.mixTwoColors(main_color, active_panel, ct)
	panel_color[4] = panel_color[4] * self.alpha

	if self.flashColorT ~= 0 then
		panel_color = self.lighten(panel_color, self.flashColorT * 0.3)
	end

	local text_color = self.mixTwoColors(inactive_text, active_text, ct)
	text_color[4] = text_color[4] * self.alpha

	self:drawChartPanel(panel_color, text_color)
end

return ChartItem
