local IViewConfig = require("osu_ui.views.IViewConfig")
local OsuLayout = require("osu_ui.views.OsuLayout")

local ui = require("osu_ui.ui")

local ViewConfig = IViewConfig + {}

local gfx = love.graphics

function ViewConfig:new(view)
	self.view = view
end

function ViewConfig:activity(w, h)
	gfx.push()
	local view = self.view
	local activity_view = view.activityView
	gfx.translate(w - activity_view.totalW - 15, h - activity_view.totalH - 15)

	view.cursor.alpha = 1
	if activity_view:checkMousePos(love.mouse.getPosition()) then
		view.cursor.alpha = 0
	end

	activity_view:draw()
	gfx.pop()
end

function ViewConfig:activityTooltip(w, h)
	gfx.push()
	local activity_view = self.view.activityView
	local tw, th = activity_view.totalW, activity_view.totalH

	gfx.translate(w - tw - 15, h - th - 15 - 200)

	if activity_view.activeTooltip then
		ui.frame(activity_view.activeTooltip, 4, -4, tw, 200, "left", "bottom")
	end
	gfx.pop()
end

function ViewConfig:draw()
	local w, h = OsuLayout:move("base")
	self:activity(w, h)
	self:activityTooltip(w, h)
end

return ViewConfig
