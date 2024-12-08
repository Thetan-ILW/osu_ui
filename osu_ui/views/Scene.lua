local Component = require("ui.Component")

local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")
local Chat = require("osu_ui.views.Chat")
local Options = require("osu_ui.views.Options")

local MainMenu = require("osu_ui.views.MainMenu")
local LobbyList = require("osu_ui.views.LobbyList")
local Select = require("osu_ui.views.SelectView")

---@alias osu.ui.SceneViewParams { game: sphere.GameController, ui: osu.ui.UserInterface }

---@class osu.ui.SceneView : ui.Component
---@overload fun(params: osu.ui.SceneViewParams): osu.ui.SceneView
---@field game sphere.GameController
---@field ui osu.ui.UserInterface
local Scene = Component + {}

function Scene:load()
	self:clearTree()

	self.screens = {
		mainMenu = MainMenu({ z = 0.1 }),
		lobbyList = LobbyList({ z = 0.08 }),
		select = Select({ z = 0.09 }),
	}

	self.viewport = self:getViewport()
	self.width = self.viewport.scaledWidth
	self.height = self.viewport.scaledHeight
	self.shared.scene = self
	self:getViewport():listenForResize(self)

	self:addChild("options", Options({
		game = self.game,
		ui = self.ui,
		localization = self.ui.localization,
		alpha = 0,
		z = 0.2,
	}))
	self:addChild("chat", Chat({
		chatModel = self.ui.chatModel,
		z = 0.3,
	}))
	self:addChild("background", ParallaxBackground({
		mode = "background_model",
		backgroundModel = self.game.backgroundModel,
		z = 0,
	}))

	self:preloadScreen("lobbyList")
	self:addScreen("mainMenu")
end

function Scene:addScreen(name)
	local screen = self.screens[name]
	if not screen then
		self:assert(false, ("No screen with name: %s"):format(name))
	end
	return self:addChild(name, screen)
end

function Scene:preloadScreen(name)
	self:addScreen(name).disabled = true
end

function Scene:transitInScreen(screen_name)
	self:getChild(screen_name):transitIn()
end

function Scene:reload()
	self.width = self.viewport.scaledWidth
	self.height = self.viewport.scaledHeight
end

---@param event table
function Scene:keyPressed(event)
	local key = event[2]
	if key == "f12" and not event[3] then
		self.game.app.screenshotModel:capture(false)
	end
end

return Scene
