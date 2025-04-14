local Component = require("ui.Component")

local flux = require("flux")
local time_util = require("time_util")

local Image = require("ui.Image")
local Label = require("ui.Label")
local DynamicLabel = require("ui.DynamicLabel")
local HoverState = require("ui.HoverState")

---@alias osu.ui.ScoreViewParams { id: integer, gradeImageName: string, username: string?, rank: number, score: string, accuracy: string, mods: string, improvement: string, tooltip: string, slideInDelay: number, recentScoreIcon: love.Text, time: number, onClick: function }

---@class osu.ui.ScoreEntryView : ui.Component
---@overload fun(params: osu.ui.ScoreViewParams): osu.ui.ScoreEntryView
---@field assets osu.ui.OsuAssets
---@field avatarScaleX number
---@field avatarScaleY number
---@field rank number
---@field grade osu.ui.Image
---@field gradeImageName string
---@field username string
---@field score string
---@field mods string
---@field accuracy string
---@field improvement string
---@field time number
---@field slideInDelay number
---@field onClick function
---@field recentIconSide "right" | "left"
---@field slide boolean
local ScoreEntryView = Component + {}

function ScoreEntryView:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets
	local fonts = scene.fontManager
	self.blockMouseFocus = true

	self.tooltipView = scene.tooltip
	self.hoverSound = assets:loadAudio("menuclick")

	self:addChild("background", Image({
		y = 4,
		scaleX = 0.55,
		scaleY = 0.555,
		image = assets:loadImage("menu-button-background"),
		color = { 0, 0, 0, 0.588 },
		update = function(this)
			this.alpha = 0.588 + (self.hoverState.progress * 0.2)
		end,
		justHovered = function ()
			self.playSound(self.hoverSound)
		end
	}))

	local avatar = assets:loadAvatar()
	local iw, ih = avatar:getDimensions()
	self:addChild("avatar", Image({
		x = 6, y = 10,
		image = avatar,
		scaleX = 46 / iw,
		scaleY = 46 / ih,
		z = 0.1,
		update = function(this)
			local p = 1 - self.hoverState.progress * 0.7
			this.color[1] = p
			this.color[2] = p
			this.color[3] = p
		end
	}))

	self:addChild("rank", Label({
		x = 6, y = 10,
		boxWidth = 46,
		boxHeight = 46,
		alignX = "center",
		alignY = "center",
		font = fonts:loadFont("Regular", 28),
		text = tostring(self.rank),
		shadow = true,
		z = 0.2,
		update = function(this)
			this.alpha = self.hoverState.progress
		end
	}))

	self:addChild("grade", Image({
		x = 73, y = 32,
		origin = { x = 0.5, y = 0.5 },
		image = assets:loadImage(self.gradeImageName),
		z = 0.1,
	}))

	self:addChild("username", Label({
		x = 96, y = 9,
		font = fonts:loadFont("Regular", 21),
		text = self.username or "-",
		shadow = true,
		z = 0.1,
	}))

	self:addChild("score", Label({
		x = 96, y = 33,
		font = fonts:loadFont("Regular", 16),
		text = self.score,
		shadow = true,
		z = 0.1,
	}))

	local right = 375

	self:addChild("mods", Label({
		y = 8,
		boxWidth = right,
		alignX = "right",
		font = fonts:loadFont("Regular", 14),
		text = self.mods,
		shadow = true,
		z = 0.1,
	}))

	self:addChild("accuracy", Label({
		y = 23,
		boxWidth = right,
		alignX = "right",
		font = fonts:loadFont("Regular", 14),
		text = self.accuracy,
		shadow = true,
		z = 0.1,
	}))

	self:addChild("improvement", Label({
		y = 38,
		boxWidth = right,
		alignX = "right",
		font = fonts:loadFont("Regular", 14),
		text = self.improvement,
		shadow = true,
		z = 0.1,
	}))

	self.nextTimeUpdateTime = -9999
	self:updateTimeSinceScore()

	if self.timeSince ~= "" then
		local x = self.recentIconSide == "right" and 390 or -50
		self:addChild("recentScoreIcon", Label({
			x = x, y = 20,
			text = "",
			font = fonts:loadFont("Awesome", 24),
			shadow = true,
			z = 1,
		}))

		self:addChild("timeSinceScore", DynamicLabel({
			x = x + 26, y = 20 + 3,
			font = fonts:loadFont("Regular", 14),
			shadow = true,
			z = 1,
			value = function()
				return self.timeSince
			end
		}))
	end

	local ScoreListView = require("osu_ui.views.ScoreListView")
	self.width, self.height = 440, ScoreListView.panelHeight
	self.alpha = 0

	self.slideInProgress = 1
	self.alpha = 1

	if self.slide then
		self.slideInProgress = 0
		self.alpha = 0
		self.slideInTween = flux.to(self, 1.3, { slideInProgress = 1 }):delay(self.slideInDelay):ease("elasticout")
		self.slideInAlphaTween = flux.to(self, 0.7, { alpha = 1 }):delay(self.slideInDelay):ease("cubicout")
	end

	self.hoverState = HoverState("quadout", 0.2)
end

function ScoreEntryView:mouseClick()
	if self.mouseOver then
		self.playSound(self.clickSound)
		self.onClick()
		return true
	end
	return false
end

function ScoreEntryView:setMouseFocus(mx, my)
	self.mouseOver = self.hoverState:checkMouseFocus(self.width - 60, self.height, mx, my)
end

function ScoreEntryView:noMouseFocus()
	self.mouseOver = false
	self.hoverState:loseFocus()
end

---@param time {[string]: number}
---@return string?
local function formatTime(time)
	local days = time.days
	local hours = time.hours
	local minutes = time.minutes
	local seconds = time.seconds

	if days then
		if days > 3 then
			return ""
		end
		return ("%id"):format(days)
	elseif hours then
		return ("%ih"):format(hours)
	elseif minutes then
		return ("%im"):format(minutes)
	elseif seconds then
		return ("%is"):format(seconds)
	end
end

function ScoreEntryView:updateTimeSinceScore()
	local current_time = love.timer.getTime()
	if current_time < self.nextTimeUpdateTime then
		return
	end

	self.nextTimeUpdateTime = current_time + 1
	self.timeUpdateTime = love.timer.getTime()
	local time = time_util.date_diff(os.time(), self.time)
	self.timeSince = formatTime(time)
end

function ScoreEntryView:update(dt)
	self:updateTimeSinceScore()
	self.x = (40 * self.slideInProgress) - 40

	if self.mouseOver then
		self.tooltipView:setText(self.tooltip)
	end
end

return ScoreEntryView
