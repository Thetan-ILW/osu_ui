local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")
local Label = require("osu_ui.ui.Label")
local consts = require("osu_ui.views.SettingsView.Consts")
local utf8validate = require("utf8validate")
local Format = require("sphere.views.Format")

local function formatSkinName(v, input_mode)
	if not v then -- error in _k.config.lua
		return "Failed to load skin"
	end

	local k = Format.inputMode(input_mode)
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

---@param assets osu.ui.OsuAssets
---@param view osu.ui.SettingsView
---@param skin_preview osu.ui.SkinPreview
---@return osu.ui.SettingsView.GroupContainer?
return function(assets, view, skin_preview)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local configs = view.game.configModel.configs
	local settings = configs.settings
	---@type osu.ui.OsuConfig
	local osu = configs.osu_ui
	local g = settings.gameplay
	local graphics = settings.graphics
	local p = graphics.perspective

	local c = GroupContainer("SKIN", assets, font, assets.images.skinTab)

	Elements.assets = assets
	Elements.currentContainer = c
	local combo = Elements.combo
	local checkbox = Elements.checkbox
	local slider = Elements.slider
	local button = Elements.button

	c:createGroup("skin", text.skin)
	Elements.currentGroup = "skin"

	if Elements.canAdd("skin") then
		c:add("skin", skin_preview)
	end

	local select_controller = view.game.selectController
	local noteskin_model = view.game.noteSkinModel

	local prev_input_mode
	local input_mode
	local selected_note_skin
	local skins

	combo(text.currentSkin, "Default", nil, function()
		if select_controller.state.inputMode ~= prev_input_mode then
			prev_input_mode = select_controller.state.inputMode
			input_mode = tostring(select_controller.state.inputMode)
			selected_note_skin = noteskin_model:getNoteSkin(input_mode)
			skins = noteskin_model:getSkinInfos(input_mode)
		end
		return selected_note_skin, skins
	end, function(v)
		view.game.noteSkinModel:setDefaultNoteSkin(input_mode, v:getPath())
		input_mode = tostring(select_controller.state.inputMode)
		selected_note_skin = noteskin_model:getNoteSkin(input_mode)
		local skin_preview_img = view.game.ui.assetModel:loadSkinPreview(v.dir)
		skin_preview:setImage(skin_preview_img)
	end, function(v)
		return formatSkinName(v, input_mode)
	end)

	local prev_color = Elements.buttonColor
	Elements.buttonColor = { 0.84, 0.38, 0.47, 1 }
	button(text.previewGameplay, function()
		if not view.game.selectModel:notechartExists() then
			return
		end

		view.game.rhythmModel:setAutoplay(true)
		view.game.gameView.view:changeScreen("gameplayView")
	end)
	Elements.buttonColor = prev_color

	button(text.openSkinSettings, function()
		view.ui.gameView.view:openModal("osu_ui.views.modals.SkinSettings")
	end)

	button(text.openCurrentSkinFolder, function()
		love.system.openURL(love.filesystem.getSource() .. "/userdata/skins/" .. osu.skin)
	end)

	local ln_shortening = { min = -300, max = 0, increment = 10 }
	slider(text.lnShortening, 0, nil, function()
		return g.longNoteShortening * 1000, ln_shortening
	end, function(v)
		g.longNoteShortening = v / 1000
	end, function(v)
		return ("%ims"):format(v)
	end)

	c:createGroup("cursor", text.cursor)
	Elements.currentGroup = "cursor"

	local cursor_size_params = { min = 0.1, max = 2, increment = 0.01 }
	local trail_density_params = { min = 1, max = 30, increment = 1 }
	local trail_quality_params = { min = 10, max = 400, increment = 10 }
	local trail_lifetime_params = { min = 1, max = 10, increment = 1 }

	Elements.sliderPixelWidth = 290
	slider(text.cursorSize, 1, nil, function ()
		return osu.cursor.size, cursor_size_params
	end, function (v)
		osu.cursor.size = v
	end)

	slider(text.trailDensity, 10, nil, function ()
		return osu.cursor.trailDensity, trail_density_params
	end, function (v)
		osu.cursor.trailDensity = v
	end)

	slider(text.trailQuality, 60, nil, function ()
		return osu.cursor.trailMaxImages, trail_quality_params
	end, function (v)
		osu.cursor.trailMaxImages = v
		view.ui.gameView.cursor:updateSpriteBatch()
	end)

	slider(text.trailLifetime, 7, nil, function ()
		return osu.cursor.trailLifetime, trail_lifetime_params
	end, function (v)
		osu.cursor.trailLifetime = v
	end)
	Elements.sliderPixelWidth = nil

	local trail_styles = { "Vanishing", "Shrinking" }
	combo(text.trailStyle, "Vanishing", nil, function ()
		return osu.cursor.trailStyle, trail_styles
	end, function (v)
		osu.cursor.trailStyle = v
	end)

	checkbox(text.showTrail, true, nil, function ()
		return osu.cursor.showTrail
	end, function ()
		osu.cursor.showTrail = not osu.cursor.showTrail
	end)

	c:createGroup("camera", text.camera)
	Elements.currentGroup = "camera"

	if Elements.canAdd("camera") then
		c:add(
			"camera",
			Label(assets, {
				text = text.cameraControls,
				font = font.labels,
				pixelWidth = consts.labelWidth - 24 - 28,
				pixelHeight = 128,
				align = "left",
			})
		)
	end

	checkbox(text.enableCamera, false, nil, function()
		return p.camera
	end, function()
		p.camera = not p.camera
	end)

	checkbox(text.cameraX, false, nil, function()
		return p.rx
	end, function()
		p.rx = not p.rx
	end)

	checkbox(text.cameraY, false, nil, function()
		return p.ry
	end, function()
		p.ry = not p.ry
	end)

	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
