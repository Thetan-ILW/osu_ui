local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")
local flux = require("flux")

---@alias ComboParams { label: string?, font: love.Font, hoverSound: audio.Source?, expandSound: audio.Source?, hoverColor: number[]?, borderColor: number[]?, onChange: (fun(value: any)), getValue: (fun(): any, any[]), format: (fun(value: any): string) }

---@class osu.ui.Combo : osu.ui.UiElement
---@overload fun(params: ComboParams): osu.ui.Combo
---@field text love.Text?
---@field font love.Font
---@field label string?
---@field hoverSound audio.Source?
---@field expandSound audio.Source?
---@field labelColor number[]
---@field hoverColor number[]
---@field borderColor number[]
---@field cellHeight number
---@field minCellHeight number
---@field private onChange function
---@field private getValue fun(): any, table
---@field private format? fun(any): string
---@field private selected string
---@field private items any[]
---@field private state "hidden" | "fade_in" | "open" | "fade_out"
---@field private visibility number
---@field private visibilityTween table?
local Combo = UiElement + {}

local border_size = 2

function Combo:load()
	if self.label then
		self.text = love.graphics.newText(self.font, self.label)
	end

	self.cellHeight = self.totalH

	local x, w, h = self:getPosAndSize()
	self.minCellHeight = h + border_size * 2
	self.totalH = self.minCellHeight

	self.hoverColor = self.hoverColor or { 0.72, 0.06, 0.46, 1 }
	self.borderColor = self.borderColor or { 0, 0, 0, 1 }
	self.selected = "! broken getValue() !"
	self.state = "hidden"
	self.visibility = 0
	self.headHoverState = HoverState("quadout", 0.12)
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

	if self.label then
		x = self.label:getWidth() * math.min(ui.getTextScale(), 1)
	end

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

function Combo:update()
	self:processState()
	local selected, items = self.getValue()
	self.selected = self.format and self.format(selected) or tostring(selected)
	self.items = items

	self.hoverIndex = 0
	local x, w, h = self:getPosAndSize()

	if self.state ~= "hidden" then
		for i, _ in ipairs(self.items) do
			self.hoverIndex = ui.isOver(w, h, x, h * i + border_size * 2) and i or self.hoverIndex
		end

		self.totalH = math.max(self.minCellHeight, #self.items * (self.cellHeight * self.visibility) + border_size * 2)
		self.hoverHeight = self.totalH
	end

	if self.mouseOver then
		self.headHoverState:check(self.totalW, h, 0, 0)
	end
end

function Combo:isFocused()
	return self.hoverIndex ~= 0
end

local black = { 0, 0, 0, 1 }
local mix = { 0, 0, 0, 1 }

function Combo:draw()
	gfx.setColor(1, 1, 1)
	if self.label then
		ui.textFrame(self.text, 0, 0, self.totalW, self.totalH, "left", "center")
	end

	gfx.setFont(self.font)
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

	gfx.setColor(1, 1, 1, self.alpha)
	ui.frame("▼", -10, 3, self.totalW, h, "right", "center")
	gfx.setColor(1, 1, 1, self.alpha)
	ui.frame(self.selected, 2, border_size, w, h, "left", "center")
	gfx.pop()
end

function Combo:drawBody()
	gfx.push()
	local x, w, h = self:getPosAndSize()
	gfx.translate(x + border_size, border_size * 2)

	for i, v in ipairs(self.items) do
		gfx.translate(0, h * self.visibility)
		local color = self.hoverIndex == i and self.hoverColor or black
		gfx.setColor(color[1], color[2], color[3], self.visibility)
		gfx.rectangle("fill", 0, 0, w, h, 4)
		gfx.setColor(1, 1, 1, self.visibility)
		ui.frame(self.format and self.format(v) or tostring(v), 15, 0, w, h, "left", "center")
	end
	gfx.pop()
end

return Combo
