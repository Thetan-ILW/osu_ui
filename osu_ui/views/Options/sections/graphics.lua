local utf8validate = require("utf8validate")

---@param section osu.ui.OptionsSection
return function(section)
	local configs = section.options:getConfigs()
	local osu = configs.osu_ui ---@cast osu osu.ui.OsuConfig
	local ui = section.options.ui

	section:group("GRAPHICS", function(group)
		group:checkbox({ label = "Enable blur",
			getValue = function ()
				return osu.graphics.blur
			end,
			clicked = function ()
				osu.graphics.blur = not osu.graphics.blur
				section.options:reloadViewport()
			end
		})

		group:slider({ label = "Blur quality", min = 0.1, max = 0.7, step = 0.01,
			getValue = function()
				return osu.graphics.blurQuality
			end,
			setValue = function(v)
				osu.graphics.blurQuality = v
			end,
		})

		local skins = ui.assetModel:getOsuSkins()
		group:combo({
			items = skins,
			getValue = function ()
				return osu.skin
			end,
			setValue = function(index)
				osu.skin = skins[index]
				local scene = section:findComponent("scene") ---@cast scene osu.ui.Scene
				scene:loadAssets()
				scene:load()
			end,
			format = function(v)
				if not v then
					return "??"
				end
				local len = v:len()
				if len > 38 then
					return utf8validate(v:sub(1, 38), ".") .. ".."
				end
				return v
			end

		})
	end)
end
