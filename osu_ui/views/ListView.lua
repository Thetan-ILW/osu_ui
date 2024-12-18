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
	self.width, self.height = self.parent:getDimensions()
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

	self.hoverRect = self:addChild("hoverRect", Rectangle({
		width = self.width,
		height = self.cellHeight,
		color = { 0.89, 0.47, 0.56, 0.2 },
		alpha = 0,
		targetY = 0,
		update = function(this)
			this.y = this.targetY - self.scrollArea.scrollPosition
		end
	}))

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

---@param component ui.Component
function ListView:addCell(component)
	self:assert(self.cells, "Call ListView.load(self)")

	local area = self.scrollArea

	component.y = self.cellHeight * self.cells
	component.z = 1 - (self.cells * 0.000001)
	component.justHovered = function(this)
		flux.to(self.hoverRect, 0.8, { targetY = this.y, alpha = 1 }):ease("elasticout")
	end
	area:addChild("cell" .. self.cells, component)

	self.cells = self.cells + 1
	area.scrollLimit = math.max(0, (self.cellHeight * self.cells) - (self.cellHeight * self.rows))
end

function ListView:receive(event)
	if not self.mouseOver then
		return
	end
	StencilComponent.receive(self, event)
end

return ListView

