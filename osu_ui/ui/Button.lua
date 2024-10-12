local UiElement = require("osu_ui.ui.UiElement")
local HoverState = require("osu_ui.ui.HoverState")

local ui = require("osu_ui.ui")

---@class osu.ui.Button : osu.ui.UiElement
---@operator call: osu.ui.Button
---@field private label love.Text
---@field private color number[]
---@field private margin number
---@field private onChange function
---@field private totalW number
---@field private totalH number
---@field private middleImgScale number
---@field private heightScale number
---@field private imageLeft love.Image
---@field private imageMiddle love.Image
---@field private imageRight love.Image
---@field private hover boolean
---@field private hoverUpdateTime number
---@field private brightenShader love.Shader
---@field private hoverState osu.ui.HoverState
---@field private animation number
local Button = UiElement + {}

---@param assets osu.ui.OsuAssets
---@param params { text: string, font: love.Font, pixelWidth: number, pixelHeight: number, color: number[]?, xOffset: number, margin: number? }
---@param on_change function
function Button:new(assets, params, on_change)
	self.assets = assets

	local img = assets.images
	self.imageLeft = img.buttonLeft
	self.imageMiddle = img.buttonMiddle
	self.imageRight = img.buttonRight

	self.label = love.graphics.newText(params.font, params.text)
	self.xOffset = params.xOffset or 0
	self.margin = params.margin or 0
	self.color = params.color or { 1, 1, 1, 1 }

	self.heightScale = params.pixelHeight / self.imageMiddle:getHeight()
	local borders_width = self.imageLeft:getWidth() * self.heightScale + self.imageRight:getWidth() * self.heightScale
	self.middleImgScale = (params.pixelWidth - borders_width) / self.imageMiddle:getWidth()

	self.totalW = params.pixelWidth
	self.totalH = params.pixelHeight + self.margin / 2

	self.hover = false
	self.hoverUpdateTime = -math.huge

	self.brightenShader = assets.shaders.brighten
	self.onChange = on_change

	self.hoverState = HoverState("quadout", 0.2)
	self.animation = 0
end

local gfx = love.graphics

---@param has_focus boolean
function Button:update(has_focus)
	local just_hovered = false
	self.hover, self.animation, just_hovered = self.hoverState:check(self.totalW, self.totalH)

	if not has_focus then
		return
	end

	if self.hover and ui.mousePressed(1) then
		self.onChange()
		self.changeTime = -math.huge
	end

	if just_hovered then
		ui.playSound(self.assets.sounds.hoverOverRect)
	end
end

function Button:draw()
	local left = self.imageLeft
	local middle = self.imageMiddle
	local right = self.imageRight
	local scale = self.scale

	local prev_shader = gfx.getShader()

	gfx.setShader(self.brightenShader)

	local a = self.animation * 0.3

	self.brightenShader:send("amount", a)

	gfx.setColor(self.color)

	gfx.push()
	gfx.translate(self.xOffset, self.margin / 4)
	gfx.draw(left, 0, 0, 0, self.heightScale, self.heightScale)
	gfx.translate(left:getWidth() * self.heightScale, 0)
	gfx.draw(middle, 0, 0, 0, self.middleImgScale, self.heightScale)
	gfx.translate(middle:getWidth() * self.middleImgScale, 0)
	gfx.draw(right, 0, 0, 0, self.heightScale, self.heightScale)
	gfx.pop()

	gfx.setShader(prev_shader)

	gfx.push()
	gfx.setColor({ 1, 1, 1, 1 })
	ui.textFrameShadow(self.label, 0, 0, self.totalW, self.totalH, "center", "center")
	gfx.pop()

	ui.next(0, self.totalH)
end

return Button
