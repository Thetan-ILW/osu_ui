local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")
local Label = require("osu_ui.ui.Label")
local consts = require("osu_ui.views.SettingsView.Consts")
local version = require("version")

---@param assets osu.OsuAssets
---@param view osu.SettingsView
---@return osu.SettingsView.GroupContainer?
return function(assets, view)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local configs = view.game.configModel.configs
	local settings = configs.settings
	local g = settings.graphics

	local gucci = view.ui.gucci ~= nil

	local c = GroupContainer(text.maintenance, assets, font, assets.images.maintenanceTab)

	Elements.assets = assets
	Elements.currentContainer = c
	local button = Elements.button

	c:createGroup("maintenance", text.maintenance)
	Elements.currentGroup = "maintenance"

	if not gucci then
		button("Switch to default UI", function()
			g.userInterface = "Default"
			view.game.uiModel:switchTheme()
		end)
	end

	if Elements.canAdd(version.date) then
		c:add("maintenance", Label(assets, { font = font.labels, pixelWidth = consts.labelWidth - 24 - 28, pixelHeight = 260, align = "left",
			text = "Credits:\n\nSpanish Translation: Leoncheto and Sanik\n\nMinaCalc:\nhttps://github.com/etternagame/etterna\nhttps://github.com/kangalio/minacalc-standalone\n\nManip Factor:\nhttps://github.com/MaidOfFire/ManipFactorEtterna\n\nsoundsphere:\nhttps://github.com/semyon422/soundsphere\nhttps://soundsphere.xyz/"}))

		local label = version.date == "" and text.gitVersion or version.date
		c:add(
			"maintenance",
			Label(
				assets,
				{ text = label, font = font.labels, pixelWidth = consts.labelWidth - 24 - 28, pixelHeight = 64 },
				function()
					if gucci then
						love.system.openURL("https://github.com/Thetan-ILW/gucci/commits/main/")
						return
					end
					love.system.openURL("https://github.com/semyon422/soundsphere/commits/master/")
				end
			)
		)
	end

	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
