local Component = require("ui.Component")

local Label = require("ui.Label")
local Image = require("ui.Image")
local QuadImage = require("ui.QuadImage")
local HoverState = require("ui.HoverState")

---@class osu.ui.PlayerInfoView : ui.Component
---@operator call: osu.ui.PlayerInfoView
---@field onClick function
local PlayerInfoView = Component + {}

local function getRankColor(rank)
	local color = love.math.colorFromBytes
	if rank > 200000 then
	    return {color(255, 255, 255, 40)}
	elseif rank > 100000 then
	    return {color(255, 255, 255, 80)}
	elseif rank > 50000 then
	    return {color(255, 255, 255, 100)}
	elseif rank > 1000 then
	    return {color(255, 255, 255, 110)}
	elseif rank > 10 then
	    return {color(255, 255, 255, 120)}
	elseif rank > 1 then
	    return {color(244, 218, 73, 120)}
	else
	    return {color(88, 171, 248, 120)}
	end
end

function PlayerInfoView:setProfileInfo()
	local profile = self.scene.ui.pkgs.playerProfile
	local username = self.scene.game.configModel.configs.online.user.name or "Guest"
	local pp = profile.pp
	local accuracy = profile.accuracy
	local level = profile.osuLevel
	local level_percent = profile.osuLevelPercent
	local rank = profile.rank

	local chartview = self.selectApi:getChartview()
	if chartview then
		local regular, ln = profile:getDanClears(chartview.chartdiff_inputmode)
		if regular ~= "-" or ln ~= "-" then
			username = ("%s [%s/%s]"):format(username, regular, ln)
		end
	end

	self.username = username
	self.firstRow = ("Performance: %ipp"):format(pp)
	self.secondRow = ("Accuracy: %0.02f%%"):format(accuracy * 100)
	self.level = level
	self.levelPercent = level_percent
	self.rank = rank
end

function PlayerInfoView:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	self.selectApi = scene.ui.selectApi
	self.scene = scene
	self:setProfileInfo()

	self.width, self.height = 330, 86

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
		x = 86, y = 58,
		text = ("Lv%i"):format(self.level),
		font = fonts:loadFont("Regular", 13),
		z = 0.1,
	}))
	self:addChild("rank", Label({
		y = 15,
		boxWidth = self.width - 7,
		boxHeight = self.height,
		alignX = "right",
		text = ("#%i"):format(self.rank),
		font = fonts:loadFont("Light", 50),
		color = getRankColor(self.rank),
		z = 0.1
	}))
	self:addChild("levelbarBackground", Image({
		x = 86 + 40, y = 56 + 13,
		image = assets:loadImage("levelbar-bg"),
		alpha = 0.5,
		z = 0.1,
	}))

	local levelbar = assets:loadImage("levelbar")
	iw, ih = levelbar:getDimensions()
	self:addChild("levelbar", QuadImage({
		x = 86 + 40, y = 56 + 13,
		image = levelbar,
		quad = love.graphics.newQuad(0, 0, iw * self.levelPercent, ih, levelbar),
		color = {love.math.colorFromBytes(252, 184, 6, 255)},
		z = 0.15
	}))

	local bg = 40 / 255
	self:addChild("background", Image({
		image = assets:loadImage("user-bg"),
		update = function(this)
			local p = self.hoverState.progress
			this.color = { bg, bg, bg, self.alpha * p }
		end,
	}))
	self:addChild("border", Image({
		image = assets:loadImage("user-border"),
		update = function(this)
			local p = self.hoverState.progress
			this.color = { bg, bg, bg, self.alpha * p }
		end,
		z = 0.05
	}))
	self:addChild("mode", Image({
		x = self.width - 6, y = 6,
		origin = { x = 1, y = 0 },
		image = assets:loadImage("mode-mania-small-for-charts"),
		alpha = 0.15,
		z = 0.1
	}))

	self.hoverState = HoverState("quadout", 0.25)
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

function PlayerInfoView:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

return PlayerInfoView
