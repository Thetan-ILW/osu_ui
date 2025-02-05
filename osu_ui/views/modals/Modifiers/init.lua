local Modal = require("osu_ui.views.modals.Modal")

local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local Slider = require("osu_ui.ui.Slider")
local Checkbox = require("osu_ui.ui.Checkbox")

local AvailableMods = require("osu_ui.views.modals.Modifiers.AvailableMods")
local SelectedMods = require("osu_ui.views.modals.Modifiers.SelectedMods")

---@class osu.ui.ModifiersModal : osu.ui.Modal
---@operator call: osu.ui.ModifiersModal
local Modifiers = Modal + {}

function Modifiers:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	self:initModal(text.ModSelection_Title)

	self.width, self.height = self.parent:getDimensions()
	local viewport = self:getViewport()
	viewport:listenForResize(self)

	local select_api = scene.ui.selectApi
	local play_context = select_api:getPlayContext()

	local precise_rates = select_api:getConfigs().osu_ui.songSelect.preciseRates

	local lists_width = 400
	local lists_spacing = 20

	local available_modifiers = self.container:addChild("availableModifiers", Component({
		x = (self.width - lists_spacing) / 2 - lists_width, y = 29,
		z = 0.1,
	}))
	available_modifiers:addChild("border", Rectangle({
		width = 400,
		height = 295,
		rounding = 5,
		lineWidth = 2,
		mode = "line",
		color = { 0.89, 0.47, 0.56 },
		z = 0.2
	}))
	available_modifiers:addChild("background", Rectangle({
		width = 400,
		height = 295,
		rounding = 5,
		color = { 0, 0, 0, 0.7 }
	}))
	available_modifiers:autoSize()
	available_modifiers:addChild("list", AvailableMods({
		selectApi = select_api,
		z = 0.1,
	}))

	local applied_modifiers = self.container:addChild("appliedModifiers", Component({
		x = (self.width + lists_spacing) / 2, y = 29,
		z = 0.1,
	}))
	applied_modifiers:addChild("border", Rectangle {
		width = 400,
		height = 295,
		rounding = 5,
		lineWidth = 2,
		mode = "line",
		color = { 0.89, 0.47, 0.56 },
		z = 0.2

	})
	applied_modifiers:addChild("background", Rectangle {
		width = 400,
		height = 295,
		rounding = 5,
		color = { 0, 0, 0, 0.7 }
	})
	applied_modifiers:autoSize()
	applied_modifiers:addChild("list", SelectedMods({
		z = 0.1
	}))

	local music_speed_label = self.container:addChild("musicSpeedLabel", Label({
		x = (self.width - lists_spacing) / 2 - lists_width,
		y = available_modifiers.y + available_modifiers:getHeight() + 24,
		font = self.fonts:loadFont("Regular", 16),
		text = "Music speed:",
	}))

	self.container:addChild("musicSpeed", Slider({
		x = music_speed_label.x + music_speed_label:getWidth() + 5,
		y = 29 + available_modifiers:getHeight() + 16,
		width = lists_width - music_speed_label:getWidth() - 5,
		min = 0.5,
		max = 2,
		step = precise_rates and 0.025 or 0.05,
		getValue = function ()
			return select_api:getTimeRate()
		end,
		setValue = function(v)
			select_api:setTimeRate(v)
			viewport:triggerEvent("event_modsChanged")
		end,
		format = function(v)
			if precise_rates then
				return ("%0.03fx"):format(v)
			else
				return ("%0.02fx"):format(v)
			end
		end
	}))

	self.container:addChild("const", Checkbox({
		x = (self.width + lists_spacing + available_modifiers:getWidth()) / 2,
		y = available_modifiers.y + available_modifiers:getHeight() + 16,
		origin = { x = 0.5 },
		large = true,
		font = self.fonts:loadFont("Regular", 16),
		label = "Constant scroll speed",
		getValue = function ()
			return play_context.const
		end,
		clicked = function ()
			play_context.const = not play_context.const
		end
	}))

	self:addOption(text.ModSelection_Reset, self.buttonColors.red, function()
		select_api:removeAllMods()
		viewport:triggerEvent("event_modsChanged")
	end)
	self:addOption(text.General_Cancel, self.buttonColors.gray, function() self:close() end)
end

return Modifiers
