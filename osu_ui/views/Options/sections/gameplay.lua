---@param section osu.ui.OptionsSection
return function(section)
	section:group("LOL", function(group)
		group:textBox({ label = "hello!" })
		group:button({ label = "goodbye" })
		group:label({ label = "hello!" })

		local items = { 1, 2, 3 }
		local value = 1
		group:combo({ label = "hello!", items = items,
			getValue = function ()
				return value
			end,
			onChange = function(v)
				value = v
			end
		})
	end)
end
