local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")
local flux = require("flux")

---@class osu.ui.Combo : osu.ui.UiElement
---@operator call: osu.ui.Combo
---@field label love.Text?
---@field font love.Font
---@field labelColor number[]
---@field hoverColor number[]
---@field borderColor number[]
---@field private defaultValue any?
---@field private valueChanged boolean
---@field private totalW number
---@field private totalH number
---@field private hover boolean
---@field private hoverIndex integer
---@field private onChange function
---@field private getValue fun(): any, table
---@field private format? fun(any): string
---@field private selected string
---@field private items any[]
---@field private icon love.Image
---@field private state "hidden" | "fade_in" | "open" | "fade_out"
---@field private visibility number
---@field private visibilityTween table?
---@field private headHoverState osu.ui.HoverState
---@field private headAnimation number
local Combo = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param params { label: string, font: love.Font, pixelWidth: number, pixelHeight: number, hoverColor: number[]?, borderColor: number[]?, defaultValue: any?, tip: string? }
---@param get_value function
---@param on_change function
---@param format function?
function Combo:new(assets, params, get_value, on_change, format)
	self.assets = assets

	if params.label then
		self.label = love.graphics.newText(params.font, params.label)
	end

	self.font = params.font
	self.totalW = params.pixelWidth
	self.totalH = params.pixelHeight
	self.hoverColor = params.hoverColor or { 0.72, 0.06, 0.46, 1 }
	self.borderColor = params.borderColor or { 0, 0, 0, 1 }
	self.defaultValue = params.defaultValue
	self.valueChanged = false
	self.tip = params.tip
	self.onChange = on_change
	self.getValue = get_value
	self.format = format
	self.selected = "! broken getValue() !"
	self.icon = assets.images.dropdownArrow
	self.state = "hidden"
	self.visibility = 0
	self.changeTime = -math.huge
	self.headHoverState = HoverState("quadout", 0.12)
	self.headAnimation = 0
end

local gfx = love.graphics

---@private
function Combo:open()
	if self.visibilityTween then
		self.visibilityTween:stop()
	end
	self.visibilityTween = flux.to(self, 0.35, { visibility = 1 }):ease("cubicout")
	self.state = "fade_in"
	local sound = self.assets.sounds.selectExpand
	ui.playSound(sound)
end

---@private
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

function Combo:getPosAndSize()
	local x = 0

	if self.label then
		x = self.label:getWidth() * math.min(ui.getTextScale(), 1)
	end

	local w = self.totalW - x - 24
	local h = math.floor(self.totalH / 1.5)

	return x, w, h
end

function Combo:update(has_focus)
	self:processState()
	local selected, items = self.getValue()
	self.selected = self.format and self.format(selected) or tostring(selected)
	self.items = items

	local just_hovered = false
	self.hover, self.headAnimation, just_hovered = self.headHoverState:check(self.totalW, self.totalH, 0, 0, has_focus)

	if not has_focus then
		return
	end

	if self.defaultValue ~= nil then
		self.valueChanged = selected ~= self.defaultValue
	end

	self.hoverIndex = 0

	if self.state ~= "hidden" then
		local x, w, h = self:getPosAndSize()
		for i, _ in ipairs(self.items) do
			self.hoverIndex = ui.isOver(w, h, x, (self.totalH - h) + h * i) and i or self.hoverIndex
		end
	end

	if self.state == "open" then
		if self.hoverIndex ~= 0 and ui.mousePressed(1) then
			self.onChange(self.items[self.hoverIndex])
			self.changeTime = love.timer.getTime()
			ui.resetJust()
			self:processState("close")
		end
	end

	self.activeTip = nil

	if self.hover then
		self.activeTip = self.tip
	end

	if self.hover and ui.mousePressed(1) then
		self:processState("toggle")
	elseif not self.hover and ui.mousePressed(1) then
		self:processState("close")
	end

	if just_hovered then
		ui.playSound(self.assets.sounds.hoverOverRect)
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
		ui.textFrame(self.label, 0, 0, self.totalW, self.totalH, "left", "center")
	end
	self:drawHead()
end

function Combo:drawHead()
	gfx.setFont(self.font)
	gfx.push()

	local x, w, h = self:getPosAndSize()
	gfx.translate(x + 12, 0)

	local y = self.totalH / 2 - h / 2

	gfx.setLineWidth(2)
	gfx.setColor(self.borderColor)
	gfx.rectangle("line", 0, y, w, h, 4)

	local color = self.hoverColor
	mix[1] = color[1] * self.headAnimation
	mix[2] = color[2] * self.headAnimation
	mix[3] = color[3] * self.headAnimation
	gfx.setColor(mix)
	gfx.rectangle("fill", 0, y, w, h, 4)

	gfx.setColor(1, 1, 1)
	ui.frame(self.selected, 2, y, w, h, "left", "center")

	y = self.totalH / 2 - self.icon:getHeight() / 2
	gfx.translate(w - 25, y)
	gfx.draw(self.icon)

	gfx.pop()

	gfx.translate(0, self.totalH)
end

function Combo:drawBody()
	gfx.setFont(self.font)
	gfx.push()
	local x, w, h = self:getPosAndSize()
	gfx.translate(x + 12, (self.totalH - h) / 2 + 2)

	for i, v in ipairs(self.items) do
		gfx.translate(0, h * self.visibility)
		local color = self.hoverIndex == i and self.hoverColor or black
		gfx.setColor(color[1], color[2], color[3], self.visibility)
		gfx.rectangle("fill", 0, 0, w, h, 4)
		gfx.setColor(1, 1, 1, self.visibility)
		ui.frame(self.format and self.format(v) or tostring(v), 2, 0, w, h, "left", "center")
	end
	gfx.pop()

	self:drawHead()
end

return Combo
