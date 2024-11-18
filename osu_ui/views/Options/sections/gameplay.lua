---@param section osu.ui.OptionsSection
return function(section)
	section:group("LOL", function(group)
		group:label({ label = "hi there" })

		local boolean = { "true", "false", "nil", "not sure", "no", "maybe", "in between", "not true", "not false" }
		local value = boolean[1]
		group:combo({
			label = "Booleans",
			items = boolean,
			getValue = function ()
				return value
			end,
			onChange = function(index)
				value = boolean[index]
			end,
			format = function(v)
				return v:upper()
			end
		})
	end)
end
