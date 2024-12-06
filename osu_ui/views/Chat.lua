local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local StencilComponent = require("ui.StencilComponent")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Label = require("ui.Label")

local flux = require("flux")
local text_input = require("ui.text_input")

---@class osu.ui.ChatView : ui.Component
---@operator call: osu.ui.ChatView
local Chat = Component + {}

function Chat:fade(target_value)
	if target_value > 0 then
		self.disabled = false
	end

	self.state = target_value == 0 and "closed" or "open"
	flux.to(self, 0.4, { alpha = target_value }):ease("quadout")
end

function Chat:toggle()
	self:fade(self.state == "closed" and 1 or 0)
end

function Chat:update()
	self.y = (1 - self.alpha) * 70

	if self.alpha == 0 then
		self.disabled = true
	end
end

local colors = {
	client = { 1, 1, 1, 1 },
	user = { 0.85, 0.8, 0.52, 1 }
}
local input_format = { ">", "" }
function Chat:updateInput()
	input_format[2] = self.input
	local input = self.inputLabel ---@cast input ui.Label
	input:replaceText(input_format)
end

function Chat:updateChannel()
	local channel = self.channel ---@cast channel ui.Label
	channel:replaceText(self.messages)

	local area = self.area ---@cast area osu.ui.ScrollAreaContainer
	area.scrollLimit = math.max(0, channel:getHeight() + 5 - self.area.height)
	area:scrollToPosition(area.scrollLimit, 0)
end

function Chat:keyPressed(event)
	if event[2] == "backspace" then
		self.input = text_input.removeChar(self.input)
		self:updateInput()
		return true
	end

	if event[2] == "return" then
		if self.input == "" then
			return true
		end
		table.insert(self.messages, colors.client)
		table.insert(self.messages, ("10:40 Player: %s\n"):format(self.input))
		self.input = ""
		self:updateInput()
		self:updateChannel()
		return true
	end
end

function Chat:textInput(event)
	self.input = self.input .. event[1]
	self:updateInput()
	return true
end

--- tabs love.math.colorFromBytes(51, 71, 157)

function Chat:load()
	self.width, self.height = self.parent:getDimensions()
	self:getViewport():listenForResize(self)

	local fonts = self.shared.fontManager

	self.state = "closed"
	self.disabled = true
	self.alpha = 0
	self.input = ""
	self.messages = {"\n\n\n\n\n\n\n\n\n",
		"Welcome to soundsphere.xyz, Player!\n",
		{ 0.65, 0.65, 0.65, 1 }, "Actually, this chat is not connected to any server, so no one will hear you.\n"
	}

	local bg = self:addChild("background", Rectangle({
		y = self.height,
		origin = { y = 1 },
		width = self.width,
		height = 256,
		color = { 0, 0, 0, 210 / 255 },
		blockMouseFocus = true,
		z = 0,
	}))

	local tabs_bg = self:addChild("tabsBackground", Rectangle({
		y = self.height - bg:getHeight(),
		width = self.width,
		height = 22,
		color = { 1, 1, 1, 0.18 },
		blockMouseFocus = true,
		z = 0.1,
	}))

	local stencil_h = bg:getHeight() - tabs_bg:getHeight() - 22
	local stencil = self:addChild("stencil", StencilComponent({
		y = self.height - bg:getHeight() + tabs_bg:getHeight(),
		z = 0.2,
		stencilFunction = function()
			love.graphics.rectangle("fill", 0, 0, self.width, stencil_h)
		end
	}))
	self.area = stencil:addChild("area", ScrollAreaContainer({
		width = self.width,
		height = bg:getHeight() - 22,
		scrollLimit = 0,
	}))
	self.channel = self.area:addChild("messages", Label({
		x = 5,
		font = fonts:loadFont("Regular", 16),
		text = self.messages,
	}))

	self.inputLabel = self:addChild("input", Label({
		x = 5, y = self.height - 4,
		origin = { y = 1 },
		text = "",
		font = fonts:loadFont("Regular", 16),
		z = 0.3,
	}))

	self:updateInput()

	-- General
	-- Lobby
	-- Logs
end

return Chat
