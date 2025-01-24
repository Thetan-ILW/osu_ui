local Component = require("ui.Component")
local CanvasComponent = require("ui.CanvasComponent")
local Label = require("ui.Label")
local Image = require("ui.Image")
local Hotkey = require("osu_ui.views.modals.Inputs.Hotkey")
local flux = require("flux")

---@class osu.ui.InputMap : ui.Component
---@operator call: osu.ui.InputMap
---@field inputModel sphere.InputModel
---@field inputs string[]
---@field mode string
local InputMap = Component + {}

local key_width = 60
local key_height = 50
local key_spacing = 4

local key_colors = {
	white = { 1, 1, 1 },
	pink = { 0.99, 0.49, 1 },
	yellow = { 1, 0.87, 0.24 },
}

local key_colors_tinted = {
	white = { 0.65, 0.65, 0.65 },
	pink = { 0.69, 0.34, 0.7 },
	yellow = { 0.71, 0.62, 0.17 },
}

local key_color_names = {
	"white",
	"pink",
	"yellow",
}

local predefined_colors = {
	{
		"yellow",
	},
	{
		"white",
		"pink",
	},
	{

		"white",
		"pink",
		"white",
	},
	{
		"white",
		"pink",
		"pink",
		"white",
	},
	{
		"white",
		"pink",
		"yellow",
		"pink",
		"white",
	},
	{
		-- 6key
	},
	{
		"white",
		"pink",
		"white",
		"yellow",
		"white",
		"pink",
		"white",
	},
}

function InputMap:load()
	self.colors = {} ---@type string[]
	self.names = {} ---@type string[]
	self.keyCount = #self.inputs

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.fonts = scene.fontManager

	local keys = 0
	local scratches = 0

	for _, v in ipairs(self.inputs) do
		if v:find("key") then
			keys = keys + 1
		elseif v:find("scratch") then
			scratches = scratches + 1
		end
	end

	local struct = 0
	local symetrical = keys % 2 == 0
	if keys < 5 then
		struct = (keys - 1) % 4 + 1
	elseif keys % 5 == 0 then
		struct = 5
	elseif keys % 6 == 0 then
		struct = 3
	elseif keys % 7 == 0 then
		struct = 7
	else
		struct = symetrical and 4 or 3
	end

	local repetitions = keys / struct

	local key = 1
	for _ = 1, repetitions do
		for _, color in ipairs(predefined_colors[struct]) do
			table.insert(self.colors, color)
			table.insert(self.names, ("%iK"):format(key))
			key = key + 1
		end
	end

	if not symetrical then
		self.colors[math.ceil(keys / 2)] = "yellow"
	end

	for i = 1, scratches do
		table.insert(self.colors, key_color_names[3])
		table.insert(self.names, ("%iS"):format(i))
	end

	if #self.colors ~= keys + scratches then
		self.colors = {}
		self.names = {}
		for i = 1, keys do
			table.insert(self.colors, key_color_names[i % 2 + 1])
			table.insert(self.names, ("%iK"):format(i))
		end
		for i = 1, scratches do
			table.insert(self.colors, key_color_names[3])
			table.insert(self.names, ("%iS"):format(i))
		end
	end

	self.arrow = self:addChild("arrow", Image({
		origin = { x = 0.5 },
		image = scene.assets:loadImage("inputs-arrow"),
	}))

	self:calcRows()
	self.height = (self.rows + 1) * key_height

	self.focusRow = 1
	self.focusColumn = 1

	self:buildMap()

	---@type table<string, boolean>
	self.keyState = {}

end

function InputMap:buildMap()
	self.width = key_width * self.keyCount + (key_spacing * (self.keyCount - 1))
	local height = (self.rows + 1) * key_height

	self.arrow.y = height
	self:removeChild("mapCanvas")
	self:removeChild("cellsContainer")
	local container = self:addChild("cellsContainer", Component({ z = 1 }))
	self.cellsContainer = container

	local map = self:addChild("mapCanvas", CanvasComponent({
		width = self.width,
		height = height,
		redrawEveryFrame = false,
	}))

	local gfx = love.graphics
	map:addChild("map", Component({
		draw = function ()
			local colors = self.colors
			local rows = self.rows
			for _, v in ipairs(colors) do
				local ct = key_colors_tinted[v]
				local c = key_colors[v]
				gfx.setColor(ct)
				gfx.rectangle("fill", 0, 0, key_width, key_height * (rows + 1), 4, 4)
				gfx.rectangle("line", 0, 0, key_width, key_height * (rows + 1), 4, 4)
				gfx.setColor(c)
				gfx.rectangle("fill", 0, rows * key_height, key_width, key_height, 4, 4)
				gfx.rectangle("line", 0, rows * key_height, key_width, key_height, 4, 4)
				gfx.setColor(0, 0, 0)
				gfx.translate(key_width + key_spacing, 0)
			end
		end
	}))

	local binds_count = self.inputModel:getBindsCount(self.mode)
	local font = self.fonts:loadFont("Regular", 20)
	for i, v in ipairs(self.names) do
		map:addChild(v, Label({
			x = (key_width + key_spacing) * (i - 1),
			y = self.rows * key_height,
			boxWidth = key_width,
			boxHeight = key_height,
			alignX = "center",
			alignY = "center",
			font = font,
			text = v,
			color = { 0, 0, 0, 1 },
			z = 1,
		}))
	end

	for i = 1, self.keyCount do
		local virtual_key = self.inputs[i]
		for j = 1, binds_count + 1 do
			local _key = self.inputModel:getKey(self.mode, virtual_key, j)
			self.cellsContainer:addChild(("%i_%i"):format(i, j), Hotkey({
				x = (key_width + key_spacing) * (i - 1),
				y = key_height * (binds_count - j + 1),
				width = key_width,
				height = key_height,
				row = j,
				column = i,
				virtualKey = virtual_key,
				key = tostring(_key or ""),
				z = 1,
				selected = function(column, row)
					self:setFocus(column, row)
				end,
				cleared = function(column, row)
					self:clear(column, row)
				end
			}))
		end
	end

	self:setFocus(self.focusColumn, self.focusRow)
end

function InputMap:setFocus(column, row)
	self.focusColumn = column
	self.focusRow = row

	for _, v in pairs(self.cellsContainer.children) do
		---@cast v osu.ui.InputsModal.Hotkey
		v.focus = false
	end

	flux.to(self.arrow, 0.23, { x = (key_width + key_spacing) * (self.focusColumn - 1) + key_width / 2 }):ease("sineout")
	if self.focusColumn > self.keyCount then
		flux.to(self.arrow, 0.23, { alpha = 0 }):ease("sineout")
	else
		flux.to(self.arrow, 0.23, { alpha = 1 }):ease("sineout")
	end

	local cell = self.cellsContainer:getChild(("%i_%i"):format(column, row))
	if not cell then
		return
	end

	---@cast cell osu.ui.InputsModal.Hotkey
	cell.focus = true
end

function InputMap:clear(column, row)
	local cell = self.cellsContainer:getChild(("%i_%i"):format(column, row))
	if not cell then
		return
	end
	---@cast cell osu.ui.InputsModal.Hotkey
	local prev_rows = self.inputModel:getBindsCount(self.mode)
	self.inputModel:setKey(self.mode, cell.virtualKey, cell.row)
	cell:replaceText("")

	if prev_rows ~= self.inputModel:getBindsCount(self.mode) then
		self:calcRows()
		self:buildMap()
		self.y = self.y + key_height
		flux.to(self, 0.4, { y = self.parent.height / 2, height = (self.rows + 1) * key_height }):ease("cubicout")
	end
end

function InputMap:calcRows()
	self.rows = math.min(self.inputModel:getBindsCount(self.mode) + 1, 6)
end

---@param event table
function InputMap:inputchanged(event)
	local device, id, key, state = event[1], event[2], event[3], event[4]

	if key == "escape" then
		return
	end

	if self.keyState[key] and not state then
		self.keyState[key] = false
		return
	elseif not self.keyState[key] and state then
		self.keyState[key] = true
	elseif self.keyState[key] and state then
		return
	end

	local cell = self.cellsContainer:getChild(("%i_%i"):format(self.focusColumn, self.focusRow))
	if not cell then
		return
	end
	---@cast cell osu.ui.InputsModal.Hotkey

	local prev_rows = self.inputModel:getBindsCount(self.mode)
	self.inputModel:setKey(self.mode, cell.virtualKey, cell.row, device, id, key)
	local _key = self.inputModel:getKey(self.mode, cell.virtualKey, cell.row)
	local text = tostring(_key or "")
	cell:replaceText(text)
	self:setFocus(self.focusColumn + 1, self.focusRow)

	if prev_rows ~= self.inputModel:getBindsCount(self.mode) then
		self:calcRows()
		self:buildMap()
		self.y = self.y - key_height
		flux.to(self, 0.4, { y = self.parent.height / 2, height = (self.rows + 1) * key_height }):ease("cubicout")
	end
end

function InputMap:updateSize()
end

return InputMap
