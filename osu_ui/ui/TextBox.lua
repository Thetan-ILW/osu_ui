local UiElement = require("osu_ui.ui.UiElement")

local utf8 = require("utf8")
local Label = require("osu_ui.ui.Label")

---@alias TextBoxParams { assets: osu.ui.OsuAssets, labelText: string }

---@class osu.ui.TextBox : osu.ui.UiElement
---@overload fun(params: TextBoxParams): osu.ui.TextBox
---@field assets osu.ui.OsuAssets
---@field focus boolean
---@field password boolean
---@field cursorPosition number
---@field labelText string
---@field label osu.ui.Label
---@field input string
---@field inputLabel osu.ui.Label
local TextBox = UiElement + {}

local function text_split(text, index)
	local _index = utf8.offset(text, index) or 1
	return text:sub(1, _index - 1), text:sub(_index)
end

function TextBox.removeChar(text)
	local index = utf8.len(text) + 1
	local _
	local left, right = text_split(text, index)

	left, _ = text_split(left, utf8.len(left))
	index = math.max(1, index - 1)

	return left .. right
end

function TextBox:load()
	self.totalH = self.totalH or 66
	self.focus = false
	self.input = self.input or ""
	self.label = Label({
		text = self.labelText,
		font = self.assets:loadFont("Regular", 17),
		textScale = self.parent.textScale,
	})
	self.label:load()

	self.inputLabel = Label({
		font = self.assets:loadFont("Regular", 17),
		textScale = self.parent.textScale,
	})
	self.inputLabel:load()

	UiElement.load(self)
end

function TextBox:bindEvents()
	self.parent:bindEvent(self, "mouseClick")
	self.parent:bindEvent(self, "keyPressed")
	self.parent:bindEvent(self, "textInput")
end

function TextBox:loseFocus()
	self.focus = false
end

function TextBox:mouseClick(event)
	if event.key ~= 1 or not self.mouseOver then
		self.focus = false
		return false
	end

	self.parent:forEachChildGlobally(function(child)
		child:loseFocus()
	end)

	self.focus = true
	return true
end

function TextBox:keyPressed(event)
	if event[2] == "escape" then
		self.focus = false
		return false
	end
	if not self.focus or event[2] ~= "backspace" then
		return false
	end
	self.input = self.removeChar(self.input)
	self.inputLabel:replaceText(self.input)
	return true
end

function TextBox:textInput(event)
	if not self.focus then
		return false
	end
	self.input = self.input .. event[1]
	self.inputLabel:replaceText(self.input)
	return true
end

local gfx = love.graphics

function TextBox:draw()
	local alpha = self.alpha
	local w, h = self.totalW, self.totalH

	gfx.push()
	gfx.translate(0, 8)
	self.label:draw()
	gfx.pop()

	local field_y = self.totalH - 20 - 6
	gfx.setColor(0.15, 0.15, 0.15, alpha)
	gfx.rectangle("fill", 0, field_y, w, 20)
	gfx.setLineWidth(1)
	gfx.setLineStyle("smooth")

	if not self.focus then
		gfx.setColor(0.7, 0.7, 0.7, alpha)
	else
		gfx.setColor(1, 1, 1, alpha)
	end

	gfx.rectangle("line", 0, field_y, w, 20)

	gfx.stencil(function ()
		gfx.rectangle("fill", 0, 0, w, h)
	end, "replace", 1)

	local diff = w - self.inputLabel:getWidth()
	local x = diff < 0 and diff - 2 or 2
	gfx.translate(x, field_y)
	gfx.setStencilTest("greater", 0)
	self.inputLabel:draw()
	gfx.setStencilTest()
end

return TextBox
