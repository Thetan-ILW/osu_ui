local UiElement = require("osu_ui.ui.UiElement")
local flux = require("flux")

local Label = require("osu_ui.ui.Label")

---@alias NotificationView { assets: osu.ui.OsuAssets }

---@class osu.ui.NotificationView : osu.ui.UiElement
---@operator call: osu.ui.NotificationView
---@field font love.Font
---@field assets osu.ui.OsuAssets
local NotificationView = UiElement + {}

function NotificationView:load()
	UiElement.load(self)
	self.animation = 0
	self.font = self.assets:loadFont("Regular", 24)
end

function NotificationView:createMessage(message)
	self.label = Label({
		text = message,
		font = self.font,
		totalW = self.parent.totalW,
		totalH = self.parent.totalH,
		alignX = "center",
		alignY = "center",
		textScale = self.parent.textScale
	})
	self.label:load()
	self.tween = flux.to(self, 0.6, { animation = 1 }):ease("elasticout"):oncomplete(function()
		self.tween = flux.to(self, 0.3, { animation = 0 }):ease("quadout"):delay(1):oncomplete(function()
			self.tween = nil
		end)
	end)
end

---@param message string
---@param dont_stop_tween boolean?
function NotificationView:show(message, dont_stop_tween)
	dont_stop_tween = dont_stop_tween == nil and false or dont_stop_tween
	if self.tween and not dont_stop_tween then
		self.tween:stop()
		self.tween = flux.to(self, 0.1, { animation = 0 }):ease("cubicout"):oncomplete(function()
			self:createMessage(message)
		end)
	else
		if self.tween then
			self.tween:stop()
		end
		self:createMessage(message)
	end
end

local gfx = love.graphics

function NotificationView:draw()
	if not self.label then
		return
	end

	local animation = self.animation
	if self.animation == 0 then
		return
	end

	gfx.push()

	local w, h = self.parent.totalW, self.parent.totalH
	local rh = 48 * animation
	local y = h / 2 - rh / 2
	gfx.setColor(0, 0, 0, math.min(0.7 * animation, 0.7))
	gfx.rectangle("fill", 0, y, w, rh)

	self.label.alpha = animation * self.alpha
	self.label:draw()
	gfx.pop()
end

return NotificationView
