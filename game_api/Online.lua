local class = require("class")

---@class game.OnlineAPI
---@operator call: game.OnlineAPI
local Online = class()

---@param game sphere.GameController
function Online:new(game)
	self.game = game
end

---@return string?
function Online:getUsername()
	return self.game.configModel.configs.online.user.name
end

---@return number
function Online:getOnlineCount()
	return #self.game.multiplayerModel.users
end

return Online
