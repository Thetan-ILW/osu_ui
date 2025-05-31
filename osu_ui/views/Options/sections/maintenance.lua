local ConfirmationModal = require("osu_ui.views.modals.Confirmation")
local ChartImport = require("osu_ui.views.ChartImport")
local RecalcScores = require("osu_ui.views.RecalcScores")

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	section:group(text.Options_Other, function (group)
		local nickname_textbox = group:textBox({
			label = text.Options_OfflineNickname,
			value = configs.osu_ui.offlineNickname
		})

		if nickname_textbox then
			group:button({
				label = text.General_Apply,
				onClick = function()
					if configs.osu_ui.offlineNickname ~= nickname_textbox.input then
						configs.osu_ui.offlineNickname = nickname_textbox.input:sub(1, 20)
						section:getViewport():triggerEvent("event_nicknameChanged")
					end
				end
			})
		end
	end)

	section:group(text.Options_TabMaintenance, function(group)
		group:button({
			label = text.Options_SwitchToLegacyUI,
			onClick = function ()
				local modal = scene:addChild("confirmation", ConfirmationModal({
					text = text.Options_UISwitchConfirm,
					z = 0.5,
					onClickYes = function()
						scene.ui:switchTheme("Default")
					end
				}))
				modal:open()
			end
		})

		group:button({
			label = "Recalculate cache",
			color = { 0.91, 0.19, 0, 1 },
			onClick = function()
				local modal = scene:addChild("confirmation", ConfirmationModal({
					text = "THIS MAY TAKE SEVERAL HOURS!!! ARE YOU SURE?",
					z = 0.5,
					onClickYes = function()
						scene.ui.locationsApi:deleteChartCache()
						scene:addChild("chartImport", ChartImport({ z = 0.6, cacheAll = true }))
					end
				}))
				modal:open()
			end
		})

		group:button({
			label = "Recalculate scores",
			color = { 0.91, 0.19, 0, 1 },
			onClick = function()
				local modal = scene:addChild("confirmation", ConfirmationModal({
					text = "Recalculate scores? This may take a while.",
					z = 0.5,
					onClickYes = function()
						scene:addChild("recalcScores", RecalcScores({ z = 0.6 }))
					end
				}))
				modal:open()
			end
		})

		group:label({
			label = "gucci!mania supporters:\nwrongsider - 2 bottles of beer and 1 bicycle"
		})
	end)
end
