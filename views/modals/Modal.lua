local class = require("class")
local flux = require("flux")

local gfx_util = require("gfx_util")

---@class osu.ui.Modal
---@operator call: osu.ui.Modal
---@field name string
---@field showTween table?
---@field hideTween table?
---@field mainView osu.ui.ScreenView
---@field assets osu.ui.OsuAssets
local Modal = class()

Modal.shouldClose = false
Modal.alpha = 0

function Modal:onShow() end
function Modal:onHide() end
function Modal:onQuit() end

function Modal:show()
	self:onShow()

	if self.hideTween then
		self.hideTween:stop()
	end

	self.showTween = flux.to(self, 0.22, { alpha = 1 }):ease("quadout")
end

function Modal:hide()
	self:onHide()

	if self.showTween then
		self.showTween:stop()
	end

	self.hideTween = flux.to(self, 0.44, { alpha = -1 }):ease("quadout")
end

function Modal:quit()
	self.shouldClose = true
	self:onQuit()
end

function Modal:update() end

function Modal:draw(view)
	if view.game.cacheModel.isProcessing then
		return
	end

	self:update()

	if self.shouldClose and self.alpha > 0.1 then
		self:hide()
	end

	local previousCanvas = love.graphics.getCanvas()
	self.canvas = gfx_util.getCanvas("ModifierView")

	love.graphics.setCanvas({ self.canvas, stencil = true })
	love.graphics.clear()
	self.viewConfig:draw(self)
	love.graphics.setCanvas({ previousCanvas, stencil = true })

	love.graphics.origin()
	love.graphics.setColor(1, 1, 1, self.alpha)
	love.graphics.draw(self.canvas)
end

return Modal
