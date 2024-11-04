local UiElement = require("osu_ui.ui.UiElement")

local Label = require("osu_ui.ui.Label")

---@alias PlayerInfoViewParams { assets: osu.ui.OsuAssets, username: string, firstRow: string, secondRow: string, rank: number, level: number, levelProgress: number, onClick: function }

---@class osu.ui.PlayerInfoView : osu.ui.UiElement
---@overload fun(params: PlayerInfoViewParams): osu.ui.PlayerInfoView
---@field assets osu.ui.OsuAssets
---@field username string
---@field firstRow string
---@field secondRow string
---@field rank number
---@field level number
---@field levelProgress number
---@field avatar love.Image
---@field avatarScaleX number
---@field avatarScaleY number
---@field border love.Image
---@field panel love.Image
---@field levelbar love.Image
---@field levelbarQuad love.Quad
---@field levelbarBackground love.Image
---@field modeIcon love.Image
---@field usernameLabel osu.ui.Label
---@field firstRowLabel osu.ui.Label
---@field secondRowLabel osu.ui.Label
---@field levelLabel osu.ui.Label
---@field rankLabel osu.ui.Label
---@field onClick function
local PlayerInfoView = UiElement + {}

local function color(r, g, b, a)
	return { r / 255, g / 255, b / 255, a / 255 }
end

local function getRankColor(rank)
	if rank > 200000 then
	    return color(255, 255, 255, 20)
	elseif rank > 100000 then
	    return color(255, 255, 255, 40)
	elseif rank > 50000 then
	    return color(255, 255, 255, 60)
	elseif rank > 1000 then
	    return color(255, 255, 255, 80)
	elseif rank > 10 then
	    return color(255, 255, 255, 100)
	elseif rank > 1 then
	    return color(244, 218, 73, 120)
	else
	    return color(88, 171, 248, 120)
	end
end

function PlayerInfoView:load()
	assert(self.assets, ("OsuAssets not provided: %s"):format(self.id))

	self.avatar = self.assets:loadAvatar()
	self.border = self.assets:loadImage("user-border")
	self.panel = self.assets:loadImage("user-bg")
	self.levelbar = self.assets:loadImage("levelbar")
	self.levelbarBackground = self.assets:loadImage("levelbar-bg")
	self.modeIcon = self.assets:loadImage("mode-mania-small")

	local iw, ih = self.levelbar:getDimensions()
	self.levelBarQuad = love.graphics.newQuad(0, 0, iw * self.levelProgress, ih, self.levelbar)

	iw, ih = self.avatar:getDimensions()
	self.avatarScaleX, self.avatarScaleY = 74 / iw, 74 / ih

	self.totalW, self.totalH = self.border:getDimensions()

	local text_scale = self.parent.textScale
	self.usernameLabel = Label({
		text = self.username,
		textScale = text_scale,
		font = self.assets:loadFont("Regular", 18)
	})
	self.firstRowLabel = Label({
		text = self.firstRow,
		textScale = text_scale,
		font = self.assets:loadFont("Regular", 13)
	})
	self.secondRowLabel = Label({
		text = self.secondRow,
		textScale = text_scale,
		font = self.assets:loadFont("Regular", 13)
	})
	self.levelLabel = Label({
		text = ("Lv%i"):format(self.level),
		textScale = text_scale,
		font = self.assets:loadFont("Regular", 13)
	})
	self.rankLabel = Label({
		totalW = self.totalW - 10,
		totalH = self.totalH,
		alignX = "right",
		text = ("#%i"):format(self.rank),
		textScale = text_scale,
		font = self.assets:loadFont("Light", 50),
		color = getRankColor(self.rank)
	})
	self.usernameLabel:load()
	self.firstRowLabel:load()
	self.secondRowLabel:load()
	self.levelLabel:load()
	self.rankLabel:load()

	UiElement.load(self)

	self.hoverState.tweenDuration = 0.25
end

function PlayerInfoView:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
end

function PlayerInfoView:mousePressed()
	if self.mouseOver then
		self.onClick()
		return true
	end

	return false
end

local gfx = love.graphics

local hover = 40 / 255
local levelbar_color = color(252, 184, 6, 255)

function PlayerInfoView:draw()
	local a = self.hoverState.progress
	gfx.setColor(hover * a, hover * a, hover * a, self.alpha)
	gfx.draw(self.panel)
	gfx.draw(self.border)

	gfx.setColor(1, 1, 1, self.alpha * 0.15)
	gfx.draw(self.modeIcon, self.totalW - 45, 6)

	gfx.push()
	gfx.translate(0, 17)
	self.rankLabel:draw()
	gfx.pop()

	gfx.setColor(1, 1, 1, self.alpha)
	gfx.draw(self.avatar, 6, 6, 0, self.avatarScaleX, self.avatarScaleY)

	gfx.translate(86, 4)
	gfx.push()
	self.usernameLabel:draw()
	gfx.pop()
	gfx.translate(0, 22)
	gfx.push()
	self.firstRowLabel:draw()
	gfx.pop()
	gfx.translate(0, 16)
	gfx.push()
	self.secondRowLabel:draw()
	gfx.pop()
	gfx.push()
	gfx.translate(0, 16)
	self.levelLabel:draw()
	gfx.pop()

	gfx.setColor(1, 1, 1, 0.5)
	gfx.translate(40, 27)
	gfx.draw(self.levelbarBackground)

	gfx.setColor(levelbar_color)
	gfx.draw(self.levelbar, self.levelBarQuad)
end

return PlayerInfoView
