local ScreenView = require("osu_ui.views.ScreenView")

local ScreenContainer = require("osu_ui.ui.ScreenContainer")
local View = require("osu_ui.views.TestView.View")

---@class TestView : osu.ui.ScreenView
---@operator call: TestView
local TestView = ScreenView + {}

function TestView:load()
	self.mainContainer = ScreenContainer({ nativeHeight = 768, transform = love.math.newTransform(0, 0) })
	self.mainContainer:load()
	self.mainContainer:addChild("view", View({ assets = self.assets }))
	self.mainContainer:build()
end

function TestView:update(dt)
	love.graphics.origin()
	self.mainContainer:setSize(love.graphics.getDimensions())
	self.mainContainer:update(dt)
end

function TestView:draw()
	love.graphics.origin()
	self.mainContainer:draw()
end

function TestView:receive(event)
	if event.name == "framestarted" then
		return
	end
	self.mainContainer:receive(event)
end

return TestView
