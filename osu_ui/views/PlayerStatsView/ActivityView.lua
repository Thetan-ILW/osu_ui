local class = require("class")
local ui = require("osu_ui.ui")

---@class osu.ui.ActivityView
---@operator call: osu.ui.ActivityView
---@field spriteBatch love.SpriteBatch
---@field rectSize number
---@field totalW number
---@field totalH number
---@field graphY number
---@field sessionCountLabel love.Text
---@field sessionTime love.Text
---@field tooltips {[string]: string}
---@field activeTooltip
local ActivityView = class()

local tooltip_format = "w%id%i"

---@param stats DayStats
---@return string
local function createTooltipText(stats)
	if stats.sessionTime == 0 then
		return "No sessions on " .. stats.date
	end

	return ("%s\nTotal session time: %i minutes\nTime played: %i minutes\nCharts played: %i\nKeys pressed: %i\nRagequits: %i"):format(
		stats.date, stats.sessionTime, stats.timePlayed, stats.chartsPlayed, stats.keysPressed, stats.rageQuits
	)
end

---@param assets osu.ui.OsuAssets
---@param activity Activity
function ActivityView:new(assets, activity)
	local rectangle_img = assets.images.activityRectangle
	local img_size = rectangle_img:getWidth() + 2

	self.assets = assets
	self.activity = activity
	self.rectSize = img_size
	self.spriteBatch = love.graphics.newSpriteBatch(rectangle_img)
	self.totalW = 0
	self.totalH = 0
	self.tooltips = {}

	for i, v in ipairs(activity.rectangles) do
		local x = v.week * img_size
		local y = v.day * img_size
		local a = math.max(0.1, v.alphaColor)
		self.spriteBatch:setColor(0.14 * a, 1 * a, 0.31 * a)
		self.spriteBatch:add(x, y)
		self.totalW = math.max(self.totalW, x + img_size)
		self.totalH = math.max(self.totalH, y + img_size)
		self.tooltips[tooltip_format:format(v.week, v.day)] = createTooltipText(v.stats)
	end

	local text, font = assets.localization:get("playerStats")
	assert(text and font)

	self.totalH = self.totalH + font.activity:getHeight()
	self.graphY = font.activity:getHeight()
	self:createUI()
end

function ActivityView:createUI()
	local activity = self.activity
	local text, font = self.assets.localization:get("playerStats")
	assert(text and font)

	self.sessionCountLabel = love.graphics.newText(font.activity, text.sessionsInYear:format(activity.sessionCount, activity.year))
	self.sessionTime = love.graphics.newText(font.activity, text.sessionsTime:format(activity.maxSessionTime, activity.avgSessionTime))
end

---@return boolean
function ActivityView:checkMousePos(x, y)
	if not ui.isOver(self.totalW, self.totalH - self.graphY, 0, self.graphY) then
		self.activeTooltip = nil
		return false
	end

	x, y = love.graphics.inverseTransformPoint(x, y)
	local week, day = math.floor(x / self.rectSize), math.floor((y - self.graphY) / self.rectSize)
	self.activeTooltip = self.tooltips[tooltip_format:format(week, day)]
	return true
end

function ActivityView:draw()
	love.graphics.setColor(1, 1, 1)
	ui.textFrame(self.sessionCountLabel, 0, -4, self.totalW, self.sessionCountLabel:getHeight(), "left", "top")
	ui.textFrame(self.sessionTime, 0, -4, self.totalW, self.sessionCountLabel:getHeight(), "right", "top")
	love.graphics.draw(self.spriteBatch, 0, self.sessionCountLabel:getHeight())
end

return ActivityView
