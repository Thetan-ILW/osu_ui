local class = require("class")

local audio = require("audio")
local source = require("audio.Source")
local gfx_util = require("gfx_util")

local path_util = require("path_util")

---@class osu.ui.Assets
---@operator call: osu.ui.Assets
---@field assetModel osu.ui.AssetModel
---@field defaultsDirectory string
---@field fileList {[string]: string}
---@field defaultsFileList {[string]: string}
---@field images table<string, love.Image>
---@field sounds table<string, audio.Source?>
---@field shaders table<string, love.Shader>
---@field params table<string, number|string|boolean>
---@field errors string[]
local Assets = class()

Assets.errors = {}

---@type string
local source_directory = love.filesystem.getSource()

local audio_extensions = { ".wav", ".ogg", ".mp3" }
local image_extensions = { ".png", ".jpg", ".jpeg", ".bmp", ".tga" }

function Assets:setDefaultsDirectory(path)
	self.defaultsDirectory = path_util.join(self.assetModel.mountPath, path)
end

function Assets:setFileList(path)
	self.fileList = {}
	local files = love.filesystem.getDirectoryItems(path)

	for _, file in ipairs(files) do
		self.fileList[file:lower()] = file
	end

	if not self.defaultsDirectory then
		return
	end

	self.defaultsFileList = {}
	files = love.filesystem.getDirectoryItems(self.defaultsDirectory)

	for _, file in ipairs(files) do
		self.defaultsFileList[file:lower()] = file
	end
end

---@param name string
---@param file_list {[string]: string}
---@return string?
function Assets.findImage(name, file_list)
	for _, format in ipairs(image_extensions) do
		local double = file_list[(name .. "@2x" .. format):lower()]
		if double then
			return double
		end

		local normal = file_list[(name .. format):lower()]
		if normal then
			return normal
		end
	end
end

---@param name string
---@param file_list {[string]: string}
---@return string?
function Assets.findAudio(name, file_list)
	for _, format in ipairs(audio_extensions) do
		local audio_file = file_list[name .. format]

		if audio_file then
			return audio_file
		end
	end
end

---@param directory string
---@param file_name string
---@param file_list {[string]: string}
---@return love.Image?
function Assets.loadImage(directory, file_name, file_list)
	local found = Assets.findImage(file_name, file_list)

	if found then
		local path = path_util.join(directory, found)
		local success, result = pcall(love.graphics.newImage, path)

		if success then
			return result
		end

		table.insert(Assets.errors, ("Failed to load image %s"):format(path))
	end
end

---@param sound_path string
---@return audio.SoundData
local function getSoundData(sound_path)
	local file_data = love.filesystem.newFileData(sound_path)
	return audio.SoundData(file_data:getFFIPointer(), file_data:getSize())
end

---@param directory
---@param file_name string
---@param file_list {[string]: string}
---@param use_sound_data boolean?
---@return audio.Source?
--- Note: use_sound_data for loading audio from mounted directories (moddedgame/charts)
function Assets.loadAudio(directory, file_name, file_list, use_sound_data)
	local found = Assets.findAudio(file_name, file_list)

	if not found then
		return
	end

	local path = path_util.join(directory, found)

	if use_sound_data then
		local success, result = pcall(audio.newSource, getSoundData(path))

		if success then
			return result
		end

		table.insert(Assets.errors, ("Failed to load sound using SoundData %s | %s"):format(path, result))
	end

	local info = love.filesystem.getInfo(path)

	if info.size and info.size < 45 then -- Empty audio, would crash the game
		return
	end

	---@type string
	path = source_directory .. "/" .. path
	local success, result = pcall(audio.newFileSource, path)

	if success then
		local valid, error = pcall(result.stop, result)

		if valid then
			return result
		end

		table.insert(Assets.errors, ("Corrupted sound %s | %s"):format(path, error))
	end

	table.insert(Assets.errors, ("Failed to load sound %s | Error: %s"):format(path, table.concat(result)))
end

---@type love.Image?
local empty_image = nil

---@return love.Image
function Assets.emptyImage()
	if empty_image then
		return empty_image
	end

	empty_image = gfx_util.newPixel(0, 0, 0, 0)

	return empty_image
end

---@type audio.Source?
local empty_audio

---@return audio.Source
function Assets.emptyAudio()
	if empty_audio then
		return empty_audio
	end

	empty_audio = source()

	return empty_audio
end

---@param name string
function Assets:loadDefaultImage(name)
	local image = Assets.loadImage(self.defaultsDirectory, name, self.defaultsFileList)

	if image then
		return image
	end

	table.insert(self.errors, ("Image not found %s"):format(name))
	return self.emptyImage()
end

---@param directory string
---@param name string
---@return love.Image
function Assets:loadImageOrDefault(directory, name)
	local image = Assets.loadImage(directory, name, self.fileList)

	if image then
		return image
	end

	return Assets.loadDefaultImage(self, name)
end

---@param directory string
---@param name string
---@return audio.Source
function Assets:loadAudioOrDefault(directory, name)
	local sound = Assets.loadAudio(directory, name, self.fileList)

	if sound then
		return sound
	end

	sound = Assets.loadAudio(self.defaultsDirectory, name, self.defaultsFileList, true)

	if sound then
		return sound
	end

	table.insert(self.errors, ("Audio not found %s"):format(name))
	return self.emptyAudio()
end

---@param config_model sphere.ConfigModel
function Assets:updateVolume(config_model)
	local configs = config_model.configs
	local settings = configs.settings
	local osu = configs.osu_ui
	local a = settings.audio
	local v = a.volume

	---@type number
	local volume = osu.uiVolume * v.master

	for _, item in pairs(self.sounds) do
		item:setVolume(volume)
	end
end

return Assets
