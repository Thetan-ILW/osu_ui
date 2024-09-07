local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@class osu.ui.SkinPreview : osu.ui.UiElement
---@operator call: osu.ui.SkinPreview
---@field private hoverSound audio.Source
---@field private image love.Image
---@field private previousImage love.Image
---@field private imageSwapTime number
---@field private noSkinPreview love.Image
---@field private hoverState osu.ui.HoverState
local SkinPreview = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param pixel_width number
function SkinPreview:new(assets, pixel_width)
	self.assets = assets
	self.hoverSound = assets.sounds.hoverOverRect
	self.noSkinPreview = assets.images.noSkinPreview
	self.image = self.noSkinPreview
	self.totalW = pixel_width
	self.totalH = 144
	self.imageSwapTime = -math.huge
	self.hoverState = HoverState("linear", 0)
end

---@param image love.Image?
function SkinPreview:setImage(image)
	if not image then
		if self.image ~= nil then
			self.previousImage = self.image
			self.imageSwapTime = love.timer.getTime()
		end
		self.image = self.noSkinPreview
		return
	end

	self.previousImage = self.image
	self.image = image
	self.imageSwapTime = love.timer.getTime()
end

---@param has_focus boolean
function SkinPreview:update(has_focus)
	local just_hovered = false
	self.hover, self.animation, just_hovered = self.hoverState:check(self.totalW, self.totalH)

	if not has_focus then
		return
	end

	if just_hovered then
		ui.playSound(self.hoverSound)
	end
end

local gfx = love.graphics

function SkinPreview:draw()
	gfx.setColor(1, 1, 1)

	local img = self.image
	local prev_img = self.previousImage

	local a = math.min(love.timer.getTime() - self.imageSwapTime, 0.25) * 4
	gfx.setColor(1, 1, 1, a)
	gfx.draw(img)

	if prev_img then
		gfx.setColor(1, 1, 1, 1 - a)
		gfx.draw(prev_img)
	end

	gfx.translate(0, self.totalH)
end

return SkinPreview
