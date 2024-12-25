local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local flux = require("flux")

---@class osu.ui.NotificationView : ui.Component
---@operator call: osu.ui.NotificationView
---@field assets osu.ui.OsuAssets
local NotificationView = Component + {}

function NotificationView:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.NotificationView
	self.width = self.parent.width
	self.height = self.height == 0 and 48 or self.height
	self.origin = self.origin or { x = 0, y = 0.5 }
	self.y = self.parent.height / 2
	self.alpha = 0

	self.label = self:addChild("label", Label({
		text = "",
		font = scene.fontManager:loadFont("Regular", 24),
		boxWidth = self.width,
		boxHeight = self.height,
		alignX = "center",
		alignY = "center",
		z = 0.1,
	}))

	self:addChild("rectangle", Rectangle({
		width = self.width,
		height = self.height,
		color = { 0, 0, 0, 0.7 },
		update = function(this)
			local h = self.height * self.alpha
			this.y = (self.height - h) / 2
			this.height = h
		end
	}))
end

---@param message string
function NotificationView:show(message)
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.6, { alpha = 1 }):ease("elasticout"):oncomplete(function()
		self.tween = flux.to(self, 0.3, { alpha = 0 }):ease("quadout"):delay(1)
	end)
	self.label:replaceText(message)
end

return NotificationView
