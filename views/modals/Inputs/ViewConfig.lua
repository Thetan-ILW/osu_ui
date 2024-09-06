local IViewConfig = require("osu_ui.views.IViewConfig")

local ui = require("osu_ui.ui")
local BackButton = require("osu_ui.ui.BackButton")
local Combo = require("osu_ui.ui.Combo")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.InputsModalViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.InputsModalViewConfig
local ViewConfig = IViewConfig + {}

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

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
	self.bindsCount = self.inputModel:getBindsCount(self.currentMode)

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
		for i = 1, keys + scratches do
			table.insert(self.colors, key_colors[i % 2 + 1])
		end
	end
end

local gfx = love.graphics

local key_width = 50
local key_height = 50
local key_spacing = 4

local colors = {
	white = { 1, 1, 1 },
	pink = { 0.99, 0.49, 1 },
	yellow = { 1, 0.87, 0.24 },
}

local colors_tinted = {
	white = { 1, 1, 1, 0.7 },
	pink = { 0.99, 0.49, 1, 0.7 },
	yellow = { 1, 0.87, 0.24, 0.7 },
}

function ViewConfig:keysBackground(rows)
	for i, v in ipairs(self.colors) do
		gfx.setColor(colors_tinted[v])
		gfx.rectangle("fill", 0, -key_height * rows, key_width, key_height * (rows + 1), 4, 4)
		gfx.setColor(colors[v])
		gfx.rectangle("fill", 0, 0, key_width, key_height, 4, 4)
		gfx.rectangle("line", 0, 0, key_width, key_height, 4, 4)
		gfx.setColor(0, 0, 0)
		ui.frame(self.names[i], 0, 0, key_width, key_height, "center", "center")
		gfx.translate(key_width + key_spacing, 0)
	end
end

function ViewConfig:binds(rows, total_w)
	local input_model = self.inputModel

	for row_i = 1, rows do
		gfx.push()
		gfx.translate(0, -row_i * key_height)
		gfx.setColor(1, 1, 1)
		gfx.line(-10, 0, total_w + 10, 0)
		for i, v in ipairs(self.inputs) do
			local bind = input_model:getKey(self.currentMode, v, row_i)

			if ui.isOver(key_width, key_height) then
				gfx.setColor(1, 1, 1, 0.4)
			elseif bind then
				gfx.setColor(0.2, 0.2, 0.2, 0.6)
			else
				gfx.setColor(0, 0, 0, 0)
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
		gfx.pop()
	end
end

function ViewConfig:keys(w, h)
	local key_count = #self.colors
	local rows = self.bindsCount + 1
	local total_w = key_width * key_count + (key_spacing * (key_count - 1))
	gfx.setLineStyle("smooth")
	gfx.setLineWidth(2)
	gfx.setFont(font.binds)

	gfx.translate(w / 2 - total_w / 2, 400)

	gfx.push()
	self:keysBackground(rows)
	gfx.pop()

	gfx.push()
	self:binds(rows, total_w)
	gfx.pop()
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
