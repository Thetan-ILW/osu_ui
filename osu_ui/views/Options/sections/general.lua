local version = require("version")
local ConfirmationModal = require("osu_ui.views.modals.Confirmation")
local ChartImport = require("osu_ui.views.ChartImport")

local wait_for_login = false
local wait_for_logout = false

local game_updated = nil

---@param group osu.ui.OptionsGroup
local function login(group)
	local email_tb = group:textBox({ label = "Email" })
	local password_tb = group:textBox({ label = "Password", password = true })
	if email_tb and password_tb then
		group:button({ label = "Sign In", color = { 0.05, 0.52, 0.65, 1 },
			onClick = function ()
				group.game.onlineModel.authManager:login(email_tb.input, password_tb.input)
				wait_for_login = true
			end
		})
		group:button({ label = "Create an account", color = { 0.05, 0.52, 0.65, 1 },
			onClick = function ()
				love.system.openURL("https://soundsphere.xyz/register")
			end
		})
	end
end

---@param group osu.ui.OptionsGroup
local function loggedIn(group)
	local username = group.game.configModel.configs.online.user.name
	group:label({
		height = 100,
		label = ("You are logged in as %s"):format(username or "?"),
		onClick = function ()
			group.game.onlineModel.authManager:logout()
			wait_for_logout = true
		end
	} )
end

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local osu = configs.osu_ui ---@cast osu osu.ui.OsuConfig
	local m = configs.settings.miscellaneous
	local ss = configs.settings.select
	local gf = configs.settings.graphics
	local dim = gf.dim

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	section:group("SIGN IN", function(group)
		local active = next(group.game.configModel.configs.online.session)

		local base_update = group.update
		function group:update(dt)
			if wait_for_login then
				local logged_in = next(group.game.configModel.configs.online.session)
				if logged_in then
					local username = group.game.configModel.configs.online.user.name
					if username then
						wait_for_login = false
						group:load()
						section.options:recalcPositions()
					end
				end
			end
			if wait_for_logout then
				local logged_in = next(group.game.configModel.configs.online.session)
				if not logged_in then
					wait_for_logout = false
					group:load()
					section.options:recalcPositions()
				end
			end
			base_update(group, dt)
		end

		if active then
			loggedIn(group)
		else
			login(group)
		end
	end)

	section:group(text.Options_Graphics_Language, function(group)
		local localization_list = scene.ui.assetModel:getLocalizationNames()
		group:combo({
			label = text.Options_Graphics_SelectLanguage,
			items = localization_list,
			getValue = function()
				return osu.language
			end,
			setValue = function(index)
				local lang = localization_list[index]
				osu.language = lang.name
				scene:reloadUI()
			end,
			format = function(v)
				return v.name
			end
		})
	end)

	if not scene.ui.isGucci then
		section:group(text.Options_Updates, function(group)
			group:checkbox({
				label = text.Options_Updates_AutoUpdate,
				key = { m, "autoUpdate" }
			})

			if game_updated == nil then
				game_updated = m.autoUpdate
			end

			local git = love.filesystem.getInfo(".git")
			local version_label = git and text.Update_Git or (game_updated and text.Update_Complete:format(version.commit:sub(1, 6)) or text.Update_NotComplete)

			group:label({
				label = version_label,
				alignX = "left",
			})

			group:button({
				label = text.Options_OpenOsuFolder,
				onClick = function()
					love.system.openURL(love.filesystem.getSource())
				end
			})
		end)
	else
		section:group(text.Options_Updates, function(group)
			local updater = scene.ui.updater

			local label = group:label({
				label = updater.status,
				alignX = "left",
				height = 100,
			})
			if label then
				---@param this ui.Label
				function label.update(this)
					---@type string
					local status = updater.status
					if this.text ~= status then
						this:replaceText(updater.status)
					end
				end
			end

			group:combo({
				label = text.Options_ReleaseStream,
				items = updater.branches,
				getValue = function ()
					return osu.gucci.branch
				end,
				setValue = function(index)
					osu.gucci.branch = updater.branches[index]
					if label then
						label:replaceText("Restart the game")
					end
					scene.notification:show("Restart the game.")
				end,
				format = function(v)
					if v == "stable" then
						return text.Options_ReleaseStrategy_Stable
					elseif v == "develop" then
						return text.Options_ReleaseStrategy_CuttingEdge
					end
					return v
				end
			})

			group:button({
				label = text.Options_OpenOsuFolder,
				onClick = function()
					love.system.openURL(love.filesystem.getSource())
				end
			})
		end)
	end


	section:group(text.Options_OtherGames, function(group)
		local other_games = scene.ui.otherGames

		if other_games.gamesFound == 0 then
			return
		end

		local s = text.Options_GamesInstalled:format(other_games.gamesFound)
		for k, _ in pairs(other_games.games) do
			s = s .. "\n" .. k
		end

		group:label({
			label = s
		})

		group:button({
			label = text.Options_OtherGames_AddSongsFromOtherGames,
			onClick = function ()
				local modal = scene:addChild("confirmation", ConfirmationModal({
					text = text.Options_OtherGames_AddSongsConfirm,
					z = 0.5,
					onClickYes = function(this)
						scene.ui:mountOtherGamesCharts()
						scene:addChild("chartImport", ChartImport({ z = 0.6, cacheAll = true }))
						this:close()
					end
				}))
				modal:open()
			end
		})

		if other_games.games["osu!"] then
			group:checkbox({
				label = text.Options_OtherGames_OsuSkins,
				getValue = function ()
					return osu.dangerous.mountOsuSkins
				end,
				clicked = function ()
					osu.dangerous.mountOsuSkins	= not osu.dangerous.mountOsuSkins
					scene.ui:mountOsuSkins()
					scene:reloadUI()
				end,
			})
		end
	end)

	section:group(text.Options_MainMenu, function(group)
		group:checkbox({
			label = text.Options_Menu_DisableIntro,
			key = { osu.mainMenu, "disableIntro" }
		})

		group:checkbox({
			label = text.Options_Menu_ShowTips,
			key = { osu.mainMenu, "hideGameTips" }
		})
	end)

	section:group(text.Options_SongSelect, function(group)
		local diff_columns = {
			"enps_diff",
			"osu_diff",
			"msd_diff",
			"user_diff",
		}

		local diff_columns_names = {
			enps_diff = "ENPS",
			osu_diff = "OSU",
			msd_diff = "MSD",
			user_diff = "USER",
		}

		group:combo({
			label = text.Options_DifficultyCalculator,
			items = diff_columns,
			getValue = function()
				return ss.diff_column
			end,
			setValue = function(index)
				ss.diff_column = diff_columns[index]
				scene.ui.selectApi:debouncePullNoteChartSet()
				scene:reloadUI()
			end,
			format = function(v)
				return diff_columns_names[v]
			end
		})

		group:slider({
			label = text.FunSpoiler_BackgroundDim,
			min = 0,
			max = 1,
			step = 0.01,
			getValue = function()
				return dim.select
			end,
			setValue = function(v)
				dim.select = v
				if scene.currentScreenId == "select" then
					scene.background.dim = v
				end
			end,
			format = function(v)
				return ("%i%%"):format(v * 100)
			end
		})

		group:checkbox({
			label = text.Options_SongSelect_DisplayDifficultyTable,
			getValue = function ()
				return osu.songSelect.diffTable
			end,
			clicked = function ()
				osu.songSelect.diffTable = not osu.songSelect.diffTable
				scene:reloadUI()
			end
		})

		group:checkbox({
			label = text.Options_SongSelect_Thumbnails,
			key = { osu.songSelect, "previewIcon" }
		})

		group:checkbox({
			label = text.Options_SongSelect_BeatmapPreview,
			key = { ss, "chart_preview" }
		})

		group:checkbox({
			label = text.Options_SongSelect_PreciseRates,
			key = { osu.songSelect, "preciseRates" }
		})
	end)

	section:group(text.Options_Result, function(group)
		group:slider({
			label = text.FunSpoiler_BackgroundDim,
			min = 0,
			max = 1,
			step = 0.01,
			getValue = function()
				return dim.result
			end,
			setValue = function(v)
				dim.result = v
				if scene.currentScreenId == "result" then
					scene.background.dim = v
				end
			end,
			format = function(v)
				return ("%i%%"):format(v * 100)
			end
		})

		group:checkbox({
			label = text.Options_Result_AlwaysDisplayScores,
			key = { osu.result, "alwaysDisplayScores" }
		})

		group:checkbox({
			label = text.Options_Result_DisplayJudgmentName,
			key = { osu.result, "judgmentName" }
		})

		group:checkbox({
			label = text.Options_Result_DisplayDifficultyAndRate,
			key = { osu.result, "difficultyAndRate" }
		})

		group:checkbox({
			label = text.Options_Result_DisplayHitGraph,
			key = { osu.result, "hitGraph" }
		})
	end)
end
