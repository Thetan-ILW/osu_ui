local class = require("class")
local json = require("json")

---@alias osu.ui.ModPresetModel.Preset {name: string, modifiers: { id: integer, value: number, version: integer }[]}

---@class osu.ui.ModPresetModel
---@operator call: osu.ui.ModPresetModel
---@field presets osu.ui.ModPresetModel.Preset[]
local ModPresetModel = class()

local preset_file_path = "userdata/mod_presets.json"

---@param play_context sphere.PlayContext
function ModPresetModel:new(play_context)
	self.playContext = play_context
	self.presets = {}
	self.selectedPresetIndex = 1
	self:load()
	self:select(self.selectedPresetIndex)
end

function ModPresetModel:load()
	local content = love.filesystem.read(preset_file_path)

	local function reset()
		self.presets = self:createDefaultPresets()
		self.selectedPresetIndex = 1
		self:save()
	end

	if not content then
		reset()
		return
	end

	local success, decoded = pcall(json.decode, content)

	if not success then
		reset()
		return
	end

	if not decoded.presets or not decoded.selectedPresetIndex then
		reset()
		return
	end

	self.presets = decoded.presets
	self.selectedPresetIndex = math.min(#self.presets, decoded.selectedPresetIndex)

	for _, preset in ipairs(self.presets) do
		-- json.encode ignores empty tables
		preset.modifiers = preset.modifiers or {}
	end
end

function ModPresetModel:save()
	local t = {}
	self.playContext:save(t)

	local preset = self.presets[self.selectedPresetIndex]
	preset.modifiers = t.modifiers

	love.filesystem.write(preset_file_path, json.encode({
		selectedPresetIndex = self.selectedPresetIndex,
		presets = self.presets
	}))
end

---@param index integer
function ModPresetModel:select(index)
	self.selectedPresetIndex = math.min(#self.presets, index)
	local preset = self.presets[self.selectedPresetIndex]

	local t = {}
	self.playContext:save(t)
	t.modifiers = preset.modifiers
	self.playContext:load(t)
end

function ModPresetModel:createNew(name)
	local t = {}
	self.playContext:save(t)

	local modifiers_copy = {}
	for _, v in ipairs(t.modifiers) do
		table.insert(modifiers_copy, v)
	end

	table.insert(self.presets, {
		name = name,
		modifiers = modifiers_copy
	})
	self:select(#self.presets)
end

function ModPresetModel:deleteSelected()
	table.remove(self.presets, self.selectedPresetIndex)
	if #self.presets == 0 then
		table.insert(self.presets, { name = "No preset", modifiers = {} })
	end
	self:select(self.selectedPresetIndex + 1)
end

function ModPresetModel:saveCurrentPreset()
	local preset = self.presets[self.selectedPresetIndex]
	local t = {}
	self.playContext:save(t)
	t.modifiers = preset.modifiers
end

---@return osu.ui.ModPresetModel.Preset
function ModPresetModel:createDefaultPresets()
	return {
		{
			name = "No preset",
			modifiers = {}
		},
		{
			name = "4K JS/HS >> 7K Bracket",
			modifiers = {
				{
					id = 13,
					value = 2,
					version = 0
				},
				{
					id = 14,
					value = "key",
					version = 0
				},
				{
					id = 17,
					value = "all",
					version = 0
				},
				{
					id = 24,
					value = 5,
					version = 0
				},
				{
					id = 11,
					value = 7,
					version = 0
				},
				{
					id = 18,
					version = 0
				}
			}
		},
		{
			name = "4K JS/HS >> 10K Bracket",
			modifiers = {
				{
					id = 12,
					value = 2,
					version = 0
				},
				{
					id = 14,
					value = "key",
					version = 0
				},
				{
					id = 17,
					value = "all",
					version = 0
				},
				{
					id = 24,
					value = 4,
					version = 0
				},
				{
					id = 11,
					value = 10,
					version = 0
				},
				{
					id = 18,
					version = 0
				}
			}
		},
		{
			name = "7K+ >> 10K",
			modifiers = {
				{
					id = 11,
					value = 11,
					version = 0
				},
				{
					id = 11,
					value = 10,
					version = 0
				}
			}
		}
	}
end

return ModPresetModel
