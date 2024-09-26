local IViewConfig = require("osu_ui.views.IViewConfig")
local OsuLayout = require("osu_ui.views.OsuLayout")

local BackButton = require("osu_ui.ui.BackButton")

local ui = require("osu_ui.ui")

local ViewConfig = IViewConfig + {}

local gfx = love.graphics

function ViewConfig:new(view)
	self.view = view
	self.assets = view.assets
	self:createUI(view)
end

function ViewConfig:createUI(view)
	local assets = self.assets

	self.backButton = BackButton(assets, { w = 93, h = 90 }, function()
		view:quit()
	end)
end

function ViewConfig:activity(w, h)
	gfx.push()
	local view = self.view
	local activity_view = view.activityView
	gfx.translate(w, h)

	local img = self.assets.images.activityBackground
	gfx.draw(img, 0, 0, 0, 1, 1, img:getDimensions())

	gfx.translate(-activity_view.totalW - 15, -activity_view.totalH - 10)

	view.cursor.alpha = 1
	if activity_view:checkMousePos(love.mouse.getPosition()) then
		view.cursor.alpha = 0
	end

	activity_view:draw()
	gfx.pop()
end

function ViewConfig:activityTooltip(w, h)
	gfx.push()
	local activity = self.view.activityView
	local tw, th = activity.totalW, activity.totalH

	gfx.translate(w - tw - 15, h - th - 15 - 200)

	if activity.activeTooltip then
		ui.frame(activity.activeTooltip, 4, -26, tw, 200, "left", "bottom")
	end
	gfx.pop()
end

local dan_table_w, dan_table_h = 370, 423

function ViewConfig:danTable(w, h)
	local img = self.assets.images.danClearsBackground
	gfx.draw(img, w, 0, 0, 1, 1, img:getWidth())

	gfx.push()
	gfx.translate(w - dan_table_w, 70)
	local dan_table = self.view.danTableView
	dan_table:update(dan_table_w, dan_table_h)
	dan_table:draw(dan_table_w, dan_table_h)
	gfx.pop()

	local overlay = self.assets.images.danClearsOverlay
	gfx.draw(overlay, w, 0, 0, 1, 1, overlay:getWidth())
end

function ViewConfig:draw()
	local w, h = OsuLayout:move("base")
	self:activity(w, h)
	self:activityTooltip(w, h)
	self:danTable(w, h)

	gfx.push()
	gfx.translate(0, h - 58)
	self.backButton:update(true)
	self.backButton:draw()
	gfx.pop()
end

return ViewConfig
