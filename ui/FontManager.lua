local class = require("class")

local Font = require("ui.Font")

---@class ui.FontManager
---@operator call: ui.FontManager
---@field fonts {[string]: ui.Font}
local FontManager = class()

---@param target_height number
---@param files {[string]: string}
---@param fallbacks {[string]: string}
function FontManager:new(target_height, files, fallbacks)
	self.currentViewportHeight = 0
	self.targetHeight = target_height
	self.fontFiles = files
	self.fontFilesFallbacks = fallbacks
	self.fonts = {}
end

---@param v number
function FontManager:setVieportHeight(v)
	self.currentViewportHeight = v
end

---@return number
function FontManager:getTextDpiScale()
	return math.ceil(self.currentViewportHeight / self.targetHeight)
end

---@param name string
---@param size number
---@return ui.Font
function FontManager:loadFont(name, size)
	if self.currentViewportHeight < 1 then
		error("Current viewport height is less than 1")
	end

	local formatted_name = ("%s_%i@%ix"):format(name, size, self:getTextDpiScale())

	if self.fonts[formatted_name] then
		return self.fonts[formatted_name]
	end

	local filename = self.fontFiles[name]

	if not filename then
		error(("No such font: %s"):format(filename))
	end

	local dpi_scale = self:getTextDpiScale()
	local s = size * dpi_scale

	local font = Font(love.graphics.newFont(filename, s), dpi_scale)

	if self.fontFilesFallbacks[name] then
		font:addFallback(love.graphics.newFont(self.fontFilesFallbacks[name], s))
	end

	font:setFilter("linear", "nearest")

	self.fonts[formatted_name] = font
	return font
end

return FontManager
