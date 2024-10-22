local UiElement = require("osu_ui.ui.UiElement")

---@alias ImageValueViewParams { files: {[string]: string}, overlap: number?, align?: "left" | "center" | "right",  oy: number?, format: string, multiplier: number }

---@class osu.ui.ImageValueView : osu.ui.UiElement
---@overload fun(params: ImageValueViewParams): osu.ui.ImageValueView
---@field overlap number
---@field align AlignX
---@field format string
---@field multiplier number
---@field images love.Image[]
local ImageValueView = UiElement + {}

function ImageValueView:load()
	self.overlap = self.overlap or 0
	self.align = self.align or "left"
	self.format = self.format or "%i"
	self.multiplier = self.multiplier or 1

	local images = {}
	self.images = images
	if not self.files then
		return
	end

	self.maxCharW = 0
	for char, path in pairs(self.files) do
		images[char] = love.graphics.newImage(path)
		if tonumber(char) then
			self.maxCharW = math.max(images[char]:getWidth(), self.maxCharW)
		end
	end

	UiElement.load(self)
end

---@param value table
---@return number
---@return number
function ImageValueView:getDimensions(value)
	local images = self.images
	local overlap = self.overlap or 0

	local width = 0
	local height = 0
	for i = 1, #value do
		local char = value:sub(i, i)
		local image = images[char]
		if image then
			if tonumber(char) then
				width = width + self.maxCharW - overlap
			else
				width = width + image:getWidth() - overlap
			end
			height = math.max(height, image:getHeight())
		end
	end
	if width > 0 then
		width = width + overlap
	end
	return width, height
end

function ImageValueView:draw()
	local images = self.images
	local overlap = self.overlap or 0

	local format = self.format
	local value = self.value
	if value then
		if type(value) == "function" then
			value = value(self)
		end
		if self.multiplier and tonumber(value) then
			value = value * self.multiplier
		end
		if type(format) == "string" then
			value = format:format(value)
		elseif type(format) == "function" then
			value = format(value)
		end
	end
	value = tostring(value)

	local oy = self.origin.y
	local align = self.align

	local width, height = self:getDimensions(value)
	self.width = width
	self.height = height

	local x = 0
	if align == "center" then
		x = x - width / 2
	elseif align == "right" then
		x = x - width
	end
	for i = 1, #value do
		local char = value:sub(i, i)
		local image = images[char]
		if image then
			if tonumber(char) then
				love.graphics.draw(image, x + (self.maxCharW - image:getWidth()) / 2, (height * (1 - oy) - image:getHeight()), 0)
				x = x + (self.maxCharW - overlap)
			else
				love.graphics.draw(image, x, (height * (1 - oy) - image:getHeight()), 0)
				x = x + (image:getWidth() - overlap)
			end
		end
	end
end

return ImageValueView
