local Component = require("ui.Component")
local HoverState = require("ui.HoverState")
local Label = require("ui.Label")
local DynamicLabel = require("ui.DynamicLabel")
local Rectangle = require("ui.Rectangle")

local flux = require("flux")

---@alias osu.ui.ComboParams { hoverColor: number[]?, borderColor: number[]?, items: any[], setValue: (fun(index: integer)), getValue: (fun(): any), format: (fun(value: any): string) }

---@class osu.ui.Combo : ui.Component
---@overload fun(params: osu.ui.ComboParams): osu.ui.Combo
---@field font ui.Font?
---@field items any[]
---@field itemsText osu.ui.DynamicText[]
---@field selectedText osu.ui.DynamicText
---@field iconDown love.Text
---@field iconRight love.Text
---@field hoverColor number[]
---@field borderColor number[]
---@field cellHeight number
---@field minCellHeight number
---@field locked boolean?
---@field setValue fun(index: integer)
---@field getValue fun(): any
---@field format? fun(any): string
---@field state "hidden" | "fade_in" | "open" | "fade_out"
---@field visibility number
---@field visibilityTween table?
local Combo = Component + {}

local border_size = 2
local black = { 0, 0, 0, 1 }

function Combo:load()
	self:assert(self.items, "No items provided")
	self.cellHeight = self.height == 0 and 37 or self.height

	local _, _, h = self:getPosAndSize()
	self.minCellHeight = h + border_size * 2
	self.height = self.minCellHeight

	self.hoverColor = self.hoverColor or { 0.72, 0.06, 0.46, 1 }
	self.borderColor = self.borderColor or { 0, 0, 0, 1 }
	self.state = "hidden"
	self.visibility = 0

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager
	local assets = scene.assets

	self.hoverSound = assets:loadAudio("click-short")
	self.expandSound = assets:loadAudio("select-expand")
	self.clickSound = assets:loadAudio("click-short-confirm")

	local font = self.font or fonts:loadFont("Regular", 16)
	local awesome_regular = fonts:loadFont("Awesome", 18)

	self.fonts = fonts
	self.font = font

	local main = self:addChild("mainCell", Component({
		width = self.width,
		height = self.minCellHeight,
		z = 0.2,
	}))
	main:addChild("mainCellLabel", DynamicLabel({
		x = 3,
		font = font,
		height = main:getHeight(),
		alignY = "center",
		z = 1,
		value = function ()
			local value = self.getValue()
			return self.format and self.format(value) or value
		end
	}))
	main:addChild("mainCellArrow", Label({
		boxWidth = main:getWidth() - 8,
		boxHeight = main:getHeight(),
		text = "",
		font = awesome_regular,
		alignX = "right",
		alignY = "center",
		z = 1,
	}))
	main:addChild("mainCellBackground", Rectangle({
		width = main:getWidth(),
		height = main:getHeight(),
		color = { 0, 0, 0, 1 },
		rounding = 4,
		blockMouseFocus = true,
		hoverState = HoverState("quadout", 0.12),
		setMouseFocus = function(this, mx, my)
			this.mouseOver = this.hoverState:checkMouseFocus(this.width, this.height, mx, my)
		end,
		noMouseFocus = function(this)
			this.hoverState:loseFocus()
			this.mouseOver = false
		end,
		update = function(this)
			if self.locked then
				this.color[1] = 0.3
				this.color[2] = 0.3
				this.color[3] = 0.3
				return
			end
			local h_color = self.hoverColor
			this.color[1] = h_color[1] * this.hoverState.progress
			this.color[2] = h_color[2] * this.hoverState.progress
			this.color[3] = h_color[3] * this.hoverState.progress
		end,
		mouseClick = function(this)
			if this.mouseOver and not self.locked then
				self:processState("toggle")
				return true
			end
			return false
		end
	}))
	main:addChild("mainCellBorder", Rectangle({
		width = main:getWidth(),
		height = main:getHeight(),
		rounding = 4,
		mode = "line",
		color = self.borderColor,
		z = 1
	}))

	self:addItems()
end

function Combo:addItems()
	local awesome_small = self.fonts:loadFont("Awesome", 15)

	self:removeChild("items")
	local items = self:addChild("items", Component({
		width = self.width,
		alpha = 0,
		z = 0,
		disabled = true,
	}))

	for i, v in ipairs(self.items) do
		local cell = items:addChild("comboCell" .. i, Component({
			width = items:getWidth(),
			height = self.minCellHeight,
			update = function(this)
				this.y = self.visibility * (self.minCellHeight * i)
			end
		}))
		cell:addChild("comboCellBackground", Rectangle({
			width = cell:getWidth(),
			height = cell:getHeight(),
			rounding = 4,
			color = black,
			blockMouseFocus = true,
			update = function(this)
				this.color = (this.mouseOver and self.state ~= "fade_out") and self.hoverColor or black
			end,
			mouseClick = function(this)
				if this.mouseOver then
					self.playSound(self.clickSound)
					self.setValue(i)
					self:processState("close")
					return true
				end
				return false
			end
		}))
		cell:addChild("comboCellLabel", Label({
			x = 15,
			boxHeight = cell:getHeight(),
			text = self.format and self.format(v) or tostring(v),
			alignY = "center",
			font = self.font,
			z = 0.1,
		}))
		cell:addChild("mainCellArrow", Label({
			x = 4,
			boxHeight = self.minCellHeight,
			text = "",
			font = awesome_small,
			alignY = "center",
			color = black,
			z = 0.1,
		}))
	end
end

function Combo:mousePressed()
	if not self.mouseOver then
		self:processState("close")
	end
	return false
end

---@private
function Combo:open()
	if self.visibilityTween then
		self.visibilityTween:stop()
	end
	self.visibilityTween = flux.to(self, 0.35, { visibility = 1 }):ease("cubicout")
	self.state = "fade_in"
	self.playSound(self.expandSound)
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

	if event == "toggle" then
		event = (state == "open" or state == "fade_in") and "close" or "open"
	end

	if state == "hidden" then
		if event == "open" then
			self.children.items.disabled = false
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
			self.children.items.disabled = true
		end
		if event == "open" then
			self:open()
		end
	end
end

function Combo:justHovered()
	self.playSound(self.hoverSound)
end

function Combo:getPosAndSize()
	local x = 0
	local w = self.width - x - (border_size * 2)
	local h = math.floor(self.cellHeight / 1.5)
	return x, w, h
end

function Combo:loseFocus()
	if self.state == "open" or self.state == "fade_in" then
		self:processState("close")
	end
end

function Combo:mouseClick()
	if not self.mouseOver and (self.state == "open" or self.state == "fade_in") then
		self:processState("close")
		return false
	end
	return false
end

function Combo:update()
	self:processState()

	local height = math.max(self.minCellHeight, (#self.items + 1) * (self.minCellHeight * self.visibility))
	self.height = height

	local items_container = self.children.items
	items_container.alpha = self.visibility
	items_container.height = height
end

return Combo
