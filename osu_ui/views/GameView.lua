local class = require("class")
local path_util = require("path_util")
local TermEmuView = require("osu_ui.views.TermEmuView")

local CursorView = require("osu_ui.views.CursorView")
--local NotificationView = require("osu_ui.views.NotificationView")
local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")
local Chat = require("osu_ui.views.Chat")

local Component = require("ui.Component")
local Viewport = require("ui.Viewport")
local FontManager = require("ui.FontManager")

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
end

function GameView:load(view)
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

	self.viewport = Viewport({
		targetHeight = 768,
		shared = {
			assets = self.ui.assets,
			fontManager = FontManager(768, fonts, fallbacks)
		}
	})
	self.viewport:load()

	self.viewport:addChild("cursor", CursorView({
		assets = self.ui.assets,
		osuConfig = self.game.configModel.configs.osu_ui,
		z = 0.98
	}))

	self.scene = self.viewport:addChild("scene", Component({
		width = self.viewport.scaledWidth,
		height = self.viewport.scaledHeight,
		load = function(this)
			this:getViewport():listenForResize(this)
		end,
		reload = function(component)
			component.width = self.viewport.scaledWidth
			component.height = self.viewport.scaledHeight
		end,
		keyPressed = function(this, event)
			local key = event[2]
			if key == "f12" and not event[3] then
				self.game.app.screenshotModel:capture(false)
			end
		end
	}))
	self.scene:addChild("options", Options({
		game = self.game,
		assets = self.ui.assets,
		localization = self.ui.localization,
		alpha = 0,
		z = 0.2,
	}))
	self.scene:addChild("chat", Chat({
		chatModel = self.ui.chatModel,
		z = 0.3,
	}))
	self.scene:addChild("background", ParallaxBackground({
		mode = "background_model",
		backgroundModel = self.game.backgroundModel,
		z = 0,
	}))

	--[[
	self.scene:addChild("terminalEmulator", TermEmuView({
		x = self.scene.width / 2 - 500 / 2, y = self.scene.height / 2 - 400 / 2,
		width = 500, height = 400,
		shell = self.ui.shell,
		z = 1,
	}))]]

	--[[
	self.viewport:addChild("notifications", NotificationView({
		assets = self.ui.assets,
		blockMouseFocus = false,
		depth = 0.97,
	}))
	]]

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
	if not self.view then
		return
	end

	self.view:update(dt)
	--self.viewport:setTextScale(1 / self.ui.assets:getTextDpiScale())
	self.viewport:updateTree(dt)
end

---@param event table
function GameView:receive(event)
	if not self.view then
		return
	end

	self.view:receive(event)

	if event.name == "framestarted" then
		return
	end

	love.graphics.origin()
	self.viewport:receive(event)
end

function GameView:draw()
	if not self.view then
		return
	end

	self.viewport:drawTree()
end

return GameView
