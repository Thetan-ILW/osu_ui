local flux = require("flux")

local CanvasContainer = require("osu_ui.ui.CanvasContainer")
local ImageButton = require("osu_ui.ui.ImageButton")
local Rectangle = require("osu_ui.ui.Rectangle")

---@alias PauseViewParams { assets: osu.ui.OsuAssets, gameplayView: osu.ui.GameplayView, gameplayController: sphere.GameplayController }

---@class osu.ui.PauseView : osu.ui.CanvasContainer
---@overload fun(PauseViewParams): osu.ui.PauseView
---@field assets osu.ui.OsuAssets 
---@field gameplayController sphere.GameplayController
---@field gameplayView osu.ui.GameplayView
local View = CanvasContainer + {}

function View:show()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.22, { alpha = 1 }):ease("quadout")
end

function View:hide()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.22, { alpha = 0 }):ease("quadout")
end

function View:load()
	CanvasContainer.load(self)

	local width, height = self.parent.totalW, self.parent.totalH
	local gameplay_controller = self.gameplayController
	local gameplay_view = self.gameplayView
	local assets = self.assets

	local bw, bh = 380, 95
	self:addChild("continueButton", ImageButton({
		x = width / 2, y = 224,
		origin = { x = 0.5, y = 0.5 },
		assets = assets,
		idleImage = assets:loadImage("pause-continue"),
		depth = 1,
		onClick = function ()
			gameplay_controller:changePlayState("play")
			self:hide()
		end
	}))

	self:addChild("retryButton", ImageButton({
		x = width / 2, y = 400,
		origin = { x = 0.5, y = 0.5 },
		assets = assets,
		idleImage = assets:loadImage("pause-retry"),
		depth = 1,
		onClick = function ()
			gameplay_controller:changePlayState("retry")
			self:hide()
		end
	}))

	self:addChild("backButton", ImageButton({
		x = width / 2, y = 576,
		origin = { x = 0.5, y = 0.5 },
		assets = assets,
		idleImage = assets:loadImage("pause-back"),
		depth = 1,
		onClick = function ()
			gameplay_view:quit()
		end
	}))

	self:addChild("tint", Rectangle({
		totalW = width,
		totalH = height,
		color = { 0.1, 0.1, 1, 0.1 },
		depth = 0,
	}))

	self:build()
end

return View
