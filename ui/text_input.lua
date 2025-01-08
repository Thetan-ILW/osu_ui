local utf8 = require("utf8")

local text_input = {}

local function text_split(text, index)
	local _index = utf8.offset(text, index) or 1
	return text:sub(1, _index - 1), text:sub(_index)
end

function text_input.removeChar(text)
	local index = utf8.len(text) + 1
	local _
	local left, right = text_split(text, index)

	left, _ = text_split(left, utf8.len(left))
	index = math.max(1, index - 1)

	return left .. right
end

return text_input
