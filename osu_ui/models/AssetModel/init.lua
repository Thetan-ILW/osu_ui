local class = require("class")

---@class osu.ui.AssetModel
---@operator call: osu.ui.AssetModel
---@field configModel sphere.ConfigModel
---@field fields table<string, osu.ui.Assets>
---@field localizations table<string,{name: string, filepath: string}>
local AssetModel = class()

function AssetModel:new(config_model)
	self.configModel = config_model

	self.fields = {}
	self:loadLocalizationList()
end

---@param name string
---@param assets osu.ui.Assets
function AssetModel:store(name, assets)
	self.fields[name] = assets
end

---@param name string
---@return osu.ui.Assets?
function AssetModel:get(name)
	return self.fields[name]
end

local localizations_dir = "theme_mount/osu_ui/osu_ui/localization/"

function AssetModel:loadLocalizationList()
	---@type {name: string, filepath: string}[]
	local list = love.filesystem.load(localizations_dir .. "list.lua")()

	for _, v in ipairs(list) do
		v.filepath = localizations_dir .. v.filepath
	end

	self.localization = list
end

function AssetModel:getLocalizationNames()
	return self.localization
end

---@param name string
---@return string
function AssetModel:getLocalizationFileName(name)
	for _, v in ipairs(self.localization) do
		if v.name == name then
			return v.filepath
		end
	end

	return self.localizations[1].filepath
end

---@return string[]
function AssetModel:getOsuSkins()
	---@type string[]
	local skins = love.filesystem.getDirectoryItems("userdata/skins/")

	---@type string[]
	local osu_skin_names = {}

	table.insert(osu_skin_names, "Default")

	for _, name in ipairs(skins) do
		---@type string
		local path = "userdata/skins/" .. name
		if love.filesystem.getInfo(path .. "/skin.ini") then
			table.insert(osu_skin_names, name)
		end
	end

	return osu_skin_names
end

---@param skin_path string
---@return love.Image?
function AssetModel:loadSkinPreview(skin_path)
	local small_path = ("%s/skin-preview.png"):format(skin_path)
	local large_path = ("%s/skin-preview@2x.png"):format(skin_path)
	local small_exist = love.filesystem.getInfo(small_path)
	local large_exist = love.filesystem.getInfo(large_path)

	---@type string?
	local image_path

	if love.graphics.getHeight() > 768 then
		image_path = large_exist and large_path or small_path
	else
		image_path = small_exist and small_path or large_path
	end

	if love.filesystem.getInfo(image_path) then
		return love.graphics.newImage(image_path)
	end
end

function AssetModel:updateVolume()
	for _, v in pairs(self.fields) do
		v:updateVolume(self.configModel)
	end
end

return AssetModel
