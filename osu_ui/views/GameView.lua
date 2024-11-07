local class = require("class")

local CursorView = require("osu_ui.views.CursorView")
local NotificationView = require("osu_ui.views.NotificationView")
local FadeTransition = require("ui.views.FadeTransition")
local ScreenContainer = require("osu_ui.ui.ScreenContainer")
local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")

---@class osu.ui.GameView
---@operator call: osu.ui.GameView
---@field view osu.ui.ScreenView?
---@field ui osu.ui.UserInterface
local GameView = class()

---@param game_ui osu.ui.UserInterface
function GameView:new(game_ui)
	self.game = game_ui.game
	self.ui = game_ui
	self.fadeTransition = FadeTransition()
	self.screenContainer = ScreenContainer({ nativeHeight = 768 })
end

function GameView:load(view)
	self.screenContainer:load()
	self.screenContainer:addChild("background", ParallaxBackground({
		mode = "background_model",
		backgroundModel = self.game.backgroundModel,
		depth = 0
	}))
	self.screenContainer:addChild("cursor", CursorView({
		assets = self.ui.assets,
		osuConfig = self.game.configModel.configs.osu_ui,
		depth = 0.98
	}))
	self.screenContainer:addChild("notification", NotificationView({
		assets = self.ui.assets,
		depth = 0.97
	}))

	self:forceSetView(view)
end

---@param view osu.ui.ScreenView
function GameView:_setView(view)
	if self.view then
		self.view:unload()
	end

	view.prevView = self.view

	local view_names = {
		[self.ui.selectView] = "selectView",
		[self.ui.resultView] = "resultView",
	}

	self.ui:loadAssets(view_names[view])
	self.view = view
	self.view.assetModel = self.ui.assetModel
	self.view.assets = self.ui.assets
	self.view.localization = self.ui.localization
	self.view:load()
	self.screenContainer:build()
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

---@param view osu.ui.ScreenView
function GameView:forceSetView(view)
	view.ui = self.ui
	view.gameView = self

	if self.fadeTransition.coroutine then
		self.fadeTransition.coroutine = nil
	end

	if self.view then
		self.view.changingScreen = true
	end

	view.changingScreen = false
	self:_setView(view)

	self.fadeTransition:transit(function()
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

	love.graphics.origin()
	self.view:update(dt)
	self.screenContainer:setSize(love.graphics.getDimensions())
	self.screenContainer:setTextScale(1 / self.ui.assets:getTextDpiScale())
	self.screenContainer:update(dt)
end

function GameView:resolutionUpdated()
	self.view:resolutionUpdated()
end

---@param event table
function GameView:receive(event)
	if not self.view then
		return
	end

	love.graphics.origin()
	self.view:receive(event)
	self.screenContainer:receive(event)
end
function GameView:draw()
	if not self.view then
		return
	end

	self.fadeTransition:drawBefore()
	self.screenContainer:draw()
	self.fadeTransition:drawAfter()
end

return GameView
