local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local Slider = require("osu_ui.ui.Slider")

local TextBox = require("osu_ui.ui.TextBox")
local Button = require("osu_ui.ui.Button")
local Combo = require("osu_ui.ui.Combo")
local Checkbox = require("osu_ui.ui.Checkbox")

---@class osu.ui.OptionsGroup : ui.Component
---@field section osu.ui.OptionsSection
---@field assets osu.ui.OsuAssets
---@field isEmpty boolean
---@field search string
---@field name string
---@field buildFunction fun(group: osu.ui.OptionsGroup)
local Group = Component + {}

function Group:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local options = self.section.options
	self.tooltip = scene.tooltip

	self.fonts = scene.fontManager

	self.game = options.game
	self.search = options.search
	self.assets = options.assets
	self.isEmpty = false
	self.indent = 12
	self.buttonColor = { 0.05, 0.52, 0.65, 1 }

	self:clearTree()
	self.comboObjects = {}

	self.labels = 0
	self.checkboxes = 0
	self.combos = 0
	self.buttons = 0
	self.textBoxes = 0
	self.sliders = 0

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
		font = self.fonts:loadFont("Bold", 16)
	}))
end

function Group:showTooltip(text)
	self.tooltip:setText(text)
end

---@return boolean
function Group:hasOpenCombos()
	for _, child in ipairs(self.comboObjects) do
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

function Group:getCurrentZ()
	local item_count = self.labels + self.checkboxes + self.combos + self.textBoxes + self.buttons + self.sliders
	return 1 - (item_count * 0.00000001)
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

	local container = self:addChild("textBoxContainer" .. self.textBoxes, Component({
		x = self.indent - 2, y = self:getCurrentY(),
		width = self:getWidth(),
		height = 66,
		z = self:getCurrentZ(),
		update = function(component, delta_time)
			Component.update(component, delta_time)
			if component.mouseOver then
				self.section:hoveringOver(component.y + self.y, component:getHeight())
			end
		end,
	}))

	container:addChild("label", Label({
		x = 2, y = 12,
		text = params.label,
		font = self.fonts:loadFont("Regular", 16),
	}))
	local text_box = container:addChild("textBox", TextBox({
		y = container:getHeight() - 5,
		origin = { y = 1 },
		width = 380,
		height = 20,
		label = params.label,
		input = params.value,
		password = params.password,
		font = self.fonts:loadFont("Regular", 17),
		justHovered = function () end
	}))

	---@cast text_box osu.ui.TextBox
	self.height = self.height + container:getHeight()
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

	local container = self:addChild("button_container" .. self.buttons, Component({
		x = self.indent - 5, y = self:getCurrentY(),
		width = self:getWidth(),
		height = 45,
		z = self:getCurrentZ(),
		update = function(container, delta_time)
			Component.update(container, delta_time)
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
		font = self.fonts:loadFont("Regular", 16),
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

	local container = self:addChild("label_container" .. self.labels, Component({
		x = self.indent, y = self:getCurrentY(),
		width = 388,
		height = params.height,
		blockMouseFocus = true,
		z = self:getCurrentZ(),
		update = function(container, delta_time)
			Component.update(container, delta_time)
			if container.mouseOver then
				self.section:hoveringOver(container.y + self.y, container:getHeight())
			end
		end,
		bindEvents = function(this)
			self:bindEvent("mouseClick")
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

---@param params { label: string, items: any[], getValue: (fun(): any), setValue: fun(index: integer), format: (fun(any): string)? }
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

	local container = self:addChild("combo_container" .. self.combos, Component({
		x = self.indent, y = self:getCurrentY(),
		width = 388,
		height = 37,
		z = self:getCurrentZ(),
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
		setValue = params.setValue,
		format = params.format,
		justHovered = function () end
	}))
	---@cast combo osu.ui.Combo
	self.height = self.height + container:getHeight()
	self.combos = self.combos + 1
	table.insert(self.comboObjects, combo)
	return combo
end

---@param params { label: string, getValue: (fun(): boolean), clicked: function }
---@return osu.ui.Checkbox?
function Group:checkbox(params)
	if not self:canAdd(params.label) then
		return
	end

	local checkbox = self:addChild("checkbox" .. self.checkboxes, Checkbox({
		x = self.indent + 5,
		y = self:getCurrentY(),
		width = self.width,
		height = 37,
		font = self.fonts:loadFont("Regular", 16),
		label = params.label,
		getValue = params.getValue,
		clicked = params.clicked,
		z = self:getCurrentZ(),
		update = function(checkbox)
			Checkbox.update(checkbox)
			if checkbox.mouseOver then
				self.section:hoveringOver(checkbox.y + self.y, checkbox:getHeight())
			end
		end,
	})) ---@cast checkbox osu.ui.Checkbox
	self.height = self.height + checkbox:getHeight()
	self.checkboxes = self.checkboxes + 1
	return checkbox
end

---@param params { label: string, min: number, max: number, step: number, getValue: (fun(): number), setValue: (fun(v: number)), format: (fun(v: number): string)? }
---@return osu.ui.Slider?
function Group:slider(params)
	if not self:canAdd(params.label) then
		return
	end

	local container = self:addChild("slider_container" .. self.sliders, Component({
		x = self.indent, y = self:getCurrentY(),
		width = self:getWidth(),
		height = 37,
		z = self:getCurrentZ(),
		update = function(container, delta_time)
			Component.update(container, delta_time)
			if container.mouseOver then
				self.section:hoveringOver(container.y + self.y, container:getHeight())
			end
		end
	}))

	local label = container:addChild("label", Label({
		text = params.label,
		font = self.fonts:loadFont("Regular", 16),
		alignY = "center",
		boxHeight = container:getHeight()
	}))

	local x = label:getWidth() + 10

	local slider = container:addChild("slider", Slider({
		x = x,
		width = container:getWidth() - x - 50,
		height = container:getHeight(),
		z = self:getCurrentZ(),
		min = params.min,
		max = params.max,
		step = params.step,
		getValue = params.getValue,
		setValue = params.setValue,
		format = params.format
	})) ---@cast slider osu.ui.Slider
	self.sliders = self.sliders + 1
	self.height = self.height + container:getHeight()
	return slider
end

return Group
