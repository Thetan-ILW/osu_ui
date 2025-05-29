---@class osu.ui.OsuConfig
local t = {
	skin = "Default",
	language = "English",
	uiVolume = 0.4,
	copyScreenshotToClipboard = true,
	offlineNickname = "Guest",
	playerInfoRating = "pp",
	dangerous = {
		mountOsuSkins = false,
		gucciInstalled = false
	},
	cursor = {
		size = 1,
		showTrail = true,
		trailLifetime = 6,
		trailDensity = 27,
		trailMaxImages = 210,
		trailStyle = "Shrinking"
	},
	mainMenu = {
		disableIntro = false,
		hideGameTips = false,
	},
	songSelect = {
		previewIcon = false,
		groupCharts = false,
		scoreSource = "local",
		preciseRates = false,
		spaceBetweenPanels = 77,
		diffTable = true,
		diffTableImageMsd = true,
	},
	result = {
		hitGraph = false,
		difficultyAndRate = true,
		judgmentName = true,
		alwaysDisplayScores = false
	},
	gameplay = {
		nativeRes = false,
		nativeResX = 0.5,
		nativeResY = 0.5
		--nativeResSize is defined in the gameplay settings!!!
	},
	graphics = {
		blur = true,
		blurQuality = 0.5,
	},
	keybinds = {
		---@class osu.ui.GameplayKeybinds
		gameplay = {
			retry = "`",
			pause = "escape",
			skipIntro = "space",
			decreaseScrollSpeed = "f3",
			increaseScrollSpeed = "f4",
			decreaseLocalOffset = "-",
			increaseLocalOffset = "=",
		}
	}
}

return t
