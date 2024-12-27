local Component = require("ui.Component")
local Image = require("ui.Image")

---@class osu.ui.MenuBackAnimation : ui.Component
---@operator call: osu.ui.MenuBackAnimation
---@field onClick function
local MenuBackAnimation = Component + {}

function MenuBackAnimation:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local frames = scene.assets.menuBackFrames

	self.width, self.height = frames[1]:getDimensions()

	local assets = scene.assets
	self.clickSound = assets:loadAudio("menuback")
	self.hoverSound = assets:loadAudio("menuclick")

	local frame_count = #frames
	local framerate = assets.params.animationFramerate
	framerate = framerate == -1 and frame_count or framerate

	self:addChild("image", Image({
		image = frames[1],
		update = function(this)
			local index = 1 + math.floor((love.timer.getTime() * framerate) % frame_count)
			this.image = frames[index]
		end
	}))
end

function MenuBackAnimation:mousePressed()
	if self.mouseOver then
		self.playSound(self.clickSound)
		self.onClick()
		return true
	end
end

function MenuBackAnimation:justHovered()
	self.playSound(self.hoverSound)
end

return MenuBackAnimation
