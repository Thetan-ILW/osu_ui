local Component = require("ui.Component")

local CursorView = require("osu_ui.views.CursorView")
local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")
local Chat = require("osu_ui.views.Chat")
local Options = require("osu_ui.views.Options")

local FontManager = require("ui.FontManager")
local OsuAssets = require("osu_ui.OsuAssets")
local Localization = require("osu_ui.models.AssetModel.Localization")

local MainMenu = require("osu_ui.views.MainMenu")
local LobbyList = require("osu_ui.views.LobbyList")
local Select = require("osu_ui.views.SelectView")
local Gameplay = require("osu_ui.views.Gameplay")

local path_util = require("path_util")

---@alias osu.ui.SceneParams { game: sphere.GameController, ui: osu.ui.UserInterface }

---@class osu.ui.Scene: ui.Component
---@overload fun(params: osu.ui.SceneParams): osu.ui.Scene
---@field game sphere.GameController
---@field ui osu.ui.UserInterface
---@field fontManager ui.FontManager
---@field assets osu.ui.OsuAssets
local Scene = Component + {}

function Scene:new(params)
	Component.new(self, params)

	local fonts = {
		["Regular"] = "osu_ui/assets/ui_font/Aller/Aller_Rg.ttf",
		["Light"] = "osu_ui/assets/ui_font/Aller/Aller_Lt.ttf",
		["Bold"] = "osu_ui/assets/ui_font/Aller/Aller_Bd.ttf",
		["Awesome"] = "osu_ui/assets/ui_font/FontAwesome/FontAwesome.ttf",
		["NotoSansMono"] = "osu_ui/assets/ui_font/NotoSansMono-Regular.ttf"
	}
	local fallbacks = {
		["Regular"] = "osu_ui/assets/ui_font/NotoSansJP/NotoSansJP-Regular.ttf",
		["Light"] = "osu_ui/assets/ui_font/NotoSansJP/NotoSansJP-Light.ttf",
		["Bold"] = "osu_ui/assets/ui_font/NotoSansJP/NotoSansJP-Bold.ttf",
	}
	for k, path in pairs(fonts) do
		fonts[k] = path_util.join(self.ui.mountPath, path)
	end
	for k, path in pairs(fallbacks) do
		fallbacks[k] = path_util.join(self.ui.mountPath, path)
	end

	self.assets = OsuAssets(self.ui.assetModel)
	self.localization = Localization(path_util.join(self.ui.mountPath, "osu_ui/localization"), "en.txt")
	self.fontManager = FontManager(768, fonts, fallbacks)
end

function Scene:load()
	self:clearTree()

	self.screens = {
		mainMenu = MainMenu({ z = 0.1 }),
		lobbyList = LobbyList({ z = 0.08 }),
		select = Select({ z = 0.09 }),
		gameplay = Gameplay ({ x = 0.07 })
	}

	self.viewport = self:getViewport()
	self.width = self.viewport.scaledWidth
	self.height = self.viewport.scaledHeight
	self:getViewport():listenForResize(self)

	self:loadAssets()
	self.localization:load()
	self.localization:loadFile("en.txt")
	self.fontManager:setVieportHeight(self.viewport.height)

	local cursor = self:addChild("cursor", CursorView({
		z = 0.98
	}))

	local options = self:addChild("options", Options({
		game = self.game,
		ui = self.ui,
		localization = self.localization,
		alpha = 0,
		z = 0.25,
	}))
	local chat = self:addChild("chat", Chat({
		chatModel = self.ui.chatModel,
		z = 0.2,
	}))
	local background = self:addChild("background", ParallaxBackground({
		mode = "background_model",
		backgroundModel = self.game.backgroundModel,
		z = 0,
	}))

	---@cast cursor osu.ui.CursorView
	---@cast options osu.ui.OptionsView
	---@cast chat osu.ui.ChatView
	---@cast background osu.ui.ParallaxBackground
	self.cursor = cursor
	self.options = options
	self.chat = chat
	self.background = background

	self:preloadScreen("lobbyList")
	self:addScreen("mainMenu")
end

function Scene:update()
	self.assets:updateVolume(self.game.configModel.configs)
end

function Scene:loadAssets()
	local configs = self.game.configModel.configs
	local osu = configs.osu_ui

	---@type string
	local skin_path = ("userdata/skins/%s"):format(osu.skin:trim())

	if self.assets.directory ~= skin_path then
		self.assets:setPaths(skin_path, "osu_ui/assets")
		self.assets:load()
	end

	self.assets:updateVolume(self.game.configModel.configs)
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

---@param screen_name string
function Scene:transitInScreen(screen_name)
	local screen = self:getChild(screen_name)
	if not screen then
		screen = self:addScreen(screen_name)
	end
	screen:transitIn()
end

function Scene:reload()
	self.width = self.viewport.scaledWidth
	self.height = self.viewport.scaledHeight
	self.fontManager:setVieportHeight(self.viewport.height)
end

---@param event table
function Scene:keyPressed(event)
	local key = event[2]
	if key == "f12" and not event[3] then
		self.game.app.screenshotModel:capture(false)
	end
end

return Scene
