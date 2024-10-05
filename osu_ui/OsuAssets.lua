local Assets = require("osu_ui.models.AssetModel.Assets")
local Localization = require("osu_ui.models.AssetModel.Localization")

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
---@field shaders table<string, love.Shader>
---@field params table<string, number|string|boolean|number[]>
---@field localization osu.ui.Localization
---@field selectViewConfig function?
---@field resultViewConfig function?
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

local images = {
	global = {
		osuLogo = "menu-osu-logo",
		cursor = "cursor",
		cursorMiddle = "cursormiddle",
		cursorTrail = "cursortrail",
		uiLock = "ui-lock",
		buttonLeft = "button-left",
		buttonMiddle = "button-middle",
		buttonRight = "button-right",
		dropdownArrow = "dropdown-arrow",
		menuBackArrow = "menu-back-arrow",

		checkboxOff = "menu-checkbox-off",
		checkboxOn = "menu-checkbox-on",
		optionChanged = "menu-option-changed",

		generalTab = "menu-general-tab",
		graphicsTab = "menu-graphics-tab",
		gameplayTab = "menu-gameplay-tab",
		audioTab = "menu-audio-tab",
		skinTab = "menu-skin-tab",
		inputTab = "menu-input-tab",
		maintenanceTab = "menu-maintenance-tab",

		noSkinPreview = "no-skin-preview",
		inputsArrow = "inputs-arrow",

		overlayOnline = "overlay-online",
		overlayChat = "overlay-show",
		onlineRanking = "ranking-online",

		maniaIcon = "mode-mania",
	},
	mainMenuView = {
		welcomeText = "welcome_text",
		background = "menu-background",
		copyright = "menu-copyright",
		nowPlaying = "menu-np",
		musicPause = "menu-pause-music",
		musicToStart = "menu-to-music-start",
		musicPlay = "menu-play-music",
		musicBackwards = "menu-music-backwards",
		musicForwards = "menu-music-forwards",
		musicInfo = "menu-music-info",
		musicList = "menu-music-list",
		directButton = "menu-osudirect",
		directButtonOver = "menu-osudirect-over",
		menuPlayButton = "menu-button-play",
		menuPlayButtonHover = "menu-button-play-over",
		menuEditButton = "menu-button-edit",
		menuEditButtonHover = "menu-button-edit-over",
		menuOptionsButton = "menu-button-options",
		menuOptionsButtonHover = "menu-button-options-over",
		menuExitButton = "menu-button-exit",
		menuExitButtonHover = "menu-button-exit-over",
		menuSoloButton = "menu-button-freeplay",
		menuSoloButtonHover = "menu-button-freeplay-over",
		menuMultiButton = "menu-button-multiplayer",
		menuMultiButtonHover = "menu-button-multiplayer-over",
		menuBackButton = "menu-button-back",
		menuBackButtonHover = "menu-button-back-over",
		supporter = "menu-subscriber",
	},
	selectView = {
		panelTop = "songselect-top",

		panelBottom = "songselect-bottom",
		rankedIcon = "selection-ranked",
		danIcon = "selection-dan",

		menuBackDefault = "menu-back",
		modeButton = "selection-mode",
		modsButton = "selection-mods",
		randomButton = "selection-random",
		optionsButton = "selection-options",

		modeButtonOver = "selection-mode-over",
		modsButtonOver = "selection-mods-over",
		randomButtonOver = "selection-random-over",
		optionsButtonOver = "selection-options-over",

		tab = "selection-tab",
		forum = "rank-forum",
		noScores = "selection-norecords",

		listButtonBackground = "menu-button-background",
		star = "star",
		osuSmallIcon = "mode-osu-small",
		taikoSmallIcon = "mode-taiko-small",
		fruitsSmallIcon = "mode-fruits-small",
		maniaSmallIcon = "mode-mania-small",
		maniaSmallIconForCharts = "mode-mania-small-for-charts",

		smallGradeD = "ranking-D-small",
		smallGradeC = "ranking-C-small",
		smallGradeB = "ranking-B-small",
		smallGradeA = "ranking-A-small",
		smallGradeS = "ranking-S-small",
		smallGradeX = "ranking-X-small",
		recentScore = "recent-score",
	},
	resultView = {
		title = "ranking-title",
		panel = "ranking-panel",
		graph = "ranking-graph",
		maxCombo = "ranking-maxcombo",
		accuracy = "ranking-accuracy",
		replay = "pause-replay",
		retry = "pause-retry",

		judgePerfect = "mania-hit300",
		judgeGreat = "mania-hit200",
		judgeGood = "mania-hit100",
		judgeBad = "mania-hit50",
		judgeMiss = "mania-hit0",

		gradeSS = "ranking-X",
		gradeS = "ranking-S",
		gradeA = "ranking-A",
		gradeB = "ranking-B",
		gradeC = "ranking-C",
		gradeD = "ranking-D",
		backgroundOverlay = "ranking-background-overlay",

		noLongNote = "selection-mod-nolongnote",
		mirror = "selection-mod-mirror",
		random = "selection-mod-random",
		doubleTime = "selection-mod-doubletime",
		halfTime = "selection-mod-halftime",
		autoPlay = "selection-mod-autoplay",
		automap4 = "selection-mod-key4",
		automap5 = "selection-mod-key5",
		automap6 = "selection-mod-key6",
		automap7 = "selection-mod-key7",
		automap8 = "selection-mod-key8",
		automap9 = "selection-mod-key9",
		automap10 = "selection-mod-key10",
		fln3 = "selection-mod-fln3",
		scorev2 = "selection-mod-scorev2"
	},
	playerStatsView = {
		activityRectangle = "activity-rectangle",
		activityBackground = "profile-activity",
		danClearsBackground = "profile-dan-clears",
		danClearsOverlay = "profile-dan-clears-overlay",
		profilePanelBottom = "profile-bottom",
		profileSelect = "profile-select",
		profileSelectOver = "profile-select-over",
		profileDisplayOptions = "profile-display-options",
		profileDisplayOptionsOver = "profile-display-options-over",
		profileSsrPanel = "profile-ssr-panel",
		profileModePanel = "profile-mode-panel"
	}
}

local sounds = {
	welcome = "welcome",
	welcomePiano = "welcome_piano",
	goodbye = "seeya",
	selectChart = "select-difficulty",
	selectGroup = "select-expand",
	hoverOverRect = "click-short",
	hoverMenu = "menuclick",
	clickShortConfirm = "click-short-confirm",

	applause = "applause",
	menuBack = "menuback",
	menuHit = "menuhit",
	menuPlayClick = "menu-play-click",
	menuEditClick = "menu-edit-click",
	menuFreeplayClick = "menu-freeplay-click",
	menuMultiplayerClick = "menu-multiplayer-click",

	checkOn = "check-on",
	checkOff = "check-off",
	sliderBar = "sliderbar",
	selectExpand = "select-expand",
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

---@param default_localization string
function OsuAssets:load(default_localization)
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

	self:loadLocalization(default_localization)

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
	self.loadedViews = {}

	self:populateImages(images.global, self.images)
	self:populateSounds(sounds, self.sounds)

	self.images.avatar = self:loadAvatar()

	self.shaders = {
		brighten = love.graphics.newShader([[
		extern Image tex;
		extern float amount;
		vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
		{
		    vec4 texturecolor = Texel(tex, texture_coords);
		    return vec4(texturecolor.rgb + amount, texturecolor.a) * color;
		}
	]]),
	}
end

---@param view_name string?
function OsuAssets:loadViewAssets(view_name)
	if not view_name then
		return
	end

	if self.loadedViews[view_name] then
		return
	end

	self:populateImages(images[view_name], self.images)
	self.loadedViews[view_name] = true

	local f = self[view_name]
	if f then
		f(self)
	end
end

---@private
function OsuAssets:selectView()
	self.images.panelTop:setWrap("clamp")
	self:loadMenuBack()
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

---@param filepath string
function OsuAssets:loadLocalization(filepath)
	if not self.localization then
		self.localization = Localization(self.assetModel, filepath, 768)
		return
	end

	if self.localization.currentFilePath ~= filepath then
		self.localization:loadFile(filepath)
	end
end

return OsuAssets
