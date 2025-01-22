local Component = require("ui.Component")

---@alias ui.QuadImageParams { image: love.Image,  quad: love.Quad  }

---@class ui.QuadImage : ui.Component
---@overload fun(params: ui.QuadImageParams): ui.QuadImage
---@field image love.Image
---@field quad love.Quad?
local QuadImage = Component + {}

function QuadImage:load()
	self:assert(self.image, "Image is not defined")
	local _, _, w, h = self.quad:getViewport()
	self.width, self.height = w, h
end

---@param image love.Image
---@param quad love.Quad
function QuadImage:replaceImage(image, quad)
	self.image = image
	self.quad = quad
	self:load()
end

---@param x number
---@param y number
---@param w number
---@param h number
function QuadImage:setViewport(x, y, w, h)
	self.quad:setViewport(x, y, w, h)
	local _, _, w, h = self.quad:getViewport()
	self.width, self.height = w, h
end

function QuadImage:draw()
	love.graphics.draw(self.image, self.quad)
end

return QuadImage
