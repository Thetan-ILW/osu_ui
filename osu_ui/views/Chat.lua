local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local StencilComponent = require("ui.StencilComponent")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Label = require("ui.Label")
local TabButton = require("osu_ui.ui.TabButton")

local flux = require("flux")
local text_input = require("ui.text_input")

---@class osu.ui.ChatView : ui.Component
---@operator call: osu.ui.ChatView
---@field chatModel osu.ui.ChatModel
local Chat = Component + {}

function Chat:fade(target_value)
	if target_value > 0 then
		self.alpha = 0.01
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

local input_format = { ">", "" }
function Chat:updateInput()
	input_format[2] = self.input
	local input = self.inputLabel ---@cast input ui.Label
	input:replaceText(input_format)
end

function Chat:updateChannel()
	local area = self.area ---@cast area osu.ui.ScrollAreaContainer
	local messages = self.messagesLabel ---@cast messages ui.Label
	messages:replaceText(self.selectedChannel.formattedMessages)
	area.scrollLimit = math.max(0, messages:getHeight() + 5 - self.area.height)
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
		self.selectedChannel:sendMessage(self.input .. "\n")
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

function Chat:load()
	self:assert(self.chatModel, "Provide the chat model")

	self.width, self.height = self.parent:getDimensions()
	self:getViewport():listenForResize(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager

	self.selectedChannel = self.chatModel:getChannel("#general")
	self.state = "closed"
	self.disabled = true
	self.alpha = 0
	self.input = ""

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
	self.messagesLabel = self.area:addChild("messages", Label({
		x = 5,
		font = fonts:loadFont("Regular", 16),
		text = "",
	}))

	self.inputLabel = self:addChild("input", Label({
		x = 5, y = self.height - 4,
		origin = { y = 1 },
		text = "",
		font = fonts:loadFont("Regular", 16),
		z = 0.3,
	}))

	self.tabs = self:addChild("tabs", Component({
		x = 5,
		y = self.height - bg:getHeight() - 2,
		z = 1,
	}))

	local tab_spacing = 107
	local channels = self.chatModel:getChannels()

	for i, v in ipairs(channels) do
		self.tabs:addChild(v.name, TabButton({
			x = (i - 1) * tab_spacing,
			text = v.name,
			tabColor = {love.math.colorFromBytes(51, 71, 157, 255)},
			z = 0.99 - (i * 0.00001),
			onClick = function() self:openChannel(v.name) end
		}))
	end

	self:updateInput()
	self:openChannel("#general")
end

function Chat:openChannel(name)
	local channels = self.chatModel:getChannels()
	for i, channel in ipairs(channels) do
		local tab = self.tabs.children[channel.name] ---@cast tab osu.ui.TabButton
		tab.active = false
		tab.z = 0.99 - (i * 0.00001)
	end

	local tab = self.tabs.children[name] ---@cast tab osu.ui.TabButton
	tab.active = true
	tab.z = 1
	self.selectedChannel = self.chatModel:getChannel(name)
	self:updateChannel()
	self.tabs.deferBuild = true

	local area = self.area ---@cast area osu.ui.ScrollAreaContainer
	local messages = self.messagesLabel ---@cast messages ui.Label
	area.scrollVelocity = 0
	area.scrollPosition = math.max(0, messages:getHeight() + 5 - self.area.height)
end

return Chat
