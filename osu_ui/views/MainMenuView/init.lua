local ScreenView = require("osu_ui.views.ScreenView")

local flux = require("flux")
local actions = require("osu_ui.actions")
local ViewConfig = require("osu_ui.views.MainMenuView.ViewConfig")
local InputMap = require("osu_ui.views.MainMenuView.InputMap")

local SettingsView = require("osu_ui.views.SettingsView")

---@class osu.ui.MainMenuView : osu.ui.ScreenView
---@operator call: osu.ui.MainMenuView
---@field state "intro" | "normal" | "fade_out" | "fade_in" | "afk" | "outro"
---@field lastUserActionTime number
---@field tween table?
---@field introTween table?
---@field outroTween table?
local MainMenuView = ScreenView + {}

local show_intro = true

function MainMenuView:load()
	self.selectModel = self.game.selectModel
	self.prevChartViewId = -1
	self.game.selectController:load()

	self.afkPercent = 1
	self.outroPercent = 0
	self.introPercent = 0
	self.state = show_intro and "intro" or "normal"

	if self.game.configModel.configs.osu_ui.mainMenu.disableIntro then
		if show_intro then
			show_intro = false
			self.state = "normal"
		end
	end

	self.inputMap = InputMap(self)
	self.settingsView = SettingsView(self.assets, self.game, self.ui)
	self.viewConfig = ViewConfig(self, self.assets)

	self.lastUserActionTime = love.timer.getTime()
	love.mouse.setVisible(false)
	actions.enable()


	if show_intro then
		local snd = self.assets.sounds
		self.cursor.alpha = 0
		snd.welcome:play()
		snd.welcomePiano:play()
		show_intro = false
	end

	self.introTween = flux.to(self, 2, { introPercent = 1 }):ease("linear")
end

function MainMenuView:beginUnload()
	self.game.selectController:beginUnload()
end

function MainMenuView:unload()
	self.game.selectController:unload()
end

function MainMenuView:setMasterVolume(volume)
	local audio = self.game.previewModel.audio

	if not audio then
		return
	end

	local configs = self.game.configModel.configs
	local settings = configs.settings
	local a = settings.audio
	local v = a.volume

	audio:setVolume(v.master * v.music * (1 - volume))
end

---@param event string?
function MainMenuView:processState(event)
	local state = self.state

	if state == "normal" then
		if love.timer.getTime() > self.lastUserActionTime + 10 then
			self.state = "fade_out"
			if self.tween then
				self.tween:stop()
			end
			self.tween = flux.to(self, 1, { afkPercent = 0 }):ease("quadout")
			self.viewConfig:processLogoState(self, "hide")
			self.settingsView:processState("hide")
		end
	elseif state == "fade_out" or state == "afk" then
		if event == "user_returned" then
			self.state = "fade_in"
			if self.tween then
				self.tween:stop()
			end
			self.tween = flux.to(self, 0.4, { afkPercent = 1 }):ease("quadout")
		end
		if self.afkPercent == 0 then
			self.state = "afk"
		end
	elseif state == "fade_in" then
		if self.afkPercent == 1 then
			self.state = "normal"
		end
	elseif state == "intro" then
		if self.introPercent == 1 then
			self.state = "normal"
		end

		local animation = math.pow(self.introPercent, 16)
		self.afkPercent = animation
		self.viewConfig.hasFocus = false
	elseif state == "outro" then
		if self.outroPercent == 1 then
			love.event.quit()
		end

		self.viewConfig.hasFocus = false
		self:setMasterVolume(self.outroPercent)
	end
end

---@param dt number
function MainMenuView:update(dt)
	ScreenView.update(self, dt)

	local chartview = self.selectModel.chartview

	if chartview then
		local chartview_id = chartview.id

		if chartview_id ~= self.prevChartViewId then
			self:notechartChanged()
			self.prevChartViewId = chartview_id
		end
	end

	self.settingsView.modalActive = self.modal == nil

	if self.changingScreen then
		self.settingsView:processState("hide")
	end

	self.settingsView:update()

	if self.state ~= "intro" then
		self.game.selectController:update()
	end

	self.viewConfig.hasFocus = (self.modal == nil) and not self.settingsView:isFocused() and not self.changingScreen
	self:processState()
	self.cursor.alpha = self.afkPercent
end

function MainMenuView:edit()
	if not self.game.selectModel:notechartExists() then
		return
	end

	self:changeScreen("editorView")
end

function MainMenuView:toggleSettings()
	self.settingsView:processState("toggle")
end

function MainMenuView:closeGame()
	if self.tween then
		self.tween:stop()
	end

	self.state = "outro"
	self.settingsView:processState("hide")
	self.outroTween = flux.to(self, 1.2, { outroPercent = 1 }):ease("quadout")
	self.tween = flux.to(self, 0.4, { afkPercent = 0 }):ease("quadout")
	self.assets.sounds.goodbye:play()
end

function MainMenuView:notechartChanged()
	self.viewConfig:updateInfo(self)
end

function MainMenuView:sendQuitSignal()
	if self.modal then
		self.modal:quit()
		return
	end
	self.settingsView:processState("hide")
end

function MainMenuView:resolutionUpdated()
	self.viewConfig:resolutionUpdated()
	self.settingsView:resolutionUpdated()

	if self.modal then
		self.modal.viewConfig:resolutionUpdated()
	end
end

function MainMenuView:receive(event)
	if event.name == "mousemoved" then
		self.lastUserActionTime = love.timer.getTime()
		self:processState("user_returned")
	end

	if event.name == "keypressed" then
		self.lastUserActionTime = love.timer.getTime()
		self:processState("user_returned")
		if self.inputMap:call("view") then
			return
		end
	end

	if event.name == "mousepressed" then
		self.lastUserActionTime = love.timer.getTime()
		self:processState("user_returned")
	end

	self.settingsView:receive(event)
end

local gfx = love.graphics

function MainMenuView:draw()
	self.viewConfig:draw(self)
	self.settingsView:draw()
	self:drawModal()
	self.ui.screenOverlayView:draw()

	if self.state == "outro" then
		gfx.origin()
		gfx.setColor(0, 0, 0, self.outroPercent)
		gfx.rectangle("fill", 0, 0, gfx.getWidth(), gfx.getHeight())
	end
end

return MainMenuView
