local Modal = require("osu_ui.views.modals.Modal")

local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local Slider = require("osu_ui.ui.Slider")
local Checkbox = require("osu_ui.ui.Checkbox")
local Combo = require("osu_ui.ui.Combo")
local Button = require("osu_ui.ui.Button")

local AvailableMods = require("osu_ui.views.modals.Modifiers.AvailableMods")
local SelectedMods = require("osu_ui.views.modals.Modifiers.SelectedMods")
local NewPresetModal = require("osu_ui.views.modals.Modifiers.NewPresetModal")

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
	viewport:listenForEvent(self, "event_modsChanged")

	local select_api = scene.ui.selectApi
	local mod_preset_model = scene.ui.modPresetModel
	local replay_base = select_api:getReplayBase()
	self.modPresetModel = mod_preset_model

	local precise_rates = select_api:getConfigs().osu_ui.songSelect.preciseRates

	local w_scale = math.min(1, self.width / 1366)
	local lists_width = 400 * w_scale
	local lists_spacing = 20

	local available_modifiers = self.container:addChild("availableModifiers", Component({
		x = (self.width - lists_spacing) / 2 - lists_width, y = 29,
		z = 0.1,
	}))
	available_modifiers:addChild("border", Rectangle({
		width = lists_width,
		height = 295,
		rounding = 5,
		lineWidth = 2,
		mode = "line",
		color = { 0.89, 0.47, 0.56 },
		z = 0.2
	}))
	available_modifiers:addChild("background", Rectangle({
		width = lists_width,
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
		width = lists_width,
		height = 295,
		rounding = 5,
		lineWidth = 2,
		mode = "line",
		color = { 0.89, 0.47, 0.56 },
		z = 0.2

	})
	applied_modifiers:addChild("background", Rectangle {
		width = lists_width,
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
			return replay_base.const
		end,
		clicked = function ()
			replay_base.const = not replay_base.const
		end
	}))

	local preset_container = self.container:addChild("presets", Component({
		x = applied_modifiers.x + applied_modifiers.width + lists_spacing, y = 29,
		z = 0.1,
	}))

	local c = preset_container:addChild("selectedPreset", Combo({
		width = 200,
		items = mod_preset_model.presets,
		z = 0.2,
		getValue = function ()
			return mod_preset_model.presets[mod_preset_model.selectedPresetIndex]
		end,
		setValue = function(index)
			mod_preset_model:select(index)
			viewport:triggerEvent("event_modsChanged")
		end,
		format = function(v)
			return v.name
		end
	}))

	local new = preset_container:addChild("addNew", Button({
		x = 10,
		y = c:getHeight() + 5,
		width = 180,
		height = 32,
		label = text.ModSelection_NewPreset,
		font = self.fonts:loadFont("Regular", 18),
		color = Modal.buttonColors.green,
		onClick = function()
			self:addChild("newPresetModal", NewPresetModal({
				modPresetModel = mod_preset_model,
				z = 1,
				onCreate = function ()
					c:addItems()
				end,
			}))
		end
	}))

	preset_container:addChild("delete", Button({
		x = 10,
		y = new.y + new:getHeight() + 5,
		width = 180,
		height = 32,
		label = text.ModSelection_DeletePreset,
		font = self.fonts:loadFont("Regular", 18),
		color = Modal.buttonColors.red,
		onClick = function()
			mod_preset_model:deleteSelected()
			viewport:triggerEvent("event_modsChanged")
			c:addItems()
		end
	}))

	self:addOption(text.ModSelection_Reset, self.buttonColors.red, function()
		select_api:removeAllMods()
		viewport:triggerEvent("event_modsChanged")
	end)
	self:addOption(text.General_Cancel, self.buttonColors.gray, function()
		self:close()
		mod_preset_model:save()
	end)
end

function Modifiers:event_modsChanged()
	self.modPresetModel:saveCurrentPreset() -- This thing calls two times when you add mods pls rewrite modifiers modal
end

return Modifiers
