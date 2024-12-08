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

---@param name string
---@param password string
---@return string? error
function Multiplayer:createRoom(name, password)
	if name == "" then
		return "empty_name"
	end
	self.multiplayerModel:createRoom(name, password)
end

return Multiplayer
