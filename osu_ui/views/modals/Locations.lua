local Modal = require("osu_ui.views.modals.Modal")
local ListView = require("osu_ui.views.ListView")
local Button = require("osu_ui.ui.Button")
local Textbox = require("osu_ui.ui.TextBox")
local ImageButton = require("osu_ui.ui.ImageButton")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local Component = require("ui.Component")
local Image = require("ui.Image")
local ChartImport = require("osu_ui.views.ChartImport")

local flux = require("flux")

---@class osu.ui.LocationsModal : osu.ui.Modal
---@operator call: osu.ui.LocationsModal
local Locations = Modal + {}

function Locations:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text
	self.fonts = scene.fontManager

	self.width, self.height = self.parent:getDimensions()

	self.selectApi = scene.ui.selectApi
	self.locationsApi = scene.ui.locationsApi
	self.locationsUpdated = false
	self.otherGames = scene.ui.otherGames

	---@type {[integer]: ui.Component}
	self.locationCells = {}

	self:getViewport():listenForResize(self)
	self:initModal(text.LocationsModal_Title)

	local list_width = 400
	local options_width = 500
	local total_width = list_width + options_width

	local spacing = 20
	local list_component = self.container:addChild("listComponent", Component({
		x = (self.width - total_width - spacing) / 2,
		width = list_width,
		height = 370,
	}))

	local list = list_component:addChild("locations", ListView({
		width = list_component:getWidth(),
		height = list_component:getHeight(),
		rows = 8,
		z = 0.1,
		stencilFunction = function()
			love.graphics.rectangle("fill", 0, 0, list_component:getWidth(), list_component:getHeight(), 5, 5)
		end
	})) ---@cast list osu.ui.ListView
	self.list = list
	list_component:addChild("border", Rectangle({
		width = list:getWidth(),
		height = list:getHeight(),
		rounding = 5,
		lineWidth = 2,
		mode = "line",
		color = { 0.89, 0.47, 0.56 },
		z = 0.2
	}))
	list_component:addChild("background", Rectangle({
		width = list:getWidth(),
		height = list:getHeight(),
		rounding = 5,
		color = { 0, 0, 0, 0.7 }
	}))

	local options_component = self.container:addChild("options", Component({
		x = (self.width + total_width + spacing) / 2,
		origin = { x = 1 },
		width = options_width,
		height = 370,
	}))
	options_component:addChild("border", Rectangle({
		width = options_component:getWidth(),
		height = options_component:getHeight(),
		rounding = 5,
		lineWidth = 2,
		mode = "line",
		color = { 0.89, 0.47, 0.56 },
		z = 0.2
	}))
	options_component:addChild("background", Rectangle({
		width = options_component:getWidth(),
		height = options_component:getHeight(),
		rounding = 5,
		color = { 0, 0, 0, 0.7 }
	}))

	self.info = options_component:addChild("info", Component({ z = 1 }))

	self.info:addChild("changeName", Label({
		x = 16, y = 10,
		font = self.fonts:loadFont("Regular", 18),
		text = text.LocationsModal_ChangeName,
	}))

	self.textBox = self.info:addChild("textBox", Textbox({
		x = 10, y = 38,
		width = options_component:getWidth() - 20,
		height = 24,
		font = self.fonts:loadFont("Regular", 20),
		changed = function(input)
			local id = self.locationsApi:getSelectedLocationId()
			local cell = self.locationCells[id]
			if cell then
				local label = cell:getChild("label") ---@cast label ui.Label
				label:replaceText(input)
				self.locationsApi:changeName(input)
				self.locationsUpdated = true
			end
		end
	}))

	self.infolabel = self.info:addChild("infolabel", Label({
		x = 10, y = 80,
		font = self.fonts:loadFont("Regular", 20),
		boxWidth = options_component:getWidth() - 10,
		text = "",
		z = 1,
	}))

	local update = self.info:addChild("update", Button({
		x = 10,
		y = options_component:getHeight() - 10,
		width = options_component:getWidth() - 20,
		height = 40,
		origin = { y = 1 },
		font = self.fonts:loadFont("Regular", 20),
		color = self.buttonColors.green,
		label = text.LocationsModal_Update,
		z = 1,
		onClick = function ()
			scene:addChild("chartImport", ChartImport({ z = 0.6 }))
		end
	}))
	self.info:addChild("openFolder", Button({
		x = 10,
		y = options_component:getHeight() - update:getHeight() - 15,
		width = options_component:getWidth() - 20,
		height = 40,
		origin = { y = 1 },
		font = self.fonts:loadFont("Regular", 20),
		color = self.buttonColors.blue,
		label = text.LocationsModal_OpenFolder,
		z = 1,
		onClick = function()
			local loc = self.locationsApi:getSelectedLocation()
			love.system.openURL(loc.path or "")
		end
	}))

	self.dropChartHere = options_component:addChild("dropFolderImage", Image({
		x = options_component:getWidth() / 2,
		y = options_component:getHeight() / 2,
		origin = { x = 0.5, y = 0.5 },
		image = scene.assets:loadImage("drop-chart-folder"),
		alpha = 0,
		z = 0.9,
	}))
	self.dropChartHere:addChild("dropFolderLabel", Label({
		y = 27,
		boxWidth = options_component:getWidth(),
		boxHeight = 130,
		alignX = "center",
		alignY = "center",
		text = text.LocationsModal_DropFolderHere,
		font = self.fonts:loadFont("Regular", 24),
		z = 1,
	}))

	local add = list_component:addChild("addButton", ImageButton({
		x = list_component:getWidth() - 5,
		y = list_component:getHeight() - 5,
		idleImage = scene.assets:loadImage("add"),
		hoverImage = scene.assets:loadImage("add-over"),
		origin = { x = 1, y = 1 },
		z = 1,
		onClick = function ()
			self.locationsApi:createLocation()
			self:addItemsToList()
			self.list:scrollToCell(math.max(0, #self.locationsApi:getLocations() - self.list.rows))
			self.locationsUpdated = true
		end
	}))

	list_component:addChild("removeButton", ImageButton({
		x = list_component:getWidth() - add:getWidth() - 10,
		y = list_component:getHeight() - 5,
		idleImage = scene.assets:loadImage("trash"),
		hoverImage = scene.assets:loadImage("trash-over"),
		origin = { x = 1, y = 1 },
		z = 1,
		blockMouseFocus = true,
		onClick = function()
			if not (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
				scene.notification:show(text.LocationsModal_HoldShiftToRemove)
				return true
			end
			local loc = self.locationsApi:getSelectedLocation()
			if loc.is_internal then
				scene.notification:show(text.LocationsModal_CantRemoveInternal)
				return true
			end
			pcall(function ()
				self.locationsApi:deleteLocation(self.locationsApi:getSelectedLocationId())
			end)
			self:addItemsToList()
			self.locationsUpdated = true
			return true
		end
	}))

	self:addOption(text.LocationsModal_UpdateAll, self.buttonColors.green, function ()
		scene:addChild("chartImport", ChartImport({ z = 0.6, cacheAll = true }))
	end)


	local has_other_games = false
	for k, v in pairs(self.otherGames.games) do
		has_other_games = true
		break
	end

	if has_other_games then
		self:addOption(text.LocationsModal_AddOtherGames, self.buttonColors.purple, function ()
			self:addOtherGames()
		end)
	end

	self:addOption(text.General_Cancel, self.buttonColors.gray, function ()
		self:close()
	end)

	self:addItemsToList()
end

function Locations:addOtherGames()
	local added = 0
	for game_name, path in pairs(self.otherGames.games) do
		local items = self.locationsApi:getLocations()
		local exists = false

		for i, v in ipairs(items) do
			if path == v.path then
				exists = true
				break
			end
		end

		if not exists then
			self.locationsApi:createLocation()
			self.locationsApi:changeName(game_name)
			self.locationsApi:changePath(path)
			added = added + 1
			self.locationsUpdated = true
		end
	end

	self:addItemsToList()
	self:updateInfo()
end

function Locations:close()
	if not self.mouseOver then
		return
	end
	Modal.close(self)

	if self.locationsUpdated then
		self:getViewport():triggerEvent("event_locationsUpdated")
		self.selectApi:reloadCollections()
		self.selectApi:debouncePullNoteChartSet()
	end
end

function Locations:directorydropped(event)
	self.locationsApi:changePath(event[1])
	self:updateInfo()
end

function Locations:updateInfo()
	local loc = self.locationsApi:getSelectedLocation()
	local info_label = self.infolabel ---@cast info_label ui.Label
	local text_box = self.textBox ---@cast text_box osu.ui.TextBox

	if not loc.path then
		flux.to(self.info, 0.3, { alpha = 0 }):ease("cubicout")
		flux.to(self.dropChartHere, 0.3, { alpha = 1 }):ease("cubicout")
		self.info.handleEvents = false
		self.dropChartHere.handleEvents = true
		return
	end

	flux.to(self.dropChartHere, 0.3, { alpha = 0 }):ease("cubicout")
	flux.to(self.info, 0.3, { alpha = 1 }):ease("cubicout")
	self.info.handleEvents = true
	self.dropChartHere.handleEvents = false

	local info = self.locationsApi:getLocationInfo()
	info_label:replaceText(("Path: %s\nFiles: %i\nSets: %i"):format(loc.path, info.chartfiles, info.chartfile_sets))
	text_box:setInput(loc.name)
end

local selected_color = { 0.39, 0.72, 0.92, 0.4 }

function Locations:addItemsToList()
	self.list:removeCells()

	local items = self.locationsApi:getLocations()

	for i, v in ipairs(items) do
		local cell = Component({
			width = self.list:getWidth(),
			height = self.list:getCellHeight(),
			blockMouseFocus = true,
			mouseClick = function(this)
				if this.mouseOver then
					self.locationsApi:selectLocation(v.id)
					self:updateInfo()
					return true
				end
			end
		})

		local bg_color = self.list:getCellBackgroundColor()
		cell:addChild("background", Rectangle({
			width = cell:getWidth(),
			height = cell:getHeight(),
			color = bg_color,
			update = function(this)
				if self.locationsApi:getSelectedLocationId() == v.id then
					this.color = selected_color
				else
					this.color = bg_color
				end
			end
		}))

		cell:addChild("label", Label({
			x = 10,
			font = self.fonts:loadFont("Regular", 24),
			text = v.name,
			boxWidth = cell:getWidth(),
			boxHeight = cell:getHeight(),
			alignY = "center",
			z = 1,
		}))

		self.list:addCell(cell)
		self.locationCells[v.id] = cell
	end

	self:updateInfo()
end

return Locations
