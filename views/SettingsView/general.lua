local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")
local Label = require("osu_ui.ui.Label")
local consts = require("osu_ui.views.SettingsView.Consts")

---@param assets osu.OsuAssets
---@param view osu.SettingsView
---@return osu.SettingsView.GroupContainer?
return function(assets, view)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local configs = view.game.configModel.configs
	local settings = configs.settings
	local m = settings.miscellaneous
	local osu = configs.osu_ui

	local c = GroupContainer(text.general, assets, font, assets.images.generalTab)

	Elements.assets = assets
	Elements.currentContainer = c
	local checkbox = Elements.checkbox
	local combo = Elements.combo

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

	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
