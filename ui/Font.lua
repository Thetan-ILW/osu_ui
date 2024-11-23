local class = require("class")

---@class ui.Font
---@operator call: ui.Font
---@field instance love.Font
---@field dpiScale number
local Font = class()

function Font:new(instance, dpi_scale)
	self.instance = instance
	self.dpiScale = dpi_scale
	self.fallbacks = {}
end

function Font:addFallback(font)
	table.insert(self.fallbacks, font)
	self.instance:setFallbacks(unpack(self.fallbacks))
end

---@param min string
---@param mag string
function Font:setFilter(min, mag)
	self.instance:setFilter(min, mag)
end

---@param text string
---@return number
function Font:getWidth(text)
	return self.instance:getWidth(text)
end

---@return number
function Font:getHeight()
	return self.instance:getHeight()
end


return Font
