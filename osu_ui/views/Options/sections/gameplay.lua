---@param section osu.ui.OptionsSection
return function(section)
	section:group("LOL", function(group)
		group:label({ label = "hi there" })
	end)
end
