local Component = require("ui.Component")
local StencilComponent = require("ui.StencilComponent")
local Label = require("ui.Label")

local text_input = require("ui.text_input")

---@alias TextBoxParams { input: string?, password: boolean?, font: ui.Font? }

---@class osu.ui.TextBox : ui.Component
---@overload fun(params: TextBoxParams): osu.ui.TextBox
---@field assets osu.ui.OsuAssets
---@field focus boolean
---@field password boolean?
---@field cursorPosition number
---@field label string
---@field input string
---@field inputLabel ui.Label
---@field font ui.Font?
local TextBox = Component + {}

function TextBox.censor(text)
	return string.rep("*", text:len())
end

function TextBox:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager

	self.height = self.height == 0 and 28 or self.height
	self.focus = false
	self.input = self.input or ""
	self.blockMouseFocus = true

	local w = self.width
	local h = self.height
	local field = self:addChild("fieldContainer", StencilComponent({
		width = w,
		height = h,
		stencilFunction = function()
			love.graphics.rectangle("fill", 0, 0, w, h)
		end
	}))
	local input_label = field:addChild("inputLabel", Label({
		x = 2,
		font = self.font or fonts:loadFont("Bold", 22),
	})) --- @cast input_label ui.Label
	self.inputLabel = input_label
	self:updateField()
end

function TextBox:loseFocus()
	self.focus = false
end

function TextBox:mouseClick(event)
	if event.key ~= 1 or not self.mouseOver then
		self.focus = false
		return false
	end
	self:getViewport():receive({ name = "loseFocus" })
	self.focus = true
	return true
end

---@param input string
function TextBox.changed(input) end

function TextBox:updateField()
	self.inputLabel:replaceText(self.password and self.censor(self.input) or self.input)
	local diff = self:getWidth() - self.inputLabel:getWidth()
	local x = diff < 0 and diff - 2 or 2
	self.inputLabel.x = x
	self.changed(self.input)
end

function TextBox:keyPressed(event)
	if event[2] == "escape" then
		self.focus = false
		return false
	end
	if not self.focus or event[2] ~= "backspace" then
		return false
	end
	self.input = text_input.removeChar(self.input)
	self:updateField()
	return true
end

function TextBox:textInput(event)
	if not self.focus then
		return false
	end
	self.input = self.input .. event[1]
	self:updateField()
	return true
end

local gfx = love.graphics

function TextBox:draw()
	local r, g, b, alpha = love.graphics.getColor()
	local w, h = self.width, self.height

	if not self.focus then
		gfx.setColor(0.15, 0.15, 0.15, alpha * 0.5)
	else
		gfx.setColor(0.15, 0.15, 0.15, alpha)
	end

	gfx.rectangle("fill", 0, 0, w, self.height)
	gfx.setLineWidth(1)
	gfx.setLineStyle("smooth")

	if not self.focus then
		gfx.setColor(0.7, 0.7, 0.7, alpha)
	else
		gfx.setColor(1, 1, 1, alpha)
	end

	gfx.rectangle("line", 0, 0, w, self.height)
end

return TextBox
