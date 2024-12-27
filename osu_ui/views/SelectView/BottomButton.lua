local Component = require("ui.Component")
local Image = require("ui.Image")
local HoverState = require("ui.HoverState")

---@class osu.ui.SelectView.BottomButton : ui.Component
---@operator call: osu.ui.SelectView.BottomButton
---@field image love.Image
---@field hoverImage love.Image
---@field onClick function
local BottomButton = Component + {}

function BottomButton:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.scene = scene

	self:addChild("image", Image({
		origin = { x = 0, y = 1 },
		image = self.image,
	}))

	self.hoverState = HoverState("quadout", 0.15)
	self.hoverSound = scene.assets:loadAudio("click-short")
	self.clickSound = scene.assets:loadAudio("select-expand")

	self:addChild("hoverImage", Image({
		origin = { x = 0, y = 1 },
		image = self.hoverImage,
		alpha = 0.01,
		blockMouseFocus = true,
		z = 0.01,
		---@param this ui.Image
		update = function(this)
			this.alpha = self.hoverState.progress + 0.01
		end,
		justHovered = function ()
			self.playSound(self.hoverSound, 0.04)
		end,
		---@param this ui.Image
		setMouseFocus = function(this, mx, my)
			this.mouseOver = self.hoverState:checkMouseFocus(this.width, this.height, mx, my)
		end,
		noMouseFocus = function(this)
			this.mouseOver = false
			self.hoverState:loseFocus()
		end,
		mousePressed = function(this)
			if this.mouseOver then
				self.playSound(self.clickSound)
				self.onClick()
			end
		end
	}))
end

return BottomButton
