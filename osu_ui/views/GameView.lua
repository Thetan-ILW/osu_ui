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
		game = self.game,
		assets = self.ui.assets,
		localization = self.ui.localization,
		depth = 0.2,
	}))

	self:setView(view)
end

---@param view osu.ui.ScreenView
function GameView:setView(view)
	local prev_view_name = ""
	if self.view then
		prev_view_name = self.view.name
		self.view:unload()
	end

	local view_names = {
		[self.ui.selectView] = "selectView",
		[self.ui.gameplayView] = "gameplayView",
		[self.ui.resultView] = "resultView",
	}

	self.ui:loadAssets(view_names[view])

	view.ui = self.ui
	view.gameView = self
	view.assetModel = self.ui.assetModel
	view.assets = self.ui.assets
	view.localization = self.ui.localization
	view.previousViewName = prev_view_name
	view:load()
	self.view = view
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

	self.viewport:draw()
end

return GameView
