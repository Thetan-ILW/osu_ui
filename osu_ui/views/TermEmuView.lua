local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local StencilComponent = require("ui.StencilComponent")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Label = require("ui.Label")

local flux = require("flux")
local text_input = require("ui.text_input")

---@class osu.ui.TermEmuView : ui.Component
---@operator call: osu.ui.TermEmuView
---@field shell gucci.Shell
local TermEmuView = Component + {}

function TermEmuView:viewportResized()
	self:clearTree()
	self:load()
end

function TermEmuView:load()
	self:assert(self.shell, "Provide the shell")

	self.open = false
	self.alpha = 0
	self.input = ""
	self.stateCounter = ""

	local fonts = self.shared.fontManager

	self:addChild("background", Rectangle({
		width = self.width,
		height = self.height,
		color = {love.math.colorFromBytes(109, 93, 110)},
		rounding = 8,
		blockMouseFocus = true
	}))

	self.dragging = false

	self:addChild("titleBar", Rectangle({
		x = 5, y = 5,
		width = self.width - 10,
		height = 40,
		rounding = 8,
		color = {love.math.colorFromBytes(79, 69, 87)},
		blockMouseFocus = true,
		z = 0.05,
		mousePressed = function(this)
			if this.mouseOver then
				self.dragging = true
				return true
			end
			return false
		end,
		mouseReleased = function(this)
			self.dragging = false
			return false
		end,
	}))

	self:addChild("title", Label({
		x = 10, y = 5,
		text = "GucciTerm Ver. 1.22474487139",
		font = fonts:loadFont("Regular", 16),
		color = {love.math.colorFromBytes(244, 238, 224)},
		z = 0.2,
	}))

	self:addChild("helpText", Label({
		x = -10, y = 5,
		width = self.width,
		text = "F7 to close",
		font = fonts:loadFont("Regular", 16),
		alignX = "right",
		color = {love.math.colorFromBytes(244, 238, 224)},
		z = 0.2,
	}))

	local output_width = self.width - 10
	local output_height = self.height - 30
	local output = self:addChild("output", StencilComponent({
		x = 5, y = 25,
		width = output_width,
		height = output_height,
		z = 0.1,
		stencilFunction = function ()
			love.graphics.rectangle("fill", 0, 0, output_width, output_height)
		end
	}))

	output:addChild("outputBackground", Rectangle({
		width = output.width,
		height = output.height,
		color = {love.math.colorFromBytes(57, 54, 70)},
		blockMouseFocus = true
	}))

	local area = output:addChild("area", ScrollAreaContainer({
		width = output_width,
		height = output_height,
		scrollLimit = 0,
		z = 0.5
	})) ---@cast area osu.ui.ScrollAreaContainer
	self.area = area

	local buf_label = self.area:addChild("buffer", Label({
		x = 3, y = 3,
		width = output_width,
		text = "",
		color = {love.math.colorFromBytes(244, 238, 224)},
		font = fonts:loadFont("NotoSansMono", 14),
		z = 0.5,
	})) ---@cast buf_label ui.Label
	self.bufferLabel = buf_label
	self:updateBuffer()
end

function TermEmuView:update()
	if self.dragging then
		local viewport_scale = self:getViewport():getInnerScale()
		local mx, my = love.mouse.getPosition()
		self.x = mx * (1 / viewport_scale)
		self.y = my * (1 / viewport_scale)
	end

	if self.stateCounter ~= self.shell.stateCounter then
		self.stateCounter = self.shell.stateCounter
		self:updateBuffer()
	end
end

function TermEmuView:updateBuffer()
	self.bufferLabel:replaceText(
		("%s$ %s"):format(self.shell.buffer, self.input)
	)
	self.area.scrollLimit = math.max(0, self.bufferLabel:getHeight() + 5 - self.area.height)
	self.area:scrollToPosition(self.area.scrollLimit, 0)
end

function TermEmuView:keyPressed(event)
	if self.open then
		if event[2] == "backspace" then
			self.input = text_input.removeChar(self.input)
			self:updateBuffer()
			return true
		end

		if event[2] == "return" then
			self.shell:execute(self.input)
			self.input = ""
			return true
		end

		if event[2] == "up" then
			self.input = self.shell:scrollHistory(-1)
			self:updateBuffer()
			return true
		end

		if event[2] == "down" then
			self.input = self.shell:scrollHistory(1)
			self:updateBuffer()
			return true
		end
	end

	if event[2] ~= "f7" then
		return false
	end

	if self.tween then
		self.tween:stop()
	end

	if self.open then
		self.open = false
		self.tween = flux.to(self, 0.15, { alpha = 0 }):ease("quadout"):oncomplete(function ()
			self:clearTree()
		end)
	else
		self:clearTree()
		self:load()
		self.open = true
		self.tween = flux.to(self, 0.3, { alpha = 1 }):ease("quadout")
	end
end

function TermEmuView:textInput(event)
	if not self.open then
		return false
	end
	self.input = self.input .. event[1]
	self:updateBuffer()
	return true
end

return TermEmuView
