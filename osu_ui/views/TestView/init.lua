local ScreenView = require("osu_ui.views.ScreenView")

local View = require("osu_ui.views.TestView.View")

---@class TestView : osu.ui.ScreenView
---@operator call: TestView
local TestView = ScreenView + {}

function TestView:load()
	self.gameView.scene:addChild("testView", View({ assets = self.assets, z = 0.1 }))
end

function TestView:update(dt)
end

function TestView:draw()
end

function TestView:receive(event)
	if event.name == "keypressed" then
		if love.keyboard.isDown("lctrl") and event[2] == "o" then
			local options = self.gameView.scene:getChild("options")
			options:toggle()
		end
	end
end

return TestView
