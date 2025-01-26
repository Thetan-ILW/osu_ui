local class = require("class")

local AssetModel = require("osu_ui.models.AssetModel")
local ChatModel = require("osu_ui.models.ChatModel")

local SelectAPI = require("game_api.Select")
local MultiplayerAPI = require("game_api.Multiplayer")
local GameplayAPI = require("game_api.Gameplay")
local ResultAPI = require("game_api.Result")
local LocationsAPI = require("game_api.Locations")

local Viewport = require("ui.Viewport")
local Scene = require("osu_ui.Scene")

local packages = require("osu_ui.packages")
local other_games = require("osu_ui.other_games")

---@class osu.ui.UserInterface
---@operator call: osu.ui.UserInterface
---@field assets osu.ui.OsuAssets
local UserInterface = class()

---@param game sphere.GameController
---@param mount_path string
function UserInterface:new(game, mount_path)
	self.game = game
	self.mountPath = mount_path
	game.persistence:openAndReadThemeConfig("osu_ui", mount_path)

	self.assetModel = AssetModel(game.persistence.configModel, mount_path)
	self.chatModel = ChatModel()

	self.selectApi = SelectAPI(game)
	self.multiplayerApi = MultiplayerAPI(game)
	self.gameplayApi = GameplayAPI(game)
	self.resultApi = ResultAPI(game)
	self.locationsApi = LocationsAPI(game)

	require("ui.Component_test")
end

function UserInterface:load()
	self.pkgs = packages(self.game)

	if love.system.getOS() == "Windows" then
		other_games:findOtherGames()
	end
	self.otherGames = other_games

	self.viewport = Viewport({
		targetHeight = 768,
	})
	self.viewport:load()
	local scene = self.viewport:addChild("scene", Scene({ game = self.game, ui = self })) ---@cast scene osu.ui.Scene
	self.scene = scene

	love.mouse.setVisible(false)
	love.keyboard.setKeyRepeat(true)
end

function UserInterface:unload()
	self.selectApi:unloadController()
end

---@param dt number
function UserInterface:update(dt)
	self.viewport:updateTree(dt)
end

function UserInterface:draw()
	self.viewport:drawTree()
end

---@param event table
function UserInterface:receive(event)
	self.gameplayApi:receive(event)

	if event.name == "framestarted" or event.name == "focus" then
		return
	elseif event.name == "mousemoved" then
		return
	end

	self.viewport:receive(event)
end

function UserInterface:switchTheme(name)
	self.game.configModel.configs.settings.graphics.userInterface = name
	self.game.uiModel:switchTheme()
	love.mouse.setVisible(true)
end

return UserInterface
