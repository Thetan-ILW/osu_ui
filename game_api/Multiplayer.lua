local class = require("class")

---@class game.MultiplayerAPI
---@operator call: game.MultiplayerAPI
local Multiplayer = class()

function Multiplayer:new(game)
	self.game = game
	assert(self.game)

	self.multiplayerModel = game.multiplayerModel
end

---@return table?
function Multiplayer:getLobby()
	return self.multiplayerModel.room
end

---@return string?
function Multiplayer:getUsername()
	return self.game.configModel.configs.online.user.name
end

---@return number
function Multiplayer:getOnlineCount()
	return #self.game.multiplayerModel.users
end

---@return table
function Multiplayer:getLobbies()
	return self.game.multiplayerModel.rooms
end

---@param name string
---@param password string
---@return string? error
function Multiplayer:createRoom(name, password)
	if name == "" then
		return "empty_name"
	end
	self.multiplayerModel:createRoom(name, password)
end

---@param index
function Multiplayer:joinRoom(index)
	self.game.multiplayerModel.selectedRoom = self:getLobbies()[index]
	self.game.multiplayerModel:joinRoom("")
end

return Multiplayer
