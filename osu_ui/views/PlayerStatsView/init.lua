local ScreenView = require("osu_ui.views.ScreenView")
local ActivityView = require("osu_ui.views.PlayerStatsView.ActivityView")
local ViewConfig = require("osu_ui.views.PlayerStatsView.ViewConfig")


---@class osu.ui.PlayerStatsView : osu.ui.ScreenView
---@operator call: osu.ui.PlayerStatsView
local PlayerStatsView = ScreenView + {}

function PlayerStatsView:load()
	self.playerProfile = self.ui.playerProfile
	self.activityView = ActivityView(self.assets, self.playerProfile:getActivity())
	self.viewConfig = ViewConfig(self)
end

function PlayerStatsView:resolutionUpdated()
	self.activityView:createUI()
end

function PlayerStatsView:draw()
	self.viewConfig:draw()
end

return PlayerStatsView
