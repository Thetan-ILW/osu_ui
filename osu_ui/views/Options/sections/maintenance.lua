local ConfirmationModal = require("osu_ui.views.modals.Confirmation")

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

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
			label = "Пить пиво играть танки",
			onClick = function()
				scene.notification:show("Flооb1nk — Today at 12:40 PM а где кнопка пить пиво играть танки")
			end
		})
	end)
end
