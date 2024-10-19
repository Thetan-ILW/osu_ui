local ui = require("osu_ui.ui")
local flux = require("flux")

local Container = require("osu_ui.ui.Container")
local CanvasContainer = require("osu_ui.ui.CanvasContainer")
local ImageButton = require("osu_ui.ui.ImageButton")

---@class osu.ui.PauseViewContainer : osu.ui.CanvasContainer
---@operator call: osu.ui.PauseViewContainer
local View = CanvasContainer + {}

function View:show()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.22, { alpha = 1 }):ease("quadout")
	self.assets.sounds.loop:play()
end

function View:hide()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, 0.22, { alpha = 0 }):ease("quadout")
	self.assets.sounds.loop:stop()
end

---@param gameplay_view osu.ui.GameplayView
function View:load(gameplay_view)
	local assets = gameplay_view.assets
	local img = assets.images
	local snd = assets.sounds
	self.assets = assets

	local gameplay_controller = gameplay_view.game.gameplayController

	local bw, bh = 380, 95
	self:addChild("continueButton", ImageButton(assets, {
		idleImage = img.continue,
		ox = 0.5,
		oy = 0.5,
		hoverArea = { w = bw, h = bh },
		clickSound = snd.continueClick,
		depth = 1,
		transform = love.math.newTransform(ui.layoutW / 2, 224)
	}, function()
		gameplay_controller:changePlayState("play")
		self:hide()
	end))

	self:addChild("retryButton", ImageButton(assets, {
		idleImage = img.retry,
		ox = 0.5,
		oy = 0.5,
		hoverArea = { w = bw, h = bh },
		clickSound = assets.sounds.retryClick,
		depth = 1,
		transform = love.math.newTransform(ui.layoutW / 2, 400)
	}, function()
		gameplay_controller:changePlayState("retry")
		self:hide()
	end))

	self:addChild("backButton", ImageButton(assets, {
		idleImage = img.back,
		ox = 0.5,
		oy = 0.5,
		hoverArea = { w = bw, h = bh },
		clickSound = assets.sounds.retryClick,
		depth = 1,
		transform = love.math.newTransform(ui.layoutW / 2, 576)
	}, function()
		gameplay_view:quit()
	end))

	self:addChild("tint", Container.drawFunction(function ()
		love.graphics.setColor(0.1, 0.1, 1, 0.1)
		love.graphics.rectangle("fill", 0, 0, ui.layoutW, ui.layoutH)
	end, 0))

	self:sortChildren()
end

return View
