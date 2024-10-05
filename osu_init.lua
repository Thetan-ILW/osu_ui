local class = require("class")

local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")
local AssetModel = require("osu_ui.models.AssetModel")
local OsuAssets = require("osu_ui.OsuAssets")
local GlobalEvents = require("osu_ui.GlobalEvents")

local GameView = require("osu_ui.views.GameView")
local SelectView = require("osu_ui.views.SelectView")
local GameplayView = require("osu_ui.views.GameplayView")
local ResultView = require("osu_ui.views.ResultView")
local MainMenuView = require("osu_ui.views.MainMenuView")
local PlayerStatsView = require("osu_ui.views.PlayerStatsView")
local EditorView = require("ui.views.EditorView")
local ScreenOverlayView = require("osu_ui.views.ScreenOverlayView")
local OsuLayout = require("osu_ui.views.OsuLayout")

---@class osu.ui.UserInterface
---@operator call: osu.ui.UserInterface
---@field assets osu.ui.OsuAssets
local UserInterface = class()

---@param game sphere.GameController
---@param mount_path string
function UserInterface:new(game, mount_path)
	game.persistence:openAndReadThemeConfig("osu_ui", mount_path)
	self.assetModel = AssetModel(game.persistence.configModel, mount_path)

	self.game = game

	self.gameView = GameView(self)
	self.globalEvents = GlobalEvents(self)
	self.mainMenuView = MainMenuView(game)
	self.selectView = SelectView(game)
	self.resultView = ResultView(game)
	self.gameplayView = GameplayView(game)
	self.playerStatsView = PlayerStatsView(game)
	self.editorView = EditorView(game)
	self.screenOverlayView = ScreenOverlayView(game)

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
end

function UserInterface:loadAssets(view_name)
	local asset_model = self.assetModel
	local configs = self.game.configModel.configs
	local osu = configs.osu_ui

	---@type string
	local language = osu.language

	---@type string
	local skin_path = ("userdata/skins/%s"):format(osu.skin)

	local assets = asset_model:get("osu")

	if not assets or (assets and assets.directory ~= skin_path) then
		local default_localization = asset_model:getLocalizationFileName("English")
		assets = OsuAssets(asset_model, skin_path)
		assets:load(default_localization)
		asset_model:store("osu", assets)
	end

	---@cast assets osu.ui.OsuAssets
	assets:loadViewAssets(view_name)
	assets:loadLocalization(asset_model:getLocalizationFileName(language))
	assets:updateVolume(self.game.configModel)
	self.assets = assets
	self.screenOverlayView:load(assets)
end

function UserInterface:load()
	self:getMods()
	self:loadAssets()
	self.screenOverlayView:load(self.assets)
	self.gameView:load(self.mainMenuView)
	actions.updateActions(self.game.persistence.configModel.configs.osu_ui)

	self.prevWindowResolution = -999
end

function UserInterface:unload()
	self.gameView:unload()
end

---@param dt number
function UserInterface:update(dt)
	local time = love.timer.getTime()
	local ww, wh = love.graphics.getDimensions()
	local resolution = ww * wh

	if time > self.lastResolutionCheck + 0.5 then
		if self.prevWindowResolution ~= resolution then
			self.assets.localization:updateScale() ---TODO: Default fonts are not being updated. Fix this pls
			self.gameView:resolutionUpdated()
			self.prevWindowResolution = resolution

			OsuLayout:draw()
			ui.layoutW, ui.layoutH = OsuLayout:move("base")
		end

		self.lastResolutionCheck = time
	end

	ui.setTextScale(math.min(768 / wh, 1))

	self.gameView:update(dt)
	self.screenOverlayView:update(dt)
end

function UserInterface:draw()
	self.gameView:draw()
end

---@param event table
function UserInterface:receive(event)
	self.globalEvents:receive(event)
	self.screenOverlayView:receive(event)
	self.gameView:receive(event)
end

return UserInterface
