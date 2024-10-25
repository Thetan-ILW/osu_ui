local class = require("class")
local path_util = require("path_util")

---@class Localization
---@operator call: Localization
---@field localizationDirectory string
---@field defaultFile string
---@field default {[string]: string}
---@field text {[string]: string}
local Localization = class()

---@param localization_directory string
---@param default_file string
function Localization:new(localization_directory, default_file)
	self.localizationDirectory = localization_directory
	self.defaultFile = default_file
end

function Localization:load()
	local strings, err = self:parse(self.defaultFile, {})
	if not strings then
		error(("The game can't run without the default localization. Error: %s"):format(err))
	end
	self.default = strings
end

---@param filename string
function Localization:loadFile(filename)
	local new = {}
	for k, v in pairs(self.default) do
		new[k] = v
	end

	local strings, err = self:parse(filename, new)
	if not strings then
		return err
	end

	self.text = strings
end

---@param filename string
---@param strings {[string]: string}
---@return {[string]: string} text
---@return string? err
function Localization:parse(filename, strings)
	local file, err = love.filesystem.newFile(path_util.join(self.localizationDirectory, filename))
	if not file then
		return strings, err
	end
	file:open("r")

	strings = strings or {}

	for line in file:lines() do
		local split = line:split("=")
		if #split > 2 then
			split[2] = table.concat(split, "", 2, #split)
		end
		strings[split[1]] = split[2] or split[1]
	end

	return strings
end

return Localization
