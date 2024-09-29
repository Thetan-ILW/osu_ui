---@class osu.ui.OsuConfig
local t = {
	skin = "Default",
	language = "English",
	originalMetadata = false,
	scoreSystem = "soundsphere",
	judgement = 0,
	cursor = {
		size = 1,
		showTrail = true,
		trailLifetime = 3,
		trailDensity = 10,
		trailMaxImages = 60,
		trailStyle = "Vanishing"
	},
	mainMenu = {
		disableIntro = false,
		hideGameTips = false,
	},
	songSelect = {
		previewIcon = false,
		scoreSource = "local",
		preciseRates = false
	},
	result = {
		hitGraph = false,
		pp = false,
		difficultyAndRate = true,
	},
	uiVolume = 0.4,
	vimMotions = false,
	keybinds = {
		quit = "escape",
		increaseVolume = { mod = { "alt", "up" } },
		decreaseVolume = { mod = { "alt", "down" } },
		play = "return",
		showMods = "f1",
		random = "f2",
		decreaseTimeRate = "f5",
		increaseTimeRate = "f6",
		exportToOsu = { mod = { "ctrl", "shift", "o" } },

		-- Modals
		showFilters = { mod = { "ctrl", "f" } },
		showInputs = { mod = { "ctrl", "i" } },
		showSettings = { mod = { "ctrl", "o" } },
		autoPlay = { mod = { "ctrl", "return" } },
		openEditor = { mod = { "ctrl", "e" } },
		openResult = { mod = { "ctrl", "r" } },

		undoRandom = { mod = { "ctrl", "f2" } },
		deleteLine = { mod = { "ctrl", "backspace" } },
		moveScreenLeft = { mod = { "ctrl", "left" } },
		moveScreenRight = { mod = { "ctrl", "right" } },
		pauseMusic = { mod = { "ctrl", "p" } },
		watchReplay = "w",
		retry = "r",
		submitScore = "s",

		-- Movement
		up = "up",
		down = "down",
		left = "left",
		right = "right",
		up10 = "pageup",
		down10 = "pagedown",
		toStart = "home",
		toEnd = "end",
	},
	vimKeybinds = {
		-- Input
		insertMode = "i",
		normalMode = "escape",
		deleteLine = { op = { "d", "d" } },
		quit = { mod = { "shift", "escape" } },
		exportToOsu = { op = { "e", "o" } },

		-- Modals
		showMods = { op = { "o", "m" } },
		showFilters = { op = { "o", "f" } },
		showInputs = { op = { "o", "i" } },
		showSettings = { op = { "o", "o" } },
		openEditor = { op = { "o", "e" } },

		increaseVolume = "'",
		decreaseVolume = ";",
		play = "return",
		random = "r",
		decreaseTimeRate = "[",
		increaseTimeRate = "]",
		undoRandom = "u",
		moveScreenLeft = { mod = { "ctrl", "h" } },
		moveScreenRight = { mod = { "ctrl", "l" } },
		pauseMusic = { mod = { "ctrl", "p" } },
		autoPlay = { mod = { "ctrl", "return" } },
		watchReplay = "w",
		retry = "r",
		submitScore = "s",

		-- Movement
		up = "h",
		down = "l",
		left = "k",
		right = "j",
		up10 = { mod = { "ctrl", "u" } },
		down10 = { mod = { "ctrl", "d" } },
		toStart = { op = { "g", "g" } },
		toEnd = { mod = { "shift", "g" } },
	},
}

return t
