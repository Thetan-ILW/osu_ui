local Component = require("ui.Component")

---@alias osu.ui.ImageValueViewParams { files: {[string]: string}, overlap: number?, align?: "left" | "center" | "right",  oy: number?, format: string, multiplier: number }

---@class osu.ui.ImageValueView : ui.Component
---@overload fun(params: osu.ui.ImageValueViewParams): osu.ui.ImageValueView
---@field overlap number
---@field align AlignX
---@field images table<string, love.Image>
---@field value string
local ImageValueView = Component + {}

function ImageValueView:load()
	self.overlap = self.overlap or 0
	self.align = self.align or "left"

	self.constantSpacing = self.constantSpacing or false
	self.constantWidth = -1
	self.spaceWidth = -1
	self.lastMeasureWidth = 0
	self.lastMeasureHeight = 0
	self.renderImages = {}
	self.renderCoordinates = {}

	local images = {}
	self.images = images
	if not self.files then
		return
	end

	for char, path in pairs(self.files) do
		images[char] = love.graphics.newImage(path)
	end

	self.text = self.text or ""
	self.prevValue = ""
	self:refreshTextures(self.text)
end

---@param text string
function ImageValueView:refreshTextures(text)
	if self.prevValue == text then
		return
	end
	self.prevValue = text

	self.renderImages = {} ---@type love.Image[]
	self.renderCoordinateX = {} ---@type number[]

	local current_x = 0
	local height = 0

	local text_len = #text

	for i = 0, text_len - 1 do
		current_x = current_x - ((self.constantSpacing or (i == 0)) and 0 or self.overlap)

		local x = current_x
		local c = text:sub(i + 1, i + 1)
		local image ---@type love.Image?
		local non_standard = false

		if c == "," then
			non_standard = true
		elseif c == "." then
			non_standard = true
		elseif c == "%" then
			non_standard = true
		end

		image = self.images[c]

		if image then
			if not self.constantSpacing or non_standard then
				current_x = current_x + image:getWidth()
			end

			if self.constantSpacing then
				table.insert(self.renderCoordinateX, current_x - x)
			else
				table.insert(self.renderCoordinateX, x)
			end

			table.insert(self.renderImages, image)

			if height == 0 then
				height = image:getHeight()
			end
		end
	end

	--[[
                if (spaceWidth < 0)
                {
                    pTexture pt = TextureManager.Load(TextFontPrefix + @"5", source, atlas);
                    constantWidth = pt != null ? pt.DisplayWidth : 40;
                    pt = TextureManager.Load(TextFontPrefix + @"dot", source, atlas);
                    spaceWidth = pt != null ? pt.DisplayWidth : 40;
                }
		]]
	if self.constantSpacing then
		if self.spaceWidth < 0 then
			local img = self.images["5"]
			self.constantWidth = img and img:getWidth() or 40
			img = self.images["."]
			self.spaceWidth = img and img:getWidth() or 40
		end

		current_x = 0

		for i = 1, #self.renderCoordinateX do
			local special = self.renderCoordinateX[i]

			if special == 0 then
				self.renderCoordinateX[i] = current_x + math.max(0, (self.constantWidth - self.renderImages[i]:getWidth()) / 2, 0)
				current_x = current_x + (self.constantWidth - self.overlap)
			else
				self.renderCoordinateX[i] = current_x
				current_x = current_x + (special - self.overlap)
			end
		end
	end

	self.lastMeasureWidth = current_x
	self.lastMeasureHeight = height
	self.width = current_x
	self.height = height
end

function ImageValueView:setText(text)
	self.value = text
	self:refreshTextures(text)
end

function ImageValueView:draw()
	for i, image in ipairs(self.renderImages) do
		love.graphics.draw(image, self.renderCoordinateX[i], 0)
	end
end

return ImageValueView
