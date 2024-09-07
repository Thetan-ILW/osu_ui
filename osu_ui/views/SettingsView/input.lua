local GroupContainer = require("osu_ui.views.SettingsView.GroupContainer")
local Elements = require("osu_ui.views.SettingsView.Elements")

local function formatMs(v)
	return ("%dms"):format(v)
end

---@param assets osu.ui.OsuAssets
---@param view osu.ui.SettingsView
---@param ui osu.ui.UserInterface
---@return osu.SettingsView.GroupContainer?
return function(assets, view, ui)
	local text, font = assets.localization:get("settings")
	assert(text and font)

	local settings = view.game.configModel.configs.settings
	local g = settings.graphics
	local gp = settings.gameplay
	local play_context = view.game.playContext

	local c = GroupContainer(text.input, assets, font, assets.images.inputTab)

	Elements.assets = assets
	Elements.currentContainer = c

	local button = Elements.button
	local checkbox = Elements.checkbox
	local slider = Elements.slider

	c:createGroup("keyboard", text.keyboard)
	Elements.currentGroup = "keyboard"

	button(text.maniaLayout, function()
		ui.gameView.view:openModal("osu_ui.views.modals.Inputs")
	end)

	c:createGroup("offsetAdjustment", text.offsetAdjustment)
	Elements.currentGroup = "offsetAdjustment"

	Elements.sliderPixelWidth = 300
	local offset = { min = -300, max = 300, increment = 1 }
	slider(text.inputOffset, 0, nil, function()
		return gp.offset.input, offset
	end, function(v)
		gp.offset.input = v
	end, formatMs)

	slider(text.visualOffset, 0, nil, function()
		return gp.offset.visual, offset
	end, function(v)
		gp.offset.visual = v
	end, formatMs)

	Elements.sliderPixelWidth = nil

	checkbox(text.multiplyInputOffset, false, nil, function()
		return gp.offsetScale.input
	end, function()
		gp.offsetScale.input = not gp.offsetScale.input
	end)

	checkbox(text.multiplyVisualOffset, false, nil, function()
		return gp.offsetScale.visual
	end, function()
		gp.offsetScale.visual = not gp.offsetScale.visual
	end)

	c:createGroup("other", text.other)
	Elements.currentGroup = "other"

	checkbox(text.threadedInput, false, text.threadedInputTip, function()
		return g.asynckey
	end, function()
		g.asynckey = not g.asynckey
	end)

	checkbox(text.taikoNoteHandler, false, text.taikoNoteHandlerTip, function()
		return play_context.single
	end, function()
		play_context.single = not play_context.single
	end)

	c:removeEmptyGroups()

	if c.isEmpty then
		return nil
	end

	return c
end
