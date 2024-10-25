local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")
local DynamicText = require("osu_ui.ui.DynamicText")
local Label = require("osu_ui.ui.Label")

local ui = require("osu_ui.ui")
local flux = require("flux")

---@alias ComboParams { label: string?, font: love.Font, hoverColor: number[]?, borderColor: number[]?, items: any[], onChange: (fun(value: any)), getValue: (fun(): any), format: (fun(value: any): string) }

---@class osu.ui.Combo : osu.ui.UiElement
---@overload fun(params: ComboParams): osu.ui.Combo
---@field items any[]
---@field font love.Font
---@field itemsText osu.ui.DynamicText[]
---@field selectedText osu.ui.DynamicText
---@field hoverSound audio.Source?
---@field expandSound audio.Source?
---@field labelColor number[]
---@field hoverColor number[]
---@field borderColor number[]
---@field cellHeight number
---@field minCellHeight number
---@field onChange function
---@field getValue fun(): any, table
---@field format? fun(any): string
---@field state "hidden" | "fade_in" | "open" | "fade_out"
---@field visibility number
---@field visibilityTween table?
local Combo = UiElement + {}

Combo.blockMouseFocus = true

local border_size = 2

function Combo:load()
	assert(self.items, ("No items were provided to: %s"):format(self.id))
	self.cellHeight = self.totalH

	local _, _, h = self:getPosAndSize()
	self.minCellHeight = h + border_size * 2
	self.totalH = self.minCellHeight

	self.hoverColor = self.hoverColor or { 0.72, 0.06, 0.46, 1 }
	self.borderColor = self.borderColor or { 0, 0, 0, 1 }
	self.state = "hidden"
	self.visibility = 0
	self.headHoverState = HoverState("quadout", 0.12)

	self.selectedText = DynamicText({
		alignY = "center",
		heightLimit = self.totalH,
		font = self.font,
		textScale = self.parent.textScale,
		value = self.getValue
	})
	self.selectedText:load()

	self.itemsText = {}

	for _, v in ipairs(self.items) do
		local text = self.format and self.format(v) or tostring(v)
		local item_text = Label({
			x = 15,
			text = text,
			alignY = "center",
			heightLimit = self.totalH,
			font = self.font,
			textScale = self.parent.textScale,
		})
		item_text:load()
		table.insert(self.itemsText, item_text)
	end

	UiElement.load(self)
end

function Combo:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
end

local gfx = love.graphics

---@private
function Combo:open()
	if self.visibilityTween then
		self.visibilityTween:stop()
	end
	self.visibilityTween = flux.to(self, 0.35, { visibility = 1 }):ease("cubicout")
	self.state = "fade_in"
	ui.playSound(self.expandSound)
end

function Combo:close()
	if self.visibilityTween then
		self.visibilityTween:stop()
	end
	self.visibilityTween = flux.to(self, 0.35, { visibility = 0 }):ease("cubicout")
	self.state = "fade_out"
end

---@param event? "open" | "close" | "toggle"
function Combo:processState(event)
	local state = self.state

	if not event then
		return
	end

	if event == "toggle" then
		event = (state == "open" or state == "fade_in") and "close" or "open"
	end

	if state == "hidden" then
		if event == "open" then
			self:open()
		end
	elseif state == "fade_in" then
		if self.visibility == 1 then
			self.state = "open"
		end
		if event == "close" then
			self:close()
		end
	elseif state == "open" then
		if event == "close" then
			self:close()
		end
	elseif state == "fade_out" then
		if self.visibility == 0 then
			self.state = "hidden"
		end
		if event == "open" then
			self:open()
		end
	end
end

function Combo:justHovered()
	ui.playSound(self.hoverSound)
end

function Combo:getPosAndSize()
	local x = 0

	--[[
	if self.label then
		x = self.label:getWidth() * self.parent.textScale
	end]]

	local w = self.totalW - x - (border_size * 2)
	local h = math.floor(self.cellHeight / 1.5)

	return x, w, h
end

function Combo:loseFocus()
	if self.state == "open" or self.state == "fade_in" then
		self:processState("close")
	end
end

function Combo:mousePressed()
	if self.mouseOver then
		if self.state == "open" or self.state == "fade_in" then
			if self.hoverIndex ~= 0 then
				self.onChange(self.items[self.hoverIndex])
			end
			self:processState("close")
			return true
		end

		self.parent:forEachChildGlobally(function(child)
			child:loseFocus()
		end)

		self:processState("toggle")
		return true
	elseif not self.mouseOver and (self.state == "open" or self.state == "fade_in") then
		self:processState("close")
		return false
	end
	return false
end

function Combo:setMouseFocus(has_focus)
	UiElement.setMouseFocus(self, has_focus)
	if has_focus then
		local x, w, h = self:getPosAndSize()
		self.headHoverState:check(self.totalW, h, 0, 0)
	end
end

function Combo:update()
	self:processState()

	self.selectedText:update()

	self.hoverIndex = 0
	local x, w, h = self:getPosAndSize()

	if self.state ~= "hidden" then
		for i, v in ipairs(self.itemsText) do
			self.hoverIndex = ui.isOver(w, h, x, h * i + border_size * 2) and i or self.hoverIndex
			gfx.push()
			v:update()
			gfx.pop()
		end

		self.totalH = math.max(self.minCellHeight, #self.itemsText * (self.cellHeight * self.visibility) + border_size * 2)
		self.hoverHeight = self.totalH
	end
end

function Combo:isFocused()
	return self.hoverIndex ~= 0
end

local black = { 0, 0, 0, 1 }
local mix = { 0, 0, 0, 1 }

function Combo:draw()
	if self.state ~= "hidden" then
		self:drawBody()
	end
	self:drawHead()
end

function Combo:drawHead()
	gfx.push()

	local x, w, h = self:getPosAndSize()
	gfx.translate(x + border_size, 0)

	gfx.setLineWidth(border_size)
	gfx.setColor(self.borderColor)
	gfx.rectangle("line", 0, border_size, w, h, 4)

	local color = self.hoverColor
	mix[1] = color[1] * self.headHoverState.progress
	mix[2] = color[2] * self.headHoverState.progress
	mix[3] = color[3] * self.headHoverState.progress
	gfx.setColor(mix)
	gfx.rectangle("fill", 0, border_size, w, h, 4)

	--gfx.setColor(1, 1, 1, self.alpha)
	--ui.frame("▼", -10, 3, self.totalW, h, "right", "center")
	gfx.setColor(1, 1, 1, self.alpha)
	self.selectedText:draw()
	gfx.pop()
end

function Combo:drawBody()
	gfx.push()
	local x, w, h = self:getPosAndSize()
	gfx.translate(x + border_size, border_size * 2)

	for i, v in ipairs(self.itemsText) do
		gfx.translate(0, h * self.visibility)
		local color = self.hoverIndex == i and self.hoverColor or black
		gfx.setColor(color[1], color[2], color[3], self.visibility)
		gfx.rectangle("fill", 0, 0, w, h, 4)
		gfx.setColor(1, 1, 1, self.visibility)
		gfx.push()
		gfx.applyTransform(v.transform)
		v:draw()
		gfx.pop()
	end
	gfx.pop()
end

return Combo
