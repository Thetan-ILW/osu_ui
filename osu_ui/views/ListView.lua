local StencilComponent = require("ui.StencilComponent")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Rectangle = require("ui.Rectangle")

local flux = require("flux")

---@class osu.ui.ListView : ui.StencilComponent
---@operator call: osu.ui.ListView
---@field rows number
---@field cells number
local ListView = StencilComponent + {}

function ListView:load()
	self.width = self.width == 0 and self.parent:getWidth() or self.width
	self.height = self.height == 0 and self.parent:getHeight() or self.height
	self.rows = self.rows or 8
	self.cells = 0
	self.cellHeight = self.height / self.rows
	local scroll_area = self:addChild("scrollArea", ScrollAreaContainer({
		width = self.width,
		height = self.height,
		drawChildren = function(area)
			---@cast area osu.ui.ScrollAreaContainer
			local scroll_pos = area.scrollPosition

			local first = math.max(1, math.floor(scroll_pos / self.cellHeight + 1))
			local last = math.min(#area.childrenOrder, first + self.rows)

			love.graphics.translate(0, -area.scrollPosition)
			for i = last, first, -1 do
				local child = area.children[area.childrenOrder[i]]
				love.graphics.push("all")
				child:drawTree()
				love.graphics.pop()

				if child.debug then
					love.graphics.push("all")
					love.graphics.applyTransform(child.transform)
					love.graphics.setColor(1, 0, 0, 1)
					love.graphics.rectangle("line", 0, 0, child.width, child.height)
					love.graphics.pop()
				end
			end
		end,
	})) ---@cast scroll_area osu.ui.ScrollAreaContainer
	self.scrollArea = scroll_area

	self.stencilFunction = self.stencilFunction or function()
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
	end
end

local odd_color = { 0.3, 0.3, 0.3, 0.3 }
local even_color = { 0.1, 0.1, 0.1, 0.5 }

---@return number[]
function ListView:getCellBackgroundColor()
	return (self.cells % 2 == 1) and even_color or odd_color
end

---@return number
function ListView:getCellHeight()
	return self.cellHeight
end

function ListView:scrollToCell(index)
	self.scrollArea:scrollToPosition(index * self:getCellHeight())
end

---@param component ui.Component
function ListView:addCell(component)
	self:assert(self.cells, "Call ListView.load(self)")

	local area = self.scrollArea

	component.y = self.cellHeight * self.cells
	component.z = 1 - (self.cells * 0.000001)
	area:addChild("cell" .. self.cells, component)

	self.cells = self.cells + 1
	area.scrollLimit = math.max(0, (self.cellHeight * self.cells) - (self.cellHeight * self.rows))
end

function ListView:removeCells()
	local area = self.scrollArea
	area:clearTree()
	area.scrollLimit = 0
	self.cells = 0
end

function ListView:receive(event)
	if not self.mouseOver and event.name ~= "mouseReleased" then
		return
	end
	StencilComponent.receive(self, event)
end

return ListView

