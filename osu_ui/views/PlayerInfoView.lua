local Component = require("ui.Component")

local Label = require("ui.Label")
local Image = require("ui.Image")
local QuadImage = require("ui.QuadImage")
local HoverState = require("ui.HoverState")

---@alias osu.ui.PlayerInfoViewParams { username: string, firstRow: string, secondRow: string, rank: number, level: number, levelProgress: number, onClick: function }

---@class osu.ui.PlayerInfoView : ui.Component
---@overload fun(params: osu.ui.PlayerInfoViewParams): osu.ui.PlayerInfoView
---@field username string
---@field firstRow string
---@field secondRow string
---@field rank number
---@field level number
---@field levelProgress number
---@field onClick function
local PlayerInfoView = Component + {}

local function getRankColor(rank)
	local color = love.math.colorFromBytes
	if rank > 200000 then
	    return {color(255, 255, 255, 20)}
	elseif rank > 100000 then
	    return {color(255, 255, 255, 40)}
	elseif rank > 50000 then
	    return {color(255, 255, 255, 60)}
	elseif rank > 1000 then
	    return {color(255, 255, 255, 80)}
	elseif rank > 10 then
	    return {color(255, 255, 255, 100)}
	elseif rank > 1 then
	    return {color(244, 218, 73, 120)}
	else
	    return {color(88, 171, 248, 120)}
	end
end

function PlayerInfoView:load()
	local assets = self.shared.assets
	local fonts = self.shared.fontManager

	local border = assets:loadImage("user-border")
	self.width, self.height = border:getDimensions()

	local avatar = assets:loadAvatar()
	local iw, ih = avatar:getDimensions()
	self:addChild("avatar", Image({
		x = 6, y = 6,
		image = avatar,
		scaleX = 74 / iw,
		scaleY = 74 / ih,
		z = 0.1,
	}))
	self:addChild("username", Label({
		x = 86, y = 4,
		text = self.username,
		font = fonts:loadFont("Regular", 18),
		z = 0.1,
	}))
	self:addChild("firstRow", Label({
		x = 86, y = 26,
		text = self.firstRow,
		font = fonts:loadFont("Regular", 13),
		z = 0.1,
	}))
	self:addChild("secondRow", Label({
		x = 86, y = 42,
		text = self.secondRow,
		font = fonts:loadFont("Regular", 13),
		z = 0.1,
	}))
	self:addChild("level", Label({
		x = 86, y = 56,
		text = ("Lv%i"):format(self.level),
		font = fonts:loadFont("Regular", 13),
		z = 0.1,
	}))
	self:addChild("rank", Label({
		width = self.width - 10,
		height = self.height,
		alignX = "right",
		text = ("#%i"):format(self.rank),
		font = fonts:loadFont("Light", 50),
		color = getRankColor(self.rank),
		z = 0.1
	}))
	self:addChild("levelbarBackground", Image({
		x = 86 + 40, y = 56 + 12,
		image = assets:loadImage("levelbar-bg"),
		alpha = 0.5,
		z = 0.1,
	}))

	local levelbar = assets:loadImage("levelbar")
	iw, ih = levelbar:getDimensions()
	self:addChild("levelbar", QuadImage({
		x = 86 + 40, y = 56 + 12,
		image = levelbar,
		quad = love.graphics.newQuad(0, 0, iw * self.levelProgress, ih, levelbar),
		color = {love.math.colorFromBytes(252, 184, 6, 255)},
		z = 0.15
	}))

	local bg = 40 / 255
	self:addChild("background", Image({
		image = assets:loadImage("user-bg"),
		update = function(this)
			local p = self.hoverState.progress
			this.color = { bg * p, bg * p, bg * p, self.alpha }
		end,
	}))
	self:addChild("border", Image({
		image = assets:loadImage("user-border"),
		update = function(this)
			local p = self.hoverState.progress
			this.color = { bg * p, bg * p, bg * p, self.alpha }
		end,
		z = 0.05
	}))
	self:addChild("mode", Image({
		x = self.width - 6, y = 6,
		origin = { x = 1, y = 0 },
		image = assets:loadImage("mode-mania-small"),
		alpha = 0.15,
		z = 0.1
	}))

	self.hoverState = HoverState("quadout", 0.25)
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

function PlayerInfoView:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width, self.height, mx, my)
end

--[[
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

	gfx.setColor(1, 1, 1, 0.5)
	gfx.translate(40, 27)
	gfx.draw(self.levelbarBackground)

	gfx.setColor(levelbar_color)
	gfx.draw(self.levelbar, self.levelBarQuad)
end
]]

return PlayerInfoView
