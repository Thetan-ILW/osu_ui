---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text
	local select_api = scene.ui.selectApi

	local leaderboards = select_api:getOnlineLeaderboards()

	if #leaderboards == 0 then
		return
	end

	section:group(text.Options_TabOnline, function (group)
		group:combo({
			label = text.Options_Online_Leaderboard,
			items = leaderboards,
			getValue = function ()
				return select_api:getOnlineLeaderboard(configs.osu_ui.leaderboardId)
			end,
			setValue = function (index)
				configs.osu_ui.leaderboardId = index
				section.options:getViewport():triggerEvent("event_leaderboardChanged")
			end,
			format = function (v)
				return v.name
			end
		})
	end)
end
