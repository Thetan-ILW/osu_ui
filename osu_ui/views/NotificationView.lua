local class = require("class")
local flux = require("flux")
local ui = require("osu_ui.ui")
local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.NotificationView
---@operator call: osu.ui.NotificationView
local NotificationView = class()

---@param assets osu.ui.OsuAssets
function NotificationView:load(assets)
	self.fonts = assets.localization.fontGroups.misc
	self.animation = 0
end

function NotificationView:createTween()
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
			self.text = message
			self:createTween()
		end)
	else
		if self.tween then
			self.tween:stop()
		end
		self.text = message
		self:createTween()
	end
end

local gfx = love.graphics

function NotificationView:draw()
	if not self.text then
		return
	end

	gfx.push()
	Layout:draw()

	local animation = self.animation

	local w, h = Layout:move("base")
	local rh = 48 * animation
	local y = h / 2 - rh / 2
	gfx.setColor(0, 0, 0, math.min(0.7 * animation, 0.7))
	gfx.rectangle("fill", 0, y, w, rh)

	gfx.setColor(1, 1, 1, animation)
	gfx.setFont(self.fonts.notification)
	ui.frame(self.text, 0, y, w, rh, "center", "center")
	gfx.pop()
end

return NotificationView
