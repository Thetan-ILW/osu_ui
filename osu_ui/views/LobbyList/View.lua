local Component = require("ui.Component")
local Label = require("ui.Label")
local Image = require("ui.Image")
local Rectangle = require("ui.Rectangle")
local TabButton = require("osu_ui.ui.TabButton")
local Checkbox = require("osu_ui.ui.Checkbox")
local TextBox = require("osu_ui.ui.TextBox")
local Button = require("osu_ui.ui.Button")

---@class osu.ui.LobbyListContainer : ui.Component
---@operator call: osu.ui.LobbyListContainer
---@field lobbyListView osu.ui.LobbyListView
local View = Component + {}

function View:keyPressed(event)
	if event[2] == "escape" then
		self.lobbyListView:quit()
	end
end

function View:load()
	local fonts = self.shared.fontManager

	self:getViewport():listenForResize(self)

	self.width, self.height = self.parent:getDimensions()

	local multi_label = self:addChild("multiplayerLabel", Label({
		x = 3,
		text = "Multiplayer Lobby",
		font = fonts:loadFont("Light", 33),
		shadow = true
	}))

	self:addChild("lobbyCount", Label({
		x = multi_label:getWidth() + 7,
		y = 13,
		text = "Showing 161 of 257 matches",
		font = fonts:loadFont("Regular", 17),
		shadow = true
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
		x = 16, y = 80,
		label = "Owned Beatmaps",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("gamesWithFriends", Checkbox({
		x = 16, y = 107,
		label = "Games with Friends",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("showFull", Checkbox({
		x = 296, y = 80,
		label = "Show Full",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("showLocked", Checkbox({
		x = 296, y = 107,
		label = "Show Locked",
		z = 0.5,
		getValue = function ()
			return false
		end
	}))

	self:addChild("showInProgress", Checkbox({
		x = 585, y = 107,
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
		y = 94,
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
			self.lobbyListView:quit()
		end
	}))

	self:addChild("newGame", Button({
		x = self.width / 2 - 160, y = 470,
		width = 320, height = 40,
		color = {love.math.colorFromBytes(99, 139, 228)},
		label = "New Game",
		font = fonts:loadFont("Regular", 27),
		z = 0.5,
	}))

	self:addChild("quickJoin", Button({
		x = self.width / 2 + 176, y = 470,
		width = 320, height = 40,
		color = { 0.52, 0.72, 0.12, 1 },
		label = "Quick Join",
		font = fonts:loadFont("Regular", 27),
		z = 0.5,
	}))
end

return View
