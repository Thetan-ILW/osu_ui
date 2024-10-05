local class = require("class")

local FrameTimeView = require("ui.views.FrameTimeView")
local AsyncTasksView = require("ui.views.AsyncTasksView")
local NotificationView = require("osu_ui.views.NotificationView")
local PopupView = require("osu_ui.views.PopupView")
local TooltipView = require("osu_ui.views.TooltipView")
local CursorView = require("osu_ui.views.CursorView")

---@class osu.ui.ScreenOverlayView
---@operator call: osu.ui.ScreenOverlayView
local ScreenOverlayView = class()

---@param game sphere.GameController
function ScreenOverlayView:new(game)
	self.configs = game.persistence.configModel.configs
	self.frameTimeView = FrameTimeView()
	self.frameTimeView.game = game
	self.notificationView = NotificationView()
	self.popupView = PopupView()
	self.tooltipView = TooltipView()
	self.cursor = CursorView(self.configs.osu_ui)
	self.notificationModel = game.notificationModel

	self.showTasks = false
end

---@param assets osu.ui.OsuAssets
function ScreenOverlayView:load(assets)
	self.notificationView:load(assets)
	self.popupView:load(assets)
	self.tooltipView:load(assets)
	self.cursor:load(assets)
	self.frameTimeView:load()

end

---@param dt number
function ScreenOverlayView:update(dt)
	self:checkForNotifications()
	self.tooltipView:update()
	self.cursor:update(dt)

	self.showTasks = self.configs.settings.miscellaneous.showTasks
end

---@param event table
function ScreenOverlayView:receive(event)
	self.frameTimeView:receive(event)
end

function ScreenOverlayView:draw()
	self.popupView:draw()
	self.notificationView:draw()
	self.cursor:draw()
	self.tooltipView:draw()
	self.frameTimeView:draw()

	if self.showTasks then
		AsyncTasksView()
	end
end

function ScreenOverlayView:checkForNotifications()
	local msg = self.notificationModel.message
	if msg ~= "" then
		if msg ~= self.prevNotification then
			local first_char = msg:sub(1, 1)

			if first_char == "$" then
				self.popupView:add(msg:sub(2, #msg), "purple")
			elseif first_char == "!" then
				self.popupView:add(msg:sub(2, #msg), "error")
			elseif first_char == "@" then
				self.popupView:add(msg:sub(2, #msg), "orange")
			else
				self.notificationView:show(msg, true)
			end

			self.prevNotification = msg
		end
	end
end

return ScreenOverlayView
