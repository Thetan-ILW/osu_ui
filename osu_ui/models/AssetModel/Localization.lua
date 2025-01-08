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

	-- AI SLOP
	for line in file:lines() do
		---@cast line string
		line = line:gsub("#.*$", ""):gsub("%-%-.*$", "")
		line = line:match("^%s*(.-)%s*$")
		if line ~= "" and not line:match("^#") then
			local equal_pos = line:find("=")
			if equal_pos then
				local key = line:sub(1, equal_pos - 1):match("^%s*(.-)%s*$")
				local value = line:sub(equal_pos + 1):match("^%s*(.-)%s*$")

				if key ~= "" then
					strings[key] = value ~= "" and value:gsub("\\n", "\n") or key
				end
			end
		end
	end

	file:close()
	return strings
end

return Localization
