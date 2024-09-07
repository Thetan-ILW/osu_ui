local Modal = require("osu_ui.views.modals.Modal")
local ViewConfig = require("osu_ui.views.modals.Inputs.ViewConfig")

local actions = require("osu_ui.actions")
local just = require("just")

---@class osu.ui.InputsModal : osu.ui.Modal
---@operator call: osu.ui.InputsModal
local InputsModal = Modal + {}

InputsModal.name = "Inputs"

function InputsModal:onShow()
	actions.disable()
	just.reset()
end

function InputsModal:onQuit()
	actions.enable()
end

function InputsModal:new(game, assets)
	self.game = game
	self.mode = tostring(self.game.selectController.state.inputMode)
	self.inputModel = game.inputModel
	self.viewConfig = ViewConfig(game, assets, self)
	self:updateKeys()
end

function InputsModal:update()
	if love.keyboard.isDown("escape") then
		self:quit()
	end
end

InputsModal.modes = {
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

function InputsModal:updateKeys()
	self.inputs = self.inputModel:getInputs(self.mode)

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

function InputsModal.getKey()
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

return InputsModal
