local Assets = require("osu_ui.models.AssetModel.Assets")

local path_util = require("path_util")

local OsuNoteSkin = require("sphere.models.NoteSkinModel.OsuNoteSkin")
local utf8validate = require("utf8validate")

---@class osu.ui.OsuAssets : osu.ui.Assets
---@operator call: osu.ui.OsuAssets
---@field loadedViews {[string]: boolean}
---@field images table<string, love.Image>
---@field imageFonts table<string, table<string, string>>
---@field animations {[string]: love.Image[]}
---@field sounds table<string, audio.Source>
---@field params {[string]: any}
---@field customViews {[string]: osu.ui.Screen}
---@field backButtonType "none" | "image" | "animation"
local OsuAssets = Assets + {}

local characters = {
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"comma",
	"dot",
	"percent",
	"x",
}

local char_alias = {
	comma = ",",
	dot = ".",
	percent = "%",
}

---@param prefix string
---@param path string
---@return table<string, string>
function OsuAssets:getImageFont(prefix, path)
	---@type table<string, string>
	local font = {}

	for _, v in ipairs(characters) do
		local file_name = Assets.findImage(("%s-%s"):format(path, v), self.fileList)
		local directory = self.directory

		if not file_name then
			file_name = ("%s-%s@2x.png"):format(prefix, v)
			directory = self.defaultsDirectory
		end

		local key = char_alias[v] and char_alias[v] or v
		font[key] = path_util.join(directory, file_name)
	end

	return font
end

---@return love.Image
function OsuAssets:loadAvatar()
	if self.images["__avatar__"] then
		return self.images["__avatar__"]
	end

	local file_list = {}
	self.populateFileList(file_list, "userdata", "", 5)

	local avatar = self.findImage("avatar", file_list)

	if avatar then
		local img = love.graphics.newImage(path_util.join("userdata", avatar))
		self.images["__avatar__"] = img
		return img
	end

	self.images["__avatar__"] = self.emptyImage()
	return self.emptyImage()
end

function OsuAssets:loadMenuBack()
	---@type love.Image[]
	self.menuBackFrames = {}

	local animtation_pattern = "menu-back-%i"
	local frame = self:loadImage(animtation_pattern:format(0))

	local i = 1
	while frame ~= self.emptyImage() do
		table.insert(self.menuBackFrames, frame)
		frame = self:loadImage(animtation_pattern:format(i))
		i = i + 1
	end

	if #self.menuBackFrames ~= 0 then
		return
	end

	local menu_back = self:loadImage("menu-back")

	if menu_back == self.emptyImage() then
		return
	end

	table.insert(self.menuBackFrames, menu_back)
end

local function strToColor(str)
	if not str then
		return { 1, 1, 1, 1 }
	end
	local color = string.split(str, ",")
	return { love.math.colorFromBytes(tonumber(color[1]), tonumber(color[2]), tonumber(color[3]), 255) }
end

---@param asset_model osu.ui.AssetModel
---@param skin_path string
function OsuAssets:new(asset_model)
	self.assetModel = asset_model
end

function OsuAssets:load()
	self:setFileList()

	local content = love.filesystem.read(path_util.join(self.directory, self.fileList["skin.ini"]))

	---@type table
	local skin_ini

	if content then
		content = utf8validate(content)
	else
		content = love.filesystem.read(path_util.join(self.defaultsDirectory, "skin.ini"))
	end

	skin_ini = OsuNoteSkin:parseSkinIni(content)

	self.params = {
		songSelectActiveText = strToColor(skin_ini.Colours.SongSelectActiveText),
		songSelectInactiveText = strToColor(skin_ini.Colours.SongSelectInactiveText),

		cursorCenter = skin_ini.General.CursorCentre,
		cursorExpand = skin_ini.General.CursorExpand,
		cursorRotate = skin_ini.General.CursorRotate,
		animationFramerate = skin_ini.General.AnimationFramerate,

		scoreFontPrefix = skin_ini.Fonts.ScorePrefix,
		scoreOverlap = skin_ini.Fonts.ScoreOverlap,
	}

	self.images = {}
	self.sounds = {}
	self.imageFonts = {}
	self.animations = {}
	self.customViews = {}
	self.loadedViews = {}

	local score_font_path = self.params.scoreFontPrefix or "score"
	---@cast score_font_path string
	score_font_path = score_font_path:gsub("\\", "/")
	self.imageFonts.scoreFont = self:getImageFont("score", score_font_path)

	self:loadMenuBack()
	if skin_ini.Gucci then
		self.params.requirePath = skin_ini.Gucci.RequirePath
		self:loadCustomViews(skin_ini)
	end
end

---@param path string
---@return table
function OsuAssets:loadModule(path)
	if self.params.requirePath then
		path = path_util.join(self.params.requirePath, path)
	end

	local f = love.filesystem.load(path_util.join(self.directory, ("%s.lua"):format(path)))

	if not f then
		error(("skin module '%s' not found."):format(path))
	end
	return f()
end

local custom_views = {
	{ key = "MainMenuView", alias = "mainMenu" },
	{ key = "LobbyListView", alias = "lobbyList" },
	{ key = "SelectView", alias = "select" },
	{ key = "GameplayView", alias = "gameplay" },
	{ key = "ResultView", alias = "result" },
}

---@param skin_ini table
function OsuAssets:loadCustomViews(skin_ini)
	for i, v in ipairs(custom_views) do
		---@type string?
		local path = skin_ini.Gucci[v.key]
		if path then
			if self.params.requirePath then
				path = path_util.join(self.params.requirePath, path)
			end
			local full_path = path_util.join(self.directory, path)
			if love.filesystem.getInfo(full_path) then
				self.customViews[v.alias] = love.filesystem.load(full_path)()
			end
		end
	end
end

---@param icon string
---@param size number
---@return love.Text
function OsuAssets:awesomeIcon(icon, size)
	return love.graphics.newText(self:loadFont("Awesome", size), icon)
end

return OsuAssets
