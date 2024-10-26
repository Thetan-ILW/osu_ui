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
---@field params table<string, number|string|boolean|number[]>
---@field selectViewConfig function?
---@field resultViewConfig function?
---@field backButtonType "none" | "image" | "animation"
local OsuAssets = Assets + {}

OsuAssets.nativeHeight = 768
OsuAssets.fontFiles = {
	["Regular"] = "osu_ui/assets/ui_font/Aller/Aller_Rg.ttf",
	["Light"] = "osu_ui/assets/ui_font/Aller/Aller_Lt.ttf",
	["Bold"] = "osu_ui/assets/ui_font/Aller/Aller_Bd.ttf",
	["Awesome"] = "osu_ui/assets/ui_font/FontAwesome/FontAwesome.ttf"
}

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
	local file_list = {}
	self.populateFileList(file_list, "userdata", "", 5)

	local avatar = self.findImage("avatar", file_list)

	if avatar then
		return love.graphics.newImage(path_util.join("userdata", avatar))
	end

	return self.emptyImage()
end

function OsuAssets:loadMenuBack()
	self.animations.menuBack = {}

	local animtation_pattern = "menu-back-%i"
	local frame = self.loadImage(self.directory, animtation_pattern:format(0), self.fileList)

	local i = 1
	while frame do
		table.insert(self.animations.menuBack, frame)
		frame = self.loadImage(self.directory, animtation_pattern:format(i), self.fileList)
		i = i + 1
	end

	if #self.animations.menuBack ~= 0 then
		self.backButtonType = "animation"
		return
	end

	local menu_back = self.loadImage(self.directory, "menu-back", self.fileList)

	if not menu_back then
		self.backButtonType = "none"
		return
	end

	self.images.menuBack = menu_back or self.emptyImage()
	self.backButtonType = "image"
end

local function strToColor(str)
	if not str then
		return { 1, 1, 1 }
	end
	local colors = string.split(str, ",")
	return { tonumber(colors[1]) / 255, tonumber(colors[2]) / 255, tonumber(colors[3]) / 255 }
end

---@param asset_model osu.ui.AssetModel
---@param skin_path string
function OsuAssets:new(asset_model, skin_path)
	self.assetModel = asset_model
	self:setPaths(skin_path, "osu_ui/assets")
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
	self.fonts = {}
	self.imageFonts = {}
	self.animations = {}
	self.customViews = {}
	self.loadedViews = {}
end

local custom_views = {
	resultView = "ResultView"
}

function OsuAssets:loadCustomViews(view_name)
	if not custom_views[view_name] then
		return
	end

	local filename = self.findFile(path_util.join("gucci", custom_views[view_name] .. ".lua"), self.fileList)
	if not filename then
		return
	end

	self.customViews[view_name] = love.filesystem.load(path_util.join(self.directory, filename))()
end

---@param view_name string?
function OsuAssets:loadViewAssets(view_name)
	if not view_name then
		return
	end

	self:loadCustomViews(view_name)

	if self.loadedViews[view_name] then
		return
	end

	self.loadedViews[view_name] = true

	local f = self[view_name]
	if f then
		f(self)
	end
end

---@private
function OsuAssets:selectView()
	--self.images.panelTop:setWrap("clamp")
	--self:loadMenuBack()
end

---@private
function OsuAssets:resultView()
	local score_font_path = self.params.scoreFontPrefix or "score"
	---@cast score_font_path string
	score_font_path = score_font_path:gsub("\\", "/")

	self.imageFonts.scoreFont = self:getImageFont("score", score_font_path)

	local marv = self.findImage("mania-hit300g-0", self.fileList) or self.findImage("mania-hit300g", self.fileList)

	if marv then
		self.images.judgeMarvelous = love.graphics.newImage(path_util.join(self.directory, marv))
	else
		self.images.judgeMarvelous = love.graphics.newImage(path_util.join(self.defaultsDirectory, "mania-hit300g@2x.png"))
	end
end

---@param icon string
---@param size number
---@return love.Text
function OsuAssets:awesomeIcon(icon, size)
	return love.graphics.newText(self:loadFont("Awesome", size), icon)
end

return OsuAssets
