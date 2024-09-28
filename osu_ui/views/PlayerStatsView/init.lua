local ScreenView = require("osu_ui.views.ScreenView")
local ActivityView = require("osu_ui.views.PlayerStatsView.ActivityView")
local DanTableView = require("osu_ui.views.PlayerStatsView.DanTableView")
local ViewConfig = require("osu_ui.views.PlayerStatsView.ViewConfig")

---@class osu.ui.PlayerStatsView : osu.ui.ScreenView
---@operator call: osu.ui.PlayerStatsView
local PlayerStatsView = ScreenView + {}

function PlayerStatsView:load()
	self.playerProfile = self.ui.playerProfile

	self.dansInfo = self.playerProfile:getAvailableDans()
	self.selectedKeymode = "4key"
	self.selectedDanType = "regular"

	self.overallStats = self.playerProfile:getOverallStats()
	self.modeStats = self.playerProfile:getModeStats(self.selectedKeymode)
	self.activityView = ActivityView(self.assets, self.playerProfile:getActivity())
	self:createDanTableList()

	self.viewConfig = ViewConfig(self)
end

function PlayerStatsView:createDanTableList()
	self.danTableView = DanTableView(self.assets, self.playerProfile:getDanTable(self.selectedKeymode, self.selectedDanType))
end

function PlayerStatsView:resolutionUpdated()
	self.activityView:createUI()
	self.viewConfig:createUI(self)
end

function PlayerStatsView:quit()
	self:changeScreen("mainMenuView")
end

function PlayerStatsView:draw()
	self.viewConfig:draw()
end

return PlayerStatsView
