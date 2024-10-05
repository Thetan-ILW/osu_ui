local class = require("class")

local FadeTransition = require("ui.views.FadeTransition")

---@class osu.ui.GameView
---@operator call: osu.ui.GameView
---@field view osu.ui.ScreenView?
---@field ui osu.ui.UserInterface
local GameView = class()

---@param ui osu.ui.UserInterface
function GameView:new(ui)
	self.game = ui.game
	self.ui = ui
	self.fadeTransition = FadeTransition()
end

function GameView:load(view)
	self:forceSetView(view)
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
		[self.ui.playerStatsView] = "playerStatsView"
	}

	local overlay = self.ui.screenOverlayView
	self.ui:loadAssets(view_names[view])
	self.view = view
	self.view.assetModel = self.ui.assetModel
	self.view.assets = self.ui.assets
	self.view.notificationView = overlay.notificationView
	self.view.popupView = overlay.popupView
	self.view.cursor = overlay.cursor
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

	self.view:update(dt)
end

function GameView:resolutionUpdated()
	self.view:resolutionUpdated()
end

---@param event table
function GameView:receive(event)
	if not self.view then
		return
	end

	self.view:receive(event)
end

function GameView:draw()
	if not self.view then
		return
	end

	self.fadeTransition:drawBefore()
	self.view:draw()
	self.fadeTransition:drawAfter()
end

return GameView
