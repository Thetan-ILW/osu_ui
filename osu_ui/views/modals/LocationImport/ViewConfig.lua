local IViewConfig = require("osu_ui.views.IViewConfig")

local ui = require("osu_ui.ui")
local flux = require("flux")
local Button = require("osu_ui.ui.Button")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.LocationImportModalViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.LocationImportModalViewConfig
---@field openAnimation number
---@field openAnimationTween table?
local ViewConfig = IViewConfig + {}

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@param modal osu.ui.LocationImportModal
---@param assets osu.ui.OsuAssets
function ViewConfig:new(modal, assets)
	text, font = assets.localization:get("locationImportModal")
	assert(text and font)
	self.modal = modal
	self.assets = assets
	self:createUI()

	self.openAnimation = 0
	self.openAnimationTween = flux.to(self, 2, { openAnimation = 1 }):ease("elasticout")
end

local btn_width = 737
local btn_height = 65
local btn_spacing = 15
local green = { 0.52, 0.72, 0.12, 1 }
local gray = { 0.42, 0.42, 0.42, 1 }

---@type osu.ui.Button
local button_1
---@type osu.ui.Button
local button_2

function ViewConfig:createUI()
	local assets = self.assets
	local modal = self.modal

	local mounted = modal.locationId ~= nil

	button_1 = Button(assets, {
		text = mounted and text.yes or text.import,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = green,
		font = font.buttons,
	}, function()
		if mounted then
			self:refresh()
			return
		end
		self:import()
	end)

	button_2 = Button(assets, {
		text = mounted and text.no or text.cancel,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = gray,
		font = font.buttons,
	}, function()
		modal:quit()
	end)
end

function ViewConfig:import()
	local modal = self.modal
	local game = modal.game
	local cache_model = game.cacheModel
	local locationsRepo = cache_model.locationsRepo
	local locationManager = cache_model.locationManager

	local location = locationsRepo:insertLocation({
		name = "Songs",
		is_relative = false,
		is_internal = false,
	})
	locationManager:selectLocations()
	locationManager:selectLocation(location.id)
	locationManager:updateLocationPath(modal.path)
	game.selectController:updateCacheLocation(location.id)

	modal.processing = true
end

function ViewConfig:refresh()
	local modal = self.modal
	local game = modal.game
	game.selectController:updateCacheLocation(modal.locationId)
	modal.processing = true
end

function ViewConfig:resolutionUpdated()
	self:createUI()
end

local gfx = love.graphics

function ViewConfig:draw(modal)
	Layout:draw()
	local w, h = Layout:move("base")

	gfx.push()
	gfx.setColor(1, 1, 1, 1)
	gfx.setFont(font.title)

	ui.frame(modal.locationId and text.alreadyImported or text.importTitle, 9, 9, w - 18, h, "left", "top")

	gfx.setFont(font.directory)

	ui.frame("Directory: " .. modal.path, 0, 200, w, h, "center", "top")

	local bw, bh = button_1:getDimensions()
	gfx.translate(w / 2 - bw / 2, 400)

	local a = self.openAnimation
	if a > 1 then
		a = 1 - (a - 1)
	end
	a = a * 50

	gfx.translate(50 - a, 0)
	button_1:update(self.openAnimation > 0.8)
	button_1:draw()
	gfx.translate(a - 50, btn_spacing)

	gfx.translate(-50 + a, 0)
	button_2:update(self.openAnimation > 0.8)
	button_2:draw()
	gfx.translate(-a + 50, 0)

	gfx.pop()
end

return ViewConfig
