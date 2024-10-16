local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")
local utf8validate = require("utf8validate")

local function formatSkinName(v)
	if not v then
		return "??"
	end
	local len = v:len()
	if len > 38 then
		return utf8validate(v:sub(1, 38), ".") .. ".."
	end

	return v
end

local vsyncNames = {
	[1] = "enabled",
	[0] = "disabled",
	[-1] = "adaptive",
}

---@param assets osu.ui.OsuAssets
---@param view osu.ui.SettingsView
---@return osu.SettingsView.GroupContainer?
return function(assets, view)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local configs = view.game.configModel.configs
	local settings = configs.settings
	local g = settings.graphics
	local gp = settings.gameplay
	local m = settings.miscellaneous
	local flags = g.mode.flags
	local osu = configs.osu_ui

	local c = GroupContainer(text.graphics, assets, font, assets.images.graphicsTab)

	Elements.assets = assets
	Elements.currentContainer = c
	local checkbox = Elements.checkbox
	local combo = Elements.combo
	local slider = Elements.slider

	--------------- RENDERER ---------------
	c:createGroup("renderer", text.renderer)
	Elements.currentGroup = "renderer"

	combo("MSAA:", 0, text.msaaTip, function()
		return flags.msaa, { 0, 1, 2, 4 }
	end, function(v)
		flags.msaa = v
	end)

	combo(text.vsyncType, 1, nil, function()
		return flags.vsync, { 1, 0, -1 }
	end, function(v)
		g.vsyncOnSelect = not (v == 0)
		flags.vsync = v
	end, function(v)
		return text[vsyncNames[v]] or ""
	end)

	local unlimited_fps = g.fps == 0

	if not unlimited_fps then
		local fps_params = { min = 60, max = 2048, increment = 1 }
		slider(text.fpsLimit, 240, nil, function()
			return g.fps, fps_params
		end, function(v)
			g.fps = v
		end, function(v)
			return ("%i FPS"):format(v)
		end)
	end

	checkbox(text.unlimitedFps, false, nil, function ()
		return g.fps == 0
	end, function()
		g.fps = (g.fps == 0) and 240 or 0
		view:build("graphics")
	end)

	checkbox(text.showFPS, false, nil, function()
		return m.showFPS
	end, function()
		m.showFPS = not m.showFPS
	end)

	local profiler = view.ui.screenOverlayView.frameTimeView
	local show_profiler = profiler.visible and profiler.profiler

	checkbox(text.showProfiler, false, nil, function()
		return show_profiler
	end, function()
		show_profiler = not show_profiler
		m.showFPS = show_profiler
		profiler.visible = show_profiler
		profiler.profiler = show_profiler
	end)

	checkbox(text.vsyncInSongSelect, true, nil, function()
		return g.vsyncOnSelect
	end, function()
		g.vsyncOnSelect = not g.vsyncOnSelect
	end)

	if jit.os == "Windows" then
		checkbox("DWM flush", false, text.dwmFlushTip, function()
			return g.dwmflush
		end, function()
			g.dwmflush = not g.dwmflush
		end)
	end

	--------------- LAYOUT ---------------
	c:createGroup("layout", text.layout)
	Elements.currentGroup = "layout"

	---@type string[]
	local osu_skins = view.ui.assetModel:getOsuSkins()

	combo(text.uiSkin, "Default", nil, function()
		return osu.skin, osu_skins
	end, function(v)
		osu.skin = v
		view.ui.gameView:reloadView()
	end, formatSkinName)

	combo(text.fullscreenType, "desktop", nil, function()
		return flags.fullscreentype, { "desktop", "exclusive" }
	end, function(v)
		flags.fullscreentype = v
	end, function(v)
		return text[v]
	end)

	local modes = love.window.getFullscreenModes()
	combo(text.windowResolution, nil, nil, function()
		return g.mode.window, modes
	end, function(v)
		local prev_canvas = love.graphics.getCanvas()
		love.graphics.setCanvas()
		g.mode.window = v
		love.window.setMode(v.width, v.height, flags)
		love.graphics.setCanvas(prev_canvas)
		view.ui:resolutionUpdated()
	end, function(mode)
		return mode.width .. "x" .. mode.height
	end)

	checkbox(text.fullscreen, nil, nil, function()
		return flags.fullscreen
	end, function()
		flags.fullscreen = not flags.fullscreen
	end)

	--------------- DETAILS ---------------
	c:createGroup("details", text.details)
	Elements.currentGroup = "details"

	checkbox(text.backgroundVideos, false, nil, function()
		return gp.bga.video
	end, function()
		gp.bga.video = not gp.bga.video
	end)

	checkbox(text.backgroundImages, false, nil, function()
		return gp.bga.image
	end, function()
		gp.bga.image = not gp.bga.image
	end)

	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
