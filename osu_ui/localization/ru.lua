local l = {}

l.textGroups = {
	mainMenu = {
		chartCount = "Доступно %i карт.",
		sessionTime = "Время работы игры %s",
		time = "Текущее время %s",
		supporter = "Они следят за тобой."
	},
	songSelect = {
		mappedBy = "Карта от %s",
		from = "Из %s",
		chartInfoFirstRow = "Длина: %s BPM: %s Объектов: %s",
		chartInfoSecondRow = "Круги: %s Слайдеры: %s Спиннеры: %s",
		chartInfoThirdRow = "Клавиш: %s OD: %s HP: %s Сложность: %s",
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
	["ZenMaruGothic-Black"] = "osu_ui/assets/ui_font/ZenMaruGothic/ZenMaruGothic-Black.ttf",
	["ZenMaruGothic-Medium"] = "osu_ui/assets/ui_font/ZenMaruGothic/ZenMaruGothic-Medium.ttf",
	["ZenMaruGothic-Bold"] = "osu_ui/assets/ui_font/ZenMaruGothic/ZenMaruGothic-Bold.ttf",
	["ZenMaruGothic-Regular"] = "osu_ui/assets/ui_font/ZenMaruGothic/ZenMaruGothic-Regular.ttf",
	["Aller"] = "osu_ui/assets/ui_font/Aller/Aller_Rg.ttf",
	["Aller-Light"] = "osu_ui/assets/ui_font/Aller/Aller_Lt.ttf",
	["Aller-Bold"] = "osu_ui/assets/ui_font/Aller/Aller_Bd.ttf",
}

l.fontGroups = {
	misc = {
		backButton = { "Aller", 20, "ZenMaruGothic-Regular" },
		notification = { "Aller", 24, "ZenMaruGothic-Regular" },
		popup = { "Aller", 14, "ZenMaruGothic-Regular" },
		tooltip = { "Aller", 14, "ZenMaruGothic-Regular" },
	},
	mainMenu = {
		username = { "Aller", 20, "ZenMaruGothic-Regular" },
		belowUsername = { "Aller", 14 },
		rank = { "Aller-Light", 50 },
		info = { "Aller", 18, "ZenMaruGothic-Regular" },
		gameTip = { "Aller", 22, "ZenMaruGothic-Regular" },
	},
	settings = {
		optionsLabel = { "Aller-Light", 28, "ZenMaruGothic-Regular" },
		gameBehaviorLabel = { "Aller-Light", 19, "ZenMaruGothic-Regular" },
		search = { "Aller", 25, "ZenMaruGothic-Regular" },
		tabLabel = { "Aller", 33, "ZenMaruGothic-Regular" },
		groupLabel = { "Aller-Bold", 16, "ZenMaruGothic-Regular" },
		buttons = { "Aller", 16, "ZenMaruGothic-Regular" },
		checkboxes = { "Aller", 16, "ZenMaruGothic-Regular" },
		combos = { "Aller", 16, "ZenMaruGothic-Regular" },
		sliders = { "Aller", 16, "ZenMaruGothic-Regular" },
		labels = { "Aller", 16, "ZenMaruGothic-Regular" },
	},
	songSelect = {
		chartName = { "Aller", 25, "ZenMaruGothic-Regular" },
		chartedBy = { "Aller", 16, "ZenMaruGothic-Regular" },
		infoTop = { "Aller-Bold", 16, "ZenMaruGothic-Black" },
		infoCenter = { "Aller", 16, "ZenMaruGothic-Medium" },
		infoBottom = { "Aller", 12, "ZenMaruGothic-Medium" },
		dropdown = { "Aller", 18 },
		groupSort = { "Aller-Light", 30 },
		username = { "Aller", 20, "ZenMaruGothic-Medium" },
		belowUsername = { "Aller", 14 },
		rank = { "Aller-Light", 50 },
		scrollSpeed = { "Aller-Light", 23 },
		tabs = { "Aller", 14 },
		mods = { "Aller", 41 },
		search = { "Aller-Bold", 18, "ZenMaruGothic-Bold" },
		searchMatches = { "Aller-Bold", 15 },
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
		title = { "Aller-Light", 33, "ZenMaruGothic-Regular" },
		buttons = { "Aller", 42, "ZenMaruGothic-Regular" },
	},
	modifiersModal = {
		title = { "Aller-Light", 33, "ZenMaruGothic-Regular" },
		mode = { "Aller-Light", 41, "ZenMaruGothic-Regular" },
		buttons = { "Aller", 42, "ZenMaruGothic-Regular" },
		modifierName = { "Aller-Light", 20, "ZenMaruGothic-Regular" },
		numberOfUses = { "Aller-Light", 14, "ZenMaruGothic-Regular" },
		notSelected = { "Aller", 16, "ZenMaruGothic-Regular" },
		sliders = { "Aller", 16, "ZenMaruGothic-Regular" },
		checkboxes = { "Aller", 16, "ZenMaruGothic-Regular" },
	},
	filtersModal = {
		title = { "Aller-Light", 33, "ZenMaruGothic-Regular" },
		checkboxes = { "Aller", 16, "ZenMaruGothic-Regular" },
		buttons = { "Aller", 42, "ZenMaruGothic-Regular" },
		groupButtons = { "Aller", 25, "ZenMaruGothic-Regular" },
	},
	skinSettingsModal = {
		title = { "Aller-Light", 33, "ZenMaruGothic-Regular" },
		mode = { "Aller-Light", 41, "ZenMaruGothic-Regular" },
		buttons = { "Aller", 42, "ZenMaruGothic-Regular" },
		noSettings = { "Aller", 24, "ZenMaruGothic-Regular" },
		noteSkinSettings = { "Aller", 24, "ZenMaruGothic-Regular" },
	},
	inputsModal = {
		title = { "Aller-Light", 33, "ZenMaruGothic-Regular" },
		combos = { "Aller", 16, "ZenMaruGothic-Regular" },
		binds = { "Aller", 16, "ZenMaruGothic-Regular" },
	},
	result = {
		title = { "Aller-Light", 30, "ZenMaruGothic-Regular" },
		creator = { "Aller", 22, "ZenMaruGothic-Regular" },
		playInfo = { "Aller", 22, "ZenMaruGothic-Regular" },
		graphInfo = { "ZenMaruGothic-Regular", 18 },
		pp = { "ZenMaruGothic-Medium", 36 },
	},
	uiLock = {
		title = { "Aller-Bold", 48 },
		status = { "Aller", 36 },
	},
}

return l
