local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local Button = require("osu_ui.ui.Button")

local flux = require("flux")

---@class osu.ui.Modal : ui.Component
---@operator call: osu.ui.Modal
local Modal = Component + {}

function Modal:keyPressed(event)
	if event[2] == "escape" or event[2] == "f1" then
		self:close()
		return true
	end

	return false
end

function Modal:close()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.2, { alpha = 0 }):ease("quadout"):oncomplete(function()
		self:kill()
	end)
end

function Modal:open()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.2, { alpha = 1 }):ease("cubicout")
end

function Modal:update()
	self.handleEvents = self.alpha > 0.7
end

---@param name string
function Modal:initModal(name)
	local width, height = self.parent:getDimensions()

	self.container = self:addChild("container", Component({
		y = 160,
		z = 0.01
	}))

	self:addChild("background", Rectangle({
		width = width,
		height = height,
		color = { 0, 0, 0, 0.784 },
		blockMouseFocus = true,
		textInput = function()
			return true
		end,
		keyPressed = function()
			return true
		end
	}))

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.fonts = scene.fontManager
	self.scene = scene
	self:addChild("label", Label({
		x = 9, y = 2,
		boxWidth = width - 18,
		text = name,
		font = self.fonts:loadFont("Light", 33),
		z = 0.1,
	}))

	self.alpha = 0
	self.buttonsAnimation = 0
	self.options = 0
	flux.to(self, 0.5, { alpha = 1 }):ease("quadout")
	flux.to(self, 1.6, { buttonsAnimation = 1 }):ease("elasticout")
end

---@enum osu.ui.ModalButtonColors
Modal.buttonColors = {
	red = { 0.91, 0.19, 0, 1 },
	green = { 0.52, 0.72, 0.12, 1 },
	purple = { 0.72, 0.4, 0.76, 1 },
	gray = { 0.42, 0.42, 0.42, 1 },
	blue =  { 0.05, 0.52, 0.65, 1 }
}

---@param label string
---@param color osu.ui.ModalButtonColors
---@param on_click function
function Modal:addOption(label, color, on_click)
	self.container:autoSize()

	local width = self.parent:getWidth()
	local start_pos = self.options % 2 == 0 and 40 or -40

	self.container:addChild(label, Button({
		x = width / 2, y = self.container:getHeight() + 12,
		origin = { x = 0.5 },
		font = self.fonts:loadFont("Regular", 42),
		label = ("%i. %s"):format(self.options + 1, label),
		color = color,
		onClick = function ()
			on_click(self)
		end,
		key = tostring(self.options + 1),
		update = function(this)
			local a = self.buttonsAnimation
			if a > 1 then
				a = 1 - (a - 1)
			end
			this.x = (width / 2) + (start_pos * (1 - a))
		end,
		keyPressed = function(this, event)
			if event[2] == this.key then
				this.onClick()
				return true
			end
		end
	}))

	self.options = self.options + 1
end

return Modal
