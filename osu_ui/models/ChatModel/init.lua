local class = require("class")

local Channel = require("osu_ui.models.ChatModel.Channel")

---@class osu.ui.ChatModel
---@operator call: osu.ui.ChatModel
---@field channels {[string]: osu.ui.ChatChannel}
local ChatModel = class()

function ChatModel:new()
	self.channels = {}

	local general = self:addChannel(Channel("#general"))
	general:addMessage({
		text = "\n\n\n\n\n\n\n\n\n",
	})
	general:addMessage({
		text = "Welcome to soundsphere.xyz, Player!\n",
	})
	general:addMessage({
		text = "Actually, this chat is not connected to any server, so no one will hear you.\n",
		messageColor = { 0.65, 0.65, 0.65, 1 }
	})

	local logs = self:addChannel(Channel("#logs"))
	logs.sendMessage = function () end
	logs:addMessage({
		text = "\n\n\n\n\n\n\n\n\n\n\n",
	})
	logs:addMessage({
		text = "Hello! You can't send messages here!\n",
	})
end

function ChatModel:addChannel(channel)
	table.insert(self.channels, channel)
	self.channels[channel.name] = channel
	return channel
end

---@param name string
---@return osu.ui.ChatChannel
function ChatModel:getChannel(name)
	return self.channels[name]
end

function ChatModel:getChannels()
	return self.channels
end

return ChatModel
