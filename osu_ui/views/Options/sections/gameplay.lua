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
			setValue = function(v)
				value = v
			end
		})

		local b = false
		group:checkbox({ label = "goodbye",
			getValue = function ()
				return b
			end,
			clicked = function ()
				b = not b
			end
		})

		local happiness = 0
		group:slider({ label = "Happiness", min = 0, max = 100, step = 1,
			getValue = function ()
				return happiness
			end,
			setValue = function (v)
				happiness = v
			end
		})
	end)
end
