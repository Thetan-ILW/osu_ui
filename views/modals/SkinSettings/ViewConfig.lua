local IViewConfig = require("osu_ui.views.IViewConfig")
local Container = require("osu_ui.ui.Container")

local just = require("just")
local ui = require("osu_ui.ui")
local spherefonts = require("sphere.assets.fonts")
local Format = require("sphere.views.Format")
local Button = require("osu_ui.ui.Button")

local Layout = require("osu_ui.views.OsuLayout")
local DefaultLayout = require("osu_ui.views.DefaultLayout")

---@class osu.ui.SkinSettingsModalView : osu.ui.IViewConfig
---@operator call: osu.ui.SkinSettingsModalView
local ViewConfig = IViewConfig + {}

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
---@param modal osu.ui.Modal
function ViewConfig:new(game, assets, modal)
	text, font = assets.localization:get("skinSettingsModal")
	assert(text and font)
	self.game = game
	self.assets = assets
	self.modal = modal
	self:createUI()
end

local scale = 0.9
local width = 2.76
local gray = { 0.42, 0.42, 0.42, 1 }

---@type osu.ui.Button
local close_button

function ViewConfig:createUI()
	local assets = self.assets
	local modal = self.modal

	close_button = Button(assets, {
		text = text.close,
		scale = scale,
		width = width,
		color = gray,
		font = font.buttons,
	}, function()
		modal:quit()
	end)

	self.container = Container("skin_settings")
end

local gfx = love.graphics

function ViewConfig:noteSkinSettings()
	local sw, sh = DefaultLayout:move("base")
	local w, h = 900, 620

	gfx.translate(sw / 2 - w / 2, 240)

	gfx.setColor(0, 0, 0, 0.7)
	gfx.rectangle("fill", 0, 0, w, h, 5, 5)
	gfx.setColor(0.89, 0.47, 0.56)
	gfx.rectangle("line", 0, 0, w, h, 5, 5)

	local config = self.modal.skin.config
	if not config or not config.draw then
		gfx.setFont(font.noSettings)
		ui.frame(text.noSettings, 0, 0, w, h, "center", "center")
		return
	end

	gfx.setFont(spherefonts.get("Noto Sans", 24))
	local startHeight = just.height
	self.container:startDraw(w, h)
	gfx.setColor(1, 1, 1)
	config:draw(w, h)
	self.container.scrollLimit = just.height - startHeight - h
	self.container.stopDraw()
end

function ViewConfig:resolutionUpdated()
	self:createUI()
end

function ViewConfig:draw(modal)
	DefaultLayout:draw()
	local w, h = Layout:move("base")

	gfx.setColor(1, 1, 1, 1)
	gfx.setFont(font.title)

	ui.frame(text.title, 9, 9, w - 18, h, "left", "top")

	local input_mode = self.game.selectController.state.inputMode
	input_mode = Format.inputMode(tostring(input_mode))
	input_mode = input_mode == "2K" and "TAIKO" or input_mode

	gfx.setFont(font.mode)

	ui.frame("Mode: " .. input_mode, 0, 90, w, h, "center", "top")

	gfx.push()
	self:noteSkinSettings()
	gfx.pop()

	local bw, bh = close_button:getDimensions()
	gfx.translate(w / 2 - bw / 2, 640)
	close_button:update(true)
	close_button:draw()
end

return ViewConfig
