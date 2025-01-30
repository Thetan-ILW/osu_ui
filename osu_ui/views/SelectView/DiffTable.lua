local Component = require("ui.Component")
local Image = require("ui.Image")
local Label = require("ui.Label")
local HoverState = require("ui.HoverState")
local ui = require("osu_ui.ui.init")
local ImageValueView = require("osu_ui.ui.ImageValueView")

---@class osu.ui.DiffTable : ui.Component
---@operator call: osu.ui.DiffTable
local DiffTable = Component + {}

function DiffTable:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager
	local osu_cfg = scene.ui.selectApi:getConfigs().osu_ui ---@type osu.ui.OsuConfig
	self.osuCfg = osu_cfg

	self.width, self.height = 375, 56
	local select = self:findComponent("select")
	assert(select, "where select screen")
	self.selectView = select ---@cast select osu.ui.SelectViewContainer	

	self.hoverState = HoverState("quadout", 0.2)
	self.hoverSound = assets:loadAudio("click-short")
	self.clickSound = assets:loadAudio("click-short-confirm")

	self.blockMouseFocus = true
	local bg = self:addChild("background", Image({
		scaleX = 0.55,
		scaleY = 0.555,
		image = assets:loadImage("menu-button-background"),
		color = { 0, 0, 0, 0.7 },
		---@param this ui.Image
		update = function(this)
			this.alpha = 0.7 + (self.hoverState.progress * 0.2)
		end,
	}))
	self.height = bg:getHeight() * 0.555

	self.msdText = self:addChild("msdText", Label({
		x = self.width - 45,
		y = self.height / 2,
		font = fonts:loadFont("QuicksandBold", 32),
		origin = { x = 0.5, y = 0.5 },
		text = "",
		z = 0.1,
		disabled = osu_cfg.songSelect.diffTableImageMsd
	}))

	local score_font = assets.imageFonts.scoreFont
	local overlap = assets.params.scoreOverlap
	self.msdImage = self:addChild("msdImage", ImageValueView({
		x = self.width - 45,
		y = self.height / 2,
		origin = { x = 0.5, y = 0.5 },
		files = score_font,
		overlap = overlap,
		z = 0.1,
		disabled = not osu_cfg.songSelect.diffTableImageMsd
	}))
	self.msdImage:setText("00.00")
	local s = 90 / self.msdImage:getWidth()
	self.msdImage.scaleX = s
	self.msdImage.scaleY = s

	self.msdValue = 0
	self.msdVisual = 0

	self.firstPattern = self:addChild("firstPattern", Label({
		y = -11,
		font = fonts:loadFont("QuicksandBold", 20),
		boxWidth = self.width - 100,
		boxHeight = self.height,
		alignX = "right",
		alignY = "center",
		z = 0.1
	}))

	self.secondPattern = self:addChild("secondPattern", Label({
		y = 11,
		font = fonts:loadFont("QuicksandBold", 16),
		boxWidth = self.width - 100,
		boxHeight = self.height,
		alignX = "right",
		alignY = "center",
		z = 0.1
	}))

	self.lnPercentFormat = { { 1, 1, 1, 1 }, "", { 1, 1, 1, 1 }, "% LN" }
	self.lnPercent = self:addChild("lnPercent", Label({
		x = 15,
		y = -11,
		font = fonts:loadFont("QuicksandBold", 20),
		boxHeight = self.height,
		alignY = "center",
		z = 0.1
	}))

	self.formatLevel = self:addChild("formatLevel", Label({
		x = 15,
		y = 11,
		font = fonts:loadFont("QuicksandBold", 20),
		boxHeight = self.height,
		alignY = "center",
		z = 0.1
	}))
end

function DiffTable:mouseClick()
	if not self.mouseOver then
		return false

	end
	local ss = self.osuCfg.songSelect
	ss.diffTableImageMsd = not ss.diffTableImageMsd

	if ss.diffTableImageMsd then
		self.msdImage.disabled = false
		self.msdText.disabled = true
	else
		self.msdImage.disabled = true
		self.msdText.disabled = false
	end

	self.playSound(self.clickSound)
	return true
end

function DiffTable:justHovered()
	self.playSound(self.hoverSound)
end

function DiffTable:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width, self.height, mx, my)
end

function DiffTable:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

---@param msd number
---@return number
local function msdHue(msd)
	return ui.convertDiffToHue((math.min(msd, 40) / 40) / 1.3)
end

local frame_aim_time = 1 / 60
local decay_factor = 0.69
local time = 0.7
local time2 = 1 / time
function DiffTable:update(dt)
	local t = 1 - (math.min(time, love.timer.getTime() - self.selectView.notechartChangeTime) * time2)
	t = 1 - (t * t * t)
	self.lnPercent.alpha = t
	self.formatLevel.alpha = t
	self.firstPattern.alpha = t
	self.secondPattern.alpha = t

	local dest = self.msdValue
	local diff = dest - self.msdVisual
	diff = diff * math.pow(decay_factor, dt / frame_aim_time)
	self.msdVisual = dest - diff

	local f = ("%05.02f"):format(self.msdVisual)

	if self.osuCfg.songSelect.diffTableImageMsd then
		if f ~= self.msdImage.text then
			self.msdImage:setText(f)
			self.msdImage.color = ui.HSV(msdHue(self.msdVisual), 1, 1)
		end
	else
		if f ~= self.msdText.text then
			self.msdText:replaceText(f)
			self.msdText.color = ui.HSV(msdHue(self.msdVisual), 1, 1)
		end
	end

end

---@param display_info osu.ui.SelectViewDisplayInfo
function DiffTable:updateInfo(display_info)
	self.msdValue = display_info.msd.first

	self.firstPattern:replaceText(display_info.msd.firstPattern)

	if display_info.msd.secondPattern ~= "" then
		self.firstPattern.y = -11
		self.secondPattern.disabled = false
		self.secondPattern:replaceText(display_info.msd.secondPattern)
	else
		self.firstPattern.y = 0
		self.secondPattern.disabled = true
	end

	self.lnPercentFormat[1] = display_info.lnPercentColor
	self.lnPercentFormat[2] = ("%i"):format(display_info.lnPercent * 100)
	self.lnPercent:replaceText(self.lnPercentFormat)
	self.formatLevel:replaceText(display_info.formatLevel)
end

function DiffTable:justHovered()
	self.playSound(self.hoverSound)
end

return DiffTable
