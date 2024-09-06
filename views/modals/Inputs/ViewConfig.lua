local IViewConfig = require("osu_ui.views.IViewConfig")

local ui = require("osu_ui.ui")
local just = require("just")
local flux = require("flux")
local math_util = require("math_util")
local BackButton = require("osu_ui.ui.BackButton")
local Combo = require("osu_ui.ui.Combo")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.InputsModalViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.InputsModalViewConfig
---@field arrowTween table?
---@field targetArrowPosition number
---@field arrowPosition number
---@field heightTween table?
local ViewConfig = IViewConfig + {}

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@type love.Image
local arrow_img
---@type osu.ui.Combo
local modes_combo
---@type osu.ui.BackButton
local back_button

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
---@param modal osu.ui.Modal
function ViewConfig:new(game, assets, modal)
	text, font = assets.localization:get("inputsModal")
	assert(text and font)
	self.game = game
	self.assets = assets
	self.modal = modal
	self.currentMode = self.modal.inputMode
	self.inputModel = self.game.inputModel
	self:updateKeys()
	self:createUI()
	arrow_img = assets.images.inputsArrow
end

local modes = {
	"1key",
	"2key",
	"3key",
	"4key",
	"5key",
	"6key",
	"7key",
	"7key1scratch",
	"8key",
	"9key",
	"10key",
	"12key",
	"12key2scratch",
	"14key",
	"14key2scratch",
	"16key",
	"16key2scratch",
}

function ViewConfig:createUI()
	local assets = self.assets
	local modal = self.modal
	local input_model = self.inputModel

	modes_combo = Combo(assets, {
		label = "",
		font = font.combos,
		pixelWidth = 300,
		pixelHeight = 37,
	}, function()
		return self.currentMode, modes
	end, function(v)
		self.currentMode = v
		self.inputs = input_model:getInputs(v)
		self:updateKeys()
	end)

	back_button = BackButton(assets, { w = 93, h = 90 }, function()
		self.modal:quit()
	end)
end

local key_width = 50
local key_height = 50
local key_spacing = 4

local colors = {
	white = { 1, 1, 1 },
	pink = { 0.99, 0.49, 1 },
	yellow = { 1, 0.87, 0.24 },
}

local colors_tinted = {
	white = { 0.65, 0.65, 0.65 },
	pink = { 0.69, 0.34, 0.7 },
	yellow = { 0.71, 0.62, 0.17 },
}

local key_colors = {
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

function ViewConfig:updateKeys()
	self.inputs = self.inputModel:getInputs(self.currentMode)
	self.bindFocus = { row = 1, key = 1 }

	self.arrowPosition = 1
	if self.arrowTween then
		self.arrowTween:stop()
	end

	local rows = math.min(self.inputModel:getBindsCount(self.currentMode) + 1, 6)
	self.visualHeight = rows * key_height

	self.colors = {}
	self.names = {}

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
	for r = 1, repetitions do
		for i, color in ipairs(predefined_colors[struct]) do
			table.insert(self.colors, color)
			table.insert(self.names, ("%iK"):format(key))
			key = key + 1
		end
	end

	if not symetrical then
		self.colors[math.ceil(keys / 2)] = "yellow"
	end

	for i = 1, scratches do
		table.insert(self.colors, key_colors[3])
		table.insert(self.names, ("%iS"):format(i))
	end

	if #self.colors ~= keys + scratches then
		self.colors = {}
		self.names = {}
		for i = 1, keys do
			table.insert(self.colors, key_colors[i % 2 + 1])
			table.insert(self.names, ("%iK"):format(i))
		end
		for i = 1, scratches do
			table.insert(self.colors, key_colors[3])
			table.insert(self.names, ("%iS"):format(i))
		end
	end
end

local gfx = love.graphics

function ViewConfig:keysBackground(rows)
	for i, v in ipairs(self.colors) do
		gfx.setColor(colors_tinted[v])
		gfx.rectangle("fill", 0, -key_height * rows, key_width, key_height * (rows + 1), 4, 4)
		gfx.rectangle("line", 0, -key_height * rows, key_width, key_height * (rows + 1), 4, 4)
		gfx.setColor(colors[v])
		gfx.rectangle("fill", 0, 0, key_width, key_height, 4, 4)
		gfx.rectangle("line", 0, 0, key_width, key_height, 4, 4)
		gfx.setColor(0, 0, 0)
		ui.frame(self.names[i], 0, 0, key_width, key_height, "center", "center")
		gfx.translate(key_width + key_spacing, 0)
	end
end

local function getKey()
	local changed = false
	local key, device, device_id
	local k, dev, dev_id = just.next_input("pressed")
	if just.keypressed("escape", true) then
		return false
	end
	if k then
		key, device, device_id = k, dev, dev_id
		changed = true
		just.reset()
	end

	return changed, key, device, device_id
end

---@param input_key string
---@param input_index number
---@param row number
function ViewConfig:buttons(input_key, input_index, row)
	local input_model = self.inputModel
	local bind = input_model:getKey(self.currentMode, input_key, row)

	if self.bindFocus.key == input_index and self.bindFocus.row == row then
		local changed, key, device, device_id = getKey()

		if changed then
			input_model:setKey(self.currentMode, self.inputs[input_index], row, device, device_id, key)
			self.bindFocus.key = input_index + 1

			if self.arrowTween then
				self.arrowTween:stop()
			end

			self.arrowTween = flux.to(self, 0.3, { arrowPosition = input_index + 1 }):ease("quadout")
		end

		gfx.setColor(1, 1, 1, 0.4)
	elseif bind then
		gfx.setColor(0, 0, 0, 0.3)
	else
		gfx.setColor(0, 0, 0, 0)
	end

	if ui.isOver(key_width, key_height) then
		if ui.mousePressed(1) then
			self.bindFocus.key = input_index
			self.bindFocus.row = row

			if self.arrowTween then
				self.arrowTween:stop()
			end

			self.arrowTween = flux.to(self, 0.3, { arrowPosition = input_index }):ease("quadout")
		end

		if love.mouse.isDown(2) then
			input_model:setKey(self.currentMode, self.inputs[input_index], row)
		end

		gfx.setColor(1, 1, 1, 0.3)
	end

	gfx.rectangle(
		"fill",
		key_width / 2 - (key_width * 0.9) / 2,
		key_height / 2 - (key_height * 0.6) / 2,
		key_width * 0.9,
		key_height * 0.6,
		4,
		4
	)

	if bind then
		gfx.setColor(1, 1, 1)
		ui.frame(bind, 0, 0, key_width, key_height, "center", "center")
	end

	gfx.translate(key_width + key_spacing, 0)
end

function ViewConfig:binds(rows, total_w)
	for row_i = 1, rows do
		gfx.push()
		gfx.translate(0, -row_i * key_height)

		if row_i ~= rows then
			gfx.setColor(1, 1, 1)
			gfx.line(-10, 0, total_w + 10, 0)
		end

		for i, v in ipairs(self.inputs) do
			self:buttons(v, i, row_i)
		end
		gfx.pop()
	end
end

function ViewConfig:keys(w, h)
	local key_count = #self.colors
	local rows = math.min(self.inputModel:getBindsCount(self.currentMode) + 1, 6)

	local total_w = key_width * key_count + (key_spacing * (key_count - 1))
	gfx.setLineStyle("smooth")
	gfx.setLineWidth(2)
	gfx.setFont(font.binds)

	local total_h = rows * key_height

	if total_h ~= self.visualHeight then
		if self.heightTween then
			self.heightTween:stop()
		end
		self.heightTween = flux.to(self, 0.2, { visualHeight = total_h }):ease("quadout")
	end

	gfx.translate(w / 2 - total_w / 2, (h - key_height) / 2 + self.visualHeight / 2)

	gfx.push()
	self:keysBackground(rows)
	gfx.pop()

	gfx.push()
	self:binds(rows, total_w)
	gfx.pop()

	local x = (self.arrowPosition - 1) * (key_width + key_spacing)
	local a = math_util.clamp((total_w - x), 0, key_width) / key_width
	gfx.setColor(1, 1, 1, a)
	gfx.draw(arrow_img, x, key_height + 5)
end

function ViewConfig:resolutionUpdated()
	self:createUI()
end

function ViewConfig:draw(modal)
	local w, h = Layout:move("base")

	gfx.setColor(1, 1, 1, 1)
	gfx.setFont(font.title)

	ui.frame(text.title, 9, 9, w - 18, h, "left", "top")

	gfx.push()
	self:keys(w, h)
	gfx.pop()

	gfx.push()
	gfx.translate(540, 128)
	modes_combo:update(true)
	modes_combo:drawBody()
	gfx.pop()

	gfx.translate(0, h - 58)
	back_button:update(true)
	back_button:draw()
end

return ViewConfig
