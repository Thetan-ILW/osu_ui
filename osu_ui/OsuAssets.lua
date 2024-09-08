local Assets = require("osu_ui.models.AssetModel.Assets")
local Localization = require("osu_ui.models.AssetModel.Localization")

local path_util = require("path_util")

local OsuNoteSkin = require("sphere.models.NoteSkinModel.OsuNoteSkin")
local utf8validate = require("utf8validate")

---@class osu.ui.OsuAssets : osu.ui.Assets
---@operator call: osu.ui.OsuAssets
---@field defaultsDirectory string
---@field images table<string, love.Image>
---@field imageFonts table<string, table<string, string>>
---@field sounds table<string, audio.Source>
---@field shaders table<string, love.Shader>
---@field params table<string, number|string|boolean>
---@field localization osu.ui.Localization
---@field selectViewConfig function?
---@field resultViewConfig function?
---@field hasBackButton boolean
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
	local file_list = {}
	self.populateFileList(file_list, "userdata")

	local avatar = self.findImage("avatar", file_list)

	if avatar then
		return love.graphics.newImage(path_util.join("userdata", avatar))
	end

	return self.emptyImage()
end

---@param skin_path string
---@param localization_file string
function OsuAssets:new(asset_model, skin_path, localization_file)
	self.assetModel = asset_model
	self:setFileList(skin_path, "osu_ui/assets")

	-- TODO: Move to Assets.findFile
	local content = love.filesystem.read(path_util.join(skin_path, self.fileList["skin.ini"]))

	---@type table
	local skin_ini

	if content then
		content = utf8validate(content)
	else
		content = love.filesystem.read(path_util.join(self.defaultsDirectory, "skin.ini"))
	end

	skin_ini = OsuNoteSkin:parseSkinIni(content)

	self:loadLocalization(localization_file)

	self.params = {
		songSelectActiveText = skin_ini.Colours.SongSelectActiveText,
		songSelectInactiveText = skin_ini.Colours.SongSelectInactiveText,

		cursorCenter = skin_ini.General.CursorCentre,
		cursorExpand = skin_ini.General.CursorExpand,
		cursorRotate = skin_ini.General.CursorRotate,

		scoreOverlap = skin_ini.Fonts.ScoreOverlap,
	}

	self.images = {
		avatar = self:loadAvatar(),
		panelTop = self:loadImageOrDefault("songselect-top"),

		menuBackArrow = self:loadImageOrDefault("menu-back-arrow"),

		panelBottom = self:loadImageOrDefault("songselect-bottom"),
		rankedIcon = self:loadImageOrDefault("selection-ranked"),
		danIcon = self:loadImageOrDefault("selection-dan"),
		dropdownArrow = self:loadImageOrDefault("dropdown-arrow"),

		menuBackDefault = self:loadDefaultImage("menu-back"),
		modeButton = self:loadImageOrDefault("selection-mode"),
		modsButton = self:loadImageOrDefault("selection-mods"),
		randomButton = self:loadImageOrDefault("selection-random"),
		optionsButton = self:loadImageOrDefault("selection-options"),

		modeButtonOver = self:loadImageOrDefault("selection-mode-over"),
		modsButtonOver = self:loadImageOrDefault("selection-mods-over"),
		randomButtonOver = self:loadImageOrDefault("selection-random-over"),
		optionsButtonOver = self:loadImageOrDefault("selection-options-over"),

		osuLogo = self:loadImageOrDefault("menu-osu"),
		tab = self:loadImageOrDefault("selection-tab"),
		forum = self:loadImageOrDefault("rank-forum"),
		noScores = self:loadImageOrDefault("selection-norecords"),

		listButtonBackground = self:loadImageOrDefault("menu-button-background"),
		star = self:loadImageOrDefault("star"),
		maniaSmallIcon = self:loadImageOrDefault("mode-mania-small"),
		maniaSmallIconForCharts = self:loadImageOrDefault("mode-mania-small-for-charts"),
		maniaIcon = self:loadImageOrDefault("mode-mania"),

		buttonLeft = self:loadImageOrDefault("button-left"),
		buttonMiddle = self:loadImageOrDefault("button-middle"),
		buttonRight = self:loadImageOrDefault("button-right"),

		smallGradeD = self:loadImageOrDefault("ranking-D-small"),
		smallGradeC = self:loadImageOrDefault("ranking-C-small"),
		smallGradeB = self:loadImageOrDefault("ranking-B-small"),
		smallGradeA = self:loadImageOrDefault("ranking-A-small"),
		smallGradeS = self:loadImageOrDefault("ranking-S-small"),
		smallGradeX = self:loadImageOrDefault("ranking-X-small"),

		cursor = self:loadImageOrDefault("cursor"),
		cursorMiddle = self:loadImageOrDefault("cursormiddle"),
		cursorTrail = self:loadImageOrDefault("cursortrail"),

		uiLock = self:loadImageOrDefault("ui-lock"),

		-- MAIN MENU

		welcomeText = self:loadImageOrDefault("welcome_text"),
		background = self:loadImageOrDefault("menu-background"),
		copyright = self:loadImageOrDefault("menu-copyright"),
		nowPlaying = self:loadImageOrDefault("menu-np"),
		musicPause = self:loadImageOrDefault("menu-pause-music"),
		musicToStart = self:loadImageOrDefault("menu-to-music-start"),
		musicPlay = self:loadImageOrDefault("menu-play-music"),
		musicBackwards = self:loadImageOrDefault("menu-music-backwards"),
		musicForwards = self:loadImageOrDefault("menu-music-forwards"),
		musicInfo = self:loadImageOrDefault("menu-music-info"),
		musicList = self:loadImageOrDefault("menu-music-list"),
		directButton = self:loadImageOrDefault("menu-osudirect"),
		directButtonOver = self:loadImageOrDefault("menu-osudirect-over"),
		menuPlayButton = self:loadImageOrDefault("menu-button-play"),
		menuPlayButtonHover = self:loadImageOrDefault("menu-button-play-over"),
		menuEditButton = self:loadImageOrDefault("menu-button-edit"),
		menuEditButtonHover = self:loadImageOrDefault("menu-button-edit-over"),
		menuOptionsButton = self:loadImageOrDefault("menu-button-options"),
		menuOptionsButtonHover = self:loadImageOrDefault("menu-button-options-over"),
		menuExitButton = self:loadImageOrDefault("menu-button-exit"),
		menuExitButtonHover = self:loadImageOrDefault("menu-button-exit-over"),
		menuSoloButton = self:loadImageOrDefault("menu-button-freeplay"),
		menuSoloButtonHover = self:loadImageOrDefault("menu-button-freeplay-over"),
		menuMultiButton = self:loadImageOrDefault("menu-button-multiplayer"),
		menuMultiButtonHover = self:loadImageOrDefault("menu-button-multiplayer-over"),
		menuBackButton = self:loadImageOrDefault("menu-button-back"),
		menuBackButtonHover = self:loadImageOrDefault("menu-button-back-over"),
		supporter = self:loadImageOrDefault("menu-subscriber"),

		checkboxOff = self:loadImageOrDefault("menu-checkbox-off"),
		checkboxOn = self:loadImageOrDefault("menu-checkbox-on"),
		optionChanged = self:loadImageOrDefault("menu-option-changed"),

		generalTab = self:loadImageOrDefault("menu-general-tab"),
		graphicsTab = self:loadImageOrDefault("menu-graphics-tab"),
		gameplayTab = self:loadImageOrDefault("menu-gameplay-tab"),
		audioTab = self:loadImageOrDefault("menu-audio-tab"),
		skinTab = self:loadImageOrDefault("menu-skin-tab"),
		inputTab = self:loadImageOrDefault("menu-input-tab"),
		maintenanceTab = self:loadImageOrDefault("menu-maintenance-tab"),

		noSkinPreview = self:loadImageOrDefault("no-skin-preview"),
		inputsArrow = self:loadImageOrDefault("inputs-arrow"),

		-- RESULT

		title = self:loadImageOrDefault("ranking-title"),
		panel = self:loadImageOrDefault("ranking-panel"),
		graph = self:loadImageOrDefault("ranking-graph"),
		maxCombo = self:loadImageOrDefault("ranking-maxcombo"),
		accuracy = self:loadImageOrDefault("ranking-accuracy"),
		replay = self:loadImageOrDefault("pause-replay"),

		judgeMarvelous = self:loadImageOrDefault("mania-hit300g"),
		judgePerfect = self:loadImageOrDefault("mania-hit300"),
		judgeGreat = self:loadImageOrDefault("mania-hit200"),
		judgeGood = self:loadImageOrDefault("mania-hit100"),
		judgeBad = self:loadImageOrDefault("mania-hit50"),
		judgeMiss = self:loadImageOrDefault("mania-hit0"),

		gradeSS = self:loadImageOrDefault("ranking-X"),
		gradeS = self:loadImageOrDefault("ranking-S"),
		gradeA = self:loadImageOrDefault("ranking-A"),
		gradeB = self:loadImageOrDefault("ranking-B"),
		gradeC = self:loadImageOrDefault("ranking-C"),
		gradeD = self:loadImageOrDefault("ranking-D"),
		backgroundOverlay = self:loadImageOrDefault("ranking-background-overlay"),

		noLongNote = self:loadImageOrDefault("selection-mod-nolongnote"),
		mirror = self:loadImageOrDefault("selection-mod-mirror"),
		random = self:loadImageOrDefault("selection-mod-random"),
		doubleTime = self:loadImageOrDefault("selection-mod-doubletime"),
		halfTime = self:loadImageOrDefault("selection-mod-halftime"),
		autoPlay = self:loadImageOrDefault("selection-mod-autoplay"),
		automap4 = self:loadImageOrDefault("selection-mod-key4"),
		automap5 = self:loadImageOrDefault("selection-mod-key5"),
		automap6 = self:loadImageOrDefault("selection-mod-key6"),
		automap7 = self:loadImageOrDefault("selection-mod-key7"),
		automap8 = self:loadImageOrDefault("selection-mod-key8"),
		automap9 = self:loadImageOrDefault("selection-mod-key9"),
		automap10 = self:loadImageOrDefault("selection-mod-key10"),
	}

	local menu_back = self.loadImage(skin_path, "menu-back", self.fileList)
	self.images.menuBack = menu_back or self.emptyImage()

	self.hasBackButton = true

	if not menu_back then
		self.hasBackButton = false
	end

	local score_font_path = skin_ini.Fonts.ScorePrefix or "score"
	score_font_path = score_font_path:gsub("\\", "/")

	self.imageFonts = {
		scoreFont = self:getImageFont("score", score_font_path),
	}

	self.sounds = {
		welcome = self:loadAudioOrDefault("welcome"),
		welcomePiano = self:loadAudioOrDefault("welcome_piano"),
		goodbye = self:loadAudioOrDefault("seeya"),
		selectChart = self:loadAudioOrDefault("select-difficulty"),
		selectGroup = self:loadAudioOrDefault("select-expand"),
		hoverOverRect = self:loadAudioOrDefault("click-short"),
		hoverMenu = self:loadAudioOrDefault("menuclick"),
		clickShortConfirm = self:loadAudioOrDefault("click-short-confirm"),

		applause = self:loadAudioOrDefault("applause"),
		menuBack = self:loadAudioOrDefault("menuback"),
		menuHit = self:loadAudioOrDefault("menuhit"),
		menuPlayClick = self:loadAudioOrDefault("menu-play-click"),
		menuEditClick = self:loadAudioOrDefault("menu-edit-click"),
		menuFreeplayClick = self:loadAudioOrDefault("menu-freeplay-click"),
		menuMultiplayerClick = self:loadAudioOrDefault("menu-multiplayer-click"),

		checkOn = self:loadAudioOrDefault("check-on"),
		checkOff = self:loadAudioOrDefault("check-off"),
		sliderBar = self:loadAudioOrDefault("sliderbar"),
		selectExpand = self:loadAudioOrDefault("select-expand"),
	}

	self.images.panelTop:setWrap("clamp")

	--self.selectViewConfig = love.filesystem.load(skin_path .. "SelectViewConfig.lua")
	--self.resultViewConfig = love.filesystem.load(skin_path .. "ResultViewConfig.lua")

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

	for _, v in ipairs(self.errors) do
		print(v)
	end
end

---@param filepath string
function OsuAssets:loadLocalization(filepath)
	if not self.localization then
		self.localization = Localization(filepath, 768)
		return
	end

	if self.localization.currentFilePath ~= filepath then
		self.localization:loadFile(filepath)
	end
end

return OsuAssets
