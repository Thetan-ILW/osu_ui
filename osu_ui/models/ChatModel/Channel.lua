local class = require("class")

---@alias osu.ui.ChatMessage { username: string?, userType?: "local" | "user" | "supporter" | "moderator" | "developer", time: number, text: string, messageColor: number[] }

---@class osu.ui.ChatChannel
---@operator call: osu.ui.ChatChannel
---@field name string
---@field messages osu.ui.ChatMessage
---@field formattedMessages table
local Channel = class()

function Channel:new(name)
	self.name = name
	self.messages = {}
	self.formattedMessages = {}
end

---@param message osu.ui.ChatMessage
function Channel:addMessage(message)
	message.time = message.time or os.time()
	message.messageColor = message.messageColor or { 1, 1, 1, 1 }
	table.insert(self.messages, message)
	self:formatAndAdd(message)
end

function Channel:formatAndAdd(message)
	table.insert(self.formattedMessages, message.messageColor)
	if message.username then
		table.insert(self.formattedMessages, ("%s %s: %s"):format(os.date("%I:%M%p"), message.username, message.text))
		return
	end
	table.insert(self.formattedMessages, message.text)
end

function Channel:fullFormat()
	self.formattedMessages = {}

	for _, v in ipairs(self.messages) do
		self:formatAndAdd(v)
	end
end

---@param text string
function Channel:sendMessage(text)
	self:addMessage({ username = "Player", text = text })
end

return Channel
