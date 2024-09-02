local class = require("class")

local audio = require("audio")
local source = require("audio.Source")
local gfx_util = require("gfx_util")

---@class osu.ui.Assets
---@operator call: osu.ui.Assets
---@field defaultsDirectory string
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

---@param path string
---@return string?
function Assets.findImage(path)
	for _, format in ipairs(image_extensions) do
		local normal = path .. format
		local double = path .. "@2x" .. format

		if love.filesystem.getInfo(double) then
			return double
		end

		if love.filesystem.getInfo(normal) then
			return normal
		end

		if love.filesystem.getInfo(double:lower()) then
			return double:lower()
		end

		if love.filesystem.getInfo(normal:lower()) then
			return normal:lower()
		end
	end
end

---@param path string
---@return string?
function Assets.findAudio(path)
	if not path then
		return
	end

	for _, format in ipairs(audio_extensions) do
		local audio_path = path .. format

		if love.filesystem.getInfo(audio_path) then
			return audio_path
		end
	end
end

---@param path string
---@return love.Image?
function Assets.loadImage(path)
	path = Assets.findImage(path)

	if path then
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

---@param path string
---@param use_sound_data boolean?
---@return audio.Source?
--- Note: use_sound_data for loading audio from mounted directories (moddedgame/charts)
function Assets.loadAudio(path, use_sound_data)
	path = Assets.findAudio(path)

	if path then
		local info = love.filesystem.getInfo(path)

		if info.size and info.size < 45 then -- Empty audio, would crash the game
			return
		end
	end

	if path and use_sound_data then
		local success, result = pcall(audio.newSource, getSoundData(path))

		if success then
			return result
		end

		table.insert(Assets.errors, ("Failed to load sound using SoundData %s | %s"):format(path, result))
	end

	if path then
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

function Assets:loadDefaultImage(name)
	local image = Assets.loadImage(self.defaultsDirectory .. name)

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
	local image = Assets.loadImage(directory .. name)

	if image then
		return image
	end

	return Assets.loadDefaultImage(self, name)
end

---@param directory string
---@param name string
---@return audio.Source
function Assets:loadAudioOrDefault(directory, name)
	local sound = Assets.loadAudio(directory .. name)

	if sound then
		return sound
	end

	sound = Assets.loadAudio(self.defaultsDirectory .. name, true)

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
