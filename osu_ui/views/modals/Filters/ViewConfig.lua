local IViewConfig = require("osu_ui.views.IViewConfig")

local ui = require("osu_ui.ui")
local flux = require("flux")
local Button = require("osu_ui.ui.Button")
local Checkbox = require("osu_ui.ui.Checkbox")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.FiltersModalViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.FiltersModalViewConfig
local ViewConfig = IViewConfig + {}

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@type osu.ui.Button
local reset_button
---@type osu.ui.Button
local close_button
---@type osu.ui.Checkbox
local modded_checkbox

---@param game sphere.GameController
---@param modal osu.ui.FiltersModal
---@param assets osu.ui.OsuAssets
function ViewConfig:new(game, modal, assets)
	self.game = game
	self.modal = modal
	self.assets = assets
	text, font = assets.localization:get("filtersModal")
	assert(text, font)

	self:createUI()

	self.filterModel = game.selectModel.filterModel
	self.filters = game.configModel.configs.filters.notechart

	self.openAnimation = 0
	self.openAnimationTween = flux.to(self, 2, { openAnimation = 1 }):ease("elasticout")
end

local btn_width = 737
local btn_height = 65
local btn_spacing = 15
local red = { 0.91, 0.19, 0, 1 }
local gray = { 0.42, 0.42, 0.42, 1 }

function ViewConfig:createUI()
	local assets = self.assets
	local modal = self.modal

	local configs = self.game.configModel.configs
	local settings = configs.settings
	local ss = settings.select

	reset_button = Button(assets, {
		text = text.reset,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = red,
		font = font.buttons,
	}, function()
		local filter_model = self.filterModel
		for _, group in ipairs(self.filters) do
			for _, filter in ipairs(group) do
				filter_model:setFilter(group.name, filter.name, false)
			end
		end
		self.game.selectModel:noDebouncePullNoteChartSet()
	end)

	close_button = Button(assets, {
		text = text.close,
		pixelWidth = btn_width,
		pixelHeight = btn_height,
		color = gray,
		font = font.buttons,
	}, function()
		modal:quit()
	end)

	modded_checkbox = Checkbox(assets, {
		text = "Show modded charts",
		font = font.checkboxes,
		pixelHeight = 37,
		tip = "This will show charts that you have played with modifiers as separate charts.",
	}, function()
		return ss.chartdiffs_list
	end, function()
		ss.chartdiffs_list = not ss.chartdiffs_list
		self.game.selectModel:noDebouncePullNoteChartSet()
	end)
end

local gfx = love.graphics

local simple_mode = {
	["original input mode"] = true,
	["actual input mode"] = true,
	["format (used parser)"] = true,
	["scratch"] = true,
	["(not) played"] = true,
}

local icon_width = 64
local icon_height = 42
local icon_spacing = 28

function ViewConfig:groups()
	local filter_model = self.filterModel
	gfx.setColor(1, 1, 1)
	gfx.translate(37, 170)

	for _, group in ipairs(self.filters) do
		if not simple_mode[group.name] then
			goto continue
		end

		gfx.setFont(font.title)
		gfx.setColor(1, 1, 1)
		ui.frame(text[group.name], 0, 0, 1366, 768, "left", "top")
		gfx.push()
		gfx.translate(292, 0)

		gfx.setFont(font.groupButtons)
		for _, filter in ipairs(group) do
			local is_active = filter_model:isActive(group.name, filter.name)

			if is_active then
				gfx.setColor(0.99, 0.49, 1, 0.5)
				gfx.rectangle("fill", 0, 0, icon_width, icon_height, 5, 5)
				gfx.setColor(0.99, 0.49, 1)
				gfx.rectangle("line", 0, 0, icon_width, icon_height, 5, 5)
			else
				gfx.setColor(0.3, 0.3, 0.3, 0.5)
				gfx.rectangle("fill", 0, 0, icon_width, icon_height, 5, 5)
				gfx.setColor(1, 1, 1)
				gfx.rectangle("line", 0, 0, icon_width, icon_height, 5, 5)
			end

			gfx.setColor(1, 1, 1)
			ui.frame(text[filter.name] or filter.name:upper(), 0, 0, icon_width, icon_height, "center", "center")

			if ui.isOver(icon_width, icon_height) and ui.mousePressed(1) then
				filter_model:setFilter(group.name, filter.name, not is_active)
				filter_model:apply()
				self.game.selectModel:noDebouncePullNoteChartSet()
			end

			gfx.translate(icon_width + icon_spacing, 0)
		end
		gfx.pop()

		gfx.translate(0, icon_height + icon_spacing)
		::continue::
	end
end

function ViewConfig:resolutionUpdated()
	self:createUI()
end

function ViewConfig:draw()
	local w, h = Layout:move("base")

	gfx.push()
	gfx.setColor(1, 1, 1, 1)
	gfx.setFont(font.title)

	ui.frame(text.title, 9, 9, w - 18, h, "left", "top")

	local count = self.game.selectModel.noteChartSetLibrary.items
	local tree = self.game.selectModel.collectionLibrary.tree
	local path = tree.items[tree.selected].name

	ui.frame(("%i charts in %s"):format(#count, path), 0, 90, w, h, "center", "top")

	gfx.push()
	gfx.translate(329, 500)
	modded_checkbox:update(true)
	modded_checkbox:draw()
	gfx.pop()

	local bw, bh = reset_button:getDimensions()
	gfx.translate(w / 2 - bw / 2, 540)

	local a = self.openAnimation
	if a > 1 then
		a = 1 - (a - 1)
	end
	a = a * 50

	gfx.translate(50 - a, 0)
	reset_button:update(self.openAnimation > 0.8)
	reset_button:draw()
	gfx.translate(a - 50, btn_spacing)

	gfx.translate(-50 + a, 0)
	close_button:update(self.openAnimation > 0.8)
	close_button:draw()
	gfx.translate(-a + 50, 0)
	gfx.pop()

	self:groups()
end

return ViewConfig
