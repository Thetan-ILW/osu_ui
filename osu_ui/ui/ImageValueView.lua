local UiElement = require("osu_ui.ui.UiElement")

---@class osu.ui.ImageValueView : osu.ui.UiElement
---@operator call: osu.ui.ImageValueView
local ImageValueView = UiElement + {}

---@param params { files: {[string]: string}, overlap: number?, align?: "left" | "center" | "right",  oy: number?, scale: number?, format: string, multiplier: number }
---@param value function | number
function ImageValueView:new(params, value)
	UiElement.new(self, params)

	self.overlap = params.overlap or 0
	self.align = params.align or "left"
	self.oy = params.oy or 0
	self.scale = params.scale or 1
	self.format = params.format or "%i"
	self.multiplier = params.multiplier or 1
	self.value = value

	local images = {}
	self.images = images
	if not params.files then
		return
	end

	self.maxCharW = 0
	for char, path in pairs(params.files) do
		images[char] = love.graphics.newImage(path)
		if tonumber(char) then
			self.maxCharW = math.max(images[char]:getWidth(), self.maxCharW)
		end
	end
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

	local sx = self.scale
	local sy = self.scale
	local oy = self.oy or 0
	local align = self.align

	local width, height = self:getDimensions(value)
	self.width = width
	self.height = height

	local x = 0
	if align == "center" then
		x = x - width / 2 * sx
	elseif align == "right" then
		x = x - width * sx
	end
	for i = 1, #value do
		local char = value:sub(i, i)
		local image = images[char]
		if image then
			if tonumber(char) then
				love.graphics.draw(image, x + (self.maxCharW - image:getWidth()) / 2, (height * (1 - oy) - image:getHeight()) * sy, 0, sx, sy)
				x = x + (self.maxCharW - overlap) * sx
			else
				love.graphics.draw(image, x, (height * (1 - oy) - image:getHeight()) * sy, 0, sx, sy)
				x = x + (image:getWidth() - overlap) * sx
			end
		end
	end
end

return ImageValueView
