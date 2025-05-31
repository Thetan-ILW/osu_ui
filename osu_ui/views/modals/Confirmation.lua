local Modal = require("osu_ui.views.modals.Modal")

---@class osu.ui.ConfirmationModal : osu.ui.Modal
---@operator call: osu.ui.ConfirmationModal
local Confirmation = Modal + {}

function Confirmation:load()
	self:getViewport():listenForResize(self)
	self.width, self.height = self.parent:getDimensions()

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	self:initModal(self.text)
	self:addOption(text.General_Yes, self.buttonColors.green, function ()
		self.onClickYes()
		self:close()
	end)
	self:addOption(text.General_No, self.buttonColors.gray, function ()
		self:close()
	end)
end

return Confirmation
