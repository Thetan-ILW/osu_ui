local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.UiLockView.Layout")

local ui = require("osu_ui.ui")

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

local gfx = love.graphics

---@class osu.ui.UiLockViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.UiLockViewConfig
local ViewConfig = IViewConfig + {}

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ViewConfig:new(game, assets)
	self.game = game
	self.assets = assets
	text, font = assets.localization:get("uiLock")
	assert(text and font)
end

function ViewConfig:draw()
	Layout:draw()

	local cache_model = self.game.cacheModel
	local location_manager = self.game.cacheModel.locationManager

	---@type number
	local selected_loc = location_manager.selected_loc
	---@type string
	local path = selected_loc.path

	local count = cache_model.shared.chartfiles_count
	local current = cache_model.shared.chartfiles_current

	local w, h = Layout:move("background")
	gfx.setColor(0, 0, 0, 0.75)
	gfx.rectangle("fill", 0, 0, w, h)

	local img = self.assets.images.uiLock

	gfx.setColor({ 1, 1, 1, 1 })
	gfx.draw(img, 0, 0, 0, w / img:getWidth(), 1)

	w, h = Layout:move("title")
	gfx.setFont(font.title)
	ui.frameWithShadow(text.processingCharts, 0, 0, w, h, "center", "center")

	w, h = Layout:move("background")
	gfx.setFont(font.status)

	local label = ("%s: %s\n%s: %s/%s\n%s: %0.02f%%"):format(
		text.path,
		path,
		text.chartsFound,
		current,
		count,
		text.chartsCached,
		current / count * 100
	)

	ui.frame(label, 0, 0, w, h, "center", "center")
end

return ViewConfig
