local ScreenView = require("osu_ui.views.ScreenView")
local ViewConfig = require("osu_ui.views.FirstTimeSetupView.ViewConfig")

---@class osu.ui.FirstTimeSetupView : osu.ui.ScreenView
---@operator call: osu.ui.FirstTimeSetupView
local FirstTimeSetupView = ScreenView + {}

function FirstTimeSetupView:load()
	love.mouse.setVisible(false)

	self.useOsuSongs = true
	self.useEtternaSongs = true
	self.useQuaverSongs = true
	self.useOsuSkins = true
	self.applyOsuSettings = true

	self.viewConfig = ViewConfig(self)
end

function FirstTimeSetupView:applySelected()
	self:changeScreen("mainMenuView")
end

function FirstTimeSetupView:resolutionUpdated()
	self.viewConfig:createUI()
end

function FirstTimeSetupView:draw()
	self.viewConfig:draw()
	self.ui.screenOverlayView:draw()
end

return FirstTimeSetupView
