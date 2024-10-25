local class = require("class")

local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")
local AssetModel = require("osu_ui.models.AssetModel")
local OsuAssets = require("osu_ui.OsuAssets")
local Localization = require("osu_ui.models.AssetModel.Localization")
local GlobalEvents = require("osu_ui.GlobalEvents")

local GameView = require("osu_ui.views.GameView")
local SelectView = require("osu_ui.views.SelectView")
--local GameplayView = require("osu_ui.views.GameplayView")
local ResultView = require("osu_ui.views.ResultView")
--local MainMenuView = require("osu_ui.views.MainMenuView")
--local PlayerStatsView = require("osu_ui.views.PlayerStatsView")
--local EditorView = require("ui.views.EditorView")
local TestView = require("osu_ui.views.TestView")
--local ScreenOverlayView = require("osu_ui.views.ScreenOverlayView")

local physfs = require("physfs")
local path_util = require("path_util")

---@class osu.ui.UserInterface
---@operator call: osu.ui.UserInterface
---@field assets osu.ui.OsuAssets
---@field otherGamesPaths {[string]: string}?
local UserInterface = class()

---@param game sphere.GameController
---@param mount_path string
function UserInterface:new(game, mount_path)
	game.persistence:openAndReadThemeConfig("osu_ui", mount_path)
	self.assetModel = AssetModel(game.persistence.configModel, mount_path)
	self.mountPath = mount_path

	self.localization = Localization(path_util.join(mount_path, "osu_ui/localization"), "en.txt")

	self.game = game

	self.gameView = GameView(self)
	self.globalEvents = GlobalEvents(self)
	--self.mainMenuView = MainMenuView(game)
	self.selectView = SelectView(game)
	self.resultView = ResultView(game)
	--self.gameplayView = GameplayView(game)
	--self.playerStatsView = PlayerStatsView(game)
	--self.editorView = EditorView(game)
	self.testView = TestView()
	--self.screenOverlayView = ScreenOverlayView(game)

	self.lastResolutionCheck = -math.huge
	self.prevWindowResolution = 0
end

function UserInterface:getMods()
	local package_manager = self.game.packageManager
	local player_profile_pkg = package_manager:getPackage("player_profile")

	local player_profile

	if player_profile_pkg then
		player_profile = self.game.playerProfileModel
	end

	if not player_profile or (player_profile and player_profile.version ~= 1) then
		player_profile = {
			notInstalled = true,
			pp = 0,
			accuracy = 0,
			osuLevel = 0,
			osuLevelPercent = 0,
			rank = 69,
			getScore = function ()
				return nil
			end,
			getDanClears = function ()
				return "-", "-"
			end,
			isDanIsCleared = function ()
				return false, false
			end,
			getActivity = function ()
				return nil
			end,
			getAvailableDans = function ()
				return nil
			end,
			getDanTable = function (_self, mode, type)
				return nil
			end,
			getOverallStats = function ()
				return nil
			end,
			getModeStats = function ()
				return nil
			end
		}
	end

	self.playerProfile = player_profile

	local minacalc_pkg = package_manager:getPackage("msd_calculator")
	local etterna_msd = minacalc_pkg and require("minacalc.etterna_msd") or {
		getMsdFromData = function ()
			return nil
		end,
		simplifySsr = function ()
			return "minacalc not installed"
		end
	}

	self.etternaMsd = etterna_msd

	local manip_factor_pkg = package_manager:getPackage("manip_factor")
	self.manipFactor = manip_factor_pkg and require("manip_factor") or nil

	local gucci_pkg = package_manager:getPackage("gucci")
	self.gucci = gucci_pkg and require("gucci_init") or nil

	if self.gucci then
		--local FirstTimeSetupView = require("osu_ui.views.FirstTimeSetupView")
		--self.firstTimeSetupView = FirstTimeSetupView(self.game)
	end
end

function UserInterface:loadAssets(view_name)
	local asset_model = self.assetModel
	local configs = self.game.configModel.configs
	local osu = configs.osu_ui

	---@type string
	local language = osu.language

	---@type string
	local skin_path = ("userdata/skins/%s"):format(osu.skin:trim())

	if not self.assets or (self.assets and self.assets.directory ~= skin_path) then
		--local default_localization = asset_model:getLocalizationFileName("English")
		self.assets = OsuAssets(asset_model, skin_path)
		self.assets:load()
	end

	self.assets:loadViewAssets(view_name)
	self.assets:updateVolume(self.game.configModel)
end

function UserInterface:load()
	self:getMods()
	--love.window.setMode(1366, 768)

	local windows = jit.os == "Windows"
	local osu = self.game.configModel.configs.osu_ui

	if windows then
		local osu_skins_path = osu.gucci.osuSkinsPath
		if osu_skins_path ~= "" then
			self:mountOsuSkins(osu_skins_path)
		end
	end

	self:loadAssets()
	self.assets.screenHeight = love.graphics.getHeight()
	self.localization:load()
	self.localization:loadFile("en.txt")

	---@type osu.ui.ScreenView
	local view = self.selectView

	if self.gucci then
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
					self.screenOverlayView.popupView:add("There are no other rhythm games installed on your PC. You should add songs manually. Join our Discord if you need help.", "purple")
					self.gucci.setDefaultSettings(self.game.configModel.configs)
					osu.gucci.installed = true
				end
			else
				self.gucci.setDefaultSettings(self.game.configModel.configs)
				osu.gucci.installed = true
			end
		end
	end

	self.gameView:load(view)
	actions.updateActions(self.game.persistence.configModel.configs.osu_ui)
end

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

function UserInterface:unload()
	self.gameView:unload()
end

function UserInterface:resolutionUpdated()
	if self.prevWindowResolution ~= 0 then
		--self.assets.localization:updateScale() ---TODO: Default fonts are not being updated. Fix this pls
		self.gameView:resolutionUpdated()
	end

	local ww, wh = love.graphics.getDimensions()
	local resolution = ww * wh
	self.prevWindowResolution = resolution
end

---@param dt number
function UserInterface:update(dt)
	local time = love.timer.getTime()
	local ww, wh = love.graphics.getDimensions()
	local resolution = ww * wh

	if time > self.lastResolutionCheck + 0.5 then
		if self.prevWindowResolution ~= resolution then
			self:resolutionUpdated()
		end

		self.lastResolutionCheck = time
	end

	self.assets.screenHeight = wh
	self.assets:updateVolume(self.game.configModel)

	self.gameView:update(dt)

end

function UserInterface:draw()
	self.gameView:draw()
end

---@param event table
function UserInterface:receive(event)
	self.globalEvents:receive(event)
	self.gameView:receive(event)
end

return UserInterface
