local Component = require("ui.Component")

local Spectrum = Component + {}

function Spectrum:load()
	local img = self.shared.assets:loadImage("menu-vis")
	self.spriteBatch = love.graphics.newSpriteBatch(img)
end

return Spectrum
