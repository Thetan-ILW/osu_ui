local ScreenView = require("osu_ui.views.ScreenView")

local View = require("osu_ui.views.TestView.View")

---@class TestView : osu.ui.ScreenView
---@operator call: TestView
local TestView = ScreenView + {}

function TestView:load()
	self.gameView.screenContainer:addChild("view", View({ assets = self.assets }))
end

function TestView:update(dt)
end

function TestView:draw()
end

function TestView:receive(event)
	if event.name == "mousepressed" then
		self.gameView.screenContainer:removeChild("view")
		self.gameView.screenContainer:addChild("view", View({ depth = 0, assets = self.assets }))
	end
end

return TestView
