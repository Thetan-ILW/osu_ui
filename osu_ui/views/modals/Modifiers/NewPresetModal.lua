local Modal = require("osu_ui.views.modals.Modal")
local Label = require("ui.Label")
local TextBox = require("osu_ui.ui.TextBox")
local Component = require("ui.Component")

---@class osu.ui.ModifiersModal.NewPresetModal : osu.ui.Modal
---@operator call: osu.ui.ModifiersModal.NewPresetModal
---@field modPresetModel osu.ui.ModPresetModel
---@field onCreate function
local NewPresetModal = Modal + {}

function NewPresetModal:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	self:initModal(text.ModSelection_NewPreset_Title)

	self.width, self.height = self.parent:getDimensions()
	local viewport = self:getViewport()
	viewport:listenForResize(self)

	local c = self.container:addChild("centeredContainer", Component({
		x = self.width / 2,
		origin = { x = 0.5 }
	}))

	local label = c:addChild("label", Label({
		text = "Name:",
		font = scene.fontManager:loadFont("Regular", 24)
	}))

	local text_box = c:addChild("searchTextBox", TextBox({
		x = label.x + label:getWidth() + 6,
		y = 0,
		width = 300,
		z = 0.5,
	}))

	c:autoSize()
	c.height = c.height + 20

	self:addOption(text.ModSelection_NewPreset_Create, self.buttonColors.red, function()
		self.modPresetModel:createNew(text_box.input)
		if self.onCreate then
			self.onCreate()
		end
		self:close()
	end)
	self:addOption(text.General_Cancel, self.buttonColors.gray, function()
		self:close()
	end)
end

return NewPresetModal
