local ListView = require("osu_ui.views.ListView")
local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")

local ModifierModel = require("sphere.models.ModifierModel")

---@class osu.ui.AvailableModsView : osu.ui.ListView
---@operator call: osu.ui.AvailableModsView
local AvailableModsView = ListView + {}

local column_modifiers = {
	"Automap",
	"Alternate",
	"Alternate2",
	"MultiplePlay",
	"MultiOverPlay",
	"NoScratch",
}

local chart_modifiers = {
	"FullLongNote",
	"NoLongNote",
	"MinLnLength",
	"BracketSwap",
	"MaxChord",
	"LessChord",
}

local column_swap = {
	"Mirror",
	"Shift",
}

local fun = {
	"WindUp",
	"Taiko",
}

function AvailableModsView:load()
	self:assert(self.selectApi, "No select API")
	self.rows = 8
	self.viewport = self:getViewport()
	ListView.load(self)

	local area = self.scrollArea
	area.scrollDistance = 115

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.selectApi = scene.ui.selectApi
	self.fonts = scene.fontManager

	self.stencilFunction = function()
		love.graphics.rectangle("fill", 0, 0, self.width, self.height, 5, 5)
	end

	self:addCategory("KEYMODE MODIFIERS", column_modifiers)
	self:addCategory("CHART MODIFIERS", chart_modifiers)
	self:addCategory("COLUMN SWAP", column_swap)
	self:addCategory("FUN", fun)
end

---@param name string
---@param mods string[]
function AvailableModsView:addCategory(name, mods)
	local width, height = self.parent:getDimensions()
	local cell_height = self:getCellHeight()

	local category_cell = Component()
	category_cell:addChild("background", Rectangle({
		width = width,
		height = cell_height,
		color = { 0.7, 0.9, 1, 0.3 },
	}))
	category_cell:addChild("name", Label({
		alignY = "center",
		alignX = "center",
		boxWidth = width,
		boxHeight = cell_height,
		font = self.fonts:loadFont("Bold", 22),
		text = name,
		z = 0.1,
	}))
	self:addCell(category_cell)

	for i, v in ipairs(mods) do
		local mod = ModifierModel:getModifier(v)
		if mod then
			local cell = Component({
				width = width,
				height = cell_height,
				mouseClick = function(this)
					if this.mouseOver then
						self.selectApi:addMod(v)
						self.viewport:triggerEvent("event_modsChanged")
						return true
					end
				end
			})
			cell:addChild("background", Rectangle({
				width = width,
				height = cell_height,
				color = self:getCellBackgroundColor(),
			}))
			cell:addChild("name", Label({
				x = 10,
				alignY = "center",
				boxHeight = cell_height,
				font = self.fonts:loadFont("Light", 20),
				text = mod.name,
				z = 0.1,
			}))

			if self.selectApi:isModOneUse(v) then
				cell:addChild("oneUse", Label({
					x = -10,
					alignY = "center",
					alignX = "right",
					boxWidth = width,
					boxHeight = cell_height,
					font = self.fonts:loadFont("Light", 18),
					text = "One use",
					z = 0.1,
				}))
			end

			self:addCell(cell)
		end
	end

	self:addCell(Component())
end

return AvailableModsView

