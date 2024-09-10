local class = require("class")
local table_util = require("table_util")
local path_util = require("path_util")

---@class osu.ui.Localization
---@operator call: osu.ui.Localization
---@field nativeViewHeight number
---@field currentScreenHeight number
---@field fontGroups table<string, table<string, love.Font>>
---@field textGroups table<string, table<string, string>>
---@field currentFile table
---@field currentFilePath string
---@field fontInstances table<string, table<string, love.Font>>
local Localization = class()

---@param asset_model osu.ui.AssetModel
---@param filepath string
---@param native_view_height number
function Localization:new(asset_model, filepath, native_view_height)
	self.assetModel = asset_model
	self.nativeViewHeight = native_view_height
	self.fontScale = 1
	self.fontGroups = {}
	self.textGroups = {}
	self:loadFile(filepath)
end

---@param filepath string
function Localization:loadFile(filepath)
	self.currentFilePath = filepath
	self.currentFile = love.filesystem.load(filepath)()
	assert(self.currentFile, "Add the return statement in the end of " .. filepath)

	self:setFonts()
	self:setText()
end

function Localization:updateScale()
	self:setFonts()
	return self.currentScreenHeight
end

Localization.fontInstances = {}

---@param name string
---@param size number
---@return love.Font
function Localization:loadFont(name, size)
	size = size * (self.currentScreenHeight / self.nativeViewHeight)
	local size_str = tostring(size)

	if self.fontInstances[name] and self.fontInstances[name][size_str] then
		return self.fontInstances[name][size_str]
	end

	---@type string?
	local filename = self.currentFile.fontFiles[name]
	assert(filename, "Font path is not specified for " .. name)

	local font = love.graphics.newFont(path_util.join(self.assetModel.mountPath, filename), size * self.fontScale)

	self.fontInstances[name] = self.fontInstances[name] or {}
	self.fontInstances[name][size_str] = font

	return font
end

function Localization:setFonts()
	---@type table<string, table>
	local fontGroups = self.currentFile.fontGroups

	self.currentScreenHeight = love.graphics.getHeight()

	if self.currentScreenHeight <= self.nativeViewHeight then
		self.currentScreenHeight = self.nativeViewHeight
	end

	for group_name, group in pairs(fontGroups) do
		---@cast group table<string, table>

		---@type table<string, love.Font>
		local fonts = {}

		for name, params in pairs(group) do
			local font = self:loadFont(params[1], params[2])

			if params[3] then
				font:setFallbacks(self:loadFont(params[3], params[2]))
			end

			local filter = "nearest"

			if params[4] then
				filter = params[4].linearFilter and "linear" or filter
			end

			font:setFilter("linear", filter)

			fonts[name] = font
		end

		self.fontGroups[group_name] = self.fontGroups[group_name] or {}
		table_util.copy(fonts, self.fontGroups[group_name])
	end
end

function Localization:setText()
	---@type table<string, table<string, string>>
	local textGroups = self.currentFile.textGroups

	for group_name, group in pairs(textGroups) do
		self.textGroups[group_name] = self.textGroups[group_name] or {}
		table_util.copy(group, self.textGroups[group_name])
	end
end

---@param text_group string
---@param font_group string?
---@return table<string, string>?
---@return table<string, love.Font>?
function Localization:get(text_group, font_group)
	font_group = font_group or text_group
	return self.textGroups[text_group], self.fontGroups[font_group]
end

return Localization
