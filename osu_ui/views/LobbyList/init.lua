local Screen = require("osu_ui.views.Screen")
local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local TabButton = require("osu_ui.ui.TabButton")
local Checkbox = require("osu_ui.ui.Checkbox")
local TextBox = require("osu_ui.ui.TextBox")
local Button = require("osu_ui.ui.Button")
local Combo = require("osu_ui.ui.Combo")
local Label = require("ui.Label")
local Blur = require("ui.Blur")
local flux = require("flux")

---@class osu.ui.LobbyListContainer : osu.ui.Screen
---@operator call: osu.ui.LobbyListContainer
---@field multiplayerApi game.MultiplayerAPI
local View = Screen + {}

function View:keyPressed(event)
	if event[2] == "escape" then
		self:quit()
		return true
	end
end

function View:update()
	if self.multiplayerApi:getLobby() then
		self.modal:close()
	end
end

function View:transitIn()
	Screen.transitIn(self, {
		time = 0.7,
		ease = "quadout"
	})
	self.disabled = false
	self.handleEvents = true
	self.alpha = 0
	flux.to(self, 0.7, { alpha = 1 }):ease("quadout")
	self.scene.chat:fade(1)
end

function View:quit()
	self.scene.chat:fade(0)
	self.scene:transitInScreen("mainMenu")
	self:transitOut()
end

function View:reload()
	Screen.reload(self)
	if self.scene.currentScreenId == self.id then
		self.scene.chat:fade(1)
	end
end

function View:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager
	self.scene = scene

	self:getViewport():listenForResize(self)

	self.width, self.height = self.parent:getDimensions()
	self.multiplayerApi = scene.ui.multiplayerApi

	local multi_label = self:addChild("multiplayerLabel", Label({
		x = 3,
		text = "Multiplayer Lobby",
		font = fonts:loadFont("Light", 33),
		shadow = true,
		z = 0.1,
	}))

	self:addChild("lobbyCount", Label({
		x = multi_label:getWidth() + 7,
		y = 13,
		text = "Showing 161 of 257 matches",
		font = fonts:loadFont("Regular", 17),
		shadow = true,
		z = 0.1,
	}))

	self:addChild("optionsBackground", Rectangle({
		y = 64,
		width = self.width,
		height = self.height,
		color = { 0, 0, 0, 0.5}
	}))

	self:addChild("allTab", TabButton({
		x = 10, y = 64,
		origin = { x = 0, y = 1 },
		text = "All",
		font = fonts:loadFont("Bold", 14),
		z = 0.5,
		onClick = function ()
			--self:selectTab("allTab")
		end
	}))
	self:addChild("taikoTab", TabButton({
		x = 128, y = 64,
		origin = { x = 0, y = 1 },
		text = "Taiko",
		font = fonts:loadFont("Bold", 14),
		z = 0.49,
		onClick = function ()
			--self:selectTab("allTab")
		end
	}))
	self:addChild("vsrgTab", TabButton({
		x = 247, y = 64,
		origin = { x = 0, y = 1 },
		text = "VSRG",
		font = fonts:loadFont("Bold", 14),
		z = 0.48,
		onClick = function ()
			--self:selectTab("allTab")
		end
	}))

	self:addChild("ownedBeatmaps", Checkbox({
		x = 16, y = 62,
		height = 37,
		font = fonts:loadFont("Regular", 16),
		label = "Owned Beatmaps",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("gamesWithFriends", Checkbox({
		x = 16, y = 89,
		height = 37,
		font = fonts:loadFont("Regular", 16),
		label = "Games with Friends",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("showFull", Checkbox({
		x = 296, y = 62,
		height = 37,
		font = fonts:loadFont("Regular", 16),
		label = "Show Full",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("showLocked", Checkbox({
		x = 296, y = 89,
		height = 37,
		font = fonts:loadFont("Regular", 16),
		label = "Show Locked",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("showInProgress", Checkbox({
		x = 585, y = 89,
		height = 37,
		font = fonts:loadFont("Regular", 16),
		label = "Show In-Progress",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	local search_label = self:addChild("searchLabel", Label({
		x = 580, y = 66,
		text = "Search:",
		font = fonts:loadFont("Regular", 19),
		shadow = true,
		z = 0.5,
	}))

	self:addChild("searchTextBox", TextBox({
		x = search_label.x + search_label:getWidth() + 6,
		y = 68,
		width = 210,
		z = 0.5,
	}))

	self:addChild("backToMenu", Button({
		x = self.width / 2 - 496, y = 470,
		width = 320, height = 40,
		color = {love.math.colorFromBytes(235, 160, 62)},
		label = "Back to Menu",
		font = fonts:loadFont("Regular", 27),
		z = 0.5,
		onClick = function ()
			self:quit()
		end
	}))

	self:addChild("newGame", Button({
		x = self.width / 2 - 160, y = 470,
		width = 320, height = 40,
		color = {love.math.colorFromBytes(99, 139, 228)},
		label = "New Game",
		font = fonts:loadFont("Regular", 27),
		z = 0.5,
		onClick = function()
			self:newGameModal()
		end
	}))

	self:addChild("quickJoin", Button({
		x = self.width / 2 + 176, y = 470,
		width = 320, height = 40,
		color = { 0.52, 0.72, 0.12, 1 },
		label = "Quick Join",
		font = fonts:loadFont("Regular", 27),
		z = 0.5,
	}))

	self:addChild("blur", Blur({
		percent = 0.5,
		z = -0.01
	}))
end

function View:newGameModal()
	if self.modal then
		return
	end

	local scene = self.scene
	local fonts = scene.fontManager
	local username = self.multiplayerApi:getUsername() or "???"
	local require_password = false

	local max_players_items = {
		{ label = "2 players", players = 2 },
		{ label = "3 players", players = 3 },
		{ label = "4 players", players = 4 },
		{ label = "5 players", players = 5 },
		{ label = "6 players", players = 6 },
		{ label = "7 players", players = 7 },
		{ label = "8 players", players = 8 },
	}
	local max_players_selected = max_players_items[#max_players_items].label

	self.modal = scene:addChild("newGameModal", Component({
		z = 0.3,
		alpha = 0,
		close =  function ()
			flux.to(self.modal, 0.3, { alpha = 0 }):ease("quadout"):oncomplete(function ()
				scene:removeChild("newGameModal")
				self.modal = nil
			end)
		end,
		keyPressed = function(this, event)
			if event[2] == "escape" then
				this:close()
				return true
			end
		end
	}))

	self.modal:addChild("background", Rectangle({
		width = self.width, height = self.height,
		color = { 0, 0, 0, 0.784 },
		blockMouseFocus = true,
	}))

	self.modal:addChild("label", Label({
		x = 9, y = 2,
		text = "Create New Game...",
		font = fonts:loadFont("Light", 33),
		z = 0.1,
	}))

	self.modal:addChild("gameName", Label({
		x = 52, y = 160,
		text = "Game Name:",
		font = fonts:loadFont("Regular", 22),
		z = 0.1,
	}))

	local game_name_textbox = self.modal:addChild("gameNameTextBox", TextBox({
		x = 240, y = 160,
		input = ("%s's game"):format(username),
		width = 720,
		z = 0.1,
	}))

	self.modal:addChild("requirePassword", Checkbox({
		x = 60, y = 204,
		label = "Require password to join",
		large = true,
		z = 0.1,
		getValue = function()
			return require_password
		end,
		clicked = function ()
			require_password = not require_password
		end
	}))

	self.modal:addChild("passwordLabel", Label({
		x = 52, y = 256,
		text = "Password:",
		font = fonts:loadFont("Regular", 22),
		z = 0.1,
	}))

	local password_textbox = self.modal:addChild("gamePassword", TextBox({
		x = 240, y = 256,
		width = 720,
		z = 0.1,
	}))

	self.modal:addChild("maxPlayersLabel", Label({
		x = 52, y = 304,
		text = "Max Players:",
		font = fonts:loadFont("Regular", 22),
		z = 0.1,
	}))

	self.modal:addChild("maxPlayerCombo", Combo({
		x = 240, y = 304,
		width = 320,
		height = 37,
		items = max_players_items,
		z = 0.2,
		getValue = function ()
			return max_players_selected
		end,
		setValue = function(index)
			max_players_selected = max_players_items[index].label
		end,
		format = function(value)
			return value.label
		end
	}))

	self.modal:addChild("startGame", Button({
		x = self.width / 2, y = 432,
		origin = { x = 0.5, y = 0.5 },
		label = "1. Start Game",
		color = { 0.52, 0.72, 0.12, 1 },
		font = fonts:loadFont("Regular", 42),
		z = 0.1,
		onClick = function ()
			local name = game_name_textbox.input
			local password = password_textbox.input
			self.multiplayerApi:createRoom(name, password)
		end
	}))

	self.modal:addChild("cancel", Button({
		x = self.width / 2, y = 512,
		origin = { x = 0.5, y = 0.5 },
		label = "2. Cancel",
		color = { 0.42, 0.42, 0.42, 1 },
		font = fonts:loadFont("Regular", 42),
		z = 0.1,
		onClick = function ()
			self.modal:close()
		end,
	}))

	flux.to(self.modal, 0.5, { alpha = 1 }):ease("quadout")
end

return View
