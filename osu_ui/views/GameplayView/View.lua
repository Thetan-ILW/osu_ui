local CanvasComponent = require("ui.CanvasComponent")
local Playfield = require("osu_ui.views.GameplayView.Playfield")
local PauseScreen = require("osu_ui.views.GameplayView.PauseScreen")
local flux = require("flux")

---@class osu.ui.GameplayViewContainer : ui.CanvasComponent
---@operator call: osu.ui.GameplayViewContainer
---@field gameplayView osu.ui.GameplayView
---@field state "play" | "pausing" | "pause" | "unpausing"
local View = CanvasComponent + {}

function View:setPauseAlpha(a)
	if self.pauseTween then
		self.pauseTween:stop()
	end
	self.pauseTween = flux.to(self.pause, 0.4, { alpha = a }):ease("quadout")
end

---@param game_state "play" | "pause" | "force_play"
function View:processGameState(game_state)
	if self.state == "play" then
		if game_state == "pause" then
			self.state = "pausing"
			self:setPauseAlpha(1)
		end
	elseif self.state == "pausing" then
		if self.pause.alpha == 1 then
			self.state = "pause"
		end
	elseif self.state == "pause" then
		if game_state == "force_play" or game_state == "play" then
			self:setPauseAlpha(0)
			self.state = "unpausing"
		end
	elseif self.state == "unpausing" then
		if self.pause.alpha == 0 then
			self.state = "play"
		end
	end
end

function View:load()
	self.width, self.height = self.parent:getDimensions()
	self:createCanvas(self.width, self.height)
	self:getViewport():listenForResize(self)

	self.state = "play"
	local gameplay_view = self.gameplayView
	local gameplay_cfg = gameplay_view.game.configModel.configs.osu_ui.gameplay

	local render_at_native_res = gameplay_view.nativeRes

	if render_at_native_res then
		local native_res_x, native_res_y = gameplay_cfg.nativeResX, gameplay_cfg.nativeResY
		local native_res_w, native_res_h = gameplay_cfg.nativeResSize.width, gameplay_cfg.nativeResSize.height
		local viewport_scale = self:getViewport():getInnerScale()
		self:addChild("playfield", Playfield({
			x = ((love.graphics.getWidth() - native_res_w) * viewport_scale) * native_res_x,
			y = ((love.graphics.getHeight() - native_res_h) * viewport_scale) * native_res_y,
			width = native_res_w,
			height = native_res_h,
			renderAtNativeResoltion = true,
			sequenceView = gameplay_view.sequenceView,
			z = 0.1
		}))
	else
		self:addChild("playfield", Playfield({
			width = self.width,
			height = self.height,
			renderAtNativeResoltion = false,
			sequenceView = gameplay_view.sequenceView,
			z = 0.1
		}))
	end

	self.pause = self:addChild("pause", PauseScreen({
		width = self.width,
		height = self.height,
		gameplayController = gameplay_view.game.gameplayController,
		gameplayView = gameplay_view,
		alpha = 0,
		z = 0.2,
	}))
end

function View:draw()
	local a = self.alpha
	love.graphics.setColor(a, a, a, a)
	love.graphics.draw(self.canvas)
end

return View
