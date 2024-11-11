local class = require("class")

local CursorView = require("osu_ui.views.CursorView")
local NotificationView = require("osu_ui.views.NotificationView")
local FadeTransition = require("ui.views.FadeTransition")
local Viewport = require("osu_ui.ui.Viewport")
local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")

local Options = require("osu_ui.views.Options")

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
	self.viewport = Viewport({ nativeHeight = 768 })
end

function GameView:load(view)
	self.viewport:load()
	self.viewport:addChild("background", ParallaxBackground({
		mode = "background_model",
		backgroundModel = self.game.backgroundModel,
		depth = 0
	}))
	self.viewport:addChild("cursor", CursorView({
		assets = self.ui.assets,
		osuConfig = self.game.configModel.configs.osu_ui,
		blockMouseFocus = false,
		depth = 0.98
	}))
	self.viewport:addChild("notifications", NotificationView({
		assets = self.ui.assets,
		blockMouseFocus = false,
		depth = 0.97,
	}))
	self.viewport:addChild("options", Options({
		depth = 0.2,
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
		[self.ui.gameplayView] = "gameplayView",
		[self.ui.resultView] = "resultView",
	}

	self.ui:loadAssets(view_names[view])
	self.view = view
	self.view.assetModel = self.ui.assetModel
	self.view.assets = self.ui.assets
	self.view.localization = self.ui.localization
	self.view:load()
	self.viewport:build()
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
	self.viewport:setSize(love.graphics.getDimensions())
	self.viewport:setTextScale(1 / self.ui.assets:getTextDpiScale())
	self.viewport:update(dt)
end

function GameView:resolutionUpdated()
	self.viewport:forEachChild(function(child)
		if child:hasTag("allowReload") then
			child:load()
		end
	end)
end

---@param event table
function GameView:receive(event)
	if not self.view then
		return
	end

	love.graphics.origin()
	self.view:receive(event)
	self.viewport:receive(event)
end
function GameView:draw()
	if not self.view then
		return
	end

	self.fadeTransition:drawBefore()
	self.viewport:draw()
	self.fadeTransition:drawAfter()
end

return GameView
