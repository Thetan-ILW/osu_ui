local ScreenView = require("osu_ui.views.ScreenView")

local flux = require("flux")

local View = require("osu_ui.views.LobbyList.View")

---@class osu.ui.LobbyListView : osu.ui.ScreenView
---@operator call: osu.ui.LobbyListView
local LobbyListView = ScreenView + {}

function LobbyListView:load()
	local scene = self.gameView.scene

	if not self.view then
		self.view = scene:addChild("lobbyListView", View({ lobbyListView = self, z = 0.1 }))
	end

	self.view.disabled = false
	self.view.alpha = 0
	flux.to(self.view, 0.7, { alpha = 1 }):ease("quadout")

	self.chat = scene:getChild("chat")
	self.chat:fade(1)
end

function LobbyListView:quit()
	local scene = self.gameView.scene
	local main_menu = scene:getChild("mainMenuView")

	flux.to(self.view, 0.4, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self.view.disabled = true
	end)

	flux.to(main_menu, 0.33, { alpha = 1 }):ease("quadout")
	self.chat:fade(0)
	self:changeScreen("mainMenuView")
end

return LobbyListView
