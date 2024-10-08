local ScreenView = require("osu_ui.views.ScreenView")
local ViewConfig = require("osu_ui.views.FirstTimeSetupView.ViewConfig")

local flux = require("flux")
local path_util = require("path_util")

local gucci = require("gucci_init")

---@class osu.ui.FirstTimeSetupView : osu.ui.ScreenView
---@operator call: osu.ui.FirstTimeSetupView
---@field state "selecting" | "transit_to_cache" | "cache" | "transit_to_end" | "end"
---@field otherGamesPaths {[string]: string}
local FirstTimeSetupView = ScreenView + {}

function FirstTimeSetupView:load()
	love.mouse.setVisible(false)

	self.otherGamesPaths = self.ui.otherGamesPaths

	for k, v in pairs(self.otherGamesPaths) do
		if k == "osu!" then
			self.osuFound = true
		elseif k == "Etterna" then
			self.etternaFound = true
		elseif k == "Quaver" then
			self.quaverFound = true
		end
	end

	self.state = "selecting"

	self.useOsuSongs = self.osuFound
	self.useEtternaSongs = self.etternaFound
	self.useQuaverSongs = self.quaverFound
	self.useOsuSkins = self.osuFound
	self.applyOsuSettings = self.osuFound

	self.viewConfig = ViewConfig(self)
end

function FirstTimeSetupView:setOsuSettings()
	local osu_path = self.otherGamesPaths["osu!"]
	local user = os.getenv("USERNAME")
	local osu_config = gucci.readOsuConfig(path_util.join(osu_path, ("osu!.%s.cfg"):format(user)))

	if not osu_config then
		print("Failed to import osu config")
		return
	end

	local configs = self.game.configModel.configs
	local settings = configs.settings
	local osu = configs.osu_ui

	osu.cursor.size = osu_config.osu.cursorSize

	local volume = settings.audio.volume
	volume.master = osu_config.volume.master
	volume.music = osu_config.volume.music
	volume.effect = osu_config.volume.effect

	settings.gameplay.speedType = "osu"
	self.game.speedModel:set(osu_config.gameplay.scrollSpeed)

	settings.graphics.dim.gameplay = osu_config.gameplay.dim

	for i = 1, 10 do
		self.game.noteSkinModel:setDefaultNoteSkin(("%ikey"):format(i), ("userdata/skins/%s/skin.ini"):format(osu_config.gameplay.skin))
	end
	osu.skin = osu_config.gameplay.skin
end

function FirstTimeSetupView:applySelected()
	if
		not self.useOsuSongs and
		not self.useEtternaSongs and
		not self.useQuaverSongs and
		not self.useOsuSongs and
		not self.applyOsuSettings
	then
		self:changeScreen("mainMenuView")
		return
	end

	self.currentSongsDirIndex = 0
	self.songDirs = {}

	if self.useOsuSongs then
		table.insert(self.songDirs, { name = "osu!", path = path_util.join(self.otherGamesPaths["osu!"], "Songs"), added = false })
	end
	if self.useEtternaSongs then
		table.insert(self.songDirs, { name = "Etterna", path = path_util.join(self.otherGamesPaths["Etterna"], "Songs"), added = false })
	end
	if self.useQuaverSongs then
		table.insert(self.songDirs, { name = "Quaver", path = path_util.join(self.otherGamesPaths["Quaver"], "Songs"), added = false })
	end

	if self.useOsuSkins then
		local path = path_util.join(self.otherGamesPaths["osu!"], "Skins")
		self.ui:mountOsuSkins(path)

		local osu = self.game.configModel.configs.osu_ui
		osu.gucci.osuSkinsPath = path
	end

	gucci.setDefaultSettings(self.game.configModel.configs)

	if self.applyOsuSettings then
		self:setOsuSettings()
	end

	self.state = "transit_to_cache"
	self.setupTransitProgress = 0
	self.setupTransitTween = flux.to(self, 0.4, { setupTransitProgress = 1 }):ease("cubicout")
end

function FirstTimeSetupView:start()
	self:changeScreen("mainMenuView")
end

function FirstTimeSetupView:update()
	local state = self.state

	if state == "transit_to_cache" then
		if self.setupTransitProgress == 1 then
			self.state = "cache"
		end
	elseif state == "cache" then
		self:cache()
	elseif state == "transit_to_end" then
		if self.endTransitProgress == 1 then
			self.state = "end"
			local osu = self.game.configModel.configs.osu_ui
			osu.gucci.installed = true
		end
	end
end

function FirstTimeSetupView:cache()
	if self.game.cacheModel.isProcessing then
		return
	end

	local i = self.currentSongsDirIndex
	if i ~= 0 then
		self.songDirs[i].added = true
	end

	self.currentSongsDirIndex = i + 1
	if self.currentSongsDirIndex > #self.songDirs then
		self.endTransitProgress = 0
		self.endTransitTween = flux.to(self, 0.4, { endTransitProgress = 1 }):ease("cubicout")
		self.state = "transit_to_end"
		return
	end

	i = self.currentSongsDirIndex


	local loc_name = self.songDirs[i].name
	local loc_path = self.songDirs[i].path

	local cache_model = self.game.cacheModel
	local location_manager = cache_model.locationManager
	local locations_repo = cache_model.locationsRepo

	---@type number?
	local location_id = nil
	local locations = location_manager.locations
	for _, v in ipairs(locations) do
		if v.path == loc_path then
			location_id = v.id
			break
		end
	end

	if location_id then
		self.game.selectController:updateCacheLocation(location_id)
		return
	end

	local location = locations_repo:insertLocation({
		name = loc_name,
		is_relative = false,
		is_internal = false,
	})
	location_manager:selectLocations()
	location_manager:selectLocation(location.id)
	location_manager:updateLocationPath(loc_path)
	self.game.selectController:updateCacheLocation(location.id)
end

function FirstTimeSetupView:resolutionUpdated()
	self.viewConfig:createUI()
end

function FirstTimeSetupView:draw()
	self.viewConfig:draw()
	self.ui.screenOverlayView:draw()
end

return FirstTimeSetupView
