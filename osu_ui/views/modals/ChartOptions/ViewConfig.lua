local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.OsuLayout")

local ui = require("osu_ui.ui")
local flux = require("flux")

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

---@param game sphere.GameController
---@param this_modal osu.ui.ChartOptionsModal
---@param assets osu.ui.OsuAssets
function ViewConfig:new(game, this_modal, assets)
	self.game = game
	self.assets = assets
	self.thisModal = this_modal
	self.openAnimation = 0
	self.openAnimationTween = flux.to(self, 2, { openAnimation = 1 }):ease("elasticout")
	self.text = assets.localization.textGroups.chartOptionsModal
end

local btn_width = 737
local btn_height = 65
local btn_spacing = 15
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
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = green,
		font = b_font,
	}, function()
		modal.notificationView:show("Not implemented")
	end)

	export_to_osu = Button(assets, {
		text = text.exportToOsu,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = purple,
		font = b_font,
	}, function()
		self.game.selectController:exportToOsu()
		modal.notificationView:show("Exported")
	end)

	filters = Button(assets, {
		text = text.filters,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = green,
		font = b_font,
	}, function()
		self.thisModal.mainView:switchModal("osu_ui.views.modals.Filters")
	end)

	edit = Button(assets, {
		text = text.edit,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = red,
		font = b_font,
	}, function()
		self.thisModal.mainView:edit()
	end)

	file_manager = Button(assets, {
		text = text.fileManager,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = purple,
		font = b_font,
	}, function()
		self.game.selectController:openDirectory()
	end)

	cancel = Button(assets, {
		text = text.cancel,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
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

	ui.text(self.text.title:format(chart_name))

	gfx.pop()

	local bw, bh = manage_locations:getDimensions()
	local total_h = (h / 2) - (bh * 6 / 2) - (btn_spacing * 5 / 2)
	gfx.translate(w / 2 - bw / 2, total_h + 14)

	local a = self.openAnimation

	if a > 1 then
		a = 1 - (a - 1)
	end

	a = a * 50

	gfx.translate(50 - a, 0)
	manage_locations:update(true)
	manage_locations:draw()
	gfx.translate(a - 50, btn_spacing)

	gfx.translate(-50 + a, 0)
	export_to_osu:update(true)
	export_to_osu:draw()
	gfx.translate(-a + 50, btn_spacing)

	gfx.translate(50 - a, 0)
	filters:update(true)
	filters:draw()
	gfx.translate(a - 50, btn_spacing)

	gfx.translate(-50 + a, 0)
	edit:update(true)
	edit:draw()
	gfx.translate(-a + 50, btn_spacing)

	gfx.translate(50 - a, 0)
	file_manager:update(true)
	file_manager:draw()
	gfx.translate(a - 50, btn_spacing)

	gfx.translate(-50 + a, 0)
	cancel:update(true)
	cancel:draw()
	gfx.translate(-a + 50, 0)
end

return ViewConfig
