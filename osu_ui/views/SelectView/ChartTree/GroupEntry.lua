local Component = require("ui.Component")
local Image = require("ui.Image")
local Label = require("ui.Label")
local ui = require("osu_ui.ui")

---@class osu.ui.ChartEntry : ui.Component
---@operator call: osu.ui.ChartEntry
---@field index integer
---@field setIndex integer
---@field list osu.ui.WindowList
---@field flashT number
---@field selectedT number
---@field selectedSetT number
local ChartEntry = Component + {}

local blue = { 0.13, 0.2, 0.56, 1 }
local green = { 0.63, 0.94, 0.17, 1 }

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

	self.inactiveText = assets.params.songSelectInactiveText ---@type number[]
	self.activeText = assets.params.songSelectActiveText ---@type number[]
	self.infoColor = { self.inactiveText[1], self.inactiveText[2], self.inactiveText[3], self.inactiveText[4] }
	self.backgroundColor = { blue[1], blue[2], blue[3], blue[4] }

	self.background = self:addChild("background", Image({
		y = 90 / 2,
		origin = { y = 0.5 },
		image = assets:loadImage("menu-button-background"),
		color = self.backgroundColor
	}))

	local label = self:addChild("label", Label({
		x = 20, y = 2,
		boxHeight = 90,
		alignX = "left",
		alignY = "center",
		font = fonts:loadFont("Regular", 33),
		text = "",
		color = self.infoColor,
		z = 1
	})) ---@cast label ui.Label

	self.label = label

	local side = self.list.side

	if side == self.list.LEFT_SIDE then
	elseif side == self.list.MIDDLE_SIDE then
	end
end

function ChartEntry:update()
	local t = self.selectedT
	self.infoColor[1] = t
	self.infoColor[2] = t
	self.infoColor[3] = t

	local s = self.selectedT
	local bg = self.backgroundColor
	bg[1] = green[1] * (1 - s) + blue[1] * s
	bg[2] = green[2] * (1 - s) + blue[2] * s
	bg[3] = green[3] * (1 - s) + blue[3] * s

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

---@param item {[string]: any}
---@param tree table
function ChartEntry:setInfo(item, tree)
	local name = item.name

	if item.depth == tree.depth and item.depth ~= 0 then
		name = "."
	elseif item.depth == tree.depth - 1 then
		name = ".."
	end

	if name == "/" then
		name = "All songs"
	end

	self.label:replaceText(name)
	--self.chartsCount = ("Charts: %i"):format(item.count)
end

return ChartEntry
