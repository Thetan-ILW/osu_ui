local class = require("class")
local Font = require("ui.Font")

---@class ui.FontManager
---@operator call: ui.FontManager
---@field fonts {[string]: ui.Font}
local FontManager = class()

---@param target_height number
function FontManager:new(target_height)
	self.currentViewportHeight = 0
	self.targetHeight = target_height
	self.fontPaths = {} ---@type {[string]: string}
	self.fontFallbackPaths = {} ---@type {[string]: string}
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

---@param font_name string
---@param font_path string
---@param fallback_path string?
function FontManager:addFont(font_name, font_path, fallback_path)
	self.fontPaths[font_name] = font_path
	if fallback_path then
		self.fontFallbackPaths[font_name] = fallback_path
	end
end

---@param name string
---@param size number
---@return ui.Font
function FontManager:loadFont(name, size)
	local formatted_name = ("%s_%i@%ix"):format(name, size, self:getTextDpiScale())

	if self.fonts[formatted_name] then
		return self.fonts[formatted_name]
	end

	local filename = self.fontPaths[name]

	if not filename then
		error(("No such font: %s"):format(filename))
	end

	local dpi_scale = self:getTextDpiScale()
	local s = size * dpi_scale

	local font = Font(love.graphics.newFont(filename, s), dpi_scale)

	if self.fontFallbackPaths[name] then
		font:addFallback(love.graphics.newFont(self.fontFallbackPaths[name], s))
	end

	font:setFilter("linear", "nearest")

	self.fonts[formatted_name] = font
	return font
end

return FontManager
