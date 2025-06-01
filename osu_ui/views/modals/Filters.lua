local Modal = require("osu_ui.views.modals.Modal")

local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local HoverState = require("ui.HoverState")
local Combo = require("osu_ui.ui.Combo")
local TextBox = require("osu_ui.ui.TextBox")

local flux = require("flux")

---@class osu.ui.FiltersModal : osu.ui.Modal
---@operator call: osu.ui.FiltersModal
local Filters = Modal + {}

local cell_width = 64
local cell_height = 44
local cell_start_x = 292
local cell_spacing_x = 20
local cell_spacing_y = 20

local allowed_groups = {
	["original input mode"] = true,
	["actual input mode"] = true,
	["format"] = true,
	["scratch"] = true,
	["(not) played"] = true,
}

function Filters:close()
	Modal.close(self)

	local lamp_tb = self.lampTextBox ---@cast lamp_tb osu.ui.TextBox
	self.selectApi:getConfigs().select.lampString = lamp_tb.input

	for group_name, group in pairs(self.changes) do
		for filter_name, filter_state in pairs(group) do
			self.selectApi:setNoteChartFilter(group_name, filter_name, filter_state)
		end
	end

	self.selectApi:applyNoteChartFilters()
end

function Filters:load()
	self:getViewport():listenForResize(self)
	self.width, self.height = self.parent:getDimensions()

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text
	local assets = scene.assets
	self.fonts = scene.fontManager
	self.hoverSound = assets:loadAudio("click-short")
	self.checkOnSound = assets:loadAudio("check-on")
	self.checkOffSound = assets:loadAudio("check-off")

	self:initModal(text.FiltersModal_Title)

	local select_api = scene.ui.selectApi
	local notechart_filters = select_api:getNoteChartFilters()
	self.selectApi = select_api

	---@type table<string, {[string]: boolean}>
	self.changes = {}

	local g_localization = {
		["original input mode"] = text.FiltersModal_OriginalMode,
		["actual input mode"] = text.FiltersModal_ActualMode,
		["format"] = text.FiltersModal_Format,
		["scratch"] = text.FiltersModal_Scratch,
		["(not) played"] = text.FiltersModal_Played,
	}
	local f_localization = {
		["played"] = text.General_Yes,
		["not played"] = text.General_No,
		["has scratch"] = text.General_Yes,
		["has not scratch"] = text.General_No,
		["sphere"] = "sph",
		["stepmania"] = "sm",
		["o2jam"] = "ojn",
		["quaver"] = "qua"
	}

	local added_columns = 0
	for column, group in ipairs(notechart_filters) do
		if allowed_groups[group.name] then
			self.container:addChild(group.name, Label({
				x = 37,
				y = added_columns * (cell_height + cell_spacing_y),
				text = g_localization[group.name],
				font = self.fonts:loadFont("Light", 33),
				origin = { y = 0.5 }
			}))
			for row, filter in ipairs(group) do
				self.container:addChild(row .. column, self:checkbox(
					row,
					added_columns,
					f_localization[filter.name] or filter.name,
					select_api:isNoteChartFilterActive(group.name, filter.name),
					function(state)
						self.changes[group.name] = self.changes[group.name] or {}
						self.changes[group.name][filter.name] = state
					end
				))
			end
			added_columns = added_columns + 1
		end
	end

	local settings_select = select_api:getConfigs().settings.select
	local chartview_table_items = {
		"chartviews",
		"chartdiffviews",
		"chartplayviews"
	}

	local table_label = self.container:addChild("chartviewTableLabel", Label({
		x = self.parent:getWidth() / 2 - 360, y = 300,
		boxHeight = 30,
		alignY = "center",
		font = self.fonts:loadFont("Bold", 18),
		text = text.FiltersModal_DisplayMode,
	}))

	self.container:addChild("chartviewTable", Combo({
		x = table_label.x + table_label:getWidth() + 10, y = 300,
		width = 200, height = 37,
		items = chartview_table_items,
		borderColor = { 0.57, 0.76, 0.9, 1 },
		hoverColor = { 0.57, 0.76, 0.9, 1 },
		z = 1,
		getValue = function()
			return settings_select.chartviews_table
		end,
		setValue = function(i)
			settings_select.chartviews_table = chartview_table_items[i]
		end,
		format = function(v)
			if v == "chartviews" then
				return text.FiltersModal_BeatmapsMode
			elseif v == "chartdiffviews" then
				return text.FiltersModal_ModdedMode
			elseif v == "chartplayviews" then
				return text.FiltersModal_PlayedMode
			end
			return v
		end
	}))

	local select = select_api:getConfigs().select
	self.lampTextBox = self.container:addChild("lamp", TextBox({
		x = self.parent:getWidth() / 2 + 360, y = 300,
		origin = { x = 1 },
		width = 200,
		input = select.lampString
	}))
	self.container:addChild("lampLabel", Label({
		x = self.lampTextBox.x - self.lampTextBox:getWidth() - 10, y = 300,
		origin = { x = 1 },
		boxHeight = 30,
		alignY = "center",
		font = self.fonts:loadFont("Bold", 18),
		text = text.FiltersModal_Lamp,
	}))

	self:addOption(text.FiltersModal_ResetFilters, self.buttonColors.red, function ()
	end)
	self:addOption(text.General_Cancel, self.buttonColors.gray, function ()
		self:close()
	end)
end

---@param row number
---@param column number
---@param label string
---@param is_active boolean
---@param on_click fun(state: boolean)
---@return ui.Component
function Filters:checkbox(row, column, label, is_active, on_click)
	local w = cell_width
	local h = cell_height

	---@class osu.ui.FiltersModal.Checkbox : ui.Component
	---@field tween table?
	---@field hoverState ui.HoverState
	local c = Component({
		x = (w / 2) + cell_start_x + (row - 1) * (w + cell_spacing_x),
		y = column * (h + cell_spacing_y),
		origin = { x = 0.5, y = 0.5 },
		hoverState = HoverState("elasticout", 0.5),
		animationProgress = 0,
		---@param this osu.ui.FiltersModal.Checkbox
		update = function(this)
			this.scaleX = 1 + (this.hoverState.progress * 0.05) + (this.animationProgress * 0.1)
			this.scaleY = 1 + (this.hoverState.progress * 0.05) + (this.animationProgress * 0.1)
			this.angle = this.animationProgress * 0.1
		end,
		animation = function(this)
			if this.tween then
				this.tween:stop()
			end
			if is_active then
				this.tween = flux.to(this, 0.7, { animationProgress = 1 }):ease("elasticout")
				this.color = { 0.99, 0.49, 1, 1 }
			else
				this.tween = flux.to(this, 0.7, { animationProgress = 0 }):ease("elasticout")
				this.color = { 0.8, 0.8, 0.8, 1 }
			end
		end,
		---@param this osu.ui.FiltersModal.Checkbox
		setMouseFocus = function(this, mx, my)
			this.mouseOver = this.hoverState:checkMouseFocus(this.width, this.height, mx, my)
		end,
		noMouseFocus = function(this)
			this.mouseOver = false
			this.hoverState:loseFocus()
		end,
		mousePressed = function(this)
			if not this.mouseOver then
				return false
			end
			is_active = not is_active
			on_click(is_active)
			this:animation()
			self.playSound(is_active and self.checkOnSound or self.checkOffSound)
			return true
		end,
		justHovered = function()
			self.playSound(self.hoverSound)
		end
	})

	c:animation()

	c:addChild("border", Rectangle({
		width = w,
		height = h,
		mode = "line",
		lineWidth = 3,
		rounding = 5,
		color = { 0.8, 0.8, 0.8, 1 },
		z = 0.5,
	}))

	c:addChild("background", Rectangle({
		width = w,
		height = h,
		rounding = 5,
		color = { 0, 0, 0, 0.5 },
		blockMouseFocus = true,
	}))
	c:autoSize()

	c:addChild("label", Label({
		boxWidth = w,
		boxHeight = h,
		alignX = "center",
		alignY = "center",
		font = self.fonts:loadFont("Regular", 24),
		text = label,
		z = 1,
	}))

	return c
end

return Filters
