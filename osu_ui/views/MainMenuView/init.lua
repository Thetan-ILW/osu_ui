local ScreenView = require("osu_ui.views.ScreenView")

local View = require("osu_ui.views.MainMenuView.View")

local flux = require("flux")

---@class osu.ui.MainMenuView : osu.ui.ScreenView
---@operator call: osu.ui.MainMenuView
---@field state "intro" | "normal" | "fade_out" | "fade_in" | "afk" | "outro"
---@field lastUserActionTime number
---@field tween table?
---@field introTween table?
---@field outroTween table?
local MainMenuView = ScreenView + {}

local loaded = false

function MainMenuView:load()
	local scene = self.gameView.scene

	if not loaded then
		self.game.selectController:load()
		self.selectModel = self.game.selectModel
		local view = scene:addChild("mainMenuView", View({ z = 0.12, mainMenu = self })) ---@cast view osu.ui.MainMenuContainer
		self.view = view
		self.view:introSequence()
		loaded = true
	else
		self.view:transitIn()
		self.prevChartViewId = -1
	end

	--[[
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

	self.lastUserActionTime = love.timer.getTime()

	if show_intro then
		local snd = self.assets.sounds
		self.cursor.alpha = 0
		snd.welcome:play()
		snd.welcomePiano:play()
		show_intro = false
	end

	self.introTween = flux.to(self, 2, { introPercent = 1 }):ease("linear")
	]]
end

function MainMenuView:toSongSelect()
	self:changeScreen("selectView")
end

function MainMenuView:edit()
	if not self.game.selectModel:notechartExists() then
		return
	end

	self.game.selectController:beginUnload()
	self.game.selectController:unload()
	self:changeScreen("editorView")
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

--[[
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
]]

---@param dt number
function MainMenuView:update(dt)
	local chartview = self.selectModel.chartview

	if chartview then
		local chartview_id = chartview.id

		if chartview_id ~= self.prevChartViewId then
			self:notechartChanged()
			self.prevChartViewId = chartview_id
		end
	end

	if not self.view.locked then
		self.game.selectController:update()
	end
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
end

function MainMenuView:sendQuitSignal()
	--self.settingsView:processState("hide")
end

--[[
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

	--self.settingsView:receive(event)
end]]

return MainMenuView
