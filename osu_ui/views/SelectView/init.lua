local ScreenView = require("osu_ui.views.ScreenView")

local actions = require("osu_ui.actions")
local ui = require("osu_ui.ui")

local OsuLayout = require("osu_ui.views.OsuLayout")
local ViewConfig = require("osu_ui.views.SelectView.ViewConfig")
local GaussianBlurView = require("sphere.views.GaussianBlurView")
local BackgroundView = require("sphere.views.BackgroundView")
local UiLockView = require("osu_ui.views.UiLockView")
local SettingsView = require("osu_ui.views.SettingsView")

local ChartPreviewView = require("sphere.views.SelectView.ChartPreviewView")
local Lists = require("osu_ui.views.SelectView.Lists")

local InputMap = require("osu_ui.views.SelectView.InputMap")

---@class osu.ui.SelectView: osu.ui.ScreenView
---@operator call: osu.ui.SelectView
---@field prevChartViewId number
---@field selectModel sphere.SelectModel
---@field configs sphere.Configs
---@field viewConfigFocus boolean
local SelectView = ScreenView + {}

local ui_lock = false
local dim = 0
local blur = 0

function SelectView:load()
	self.chartPreviewView = ChartPreviewView(self.game, self.ui)
	self.chartPreviewView:load()

	self.selectModel = self.game.selectModel
	self.configs = self.game.configModel.configs

	self.search = self.configs.select.filterString
	self.lists = Lists(self)

	self.inputMap = InputMap(self)

	self.viewConfig = ViewConfig(self, self.assets)
	self.settingsView = SettingsView(self.assets, self.game, self.ui)

	self.uiLockViewConfig = UiLockView(self.game, self.assets)

	BackgroundView.game = self.game

	love.mouse.setVisible(false)
	self.cursor.alpha = 1

	self:notechartChanged()
	actions.enable()
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

	local chartview_i = self.selectModel.chartview_index
	local chartview_set_i = self.selectModel.chartview_set_index

	if chartview_i ~= self.prevChartViewIndex or chartview_set_i ~= self.prevChartViewSetIndex then
		self.prevChartViewIndex = chartview_i
		self.prevChartViewSetIndex = chartview_set_i
		self:notechartChanged(true)
	end

	self.settingsView.modalActive = self.modal == nil

	if self.changingScreen then
		self.settingsView:processState("hide")
	end

	self.settingsView:update()

	self.viewConfigFocus = (self.modal == nil) and not self.settingsView:isFocused() and not self.changingScreen
	self:updateSearch()

	local graphics = self.configs.settings.graphics
	dim = graphics.dim.select
	blur = graphics.blur.select

	self.assets:updateVolume(self.game.configModel)

	self.lists:update(dt)
	self.viewConfig:setFocus(self.viewConfigFocus)
	self.game.selectController:update()
	self.chartPreviewView:update(dt)
end

function SelectView:notechartChanged()
	self.viewConfig:updateInfo(self, true)
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

function SelectView:select()
	if self.lists.showing == "charts" then
		self:play()
		return
	end

	self.lists:show("charts")
end

function SelectView:updateSearch()
	local vim_motions = actions.isVimMode()
	local insert_mode = actions.isInsertMode()

	local config = self.configs.select
	local selectModel = self.game.selectModel

	local changed = false
	if (not vim_motions or insert_mode) and self.viewConfigFocus then
		changed, self.search = actions.textInput(config.filterString)
	end

	if actions.isEnabled() then
		if changed then
			config.filterString = self.search
			selectModel:debouncePullNoteChartSet()
			return
		end

		local delete_all = actions.consumeAction("deleteLine")

		if delete_all then
			self.search = ""
			config.filterString = ""
			selectModel:debouncePullNoteChartSet()
		end
	end
end

local events = {
	keypressed = function(self, event)
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
			return
		end

		self.inputMap:call("select")
	end,
	wheelmoved = function(self, event)
		if not actions.isModKeyDown() then
			self.lists:mouseScroll(-event[2])
		end
	end,
	directorydropped = function(self, event)
		self:openModal("osu_ui.views.modals.LocationImport", event[1])
	end
}

function SelectView:receive(event)
	self.game.selectController:receive(event)

	local f = events[event.name]
	if f then
		f(self, event)
	end

	self.chartPreviewView:receive(event)
	self.settingsView:receive(event)
end

---@param back_button_click boolean?
function SelectView:quit(back_button_click)
	if self.settingsView.state ~= "hidden" then
		self.settingsView:processState("hide")
		return
	end

	if self.search ~= "" then
		local config = self.game.configModel.configs.select
		self.search = ""
		config.filterString = ""
		self.game.selectModel:debouncePullNoteChartSet()

		if not back_button_click then
			return
		end
	end

	if not back_button_click then
		ui.playSound(self.assets.sounds.menuBack)
	end

	self:changeScreen("mainMenuView")
end

function SelectView:resolutionUpdated()
	self.viewConfig:resolutionUpdated(self)
	self.settingsView:resolutionUpdated()

	if self.modal then
		self.modal.viewConfig:resolutionUpdated()
	end
end

function SelectView:draw()
	OsuLayout:draw()
	local w, h = OsuLayout:move("base")

	GaussianBlurView:draw(blur)
	BackgroundView:draw(w, h, dim, 0.01)
	GaussianBlurView:draw(blur)

	if ui_lock then
		self.uiLockViewConfig:draw()
		return
	end

	self.viewConfig:draw(self)
	self.settingsView:draw()

	self:drawModal()
end

return SelectView
