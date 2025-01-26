local utf8validate = require("utf8validate")

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local g = configs.settings.graphics
	local gp = configs.settings.gameplay
	local m = configs.settings.miscellaneous
	local flags = g.mode.flags
	local osu = configs.osu_ui ---@cast osu osu.ui.OsuConfig
	local ui = section.options.ui

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	section:group(text.Options_Graphics_Renderer, function(group)
		group:combo({
			label = "MSAA:",
			items = { 0, 1, 2, 4 },
			key = { flags, "msaa" }
		})

		local vsync_items = { 1, 0, -1 }
		group:combo({
			label = text.Options_Graphics_Vsync,
			items = vsync_items,
			getValue = function()
				return flags.vsync
			end,
			setValue = function(index)
				local v = vsync_items[index]
				g.vsyncOnSelect = not (v == 0)
				flags.vsync = v
			end,
			format = function(v)
				if v == 1 then
					return text.Options_Graphics_Enabled
				elseif v == 0 then
					return text.Options_Graphics_Disabled
				else
					return text.Options_Graphics_Adaptive
				end
			end
		})

		local unlimited_fps = g.fps == 0

		if not unlimited_fps then
			group:slider({
				label = text.Options_Graphics_FrameLimiter,
				min = 64,
				max = 1024,
				step = 4,
				key = { g, "fps" },
				format = function(v)
					return ("%i FPS"):format(v)
				end
			})
		end

		group:checkbox({
			label = text.Options_Graphics_FrameLimiter_Unlim,
			getValue = function()
				return g.fps == 0
			end,
			clicked = function ()
				g.fps = (g.fps == 0) and 240 or 0
				group:load()
				section.options:recalcPositions()
			end
		})

		group:checkbox({
			label = text.Options_Graphics_FpsCounter,
			getValue = function()
				return m.showFPS
			end,
			clicked = function()
				m.showFPS = not m.showFPS
				scene.fpsDisplay:fade()
			end
		})

		group:checkbox({
			label = text.Options_Graphics_VsyncInMenus,
			key = { g, "vsyncOnSelect" }
		})

		if love.system.getOS() == "Windows" then
			group:checkbox({
				label  = "DWM flush",
				key = { g, "dwmflush" }
			})
		end
	end)

	section:group(text.Options_Graphics_ScreenResolution, function(group)
		local skins = ui.assetModel:getOsuSkins()
		group:combo({
			label = text.Options_Graphics_UISkin,
			items = skins,
			getValue = function ()
				return osu.skin
			end,
			setValue = function(index)
				osu.skin = skins[index]
				scene:reloadUI()
			end,
			format = function(v)
				if not v then
					return "??"
				end
				local len = v:len()
				if len > 38 then
					return utf8validate(v:sub(1, 38), ".") .. ".."
				end
				return v
			end
		})

		group:combo({
			label = text.Options_Graphics_FullscreenType,
			items = { "desktop", "exclusive" },
			key = { flags, "fullscreentype" },
			format = function(v)
				if v == "desktop" then
					return text.Options_Graphics_FullscreenDesktop
				else
					return text.Options_Graphics_FullscreenExclusive
				end
			end
		})

		local modes = love.window.getFullscreenModes()
		group:combo({
			label = text.Options_Graphics_SelectResolution,
			items = modes,
			getValue = function()
				return g.mode.window
			end,
			setValue = function(index)
				local mode = modes[index]
				local prev_canvas = love.graphics.getCanvas()
				love.graphics.setCanvas()
				g.mode.window = mode
				love.window.setMode(mode.width, mode.height, flags)
				love.graphics.setCanvas(prev_canvas)
			end,
			format = function(v)
				return v.width .. "x" .. v.height
			end
		})

		group:checkbox({
			label = text.Options_Graphics_Fullscreen,
			key = { flags, "fullscreen" }
		})
	end)

	section:group(text.Options_Graphics_Details, function(group)
		group:checkbox({
			label = text.Options_Graphics_CopyScreenshot,
			key = { osu, "copyScreenshotToClipboard" }
		})

		group:checkbox({
			label = text.Options_Graphics_Video,
			key = { gp.bga, "video" }
		})

		group:checkbox({
			label = text.Options_Graphics_Image,
			key = { gp.bga, "image" }
		})

		group:checkbox({ label = text.Options_Graphics_EnableBlur,
			getValue = function ()
				return osu.graphics.blur
			end,
			clicked = function ()
				osu.graphics.blur = not osu.graphics.blur
				section.options:reloadViewport()
			end
		})

		group:slider({ label = text.Options_Graphics_BlurQuality, min = 0.1, max = 0.7, step = 0.01,
			getValue = function()
				return osu.graphics.blurQuality
			end,
			setValue = function(v)
				osu.graphics.blurQuality = v
			end,
		})
	end)
end
