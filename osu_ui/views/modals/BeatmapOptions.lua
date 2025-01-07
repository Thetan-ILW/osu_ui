local Modal = require("osu_ui.views.modals.Modal")

---@class osu.ui.BeatmapOptionsModal : osu.ui.Modal
---@operator call: osu.ui.BeatmapOptionsModal
local BeatmapOptions = Modal + {}

function BeatmapOptions:load()
	self:getViewport():listenForResize(self)
	self.width, self.height = self.parent:getDimensions()

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	local select_api = scene.ui.selectApi
	local chartview = select_api:getChartview()

	self:initModal(text.SongSelection_ThisBeatmap:format(
		("%s - %s [%s]"):format(chartview.artist, chartview.title, chartview.name)
	))

	self:addOption(text.SongSelection_Collection, self.buttonColors.green, function ()
		self:close()
		scene:openModal("locations")
	end)
	self:addOption(text.SongSelection_ExportToOsu, self.buttonColors.purple, function ()
		select_api:exportOsuChart()
		scene.notification:show(text.SongSelection_OsuExported)
	end)
	self:addOption(text.SongSelection_Filters, self.buttonColors.green, function ()
		self:close()
		scene:openModal("filters")
	end)
	self:addOption(text.SongSelection_Edit, self.buttonColors.red, function ()
		scene.notification:show("Not implemented")
	end)
	self:addOption(text.SongSelection_OpenInFileManager, self.buttonColors.purple, function ()
		select_api:openChartDirectory()
	end)
	self:addOption(text.General_Cancel, self.buttonColors.gray, function ()
		self:close()
	end)
end

return BeatmapOptions

