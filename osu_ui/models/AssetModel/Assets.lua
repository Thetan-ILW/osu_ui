local class = require("class")

local audio = require("audio")
local source = require("audio.Source")
local gfx_util = require("gfx_util")

local path_util = require("path_util")

---@class osu.ui.Assets
---@operator call: osu.ui.Assets
---@field assetModel osu.ui.AssetModel
---@field directory string
---@field defaultsDirectory string
---@field fileList {[string]: string}
---@field defaultsFileList {[string]: string}
---@field images table<string, love.Image>
---@field sounds table<string, audio.Source?>
---@field fonts {[string]: love.Font}
---@field shaders table<string, love.Shader>
---@field params table<string, number|string|boolean>
---@field errors string[]
---@field screenHeight number
---@field nativeHeight number
local Assets = class()

Assets.errors = {}
Assets.fontFiles = {}
Assets.fontFilesFallbacks = {}

---@type string
local source_directory = love.filesystem.getSource()

local audio_extensions = { ".wav", ".ogg", ".mp3" }
local image_extensions = { ".png", ".jpg", ".jpeg", ".bmp", ".tga" }

local max_depth = 5

---@param list {[string]: string}
---@param root string
---@param path string?
---@param depth number?
function Assets.populateFileList(list, root, path, depth)
	path = path or ""
	depth = depth or 1

	if depth > max_depth then
		return
	end

	local files = love.filesystem.getDirectoryItems(path_util.join(root, path))

	for _, file in ipairs(files) do
		local local_path = file

		if path ~= "" then
			local_path = path_util.join(path, file)
		end

		local full_path = path_util.join(root, local_path)
		local info = love.filesystem.getInfo(full_path)

		if info.type == "directory" then
			Assets.populateFileList(list, root, local_path, depth + 1)
		elseif info.type == "file" then
			list[local_path:lower()] = local_path
		end
	end
end

function Assets:setPaths(directory, defaults_directory)
	self.directory = directory

	if defaults_directory then
		self.defaultsDirectory = path_util.join(self.assetModel.mountPath, defaults_directory)
	end
end

function Assets:setFileList()
	self.fileList = {}

	if self.directory ~= "" then
		self.populateFileList(self.fileList, self.directory)
	end

	if not self.defaultsDirectory then
		return
	end

	self.defaultsFileList = {}
	self.populateFileList(self.defaultsFileList, self.defaultsDirectory)
end

---@param name string
---@param file_list {[string]: string}
---@return string?
function Assets.findImage(name, file_list)
	if not file_list then
		print(debug.traceback())
	end
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

---@param name string
---@param file_list {[string]: string}
---@return string?
function Assets.findFile(name, file_list)
	return file_list[name:lower()]
end

---@param root string
---@param file_name string
---@param file_list {[string]: string}
---@return love.Image?
function Assets.newImage(root, file_name, file_list)
	local path = Assets.findImage(file_name, file_list)

	if path then
		path = path_util.join(root, path)
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

---@param root string
---@param file_name string
---@param file_list {[string]: string}
---@param use_sound_data boolean?
---@return audio.Source?
--- Note: use_sound_data for loading audio from mounted directories (moddedgame/charts)
function Assets.newAudio(root, file_name, file_list, use_sound_data)
	local path = Assets.findAudio(file_name, file_list)

	if not path then
		return
	end

	path = path_util.join(root, path)

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

	if type(result) == "table" then
		result = table.concat(result)
	end
	table.insert(Assets.errors, ("Failed to load sound %s | Error: %s"):format(path, result))
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
function Assets:newDefaultImage(name)
	local image = Assets.newImage(self.defaultsDirectory, name, self.defaultsFileList)

	if image then
		return image
	end

	table.insert(self.errors, ("Image not found %s"):format(name))
	return self.emptyImage()
end

---@param name string
---@return love.Image
function Assets:loadImage(name)
	if self.images[name] then
		return self.images[name]
	end

	local image = Assets.newImage(self.directory, name, self.fileList)

	if image then
		self.images[name] = image
		return image
	end

	local default = Assets.newDefaultImage(self, name)
	self.images[name] = default
	return default
end

---@param name string
---@return audio.Source
function Assets:loadAudio(name)
	if self.sounds[name] then
		return self.sounds[name]
	end

	local sound = Assets.newAudio(self.directory, name, self.fileList)

	if sound then
		self.sounds[name] = sound
		return sound
	end

	sound = Assets.newAudio(self.defaultsDirectory, name, self.defaultsFileList, true)

	if sound then
		self.sounds[name] = sound
		return sound
	end

	table.insert(self.errors, ("Audio not found %s"):format(name))
	self.sounds[name] = self.emptyAudio()
	return self.emptyAudio()
end

---@return number
function Assets:getTextDpiScale()
	return math.ceil(self.screenHeight / self.nativeHeight)
end

---@param name string
---@param size number
---@return love.Font
function Assets:loadFont(name, size)
	if self.screenHeight < 1 then
		error("wtf")
	end

	local formatted_name = ("%s_%i@%ix"):format(name, size, self:getTextDpiScale())

	if self.fonts[formatted_name] then
		return self.fonts[formatted_name]
	end

	local filename = self.fontFiles[name]

	if not filename then
		error(("No such font: %s"):format(filename))
	end

	local s = size * self:getTextDpiScale()
	local font = love.graphics.newFont(path_util.join(self.assetModel.mountPath, filename), s)

	if self.fontFilesFallbacks[name] then
		font:setFallbacks(love.graphics.newFont(path_util.join(self.assetModel.mountPath, self.fontFilesFallbacks[name]), s))
	end

	font:setFilter("linear", "nearest")
	self.fonts[formatted_name] = font

	return font
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
