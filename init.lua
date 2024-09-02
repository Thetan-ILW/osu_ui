local class = require("class")

local NotificationModel = require("ui.models.NotificationModel")
local BackgroundModel = require("ui.models.BackgroundModel")
local PreviewModel = require("ui.models.PreviewModel")
local ChartPreviewModel = require("ui.models.ChartPreviewModel")

local ActionModel = require("osu_ui.models.ActionModel")
local AssetModel = require("osu_ui.models.AssetModel")

local GameView = require("osu_ui.views.GameView")
local SelectView = require("osu_ui.views.SelectView")
local GameplayView = require("osu_ui.views.GameplayView")
local ResultView = require("osu_ui.views.ResultView")
local MainMenuView = require("osu_ui.views.MainMenuView")
local EditorView = require("ui.views.EditorView")

---@class osu.ui.UserInterface
---@operator call: osu.ui.UserInterface
local UserInterface = class()

---@param persistence sphere.Persistence
---@param game sphere.GameController
function UserInterface:new(persistence, game)
	self.backgroundModel = BackgroundModel()
	self.notificationModel = NotificationModel()
	self.previewModel = PreviewModel(persistence.configModel)
	self.chartPreviewModel = ChartPreviewModel(persistence.configModel, self.previewModel, game)

	self.actionModel = ActionModel(persistence.configModel)
	self.assetModel = AssetModel(persistence.configModel)

	self.gameView = GameView(game, self)
	self.mainMenuView = MainMenuView(game)
	self.selectView = SelectView(game)
	self.resultView = ResultView(game)
	self.gameplayView = GameplayView(game)
	self.editorView = EditorView(game)

	self.persistence = persistence
	self.game = game
end

function UserInterface:load()
	self.backgroundModel:load()
	self.previewModel:load()
	self.actionModel:load()
	self.gameView:load()
end

function UserInterface:unload()
	self.previewModel:stop()
	self.gameView:unload()
end

---@param dt number
function UserInterface:update(dt)
	self.backgroundModel:update()
	self.chartPreviewModel:update()
	self.gameView:update(dt)
end

function UserInterface:draw()
	self.gameView:draw()
end

---@param event table
function UserInterface:receive(event)
	self.gameView:receive(event)
end

return UserInterface
