local ui = {}

function ui.lighten(c, amount)
	return {
		math.min(1, c[1] * (1 + amount)),
		math.min(1, c[2] * (1 + amount)),
		math.min(1, c[3] * (1 + amount)),
		c[4],
	}
end

return ui
