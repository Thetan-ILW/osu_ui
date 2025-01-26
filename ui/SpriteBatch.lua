local Component = require("ui.Component")

---@class ui.SpriteBatch : ui.Component
---@operator call: ui.SpriteBatch
---@field setup function
local SpriteBatch = Component + {}

function SpriteBatch:load()
	self:assert(self.image, "Provide the image")
	self.batch = love.graphics.newSpriteBatch(self.image)
end

function SpriteBatch:setup() end

function SpriteBatch:draw()
	love.graphics.draw(self.batch)
end

return SpriteBatch
