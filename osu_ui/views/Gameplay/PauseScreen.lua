local Component = require("ui.Component")
local ImageButton = require("osu_ui.ui.ImageButton")
local Rectangle = require("ui.Rectangle")

---@alias osu.ui.PauseViewParams { assets: osu.ui.OsuAssets, gameplayView: osu.ui.GameplayView, gameplayController: sphere.GameplayController }

---@class osu.ui.PauseView : ui.Component
---@overload fun(params: osu.ui.PauseViewParams): osu.ui.PauseView
---@field assets osu.ui.OsuAssets 
---@field gameplayController sphere.GameplayController
---@field gameplayView osu.ui.GameplayView
local View = Component + {}

function View:load()
	local width, height = self.width, self.height

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets

	--local bw, bh = 380, 95
	self:addChild("continueButton", ImageButton({
		x = width / 2, y = 224,
		origin = { x = 0.5, y = 0.5 },
		idleImage = assets:loadImage("pause-continue"),
		z = 1,
		onClick = function ()
			gameplay_controller:changePlayState("play")
		end
	}))

	self:addChild("retryButton", ImageButton({
		x = width / 2, y = 400,
		origin = { x = 0.5, y = 0.5 },
		idleImage = assets:loadImage("pause-retry"),
		z = 1,
		onClick = function ()
			gameplay_controller:changePlayState("retry")
		end
	}))

	self:addChild("backButton", ImageButton({
		x = width / 2, y = 576,
		origin = { x = 0.5, y = 0.5 },
		idleImage = assets:loadImage("pause-back"),
		z = 1,
		onClick = function ()
			gameplay_view:quit()
		end
	}))

	self:addChild("tint", Rectangle({
		width = width,
		height = height,
		color = { 0.1, 0.1, 1, 0.1 },
	}))
end

return View
