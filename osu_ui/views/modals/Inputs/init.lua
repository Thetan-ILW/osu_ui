local Modal = require("osu_ui.views.modals.Modal")

local InputMap = require("osu_ui.views.modals.Inputs.InputMap")
local BackButton = require("osu_ui.ui.BackButton")

---@class osu.ui.InputsModal : osu.ui.Modal
---@operator call: osu.ui.InputsModal
local Inputs = Modal + {}

Inputs.modes = {
	"4key",
	"5key",
	"6key",
	"7key",
	"7key1scratch",
	"8key",
	"9key",
	"10key",
	"12key",
	"12key2scratch",
	"14key",
	"14key2scratch",
}

function Inputs:load()
	self:getViewport():listenForResize(self)
	self.width, self.height = self.parent:getDimensions()

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text
	local fonts = scene.fontManager

	local select_api = scene.ui.selectApi
	local input_model = scene.ui.selectApi:getInputModel()

	local mode = select_api:getCurrentInputMode()
	local inputs = input_model:getInputs(tostring(mode))

	self:initModal(text.Options_TabSkin_CustonKey)

	self:addChild("inputMap", InputMap({
		x = self.width / 2, y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		inputs = inputs,
		inputModel = input_model,
		mode = tostring(mode),
		z = 0.5
	}))

	self:addChild("backButton", BackButton({
		y = self.height - 58,
		font = fonts:loadFont("Regular", 20),
		text = "back",
		hoverWidth = 93,
		hoverHeight = 58,
		onClick = function ()
			self:close()
		end,
		z = 0.9,
	}))
end

return Inputs
