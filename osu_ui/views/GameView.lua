local class = require("class")
local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")

local FadeTransition = require("ui.views.FadeTransition")
local FrameTimeView = require("ui.views.FrameTimeView")
local AsyncTasksView = require("ui.views.AsyncTasksView")
local NotificationView = require("osu_ui.views.NotificationView")
local PopupView = require("osu_ui.views.PopupView")
local TooltipView = require("osu_ui.views.TooltipView")
local CursorView = require("osu_ui.views.CursorView")
local OsuAssets = require("osu_ui.OsuAssets")
local OsuLayout = require("osu_ui.views.OsuLayout")

---@class osu.ui.GameView
---@operator call: osu.ui.GameView
---@field view osu.ui.ScreenView?
---@field ui osu.ui.UserInterface
---@field assetModel osu.ui.AssetModel
---@field assets osu.ui.OsuAssets
local GameView = class()

local last_height_check = -math.huge
local prev_window_res = 0

---@param game sphere.GameController
---@param ui osu.ui.UserInterface
function GameView:new(game, game_ui)
	self.game = game
	self.ui = game_ui
	self.fadeTransition = FadeTransition()
	self.frameTimeView = FrameTimeView()
	self.notificationView = NotificationView()
	self.popupView = PopupView()
	self.tooltipView = TooltipView()
	self.cursor = CursorView()
	self.screenshotSaveLocation = love.filesystem.getSource() .. "/userdata/screenshots"
end

function GameView:load()
	actions.updateActions(self.game.persistence.configModel.configs.osu_ui)
	self.frameTimeView.game = self.game
	self.frameTimeView:load()

	prev_window_res = love.graphics.getWidth() * love.graphics.getHeight()
	self.assetModel = self.ui.assetModel
	self:loadAssets()
	self.notificationView:load(self.assets)
	self.popupView:load(self.assets)
	self.tooltipView:load(self.assets)
	self.cursor:load(self.assets)
	self:setView(self.ui.mainMenuView)
end

function GameView:loadAssets(view_name)
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
end

---@param view osu.ui.ScreenView
function GameView:_setView(view)
	if self.view then
		self.view:unload()
	end

	view.prevView = self.view

	local view_names = {
		[self.ui.mainMenuView] = "mainMenuView",
		[self.ui.selectView] = "selectView",
		[self.ui.resultView] = "resultView",
	}

	self:loadAssets(view_names[view])
	self.view = view
	self.view.assetModel = self.ui.assetModel
	self.view.assets = self.assets
	self.view.notificationView = self.notificationView
	self.view.popupView = self.popupView
	self.view.cursor = self.cursor
	self.view:load()
end

---@param view osu.ui.ScreenView
function GameView:setView(view)
	view.ui = self.ui
	view.gameView = self

	self.fadeTransition:transit(function()
		if self.view then
			self.view.changingScreen = true
		end

		self.fadeTransition:transitAsync(1, 0)
		view.changingScreen = false
		self:_setView(view)
		self.fadeTransition:transitAsync(0, 1)
	end)
end

function GameView:reloadView()
	self:setView(self.view)
end

function GameView:unload()
	love.mouse.setVisible(true)
	if not self.view then
		return
	end
	self.view:unload()
	self.view = nil
end

---@param dt number
function GameView:update(dt)
	self.fadeTransition:update()
	if not self.view then
		return
	end

	local time = love.timer.getTime()
	local ww, wh = love.graphics.getDimensions()
	local resolution = ww * wh

	if time > last_height_check + 0.5 then
		if prev_window_res ~= resolution then
			self.assets.localization:updateScale()
			self.view:resolutionUpdated()
			prev_window_res = resolution
		end

		last_height_check = time
	end

	ui.setTextScale(math.min(768 / wh, 1))
	self.tooltipView:update()
	self.view:update(dt)
	self.cursor:update(dt)

	if ui.keyPressed("f12") then
		self.popupView:add(("Saved screenshot to %s"):format(self.screenshotSaveLocation), "purple", function()
			love.system.openURL(self.screenshotSaveLocation)
		end)
	end

	OsuLayout:draw()
end

function GameView:draw()
	if not self.view then
		return
	end

	self.fadeTransition:drawBefore()
	self.view:draw()
	self.popupView:draw()
	self.notificationView:draw()
	self.cursor:draw()
	self.tooltipView:draw()
	self.fadeTransition:drawAfter()
	self.frameTimeView:draw()

	local settings = self.game.configModel.configs.settings
	local showTasks = settings.miscellaneous.showTasks

	if showTasks then
		AsyncTasksView()
	end
end

---@param event table
function GameView:receive(event)
	self.frameTimeView:receive(event)
	if not self.view then
		return
	end

	self.view:receive(event)
end

return GameView
