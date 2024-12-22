local ListView = require("osu_ui.views.ListView")
local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")

local ModifierModel = require("sphere.models.ModifierModel")
local ModifierRegistry = require("sphere.models.ModifierModel.ModifierRegistry")

local flux = require("flux")

---@class osu.ui.SelectedModsView : osu.ui.ListView
local SelectedMods = ListView + {}

function SelectedMods:load()
	self.rows = 8
	ListView.load(self)

	local area = self.scrollArea
	area.scrollDistance = 115

	self.viewport = self:getViewport()
	self.viewport:listenForEvent(self, "event_modsChanged")

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.fonts = scene.fontManager
	self.selectApi = scene.ui.selectApi

	self.stencilFunction = function()
		love.graphics.rectangle("fill", 0, 0, self.width, self.height, 5, 5)
	end

	-- Accidentaly typed awwow instead of arrow, I like it UwU
	self.awwow = self:addChild("arrow", Component({
		z = 1,
		draw = function()
			love.graphics.translate(0, -self.scrollArea.scrollPosition)
			love.graphics.polygon("fill", 0,-10, 10,0, 0,10)
		end
	}))

	self:addCells()
	self:moveCursor()
end

function SelectedMods:addCells()
	local width, height = self.parent:getDimensions()
	local cell_height = self:getCellHeight()
	local items = self.selectApi:getSelectedMods()

	for i, item in ipairs(items) do
		local cell = Component({
			width = width,
			height = cell_height,
			mouseClick = function(this, event)
				if this.mouseOver then
					if event.key == 2 then
						self.selectApi:removeMod(i)
						self.viewport:triggerEvent("event_modsChanged")
						return true
					elseif event.key == 1 then
						local si = self.selectApi:getSelectedModifiersCursor()
						self.selectApi:moveSelectedModifiersCursor(i - si)
						self:moveCursor()
						return true
					end
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
			text = ModifierRegistry:getName(item.id),
			z = 0.1,
		}))
		self:addCell(cell)
	end

	local c = Component({
		width = width,
		height = height,
		mouseClick = function(this, event)
		if this.mouseOver and event.key == 1 then
				local si = self.selectApi:getSelectedModifiersCursor()
				self.selectApi:moveSelectedModifiersCursor(#items + 1 - si)
				self:moveCursor()
				return true
			end
		end
	})
	self:addCell(c)
end

function SelectedMods:scrollToCell(index)
	self.scrollArea:scrollToPosition(index * self:getCellHeight())
end

function SelectedMods:moveCursor()
	local target = (self.selectApi:getSelectedModifiersCursor() - 1) * self:getCellHeight()
	flux.to(self.awwow, 0.2, { y = target }):ease("cubicout")
end

function SelectedMods:event_modsChanged()
	self:removeCells()
	self:addCells()

	local selected = self.selectApi:getSelectedModifiersCursor()
	if selected == 0 then
		self.selectApi:moveSelectedModifiersCursor(1)
		selected = 1
	end
	self:moveCursor()
	self:scrollToCell(math.max(0, selected - self.rows))
end

return SelectedMods
