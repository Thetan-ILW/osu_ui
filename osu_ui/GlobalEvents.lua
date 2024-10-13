local class = require("class")

local actions = require("osu_ui.actions")
local math_util = require("math_util")

---@class osu.ui.GlobalEvents
---@operator call: osu.ui.GlobalEvents
local GlobalEvents = class()

GlobalEvents.screenshotSaveLocation = love.filesystem.getSource() .. "/userdata/screenshots"

---@param ui osu.ui.UserInterface
function GlobalEvents:new(ui)
	self.game = ui.game
	self.ui = ui
end

---@param delta number
function GlobalEvents:changeVolume(delta)
	local configs = self.game.configModel.configs
	local settings = configs.settings
	local a = settings.audio
	local v = a.volume

	v.master = math_util.clamp(math_util.round(v.master + (delta * 0.05), 0.05), 0, 1)

	self.ui.screenOverlayView.notificationView:show(("Volume: %i%%"):format(v.master * 100), true)
	self.ui.assetModel:updateVolume()
end

---@param event table
function GlobalEvents:keypressed(event)
	local key = event[2]

	if key == "f12" and not event[3] then
		self.game.app.screenshotModel:capture(false)
	end

	actions.keyPressed(event)
	if event[2] == "backspace" then
		actions.textInputEvent("backspace")
	end
end

local events = {
	wheelmoved = function(self, event)
		if love.keyboard.isDown("lalt") then
			self:changeVolume(event[2])
		end
	end,
	keypressed = function(self, event)
		self:keypressed(event)
	end,
	inputchanged = function(self, event)
		actions.inputChanged(event)
	end,
	textinput = function(self, event)
		actions.textInputEvent(event[1])
	end,
	focus = function()
		actions.resetInputs()
	end,
}

---@param event table
function GlobalEvents:receive(event)
	local f = events[event.name]

	if f then
		f(self, event)
	end
end

return GlobalEvents
