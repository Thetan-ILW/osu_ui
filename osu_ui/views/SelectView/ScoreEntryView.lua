local UiElement = require("osu_ui.ui.UiElement")

local flux = require("flux")
local time_util = require("time_util")

local Image = require("osu_ui.ui.Image")
local Label = require("osu_ui.ui.Label")
local DynamicText = require("osu_ui.ui.DynamicText")

---@alias ScoreViewParams { id: integer, assets: osu.ui.OsuAssets, gradeImageName: string, username: string?, rank: number, score: string, accuracy: string, mods: string, improvement: string, tooltip: string, slideInDelay: number, recentScoreIcon: love.Text, time: number }

---@class osu.ui.ScoreEntryView : osu.ui.UiElement
---@overload fun(params: ScoreViewParams): osu.ui.ScoreEntryView
---@field assets osu.ui.OsuAssets
---@field background love.Image
---@field avatar love.Image
---@field avatarScaleX number
---@field avatarScaleY number
---@field rankLabel osu.ui.Label
---@field rank number
---@field grade osu.ui.Image
---@field gradeImageName string
---@field usernameLabel osu.ui.Label
---@field username string
---@field scoreLabel osu.ui.Label
---@field score string
---@field modsLabel osu.ui.Label
---@field mods string
---@field accuracyLabel osu.ui.Label
---@field accuracy string
---@field improvementLabel osu.ui.Label
---@field improvement string
---@field recentScoreIcon love.Text
---@field time number
---@field slideInDelay number
---@field mouseDown boolean
---@field lastMouseY number
local ScoreEntryView = UiElement + {}

function ScoreEntryView:load()
	self.background = self.assets:loadImage("menu-button-background")

	self.avatar = self.assets:loadAvatar()
	local iw, ih = self.avatar:getDimensions()
	self.avatarScaleX, self.avatarScaleY = 46 / iw, 46 / ih

	self.rankLabel = Label({
		totalW = 46,
		totalH = 46,
		alignX = "center",
		alignY = "center",
		font = self.assets:loadFont("Regular", 28),
		text = tostring(self.rank),
		textScale = self.parent.textScale,
		shadow = true
	})
	self.rankLabel:load()

	self.grade = Image({
		origin = { x = 0.5, y = 0.5 },
		image = self.assets:loadImage(self.gradeImageName),
	})
	self.grade:load()

	self.usernameLabel = Label({
		font = self.assets:loadFont("Regular", 21),
		text = self.username or "-",
		textScale = self.parent.textScale,
		shadow = true
	})
	self.usernameLabel:load()

	self.scoreLabel = Label({
		font = self.assets:loadFont("Regular", 16),
		text = self.score,
		textScale = self.parent.textScale,
		shadow = true
	})
	self.scoreLabel:load()

	local right = 375

	self.modsLabel = Label({
		totalW = right,
		alignX = "right",
		font = self.assets:loadFont("Regular", 14),
		text = self.mods,
		textScale = self.parent.textScale,
		shadow = true
	})
	self.modsLabel:load()

	self.accuracyLabel = Label({
		totalW = right,
		alignX = "right",
		font = self.assets:loadFont("Regular", 14),
		text = self.accuracy,
		textScale = self.parent.textScale,
		shadow = true
	})
	self.accuracyLabel:load()

	self.improvementLabel = Label({
		totalW = right,
		alignX = "right",
		font = self.assets:loadFont("Regular", 14),
		text = self.improvement,
		textScale = self.parent.textScale,
		shadow = true
	})
	self.improvementLabel:load()

	self.timeSinceScore = DynamicText({
		font = self.assets:loadFont("Regular", 14),
		textScale = self.parent.textScale,
		shadow = true,
		value = function ()
			return self.timeSince or ""
		end
	})
	self.timeSinceScore:load()
	self.nextTimeUpdateTime = 0

	local ScoreListView = require("osu_ui.views.SelectView.ScoreListView")
	self.totalW, self.totalH = 430, ScoreListView.panelHeight

	self.slideInProgress = 0
	self.slideInTween = flux.to(self, 1.3, { slideInProgress = 1 }):delay(self.slideInDelay):ease("elasticout")
	self.slideInAlphaProgress = 0
	self.slideInAlphaTween = flux.to(self, 0.7, { slideInAlphaProgress = 1 }):delay(self.slideInDelay):ease("cubicout")

	self.color = { 0, 0, 0, 0.588 }
	self.mouseDown = false
	self.lastMouseY = 0
	UiElement.load(self)
	self.hoverState.tweenDuration = 0.2
end

function ScoreEntryView:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
	self.parent:bindEvent(self, "mouseReleased")
end

function ScoreEntryView:mousePressed()
	if self.mouseOver then
		self.mouseDown = true
		self.lastMouseY = love.mouse.getY()
		return true
	end
	return false
end

function ScoreEntryView:mouseReleased()
	if self.mouseDown and self.mouseOver then
		if math.abs(self.lastMouseY - love.mouse.getY()) < 4 then
			self.parent:openScore(self.id)
		end
	end
	self.mouseDown = false
	return false
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
			return
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

function ScoreEntryView:update(dt, mouse_focus)
	local ap = self.slideInAlphaProgress
	self.usernameLabel.alpha = ap
	self.scoreLabel.alpha = ap
	self.modsLabel.alpha = ap
	self.accuracyLabel.alpha = ap
	self.improvementLabel.alpha = ap
	self.timeSinceScore.alpha = ap

	self.rankLabel.alpha = self.hoverState.progress

	self:applyTransform()
	self:updateTimeSinceScore()
	self.timeSinceScore:update()

	return UiElement.update(self, dt, mouse_focus)
end

function ScoreEntryView:applyTransform()
	self.transform = love.math.newTransform(self.x + (40 * self.slideInProgress) - 40, self.y, self.rotation, self.scale, self.scale, self:getOrigin())
end

local gfx = love.graphics

function ScoreEntryView:draw()
	local ap = self.slideInAlphaProgress

	if ap == 0 then
		return
	end

	gfx.setColor(0, 0, 0, (0.588 + (self.hoverState.progress * 0.2)) * ap)
	gfx.draw(self.background, 0, 4, 0, 0.55, 0.555)

	gfx.push()
	gfx.translate(6, 10)
	gfx.setColor(1, 1, 1, ap)
	gfx.draw(self.avatar, 0, 0, 0, self.avatarScaleX, self.avatarScaleY)

	gfx.setColor(0, 0, 0, self.hoverState.progress * 0.4)
	gfx.rectangle("fill", 0, 0, 46, 46)

	if self.rankLabel.alpha ~= 0 then
		self.rankLabel:draw()
	end
	gfx.pop()

	gfx.push()
	gfx.applyTransform(self.grade.transform)
	gfx.translate(73, 32)
	gfx.setColor(1, 1, 1, ap)
	self.grade:draw()
	gfx.pop()

	gfx.push()
	gfx.translate(96, 9)
	gfx.push()
	self.usernameLabel:draw()
	gfx.pop()
	gfx.translate(0, 24)
	self.scoreLabel:draw()
	gfx.pop()

	gfx.push()

	gfx.translate(0, 8)
	gfx.push()
	self.modsLabel:draw()
	gfx.pop()

	gfx.translate(0, 15)
	gfx.push()
	self.accuracyLabel:draw()
	gfx.pop()

	gfx.translate(0, 15)
	gfx.push()
	self.improvementLabel:draw()
	gfx.pop()

	gfx.pop()

	if self.timeSince then
		gfx.translate(390, 18)
		gfx.setColor(0.078, 0.078, 0.078, 0.64 * ap)
		gfx.push()
		gfx.scale(self.parent.textScale)
		gfx.draw(self.recentScoreIcon, -1, 0)
		gfx.draw(self.recentScoreIcon, 1, 0)
		gfx.draw(self.recentScoreIcon, 0, 1)
		gfx.setColor(1, 1, 1, ap)
		gfx.draw(self.recentScoreIcon)
		gfx.pop()
		gfx.translate(26, 3)

		gfx.setColor(0.078, 0.078, 0.078, 0.64 * ap)
		self.timeSinceScore:draw()
	end
end

return ScoreEntryView
