local Container = require("osu_ui.ui.Container")

local TextBox = require("osu_ui.ui.TextBox")
local Button = require("osu_ui.ui.Button")
local Rectangle = require("osu_ui.ui.Rectangle")
local Label = require("osu_ui.ui.Label")

---@class osu.ui.OptionsGroup : osu.ui.Container
---@field section osu.ui.OptionsSection
---@field assets osu.ui.OsuAssets
---@field isEmpty boolean
---@field search string
---@field name string
---@field buildFunction fun(group: osu.ui.OptionsGroup)
local Group = Container + {}

function Group:load()
	local options = self.section.options

	self.game = options.game
	self.search = options.search
	self.assets = options.assets
	self.automaticSizeCalc = false
	self.isEmpty = false
	self.indent = 12
	self.buttonColor = { 0.05, 0.52, 0.65, 1 }

	Container.load(self)

	self.totalH = 0
	self.startY = 25
	self:buildFunction()

	if self.totalH == 0 then
		self.isEmpty = true
		return
	end

	self:addChild("rectangle", Rectangle({
		totalW = 5,
		totalH = self.totalH + self.startY,
		color = { 1, 1, 1, 0.2 }
	}))

	self:addChild("label", Label({
		x = self.indent,
		text = self.name,
		font = self.assets:loadFont("Bold", 16)
	}))

	self:build()
end

function Group:getCurrentY()
	return self.startY + self.totalH
end

function Group:canAdd(text)
	if self.search == "" then
		return true
	end
	return text:lower():find(self.search:lower())
end

---@param params { label: string, value: string? }
---@return osu.ui.TextBox?
function Group:textBox(params)
	if not self:canAdd(params.label) then
		return
	end

	self.textBoxes = self.textBoxes or 1
	local text_box = self:addChild("textBox" .. self.textBoxes, TextBox({
		x = self.indent, y = self:getCurrentY(),
		totalW = 380,
		assets = self.assets,
		labelText = params.label,
		input = params.value
	}))
	function text_box.justHovered()
		TextBox.justHovered(text_box)
		self.section:hoverOver(text_box.y + self.y, text_box:getHeight())
	end

	---@cast text_box osu.ui.TextBox
	self.totalH = self.totalH + text_box:getHeight()
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

	local assets = self.assets
	self.buttons = self.buttons or 1

	local container = self:addChild("button_container" .. self.buttons, Container({
		x = self.indent - 5, y = self:getCurrentY(),
		totalW = 388,
		totalH = 45,
		automaticSizeCalc = false,
	}))
	---@cast container osu.ui.Container

	function container.justHovered()
		Container.justHovered(container)
		self.section:hoverOver(container.y + self.y, container:getHeight())
	end

	local button = container:addChild("button" .. self.buttons, Button({
		y = container.totalH / 2 - 34 / 2,
		totalW = 388,
		totalH = 34,
		text = params.label,
		font = assets:loadFont("Regular", 16),
		imageLeft = assets:loadImage("button-left"),
		imageMiddle = assets:loadImage("button-middle"),
		imageRight = assets:loadImage("button-right"),
		color = self.buttonColor,
		onClick = params.onClick
	}))
	---@cast button osu.ui.Button
	container:build()
	self.totalH = self.totalH + container:getHeight()
	self.buttons = self.buttons + 1
	return button
end

---@param params { label: string, totalH: number?, alignX: AlignX?, onClick: function }
---@return osu.ui.Label?
function Group:label(params)
	if not self:canAdd(params.label) then
		return
	end

	self.labels = self.labels or 1
	local container = self:addChild("label_container" .. self.labels, Container({
		x = self.indent, y = self:getCurrentY(),
		totalW = 388,
		totalH = params.totalH,
		automaticSizeCalc = params.totalH == nil,
		bindEvents = function(this)
			self:bindEvent(this, "mouseClick")
		end,
		mouseClick = function(this)
			if this.mouseOver then
				params.onClick()
				return true
			end
			return false
		end
	}))
	---@cast container osu.ui.Container

	function container.justHovered()
		Container.justHovered(container)
		self.section:hoverOver(container.y + self.y, container:getHeight())
	end

	local label = container:addChild("label" .. self.labels, Label({
		text = params.label,
		font = self.assets:loadFont("Regular", 16),
		alignX = params.alignX,
		alignY = "center",
		totalW = container.totalW,
		totalH = params.totalH
	}))
	---@cast label osu.ui.Label
	container:build()
	self.totalH = self.totalH + container:getHeight()
	self.labels = self.labels + 1
	return label
end

return Group
