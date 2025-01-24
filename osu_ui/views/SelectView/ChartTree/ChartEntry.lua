local Component = require("ui.Component")
local Image = require("ui.Image")
local QuadImage = require("ui.QuadImage")
local Label = require("ui.Label")
local ui = require("osu_ui.ui")

local Format = require("sphere.views.Format")

---@class osu.ui.ChartEntry : ui.Component
---@operator call: osu.ui.ChartEntry
---@field index integer
---@field setIndex integer
---@field list osu.ui.WindowList
---@field flashT number
---@field selectedT number
---@field selectedSetT number
local ChartEntry = Component + {}

local blue = {love.math.colorFromBytes(0, 150, 236, 240)}
local inactive_background = {love.math.colorFromBytes(235, 73, 153, 240)}
local active_background = ui.lighten(blue, 0.3)
local lamp_color = { 0.99, 0.98, 0.44, 1 }

function ChartEntry:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	self.assets = assets
	self.fonts = fonts
	self.flashT = 0
	self.selectedT = 0
	self.selectedSetT = 0
	self.width = 700
	self.height = 103
	self.blockMouseFocus = true

	self.inactiveText = assets.params.songSelectInactiveText
	self.activeText = assets.params.songSelectActiveText
	self.infoColor = { self.inactiveText[1], self.inactiveText[2], self.inactiveText[3], self.inactiveText[4] }
	self.backgroundColor = { inactive_background[1], inactive_background[2], inactive_background[3], inactive_background[4] }

	self.background = self:addChild("background", Image({
		y = 90 / 2,
		origin = { y = 0.5 },
		image = assets:loadImage("menu-button-background"),
		color = self.backgroundColor
	}))

	local y = 5
	local preview_icon_w = 108 -- or 0
	self.icon = self:addChild("icon", Image({
		x = 20 + preview_icon_w, y = y + 2,
		image = assets:loadImage("mode-mania-small-for-charts"),
		scale = 0.8,
		color = self.infoColor,
		z = 0.1
	}))

	local title = self:addChild("title", Label({
		x = preview_icon_w + 15 + 40, y = y,
		font = fonts:loadFont("Regular", 22),
		text = "",
		color = self.infoColor,
		z = 1
	})) ---@cast title ui.Label

	local second_row = self:addChild("secondRow", Label({
		x = preview_icon_w + 15 + 40, y = y + 22,
		font = fonts:loadFont("Regular", 16),
		text = "",
		color = self.infoColor,
		z = 1
	})) ---@cast second_row ui.Label

	local third_row = self:addChild("thirdRow", Label({
		x = preview_icon_w + 15 + 40, y = y + 22 + 18,
		font = fonts:loadFont("Regular", 16),
		text = "",
		color = self.infoColor,
		z = 1
	})) ---@cast third_row ui.Label

	local star_image = assets.specialKids.star
	star_image:setWrap("repeat")
	local stars = self:addChild("stars", QuadImage({
		x = preview_icon_w + 17 + 40, y = 74,
		origin = { x = 0, y = 0.5 },
		scale = 0.35,
		image = star_image,
		quad = love.graphics.newQuad(0, 0, star_image:getWidth() * 2, star_image:getHeight(), star_image:getWidth(), star_image:getHeight()),
		color = self.infoColor,
		z = 0.5,
	})) ---@cast stars ui.QuadImage

	self.title = title
	self.secondRow = second_row
	self.thirdRow = third_row
	self.stars = stars

	local side = self.list.side

	if side == self.list.LEFT_SIDE then
		self.icon.x = self.width - 20 - preview_icon_w
		self.title.x = self.width - preview_icon_w - 30
		self.secondRow.x = self.width - preview_icon_w - 30
		self.thirdRow.x = self.width - preview_icon_w - 30
		self.stars.x = self.width - preview_icon_w - 40
		self.title.origin.x = 1
		self.secondRow.origin.x = 1
		self.thirdRow.origin.x = 1
		self.stars.origin.x = 1
	elseif side == self.list.MIDDLE_SIDE then
		self.icon.alpha = 0
		local t = self.title
		local sr = self.secondRow
		local tr = self.thirdRow
		t.x = 0
		sr.x = 0
		tr.x = 0
		t.boxWidth = self.width
		sr.boxWidth = self.width
		tr.boxWidth = self.width
		t.alignX = "center"
		sr.alignX = "center"
		tr.alignX = "center"
		self.stars.x = self.width / 2
		self.stars.origin.x = 0.5
	end
end

function ChartEntry:update()
	local t = self.selectedT

	local active_text = self.activeText
	local inactive_text = self.inactiveText
	self.infoColor[1] = active_text[1] * (1 - t) + inactive_text[1] * t
	self.infoColor[2] = active_text[2] * (1 - t) + inactive_text[2] * t
	self.infoColor[3] = active_text[3] * (1 - t) + inactive_text[3] * t

	local st = self.selectedSetT
	local bg = self.backgroundColor
	bg[1] = active_background[1] * (1 - st) + inactive_background[1] * st
	bg[2] = active_background[2] * (1 - st) + inactive_background[2] * st
	bg[3] = active_background[3] * (1 - st) + inactive_background[3] * st

	bg[1] = 1 - t + bg[1] * t
	bg[2] = 1 - t + bg[2] * t
	bg[3] = 1 - t + bg[3] * t

	-- Flash
	local ft = self.flashT
	bg[1] = math.min(1, bg[1] * (1 + ft))
	bg[2] = math.min(1, bg[2] * (1 + ft))
	bg[3] = math.min(1, bg[3] * (1 + ft))
end

function ChartEntry:mouseClick(event)
	if not self.mouseOver or event.key == 2 then
		return false
	end
	self.list:selectItem(self.index)
	return true
end

function ChartEntry:justHovered()
	self.list:justHoveredOver(self.index)
end

---@param chart {[string]: any}
function ChartEntry:setInfo(chart)
	local title = chart.title

	if not title then
		self.title:replaceText(("%s | %s"):format(chart.chartfile_name or "", chart.set_name or ""))
		self.secondRow:replaceText("PRESS F5, this chart is not cached for some reason")
		self.thirdRow:replaceText(chart.dir)
		return
	end

	self.title:replaceText(title)

	if chart.format == "sm" then
		self.secondRow:replaceText(("%s // %s"):format(chart.artist, chart.set_dir))
	else
		self.secondRow:replaceText(("%s // %s"):format(chart.artist, chart.creator))
	end

	local third_row = ("%s (%s)"):format(chart.name, Format.inputMode(chart.inputmode))

	self.thirdRow:replaceText(third_row)
	local iw, ih = self.stars.image:getDimensions()
	self.stars:setViewport(0, 0, chart.osu_diff * iw, ih)
	self.stars.color = chart.lamp and lamp_color or self.infoColor
end

return ChartEntry
