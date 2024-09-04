local ScreenView = require("osu_ui.views.ScreenView")

local ui = require("osu_ui.ui")

local OsuLayout = require("osu_ui.views.OsuLayout")
local ViewConfig = require("osu_ui.views.SelectView.ViewConfig")
local BackgroundView = require("sphere.views.BackgroundView")
local UiLockView = require("osu_ui.views.UiLockView")
local SettingsView = require("osu_ui.views.SettingsView")

local ChartPreviewView = require("sphere.views.SelectView.ChartPreviewView")

local InputMap = require("osu_ui.views.SelectView.InputMap")

---@class osu.ui.SelectView: osu.ui.ScreenView
---@operator call: osu.ui.SelectView
---@field prevChartViewId number
---@field selectModel sphere.SelectModel
local SelectView = ScreenView + {}

local ui_lock = false

function SelectView:load()
	self.game.selectController:load(self)

	self.chartPreviewView = ChartPreviewView(self.game, self.ui)
	self.chartPreviewView:load()

	self.selectModel = self.game.selectModel

	self.inputMap = InputMap(self, self.actionModel)
	self.actionModel.enable()

	--if self.assets.selectViewConfig then
	--self.viewConfig = self.assets.selectViewConfig()(self, self.assets)
	--else
	self.viewConfig = ViewConfig(self, self.assets)
	self.settingsView = SettingsView(self.assets, self.game, self.ui)
	--end

	self.uiLockViewConfig = UiLockView(self.game, self.assets)

	BackgroundView.game = self.game

	love.mouse.setVisible(false)
	self.gameView:setCursorVisible(true)

	self:notechartChanged()
end

function SelectView:beginUnload()
	self.game.selectController:beginUnload()
end

function SelectView:unload()
	self.game.selectController:unload()
	self.chartPreviewView:unload()
end

---@param dt number
function SelectView:update(dt)
	ScreenView.update(self, dt)

	ui_lock = self.game.cacheModel.isProcessing

	local chartview_id = self.selectModel.chartview.id

	if chartview_id ~= self.prevChartViewId then
		self:notechartChanged()
		self.prevChartViewId = chartview_id
	end

	self.settingsView.modalActive = self.modal == nil

	if self.changingScreen then
		self.settingsView:processState("hide")
	end

	self.settingsView:update()

	self.assets:updateVolume(self.game.configModel)

	self.viewConfig:setFocus((self.modal == nil) and not self.settingsView:isFocused() and not self.changingScreen)
	self.game.selectController:update()
	self.chartPreviewView:update(dt)
end

function SelectView:notechartChanged()
	self.viewConfig:updateInfo(self)
end

function SelectView:play()
	if not self.game.selectModel:notechartExists() then
		return
	end

	self.assets.sounds.menuHit:stop()
	self.assets.sounds.menuHit:play()

	local multiplayer_model = self.game.multiplayerModel
	if multiplayer_model.room and not multiplayer_model.isPlaying then
		multiplayer_model:pushNotechart()
		self:changeScreen("multiplayerView")
		return
	end

	self:changeScreen("gameplayView")
end

function SelectView:edit()
	if not self.game.selectModel:notechartExists() then
		return
	end

	self:changeScreen("editorView")
end

function SelectView:result()
	if self.game.selectModel:isPlayed() then
		self:changeScreen("resultView")
	end
end

function SelectView:toggleSettings()
	self.settingsView:processState("toggle")
end

function SelectView:changeTimeRate(delta)
	if self.modalActive then
		return
	end

	local configs = self.game.configModel.configs
	local g = configs.settings.gameplay

	local time_rate_model = self.game.timeRateModel

	---@type table
	local range = time_rate_model.range[g.rate_type]

	---@type number
	local new_rate = time_rate_model:get() + range[3] * delta

	if new_rate ~= time_rate_model:get() then
		self.game.modifierSelectModel:change()
		time_rate_model:set(new_rate)
		self.viewConfig:updateInfo(self)
	end
end

local selected_group = "charts"
local previous_collections_group = "locations"

---@param name "charts" | "locations" | "directories" | "last_visited_locations"
function SelectView:changeGroup(name)
	if name == "charts" then
		self.game.selectModel:noDebouncePullNoteChartSet()
	elseif name == "locations" then
		if previous_collections_group ~= "locations" then
			self.game.selectModel.collectionLibrary:load(true)
		end

		self.viewConfig.collectionListView:reloadItems()
		previous_collections_group = name
	elseif name == "directories" then
		if previous_collections_group ~= "directories" then
			self.game.selectModel.collectionLibrary:load(false)
		end

		self.viewConfig.collectionListView:reloadItems()
		previous_collections_group = name
	elseif name == "last_visited_locations" then
		name = previous_collections_group
	end

	selected_group = name
end

function SelectView:select()
	if selected_group == "charts" then
		self:play()
		return
	end

	self:changeGroup("charts")
end

function SelectView:updateSearch(text)
	local config = self.game.configModel.configs.select
	local selectModel = self.game.selectModel
	config.filterString = text
	selectModel:debouncePullNoteChartSet()
end

function SelectView:receive(event)
	self.game.selectController:receive(event)
	self.chartPreviewView:receive(event)

	if event.name == "keypressed" then
		if self.inputMap:call("music") then
			return
		end

		if ui_lock then
			return
		end

		if self.inputMap:call("view") then
			return
		end

		if self.inputMap:call("selectModals") then
			return
		end

		if self.modal then
			return false
		end

		self.inputMap:call("select")
	end

	self.settingsView:receive(event)
end

function SelectView:quit()
	if self.settingsView.state ~= "hidden" then
		self.settingsView:processState("hide")
		return
	end
	self:changeScreen("mainMenuView")
end

local gfx = love.graphics

function SelectView:resolutionUpdated()
	self.viewConfig:resolutionUpdated(self)

	if self.modal then
		self.modal.viewConfig:resolutionUpdated()
	end
end

function SelectView:draw()
	OsuLayout:draw()
	local w, h = OsuLayout:move("base")

	BackgroundView:draw(w, h, 0.13, 0.01)

	if ui_lock then
		self.uiLockViewConfig:draw()
		return
	end

	self.viewConfig:draw(self)
	self.settingsView:draw()

	self:drawModal()
end

return SelectView
