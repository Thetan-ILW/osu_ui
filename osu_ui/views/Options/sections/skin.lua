local utf8validate = require("utf8validate")
local Format = require("sphere.views.Format")
local path_util = require("path_util")

local function formatSkinName(v, input_mode)
	if not v then -- error in _k.config.lua
		return "Failed to load skin"
	end

	local k = Format.inputMode(tostring(input_mode))
	local name = ("[%s] %s"):format(k, v.name)
	if not name then
		return "??"
	end
	local len = name:len()
	if len > 38 then
		return utf8validate(name:sub(1, 38), ".") .. ".."
	end

	return name
end

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local settings = configs.settings
	local gameplay = settings.gameplay
	local osu = configs.osu_ui ---@cast osu osu.ui.OsuConfig
	local p = settings.graphics.perspective

	local select_api = section.options.ui.selectApi

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	section:group(text.Options_Skin, function(group)
		local current_input_mode ---@type string?
		local selected_note_skin ---@type sphere.NoteSkin
		local skins ---@type table

		local skins_combo = group:combo({
			label = text.Options_SkinSelect,
			items = {},
			setValue = function(index)
				if not current_input_mode then
					return
				end
				local skin = skins[index]
				select_api:setNoteSkin(current_input_mode, skin:getPath())
				current_input_mode = tostring(select_api:getCurrentInputMode()) -- what is the point of this line? I don't remember
			end,
			format = function(v)
				return formatSkinName(v, current_input_mode)
			end
		})
		if skins_combo then
			skins_combo.getValue = function ()
				local im = select_api:getCurrentInputMode()
				if im ~= current_input_mode then
					current_input_mode = im
					local str_im = tostring(im)
					selected_note_skin = select_api:getNoteSkin(str_im)
					skins = select_api:getNoteSkinInfos(str_im)
					skins_combo.items = skins
					skins_combo:addItems()
				end
				return selected_note_skin
			end
			skins_combo:update()
		end

		group:button({
			label = text.Options_SkinPreview,
			color = { 0.84, 0.38, 0.47, 1 },
			onClick = function()
				local current_screen = scene:getChild(scene.currentScreenId)
				if current_screen then
					---@cast current_screen osu.ui.Screen
					scene:hideOverlay()
					section.options:fade(0)
					current_screen:transitOut({
						onComplete = function ()
							select_api:setAutoplay(true)
							scene:transitInScreen("gameplay")
						end
					})
				end
			end
		})

		group:button({
			label = text.Options_SkinSettings,
			onClick = function()
				scene.notification:show("Not implemented")
			end
		})

		group:button({
			label = text.Options_OpenSkinFolder,
			onClick = function ()
				local im = select_api:getCurrentInputMode()
				local path = settings.gameplay[("noteskin%s"):format(tostring(im))]
				if path and type(path) == "string" then
					love.system.openURL(path_util.join(love.filesystem.getSource(), path:match("^(.*/)")))
				end
			end
		})

		group:slider({
			label = text.Options_LongNoteShortening,
			min = -300,
			max = 0,
			step = 10,
			getValue = function ()
				return gameplay.longNoteShortening * 1000
			end,
			setValue = function(v)
				gameplay.longNoteShortening = v / 1000
			end,
			format = function (v)
				return ("%ims"):format(v)
			end
		})
	end)

	section:group(text.Options_Cursor, function(group)
		group:slider({
			label = text.Options_CursorSize,
			min = 0.1,
			max = 2,
			step = 0.01,
			getValue = function ()
				return osu.cursor.size
			end,
			setValue = function(v)
				osu.cursor.size = v
			end,
			format = function(v)
				return ("%0.02fx"):format(v)
			end
		})

		group:slider({
			label = text.Options_TrailDensity,
			min = 1,
			max = 30,
			step = 1,
			getValue = function ()
				return osu.cursor.trailDensity
			end,
			setValue = function(v)
				osu.cursor.trailDensity = v
			end
		})

		group:slider({
			label = text.Options_TrailQuality,
			min = 10,
			max = 400,
			step = 10,
			getValue = function ()
				return osu.cursor.trailMaxImages
			end,
			setValue = function(v)
				osu.cursor.trailMaxImages = v
				scene.cursor:updateSpriteBatch()
			end
		})

		group:slider({
			label = text.Options_TrailLifetime,
			min = 1,
			max = 10,
			step = 1,
			getValue = function ()
				return osu.cursor.trailLifetime
			end,
			setValue = function (v)
				osu.cursor.trailLifetime = v
			end
		})

		local styles = { "Vanishing", "Shrinking" }
		group:combo({
			label = text.Options_TrailStyle,
			items = styles,
			getValue = function ()
				return osu.cursor.trailStyle
			end,
			setValue = function(index)
				osu.cursor.trailStyle = styles[index]
			end
		})

		group:checkbox({
			label =  text.Options_ShowTrail,
			key = { osu.cursor, "showTrail" }
		})
	end)

	section:group(text.Options_Camera, function(group)
		group:checkbox({
			label = text.Options_EnableCamera,
			key = { p, "camera" }
		})
		group:checkbox({
			label = text.Options_CameraXRotation,
			key = { p, "rx" },
		})
		group:checkbox({
			label = text.Options_CameraYRotation,
			key = { p, "ry" },
		})
	end)


end
