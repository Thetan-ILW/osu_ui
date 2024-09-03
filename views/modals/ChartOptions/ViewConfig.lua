local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.OsuLayout")

local ui = require("osu_ui.ui")

---@type table<string, love.Font>
local font

local Button = require("osu_ui.ui.Button")

---@class osu.ui.ChartOptionsModalViewConfig: osu.ui.IViewConfig
---@operator call: osu.ui.ChartOptionsModalViewConfig
---@field assets osu.ui.OsuAssets
local ViewConfig = IViewConfig + {}

local gfx = love.graphics

local manage_locations ---@type osu.ui.Button
local export_to_osu ---@type osu.ui.Button
local filters ---@type osu.ui.Button
local edit ---@type osu.ui.Button
local file_manager ---@type osu.ui.Button
local cancel ---@type osu.ui.Button

local open_time = 0

---@param game sphere.GameController
---@param this_modal osu.ui.ChartOptionsModal
---@param assets osu.ui.OsuAssets
function ViewConfig:new(game, this_modal, assets)
	self.game = game
	self.assets = assets
	self.thisModal = this_modal
	open_time = love.timer.getTime()
end

local scale = 0.9
local width = 2.76
local green = { 0.52, 0.72, 0.12, 1 }
local purple = { 0.72, 0.4, 0.76, 1 }
local red = { 0.91, 0.19, 0, 1 }
local gray = { 0.42, 0.42, 0.42, 1 }

function ViewConfig:loadUI()
	local assets = self.assets

	font = assets.localization.fontGroups.chartOptionsModal
	local text = assets.localization.textGroups.chartOptionsModal

	local b_font = font.buttons

	local modal = self.thisModal
	manage_locations = Button(assets, {
		text = text.manageLocations,
		scale = scale,
		width = width,
		color = green,
		font = b_font,
	}, function()
		modal.notificationView:show("Not implemented")
	end)

	export_to_osu = Button(assets, {
		text = text.exportToOsu,
		scale = scale,
		width = width,
		color = purple,
		font = b_font,
	}, function()
		self.game.selectController:exportToOsu()
		modal.notificationView:show("Exported")
	end)

	filters = Button(assets, {
		text = text.filters,
		scale = scale,
		width = width,
		color = green,
		font = b_font,
	}, function()
		modal.notificationView:show("Not implemented")
	end)

	edit = Button(assets, {
		text = text.edit,
		scale = scale,
		width = width,
		color = red,
		font = b_font,
	}, function()
		self.thisModal.mainView:edit()
	end)

	file_manager = Button(assets, {
		text = text.fileManager,
		scale = scale,
		width = width,
		color = purple,
		font = b_font,
	}, function()
		self.game.selectController:openDirectory()
	end)

	cancel = Button(assets, {
		text = text.cancel,
		scale = scale,
		width = width,
		color = gray,
		font = b_font,
	}, function()
		self.thisModal:quit()
	end)
end

function ViewConfig:resolutionUpdated()
	self:loadUI()
end

function ViewConfig:draw(view)
	Layout:draw()
	local w, h = Layout:move("base")

	gfx.push()
	gfx.translate(9, 9)
	gfx.setColor({ 1, 1, 1, 1 })
	gfx.setFont(font.title)

	---@type table
	local chartview = view.game.selectModel.chartview
	local chart_name = "No chart"

	if chartview then
		chart_name = string.format("%s - %s [%s]", chartview.artist, chartview.title, chartview.name)
	end

	ui.text(("%s\nWhat do you want to do with this chart?"):format(chart_name))

	gfx.pop()

	local bw, bh = manage_locations:getDimensions()
	local total_h = (h / 2) - ((bh / 2) * 6)
	gfx.translate(w / 2 - bw / 2, 10 + total_h)

	local a = ui.easeOutCubic(open_time, 1) * 50

	gfx.translate(50 - a, 0)
	manage_locations:update(true)
	manage_locations:draw()
	gfx.translate(a - 50, 0)

	gfx.translate(-50 + a, 0)
	export_to_osu:update(true)
	export_to_osu:draw()

	gfx.translate(-a + 50, 0)

	gfx.translate(50 - a, 0)
	filters:update(true)
	filters:draw()
	gfx.translate(a - 50, 0)

	gfx.translate(-50 + a, 0)
	edit:update(true)
	edit:draw()
	gfx.translate(-a + 50, 0)

	gfx.translate(50 - a, 0)
	file_manager:update(true)
	file_manager:draw()
	gfx.translate(a - 50, 0)

	gfx.translate(-50 + a, 0)
	cancel:update(true)
	cancel:draw()
	gfx.translate(-a + 50, 0)
end

return ViewConfig
