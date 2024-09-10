local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")
local Label = require("osu_ui.ui.Label")
local consts = require("osu_ui.views.SettingsView.Consts")

local actions = require("osu_ui.actions")
local diff_columns = {
	"enps_diff",
	"osu_diff",
	"msd_diff",
	"user_diff",
}

local diff_columns_names = {
	enps_diff = "ENPS",
	osu_diff = "OSU",
	msd_diff = "MSD",
	user_diff = "USER",
}

---@param assets osu.OsuAssets
---@param view osu.SettingsView
---@return osu.SettingsView.GroupContainer?
return function(assets, view)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local configs = view.game.configModel.configs
	local settings = configs.settings
	local m = settings.miscellaneous
	local ss = settings.select
	local gf = settings.graphics
	local dim = gf.dim
	local blur = gf.blur
	local osu = configs.osu_ui

	local c = GroupContainer(text.general, assets, font, assets.images.generalTab)

	Elements.assets = assets
	Elements.currentContainer = c
	local checkbox = Elements.checkbox
	local combo = Elements.combo
	local slider = Elements.slider

	c:createGroup("language", text.language)
	Elements.currentGroup = "language"

	---@type string[]
	local localization_list = view.ui.assetModel:getLocalizationNames("osu")

	combo(text.selectLanguage, "English", nil, function()
		return osu.language, localization_list
	end, function(v)
		osu.language = v.name
	end, function(v)
		return v.name
	end)

	checkbox(text.originalMetadata, false, nil, function()
		return osu.originalMetadata
	end, function()
		osu.originalMetadata = not osu.originalMetadata
	end)

	c:createGroup("updates", text.updates)
	Elements.currentGroup = "updates"

	checkbox(text.autoUpdate, true, nil, function()
		return m.autoUpdate
	end, function()
		m.autoUpdate = not m.autoUpdate
	end)

	local git = love.filesystem.getInfo(".git")

	local version_label = git and text.gitVersion or (m.autoUpdate and text.upToDate or text.notUpToDate)

	if Elements.canAdd(version_label) then
		c:add(
			"updates",
			Label(assets, {
				text = version_label,
				font = font.labels,
				pixelWidth = consts.labelWidth - 24 - 28,
				pixelHeight = 37,
				align = "left",
			})
		)
	end

	Elements.button(text.openSoundsphereFolder, function()
		love.system.openURL(love.filesystem.getSource())
	end)

	c:createGroup("songSelect", text.songSelect)
	Elements.currentGroup = "songSelect"

	combo(text.difficultyCalculator, "osu_diff", nil, function()
		return ss.diff_column, diff_columns
	end, function(v)
		ss.diff_column = v
	end, function(v)
		return diff_columns_names[v]
	end)

	Elements.sliderPixelWidth = 265

	local background_params = { min = 0, max = 1, increment = 0.01 }
	slider(text.backgroundDim, 0.2, nil, function()
		return dim.select, background_params
	end, function(v)
		dim.select = v
	end, function(v)
		return ("%i%%"):format(v * 100)
	end)

	local blur_params = { min = 0, max = 20, increment = 1 }
	slider(text.backgroundBlur, 0, nil, function()
		return blur.select, blur_params
	end, function(v)
		blur.select = v
	end)

	checkbox(text.vimMotions, false, nil, function()
		return osu.vimMotions
	end, function()
		osu.vimMotions = not osu.vimMotions
		actions.updateActions(osu)
	end)

	checkbox(text.previewIcon, false, nil, function()
		return osu.songSelect.previewIcon
	end, function()
		osu.songSelect.previewIcon = not osu.songSelect.previewIcon
	end)

	checkbox(text.chartPreview, false, nil, function()
		return ss.chart_preview
	end, function()
		ss.chart_preview = not ss.chart_preview
	end)

	c:createGroup("result", text.resultScreen)
	Elements.currentGroup = "result"

	slider(text.backgroundDim, 0.2, nil, function()
		return dim.result, background_params
	end, function(v)
		dim.result = v
	end, function(v)
		return ("%i%%"):format(v * 100)
	end)

	slider(text.backgroundBlur, 0, nil, function()
		return blur.result, blur_params
	end, function(v)
		blur.result = v
	end)

	checkbox(text.showHitGraph, false, nil, function()
		return osu.result.hitGraph
	end, function()
		osu.result.hitGraph = not osu.result.hitGraph
	end)

	checkbox(text.showPP, false, nil, function()
		return osu.result.pp
	end, function()
		osu.result.pp = not osu.result.pp
	end)

	Elements.sliderPixelWidth = nil

	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
