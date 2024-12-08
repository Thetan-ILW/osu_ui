local class = require("class")

local AssetModel = require("osu_ui.models.AssetModel")
local OsuAssets = require("osu_ui.OsuAssets")
local Localization = require("osu_ui.models.AssetModel.Localization")
local ChatModel = require("osu_ui.models.ChatModel")

local SelectAPI = require("game_api.Select")
local MultiplayerAPI = require("game_api.Multiplayer")

local Viewport = require("ui.Viewport")
local FontManager = require("ui.FontManager")
local CursorView = require("osu_ui.views.CursorView")
local Scene = require("osu_ui.views.Scene")

local packages = require("osu_ui.packages")

local path_util = require("path_util")

---@class osu.ui.UserInterface
---@operator call: osu.ui.UserInterface
---@field assets osu.ui.OsuAssets
---@field otherGamesPaths {[string]: string}?
local UserInterface = class()

---@param game sphere.GameController
---@param mount_path string
function UserInterface:new(game, mount_path)
	self.game = game
	self.mountPath = mount_path
	game.persistence:openAndReadThemeConfig("osu_ui", mount_path)

	self.assetModel = AssetModel(game.persistence.configModel, mount_path)
	self.chatModel = ChatModel()
	self.localization = Localization(path_util.join(mount_path, "osu_ui/localization"), "en.txt")
	self.assets = OsuAssets(self.assetModel)

	self.selectApi = SelectAPI(game)
	self.multiplayerApi = MultiplayerAPI(game)

	require("ui.Component_test")
end

function UserInterface:loadAssets()
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

function UserInterface:load()
	self.pkgs = packages(self.game)

	self:loadAssets()
	self.localization:load()
	self.localization:loadFile("en.txt")

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
		fonts[k] = path_util.join(self.mountPath, path)
	end
	for k, path in pairs(fallbacks) do
		fallbacks[k] = path_util.join(self.mountPath, path)
	end

	self.viewport = Viewport({
		targetHeight = 768,
		shared = {
			assets = self.assets,
			fontManager = FontManager(768, fonts, fallbacks),
			localization =  self.localization,
			pkgs = self.pkgs,
			selectApi = self.selectApi,
			multiplayerApi = self.multiplayerApi
		}
	})
	self.viewport:load()
	self.viewport:addChild("cursor", CursorView({
		osuConfig = self.game.configModel.configs.osu_ui,
		z = 0.98
	}))

	local scene = self.viewport:addChild("scene", Scene({ game = self.game, ui = self })) ---@cast scene osu.ui.SceneView
	self.scene = scene

	love.mouse.setVisible(false)

	--[[
	local windows = jit.os == "Windows"
	local osu = self.game.configModel.configs.osu_ui
	if windows then
		local osu_skins_path = osu.gucci.osuSkinsPath
		if osu_skins_path ~= "" then
			self:mountOsuSkins(osu_skins_path)
		end
	end
	if self.pkgs.gucci then
		if not osu.gucci.installed then
			if windows then
				local other_games = self.gucci.findOtherGames()
				local has_other_games = false
				for _, _ in pairs(other_games) do
					has_other_games = true
				end

				if has_other_games then
					self.otherGamesPaths = other_games
					view = self.firstTimeSetupView
				else
					self.screenOverlayView.popupView:add(
						"There are no other rhythm games installed on your PC. You should add songs manually. Join our Discord if you need help.",
						"purple")
					self.gucci.setDefaultSettings(self.game.configModel.configs)
					osu.gucci.installed = true
				end
			else
				self.gucci.setDefaultSettings(self.game.configModel.configs)
				osu.gucci.installed = true
			end
		end
	end
	]]
end

--[[
local osu_skins_mounted = false

function UserInterface:mountOsuSkins(path)
	if osu_skins_mounted then
		return
	end

	local success, err = physfs.mount(path, "/userdata/skins", false)
	if not success then
		print(err)
		return
	end
	self.game.noteSkinModel:load()
	osu_skins_mounted = true
end
]]

function UserInterface:unload()
end

---@param dt number
function UserInterface:update(dt)
	self.assets:updateVolume(self.game.configModel.configs)
	self.viewport:updateTree(dt)
end

function UserInterface:draw()
	self.viewport:drawTree()
end

---@param event table
function UserInterface:receive(event)
	if event.name == "framestarted" then
		return
	elseif event.name == "mousemoved" then
		return
	end

	self.viewport:receive(event)
end

return UserInterface
