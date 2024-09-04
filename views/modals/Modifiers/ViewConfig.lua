local IViewConfig = require("osu_ui.views.IViewConfig")

local ui = require("osu_ui.ui")
local flux = require("flux")
local Format = require("sphere.views.Format")
local Button = require("osu_ui.ui.Button")
local Slider = require("osu_ui.ui.Slider")
local Checkbox = require("osu_ui.ui.Checkbox")
local AvailableModifiersListView = require("osu_ui.views.modals.Modifiers.AvailableModifiersListView")
local ModifiersListView = require("osu_ui.views.modals.Modifiers.ModifiersListView")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.ModifierModalViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.ModifierModalViewConfig
---@field openAnimation number
---@field openAnimationTween table?
local ViewConfig = IViewConfig + {}

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
---@param modal osu.ui.Modal
function ViewConfig:new(game, assets, modal)
	text, font = assets.localization:get("modifiersModal")
	assert(text and font)
	self.game = game
	self.assets = assets
	self.modal = modal
	self:createUI()
	self.availableModifiers = AvailableModifiersListView(game, assets)
	self.modifiers = ModifiersListView(game, assets)
	self.openAnimation = 0
	self.openAnimationTween = flux.to(self, 2, { openAnimation = 1 }):ease("elasticout")
end

local scale = 0.9
local width = 2.76
local red = { 0.91, 0.19, 0, 1 }
local gray = { 0.42, 0.42, 0.42, 1 }

---@type osu.ui.Button
local reset_button
---@type osu.ui.Button
local close_button
---@type osu.ui.Slider
local rate_slider
---@type osu.ui.Checkbox
local const_checkbox

function ViewConfig:createUI()
	local assets = self.assets
	local modal = self.modal
	local play_context = self.game.playContext

	reset_button = Button(assets, {
		text = text.reset,
		scale = scale,
		width = width,
		color = red,
		font = font.buttons,
	}, function()
		local modifier_select_model = self.game.modifierSelectModel
		local modifiers = play_context.modifiers
		for i = 1, #modifiers do
			modifier_select_model:remove(1)
		end
	end)

	close_button = Button(assets, {
		text = text.close,
		scale = scale,
		width = width,
		color = gray,
		font = font.buttons,
	}, function()
		modal:quit()
	end)

	---@type "linear" | "exp"
	local rate_type = self.game.configModel.configs.settings.gameplay.rate_type
	---@type sphere.TimeRateModel
	local time_rate_model = self.game.timeRateModel

	local format = time_rate_model.format[rate_type]
	local rate_params = {
		linear = { min = 0.75, max = 1.75, increment = 0.05 },
		exp = { min = -6, max = 10, increment = 1 },
	}

	rate_slider = Slider(assets, {
		label = "Music speed:",
		font = font.sliders,
		pixelWidth = 400,
		pixelHeight = 37,
		defaultValue = rate_type == "linear" and 1 or 0,
	}, function()
		return time_rate_model:get(), rate_params[rate_type]
	end, function(v)
		self.game.modifierSelectModel:change()
		time_rate_model:set(v)
	end, function(v)
		return format:format(v)
	end)

	const_checkbox = Checkbox(assets, {
		text = "Constant scroll speed",
		font = font.checkboxes,
		pixelHeight = 37,
	}, function()
		return play_context.const
	end, function()
		play_context.const = not play_context.const
	end)
end

function ViewConfig:resolutionUpdated()
	self:createUI()
end

local gfx = love.graphics

local list_width = 400
local list_height = 295
local spacing = 20

function ViewConfig:draw(modal)
	Layout:draw()
	local w, h = Layout:move("base")

	gfx.push()
	gfx.setColor(1, 1, 1, 1)
	gfx.setFont(font.title)

	ui.frame(text.title, 9, 9, w - 18, h, "left", "top")

	local input_mode = self.game.selectController.state.inputMode
	input_mode = Format.inputMode(tostring(input_mode))
	input_mode = input_mode == "2K" and "TAIKO" or input_mode

	gfx.setFont(font.mode)

	ui.frame("Mode: " .. input_mode, 0, 112, w, h, "center", "top")

	gfx.push()

	local list_x = w / 2 - (list_width * 2 + spacing) / 2

	gfx.translate(list_x, 189)
	self.availableModifiers:reloadItems()
	gfx.setColor(0, 0, 0, 0.7)
	gfx.rectangle("fill", 0, 0, 400, 295, 5, 5)
	self.availableModifiers:draw(400, 295, true)
	gfx.setColor(0.89, 0.47, 0.56)
	gfx.rectangle("line", 0, 0, 400, 295, 5, 5)

	local modifiers_selected = #self.game.playContext.modifiers ~= 0

	gfx.translate(spacing + list_width, 0)
	gfx.setColor(0, 0, 0, 0.7)
	gfx.rectangle("fill", 0, 0, 400, 295, 5, 5)

	if not modifiers_selected then
		gfx.setColor(1, 1, 1, 1)
		gfx.setFont(font.notSelected)
		ui.frame(
			"No modifiers selected.\nYou can select them from the list on the left.",
			0,
			0,
			list_width,
			list_height,
			"center",
			"center"
		)
	else
		self.modifiers:reloadItems()
		self.modifiers:draw(list_width, list_height, true)
	end
	gfx.setColor(0.89, 0.47, 0.56)
	gfx.rectangle("line", 0, 0, 400, 295, 5, 5)

	gfx.pop()

	gfx.push()
	gfx.translate(list_x + 10, 500)
	rate_slider:update(true)
	rate_slider:draw()
	gfx.pop()
	gfx.push()
	gfx.translate(list_x + list_width + spacing + list_width / 2 - const_checkbox:getWidth() / 2 + 10, 500)
	const_checkbox:update(true)
	const_checkbox:draw()
	gfx.pop()

	local bw, bh = reset_button:getDimensions()
	gfx.translate(w / 2 - bw / 2, 540)

	local a = self.openAnimation
	if a > 1 then
		a = 1 - (a - 1)
	end
	a = a * 50

	gfx.translate(50 - a, 0)
	reset_button:update(self.openAnimation > 0.8)
	reset_button:draw()
	gfx.translate(a - 50, 0)

	gfx.translate(-50 + a, 0)
	close_button:update(self.openAnimation > 0.8)
	close_button:draw()
	gfx.translate(-a + 50, 0)

	gfx.pop()
end

return ViewConfig
