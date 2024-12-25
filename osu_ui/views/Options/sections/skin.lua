local utf8validate = require("utf8validate")
local Format = require("sphere.views.Format")

local function formatSkinName(v, input_mode)
	if not v then -- error in _k.config.lua
		return "Failed to load skin"
	end

	local k = Format.inputMode(tostring(input_mode))
	local name = ("[%s] %s"):format(k, v.name)
	if not name then
		return "??"
	end
	local len = name:len()
	if len > 38 then
		return utf8validate(name:sub(1, 38), ".") .. ".."
	end

	return name
end

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local settings = configs.settings

	local select_api = section.options.ui.selectApi

	local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
	local text = scene.localization.text

	section:group(text.Options_Skin, function(group)
		local current_input_mode ---@type string?
		local selected_note_skin ---@type sphere.NoteSkin
		local skins ---@type table

		local skins_combo = group:combo({
			label = text.Options_SkinSelect,
			items = {},
			setValue = function(index)
				if not current_input_mode then
					return
				end
				local skin = skins[index]
				select_api:setNoteSkin(current_input_mode, skin:getPath())
				current_input_mode = tostring(select_api:getCurrentInputMode()) -- what is the point of this line? I don't remember
			end,
			format = function(v)
				return formatSkinName(v, current_input_mode)
			end
		})
		if skins_combo then
			skins_combo.getValue = function ()
				local im = select_api:getCurrentInputMode()
				if im ~= current_input_mode then
					current_input_mode = im
					local str_im = tostring(im)
					selected_note_skin = select_api:getNoteSkin(str_im)
					skins = select_api:getNoteSkinInfos(str_im)
					skins_combo.items = skins
					skins_combo:addItems()
				end
				return selected_note_skin
			end
			skins_combo:update()
		end

		group:button({
			label = text.Options_SkinPreview,
			color = { 0.84, 0.38, 0.47, 1 },
			onClick = function()
				local current_screen = scene:getChild(scene.currentScreenId)
				if current_screen then
					---@cast current_screen osu.ui.Screen
					scene:hideOverlay()
					section.options:fade(0)
					current_screen:transitOut({
						onComplete = function ()
							select_api:setAutoplay(true)
							scene:transitInScreen("gameplay")
						end
					})
				end
			end
		})

		group:button({
			label = text.Options_SkinSettings,
			onClick = function()
				scene.notification:show("Not implemented")
			end
		})
	end)
end
