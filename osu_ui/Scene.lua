local Component = require("ui.Component")

local CursorView = require("osu_ui.views.CursorView")
local ParallaxBackground = require("osu_ui.ui.ParallaxBackground")
local Chat = require("osu_ui.views.Chat")
local Options = require("osu_ui.views.Options")
local Tooltip = require("osu_ui.views.Tooltip")
local Notification = require("osu_ui.views.NotificationView")
local FpsDisplay = require("osu_ui.views.FpsDisplay")

local FontManager = require("ui.FontManager")
local OsuAssets = require("osu_ui.OsuAssets")
local Localization = require("osu_ui.models.AssetModel.Localization")

local MainMenu = require("osu_ui.views.MainMenu")
local LobbyList = require("osu_ui.views.LobbyList")
local Select = require("osu_ui.views.SelectView")
local Gameplay = require("osu_ui.views.Gameplay")
local Result = require("osu_ui.views.ResultView")

local ModifiersModal = require("osu_ui.views.modals.Modifiers")
local LocationsModal = require("osu_ui.views.modals.Locations")
local BeatmapOptionsModal = require("osu_ui.views.modals.BeatmapOptions")
local FiltersModal = require("osu_ui.views.modals.Filters")
local InputsModal = require("osu_ui.views.modals.Inputs")

local MusicFft = require("osu_ui.MusicFft")

local flux = require("flux")
local path_util = require("path_util")
local math_util = require("math_util")

---@alias osu.ui.SceneParams { game: sphere.GameController, ui: osu.ui.UserInterface }

---@class osu.ui.Scene: ui.Component
---@overload fun(params: osu.ui.SceneParams): osu.ui.Scene
---@field game sphere.GameController
---@field ui osu.ui.UserInterface
---@field fontManager ui.FontManager
---@field assets osu.ui.OsuAssets
---@field screens {[string]: osu.ui.Screen}
local Scene = Component + {}

function Scene:new(params)
	Component.new(self, params)

	local fonts = {
		["Regular"] = "osu_ui/assets/ui_font/Aller/Aller_Rg.ttf",
		["Light"] = "osu_ui/assets/ui_font/Aller/Aller_Lt.ttf",
		["Bold"] = "osu_ui/assets/ui_font/Aller/Aller_Bd.ttf",
		["Awesome"] = "osu_ui/assets/ui_font/FontAwesome/FontAwesome.ttf",
		["MonoRegular"] = "osu_ui/assets/ui_font/SpaceMono/SpaceMono-Regular.ttf",
		["MonoBold"] = "osu_ui/assets/ui_font/SpaceMono/SpaceMono-Bold.ttf",
		["QuicksandSemiBold"] = "osu_ui/assets/ui_font/Quicksand/Quicksand-SemiBold.ttf"
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

	self.assets = OsuAssets(self.ui.assetModel)
	self.localization = Localization(path_util.join(self.ui.mountPath, "osu_ui/localization"), "en.txt")
	self.fontManager = FontManager(768, fonts, fallbacks)
end

function Scene:load()
	self:clearTree()

	self.defaultScreens = {
		mainMenu = MainMenu({ z = 0.1 }),
		lobbyList = LobbyList({ z = 0.08, alpha = 0 }),
		select = Select({ z = 0.09, alpha = 0 }),
		gameplay = Gameplay({ z = 0.07, alpha = 0 }),
		result = Result({ z = 0.08, alpha = 0 }),
	}

	self.screens = {}

	self.modals = {
		modifiers = ModifiersModal({ z = 0.5 }),
		locations = LocationsModal({ z = 0.5 }),
		beatmapOptions = BeatmapOptionsModal({ z = 0.5 }),
		filters = FiltersModal({ z = 0.5 }),
		inputsModal = InputsModal({ z = 0.5 })
	}

	self.viewport = self:getViewport()
	self.width = self.viewport.scaledWidth
	self.height = self.viewport.scaledHeight
	self:getViewport():listenForResize(self)

	self.localization:load()
	self:loadAssets()

	self.fontManager:setVieportHeight(self.viewport.height)

	local music_fft = self:addChild("musicFft", MusicFft())
	---@cast music_fft osu.ui.MusicFft
	self.musicFft = music_fft

	local cursor = self:addChild("cursor", CursorView({
		z = 0.98
	}))

	local notification = self:addChild("notification", Notification({z = 0.9})) ---@cast notification osu.ui.NotificationView
	self.notification = notification

	local tooltip = self:addChild("tooltip", Tooltip({
		z = 0.981
	})) ---@cast tooltip osu.ui.TooltipView
	self.tooltip = tooltip

	local options = self:addChild("options", Options({
		game = self.game,
		ui = self.ui,
		localization = self.localization,
		alpha = 0,
		z = 0.25,
	}))
	local chat = self:addChild("chat", Chat({
		chatModel = self.ui.chatModel,
		z = 0.2,
	}))
	local background = self:addChild("background", ParallaxBackground({
		mode = "background_model",
		backgroundModel = self.game.backgroundModel,
		z = 0,
	}))
	local fps_display = self:addChild("fpsDisplay", FpsDisplay({
		z = 0.9,
	}))

	---@cast cursor osu.ui.CursorView
	---@cast options osu.ui.OptionsView
	---@cast chat osu.ui.ChatView
	---@cast background osu.ui.ParallaxBackground
	---@cast fps_display osu.ui.FpsDisplayView
	self.fpsDisplay = fps_display
	self.cursor = cursor
	self.options = options
	self.chat = chat
	self.background = background

	self.currentScreenId = ""
	self.previousScreenId = ""
	self:preloadScreen("lobbyList")
	self:transitInScreen("mainMenu")

	flux.to(self.viewport, 0.3, { alpha = 1 }):ease("cubicout")
end

function Scene:reloadUI()
	flux.to(self.viewport, 0.3, { alpha = 0 }):ease("cubicout"):oncomplete(function ()
		self:load()
	end)
end

function Scene:update()
	self.assets:updateVolume(self.game.configModel.configs)
end

function Scene:loadAssets()
	local configs = self.game.configModel.configs
	local osu = configs.osu_ui

	---@type string
	local skin_path = ("userdata/skins/%s"):format(osu.skin:trim())

	for k, v in pairs(self.screens) do
		if v.parent then
			v:kill()
		end
	end

	if self.assets.directory ~= skin_path then
		self.assets:setPaths(skin_path, "osu_ui/assets")
		self.assets:load()
	end

	self.assets:updateVolume(self.game.configModel.configs)

	self.localization:loadFile(self.ui.assetModel:getLocalizationFileName(osu.language))

	local custom_views = self.assets.customViews
	for k, v in pairs(self.defaultScreens) do
		self.screens[k] = custom_views[k] and custom_views[k]({ z = 0.05 }) or v
	end
end

function Scene:addScreen(name)
	local screen = self.screens[name]
	if not screen then
		self:assert(false, ("No screen with name: %s"):format(name))
	end
	return self:addChild(name, screen)
end

function Scene:preloadScreen(name)
	if self:getChild(name) then
		return
	end
	self:addScreen(name).disabled = true
end

---@param screen_name string
function Scene:transitInScreen(screen_name)
	local screen = self:getChild(screen_name)
	if not screen then
		screen = self:addScreen(screen_name)
	end
	self.previousScreenId = self.currentScreenId
	self.currentScreenId = screen_name
	screen:transitIn()
	love.mouse.setVisible(false)
end

---@param name string
function Scene:openModal(name)
	local modal = self.modals[name] ---@cast modal osu.ui.Modal

	if self:getChild(name) then
		modal:open()
		return
	end

	self:addChild(name, modal)
	modal:open()
end

---@param time number?
---@param background_dim number?
---@param on_complete function?
function Scene:hideOverlay(time, background_dim, on_complete)
	time = time or 0.4
	background_dim = background_dim or 0.3
	self:receive({ name = "loseFocus" })
	self.options:fade(0)
	self.chat:fade(0)
	flux.to(self.cursor, time, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		if on_complete then
			on_complete()
		end
	end)
	flux.to(self.background, time * 0.6, { dim = background_dim, parallax = 0 }):ease("quadout")
end

---@param time number?
---@param background_dim number?
function Scene:showOverlay(time, background_dim)
	time = time or 0.4
	background_dim = background_dim or 0.3
	flux.to(self.cursor, time, { alpha = 1 }):ease("quadin")
	flux.to(self.background, time * 0.6, { dim = background_dim, parallax = 0.01 }):ease("quadin")
end

function Scene:reload()
	self.width = self.viewport.scaledWidth
	self.height = self.viewport.scaledHeight
	self.fontManager:setVieportHeight(self.viewport.height)
end

function Scene:makeScreenshot()
	local canvas = self:getViewport().canvas
	local image = canvas:newImageData()
	local path = ("userdata/screenshots/screenshot %s.jpg"):format(os.date("%d.%m.%Y %H-%M-%S", os.time()))
	image:encode("png", path)
	image:release()

	local configs = self.ui.selectApi:getConfigs()
	if not configs.osu_ui.copyScreenshotToClipboard then
		return
	end

	local full_path = path_util.join(love.filesystem.getSource(), path)

	-- https://wiki.libsdl.org/SDL3/SDL_SetClipboardData
	if love.system.getOS() == "Windows" then
		os.execute(([[powershell -command "Set-Clipboard -Path '%s'"]]):format(full_path))
	elseif love.system.getOS() == "Linux" then
		os.execute(([[wl-copy < "%s"]]):format(full_path))
	end
end

function Scene:scrollVolume(delta)
	local configs = self.ui.selectApi:getConfigs()
	local v = configs.settings.audio.volume
	v.master = math_util.clamp(math_util.round(v.master + delta * 0.05, 0.05), 0, 1)
	self.notification:show(self.localization.text.General_Volume:format(("%i%%"):format(v.master * 100)))
end

---@param event table
function Scene:keyPressed(event)
	local key = event[2]
	if key == "f12" and not event[3] then
		self:makeScreenshot()
	end
end


function Scene:wheelUp()
	if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
		self:scrollVolume(1)
		return true
	end
end

function Scene:wheelDown()
	if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
		self:scrollVolume(-1)
		return true
	end
end

return Scene
