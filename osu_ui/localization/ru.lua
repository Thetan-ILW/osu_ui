local l = {}

l.textGroups = {
	songSelect = {
		mappedBy = "Карта от %s",
		from = "Из %s",
		chartInfoFirstRow = "Длина: %s BPM: %i Объектов: %i",
		chartInfoSecondRow = "Круги: %i Слайдеры: %i Спиннеры: %i",
		chartInfoThirdRow = "Клавиш: %s OD: %g HP: %g Сложность: %s",
		--
		localRanking = "Локальный топ",
		onlineRanking = "Топ мира",
		osuApiRanking = "Топ osu! API",
		--
		collections = "Коллекции",
		recent = "Недавнее",
		artist = "Артист",
		difficulty = "Сложность",
		noGrouping = "Всё вместе",
		--
		group = "Группировать",
		sort = "Сортировка",
		byCharts = "По картам",
		byLocations = "По локации",
		byDirectories = "По директории",
		byId = "По ID",
		byTitle = "По названию",
		byArtist = "По артисту",
		byDifficulty = "По сложности",
		byLevel = "По уровню",
		byLength = "По длине",
		byBpm = "По BPM",
		byModTime = "По времени мод.",
		bySetModTime = "По времени мод. набора",
		byLastPlayed = "По дате игры",
		--
		search = "Поиск:",
		searchInsert = "Поиск (Вставка):",
		typeToSearch = "введите название",
		noMatches = "Ничего не найдено.",
		matchesFound = "%i совпадений.",
	},
	scoreList = {
		score = "Очки",
		hasMods = "Есть моды",
	},
	chartOptionsModal = {
		manageLocations = "1. Управление локациями",
		chartInfo = "2. Информация о карте",
		filters = "3. Фильтры",
		edit = "4. Редактировать",
		fileManager = "5. Открыть в файловом менеджере",
		cancel = "6. Отмена",
	},
}

l.fontFiles = {
	["ZenMaruGothic-Black"] = "resources/osu_default_assets/ui_font/ZenMaruGothic/ZenMaruGothic-Black.ttf",
	["ZenMaruGothic-Medium"] = "resources/osu_default_assets/ui_font/ZenMaruGothic/ZenMaruGothic-Medium.ttf",
	["ZenMaruGothic-Bold"] = "resources/osu_default_assets/ui_font/ZenMaruGothic/ZenMaruGothic-Bold.ttf",
	["ZenMaruGothic-Regular"] = "resources/osu_default_assets/ui_font/ZenMaruGothic/ZenMaruGothic-Regular.ttf",
	["Aller"] = "resources/osu_default_assets/ui_font/Aller/Aller_Rg.ttf",
	["Aller-Light"] = "resources/osu_default_assets/ui_font/Aller/Aller_Lt.ttf",
	["Aller-Bold"] = "resources/osu_default_assets/ui_font/Aller/Aller_Bd.ttf",
}

l.fontGroups = {
	songSelect = {
		chartName = { "Aller", 25, "ZenMaruGothic-Medium" },
		chartedBy = { "Aller", 16, "ZenMaruGothic-Medium" },
		infoTop = { "Aller-Bold", 16, "ZenMaruGothic-Bold" },
		infoCenter = { "Aller", 16, "ZenMaruGothic-Regular" },
		infoBottom = { "Aller", 12, "ZenMaruGothic-Regular" },
		dropdown = { "Aller", 19, "ZenMaruGothic-Regular" },
		groupSort = { "Aller", 30, "ZenMaruGothic-Regular" },
		username = { "Aller", 20, "ZenMaruGothic-Regular" },
		belowUsername = { "Aller", 14 },
		rank = { "Aller-Light", 50 },
		scrollSpeed = { "Aller-Light", 23 },
		tabs = { "Aller", 14, "ZenMaruGothic-Regular" },
		mods = { "Aller", 41 },
		search = { "Aller-Bold", 18, "ZenMaruGothic-Bold" },
		searchMatches = { "Aller-Bold", 15, "ZenMaruGothic-Bold" },
	},

	chartSetList = {
		title = { "Aller", 22, "ZenMaruGothic-Medium" },
		secondRow = { "Aller", 16, "ZenMaruGothic-Medium" },
		thirdRow = { "Aller-Bold", 16, "ZenMaruGothic-Medium" },
		noItems = { "Aller", 36 },
	},

	scoreList = {
		username = { "Aller-Bold", 22, "ZenMaruGothic-Medium" },
		score = { "Aller", 16 },
		rightSide = { "Aller", 14 },
		noItems = { "Aller", 36 },
	},

	chartOptionsModal = {
		title = { "Aller-Light", 33 },
		buttons = { "Aller", 42, "ZenMaruGothic-Regular" },
	},
}

return l
