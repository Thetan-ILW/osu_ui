local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")

local TextBox = require("osu_ui.ui.TextBox")
local Button = require("osu_ui.ui.Button")
local Combo = require("osu_ui.ui.Combo")

---@class osu.ui.OptionsGroup : ui.Component
---@field section osu.ui.OptionsSection
---@field assets osu.ui.OsuAssets
---@field isEmpty boolean
---@field search string
---@field name string
---@field buildFunction fun(group: osu.ui.OptionsGroup)
local Group = Component + {}

function Group:load()
	local fonts = self.shared.fontManager
	local options = self.section.options

	self.game = options.game
	self.search = options.search
	self.assets = options.assets
	self.fonts = fonts
	self.isEmpty = false
	self.indent = 12
	self.buttonColor = { 0.05, 0.52, 0.65, 1 }

	self.comboObjects = {}

	self.height = 0
	self.startY = 25
	self:buildFunction()
	self:autoSize()

	if self.height == 0 then
		self.isEmpty = true
		return
	end

	self:addChild("rectangle", Rectangle({
		width = 5,
		height = self.height,
		color = { 1, 1, 1, 0.2 }
	}))

	self:addChild("label", Label({
		x = self.indent,
		text = self.name,
		font = fonts:loadFont("Bold", 16)
	}))

	self:build()
end

---@return boolean
function Group:hasOpenCombos()
	for i, child in ipairs(self.comboObjects) do
		if child.state ~= "hidden" then
			return true
		end
	end
	return false
end

---@return number
function Group:getCurrentY()
	return self.startY + self.height
end

---@param text string
---@return boolean
function Group:canAdd(text)
	if self.search == "" then
		return true
	end
	return text:lower():find(self.search:lower()) ~= nil
end

---@param params { label: string, value: string?, password: boolean? }
---@return osu.ui.TextBox?
function Group:textBox(params)
	if not self:canAdd(params.label) then
		return
	end

	self.textBoxes = self.textBoxes or 1
	local text_box = self:addChild("textBox" .. self.textBoxes, TextBox({
		x = self.indent, y = self:getCurrentY(),
		width = 380,
		height = 66,
		assets = self.assets,
		label = params.label,
		input = params.value,
		password = params.password,
		update = function(text_box, delta_time)
			TextBox.update(text_box, delta_time)
			if text_box.mouseOver then
				self.section:hoveringOver(text_box.y + self.y, text_box:getHeight())
			end
		end,
		justHovered = function () end
	}))

	---@cast text_box osu.ui.TextBox
	self.height = self.height + text_box:getHeight()
	self.textBoxes = self.textBoxes + 1
	return text_box
end

---@param color Color
function Group:setButtonColor(color)
	self.buttonColor = color
end

---@param params { label: string, onClick: function }  
---@return osu.ui.Button?
function Group:button(params)
	if not self:canAdd(params.label) then
		return
	end

	local fonts = self.fonts
	self.buttons = self.buttons or 1

	local container = self:addChild("button_container" .. self.buttons, Component({
		x = self.indent - 5, y = self:getCurrentY(),
		width = 388,
		height = 45,
		update = function(container, delta_time)
			TextBox.update(container, delta_time)
			if container.mouseOver then
				self.section:hoveringOver(container.y + self.y, container:getHeight())
			end
		end
	}))

	local button = container:addChild("button" .. self.buttons, Button({
		y = container:getHeight() / 2 - 34 / 2,
		width = 388,
		height = 34,
		label = params.label,
		font = fonts:loadFont("Regular", 16),
		color = self.buttonColor,
		onClick = params.onClick,
		justHovered = function () end
	}))
	---@cast button osu.ui.Button
	self.height = self.height + container:getHeight()
	self.buttons = self.buttons + 1
	return button
end

---@param params { label: string, height: number?, alignX: AlignX?, onClick: function }
---@return ui.Label?
function Group:label(params)
	if not self:canAdd(params.label) then
		return
	end
	params.height = params.height or 37

	self.labels = self.labels or 1
	local container = self:addChild("label_container" .. self.labels, Component({
		x = self.indent, y = self:getCurrentY(),
		width = 388,
		height = params.height,
		blockMouseFocus = true,
		update = function(container, delta_time)
			Component.update(container, delta_time)
			if container.mouseOver then
				self.section:hoveringOver(container.y + self.y, container:getHeight())
			end
		end,
		bindEvents = function(this)
			self:bindEvent(this, "mouseClick")
		end,
		mouseClick = function(this)
			if params.onClick then
				if this.mouseOver then
					params.onClick()
					return true
				end
			end
			return false
		end,
	}))

	local label = container:addChild("label", Label({
		text = params.label,
		font = self.fonts:loadFont("Regular", 16),
		alignX = params.alignX,
		alignY = "center",
		width = container:getWidth(),
		height = params.height
	}))
	---@cast label ui.Label
	self.height = self.height + container:getHeight()
	self.labels = self.labels + 1
	return label
end

---@param params { label: string, items: any[], getValue: (fun(): any), onChange: fun(index: integer), format: (fun(any): string)? }
---@return osu.ui.Combo?
function Group:combo(params)
	if not self:canAdd(params.label) then
		return
	end

	local found_something = false
	for _, v in ipairs(params.items) do
		if self:canAdd(params.format and params.format(v) or tostring(v)) then
			found_something = true
			break
		end
	end

	if not found_something then
		return
	end

	self.combos = self.combos or 1
	local container = self:addChild("combo_container" .. self.combos, Component({
		x = self.indent, y = self:getCurrentY(),
		width = 388,
		height = 37,
		update = function(container, delta_time)
			Component.update(container, delta_time)
			if container.mouseOver then
				self.section:hoveringOver(container.y + self.y, container:getHeight())
			end
		end,
	}))

	local label = container:addChild("label", Label({
		text = params.label,
		font = self.fonts:loadFont("Regular", 16),
		alignY = "center",
		height = container:getHeight()
	}))

	local x = label:getWidth() + 10

	local combo = container:addChild("combo", Combo({
		x = x, y = 5,
		width = container:getWidth() - x,
		height = container:getHeight(),
		font = self.fonts:loadFont("Regular", 16),
		items = params.items,
		getValue = params.getValue,
		onChange = params.onChange,
		format = params.format,
		justHovered = function () end
	}))
	---@cast combo osu.ui.Combo
	self.height = self.height + container:getHeight()
	self.combos = self.combos + 1
	table.insert(self.comboObjects, combo)
	return combo
end

return Group
