local Component = require("ui.Component")

local Label = require("ui.Label")
local Image = require("ui.Image")
local QuadImage = require("ui.QuadImage")
local HoverState = require("ui.HoverState")

local LeaderboardUser = require("sea.leaderboards.LeaderboardUser")

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

function PlayerInfoView:bindEvents()
	self:getViewport():listenForEvent(self, "event_nicknameChanged")
end

---@param leaderboard sea.Leaderboard?
---@param leaderboard_user sea.LeaderboardUser?
---@param user sea.User?
function PlayerInfoView:setProfileInfo(leaderboard, leaderboard_user, user)
	local configs = self.scene.ui.selectApi:getConfigs()
	self.username = configs.online.user.name or configs.osu_ui.offlineNickname

	if not leaderboard or not leaderboard_user then
		return
	end

	if leaderboard.rating_calc == "pp" then
		self.firstRow = ("Performance: %ipp"):format(leaderboard_user.total_rating)
	elseif leaderboard.rating_calc == "msd" then
		self.firstRow = ("Performance: %0.02f MSD"):format(leaderboard_user.total_rating)
	elseif leaderboard.rating_calc == "enps" then
		self.firstRow = ("Performance: %0.02f ENPS"):format(leaderboard_user.total_rating)
	end

	setmetatable(leaderboard_user, LeaderboardUser)
	self.secondRow = ("Accuracy: %0.02f%%"):format(leaderboard_user:getNormAccuracy() * 100)
	self.level = 0
	self.levelPercent = 0
	self.rank = leaderboard_user.rank

	if not user then
		return
	end

	local lvls = self.osuLevels
	local total_score = user.chartplays_count * 1000000
	for i = 2, 199 do
		local this = lvls[i - 1]
		local next = lvls[i]
		if total_score >= this and total_score < next then
			self.level = i - 1
			self.levelPercent = (total_score - this) / (next - this)
			return
		end
	end
end

function PlayerInfoView:event_nicknameChanged()
	self:reload()
end

function PlayerInfoView:event_onlineReady()
	self:reload()
end

function PlayerInfoView:event_leaderboardChanged()
	self:reload()
end

function PlayerInfoView:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager

	self.selectApi = scene.ui.selectApi
	self.scene = scene
	self.rating = self.selectApi:getConfigs().osu_ui.playerInfoRating ---@type string

	self:getViewport():listenForEvent(self, "event_onlineReady")
	self:getViewport():listenForEvent(self, "event_leaderboardChanged")
	local leaderboard = self.selectApi:getSelectedLeaderboard()
	local leaderboard_user = self.selectApi:getSelectedLeaderboardUser()
	local user = self.selectApi:getOnlineUser()

	self.osuLevels = { 0 }

	---TODO: Add levels above 100
	for i = 1, 100 do
		table.insert(self.osuLevels, 5000 / 3 * (4 * i^3 - 3 * i^2 - i) + 1.25 * 1.8^(i - 60))
	end

	self:setProfileInfo(leaderboard, leaderboard_user, user)

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

	if leaderboard then
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
	end

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

function PlayerInfoView:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width, self.height, mx, my)
end

function PlayerInfoView:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

return PlayerInfoView
