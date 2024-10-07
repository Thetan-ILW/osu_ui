local IViewConfig = require("osu_ui.views.IViewConfig")
local Layout = require("osu_ui.views.OsuLayout")

local ui = require("osu_ui.ui")
local gfx_util = require("gfx_util")
local math_util = require("math_util")
local flux = require("flux")

local Checkbox = require("osu_ui.ui.Checkbox")
local Button = require("osu_ui.ui.Button")

local ViewConfig = IViewConfig + {}

---@param view osu.ui.FirstTimeSetupView
function ViewConfig:new(view)
	self.view = view
	self:createUI()
end

function ViewConfig:createUI()
	local view = self.view
	local assets = view.assets
	local text, font = assets.localization:get("firstTimeSetup")
	assert(text and font)

	self.text, self.font = text, font

	self.checkboxContainer = {
		Checkbox(assets, {
			text = text.useOsuSongs,
			font = font.checkboxes,
			pixelHeight = 37,
			disabled = not view.osuFound
		}, function ()
			return view.useOsuSongs
		end,  function ()
			view.useOsuSongs = not view.useOsuSongs
		end),
		Checkbox(assets, {
			text = text.useEtternaSongs,
			font = font.checkboxes,
			pixelHeight = 37,
			disabled = not view.etternaFound
		}, function ()
			return view.useEtternaSongs
		end,  function ()
			view.useEtternaSongs = not view.useEtternaSongs
		end),
		Checkbox(assets, {
			text = text.useQuaverSongs,
			font = font.checkboxes,
			pixelHeight = 37,
			disabled = not view.quaverFound
		}, function ()
			return view.useQuaverSongs
		end,  function ()
			view.useQuaverSongs = not view.useQuaverSongs
		end),
		Checkbox(assets, {
			text = text.useOsuSkins,
			font = font.checkboxes,
			pixelHeight = 37,
			disabled = not view.osuFound
		}, function ()
			return view.useOsuSkins
		end,  function ()
			view.useOsuSkins = not view.useOsuSkins
		end),
		Checkbox(assets, {
			text = text.applyOsuSettings,
			font = font.checkboxes,
			pixelHeight = 37,
			disabled = not view.osuFound
		}, function ()
			return view.applyOsuSettings
		end,  function ()
			view.applyOsuSettings = not view.applyOsuSettings
		end)
	}

	self.checkboxContainerWidth = 0
	for i, v in ipairs(self.checkboxContainer) do
		self.checkboxContainerWidth = math.max(self.checkboxContainerWidth, v.totalW)
	end

	self.hoverRectTargetY = 1
	self.hoverRectY = 1
	self.hoverTime = -math.huge

	self.doneButton = Button(assets, {
		text = text.done,
		font = font.buttons,
		pixelWidth = 737,
		pixelHeight = 65,
		color = { 0.52, 0.72, 0.12, 1 }

	}, function ()
		view:applySelected()
	end)

	self.startButton = Button(assets, {
		text = text.start,
		font = font.buttons,
		pixelWidth = 737,
		pixelHeight = 65,
		color = { 0.52, 0.72, 0.12, 1 }
	}, function ()
		view:start()
	end)

	---TODO: Add master volume at the bottom
	---TODO: Add language swtich dropdown at the top
end

local gfx = love.graphics

local parallax = 0.08
local function background(image)
	gfx.origin()
	local w, h = gfx.getDimensions()
	local mx, my = love.mouse.getPosition()
	gfx.setColor(0.4, 0.4, 0.4, 1)
	gfx_util.drawFrame(
		image,
		-math_util.map(mx, 0, w, parallax, 0) * w,
		-math_util.map(my, 0, h, parallax, 0) * h,
		(1 + 2 * parallax) * w,
		(1 + 2 * parallax) * h,
		"out"
	)
end

local checkbox_y = 380
function ViewConfig:checkboxes(w, h)
	gfx.push()
	gfx.setColor(0, 0, 0, 1 - math_util.clamp(love.timer.getTime() - self.hoverTime, 0, 0.5) * 2)
	gfx.rectangle("fill", 0, checkbox_y + ((self.hoverRectY - 1) * 37), w, 37)

	gfx.translate(w / 2 - self.checkboxContainerWidth / 2, checkbox_y)
	for i, v in ipairs(self.checkboxContainer) do
		v:update(true)
		if v:isMouseOver() then
			self.hoverTime = love.timer.getTime()
			if self.hoverRectTargetY ~= i then
				self.hoverRectTargetY = i
				if self.hoverRectTween then
					self.hoverRectTween:stop()
				end
				self.hoverRectTween =
					flux.to(self, 0.6, { hoverRectY = i })
						:ease("elasticout")
			end
		end
		v:draw()
	end
	gfx.pop()
end

function ViewConfig:options(w, h)
	gfx.push()
	gfx.setColor(1, 1, 1)
	gfx.setFont(self.font.info)
	ui.frameWithShadow(self.text.underLogo, 0, 270, w, h, "center", "top")

	self:checkboxes(w, h)

	local bw, _ = self.doneButton:getDimensions()
	gfx.translate(w / 2 - bw / 2, 620)
	self.doneButton:update(true)
	self.doneButton:draw()
	gfx.pop()
end

local game_colors = {
	["osu!"] = { 0.97, 0.38, 0.82 },
	Etterna = { 0.52, 0.09, 0.92 },
	Quaver = { 0.28, 0.84, 0.93 }
}

function ViewConfig:progress(w, h)
	gfx.push()
	local view = self.view

	gfx.translate(9, h - #view.songDirs * 40)
	gfx.setFont(self.font.info)

	for i, v in ipairs(view.songDirs) do
		gfx.setColor(game_colors[v.name])
		gfx.rectangle("fill", 0, 0, 30, 30, 8, 8)
		gfx.rectangle("line", 0, 0, 30, 30, 8, 8)

		gfx.setColor(1, 1, 1)
		local processing = view.currentSongsDirIndex == i

		if processing then
			ui.frameWithShadow(("%s (Processing)"):format(v.name), 40, 0, w, 30, "left", "center")
		elseif v.added then
			ui.frameWithShadow(("%s (Complete)"):format(v.name), 40, 0, w, 30, "left", "center")
		else
			ui.frameWithShadow(("%s"):format(v.name), 40, 0, w, 30, "left", "center")
		end

		gfx.translate(0, 40)
	end

	gfx.pop()

	local dir = view.songDirs[view.currentSongsDirIndex]

	local path = "Waiting..."
	if dir then
		path = dir.path
	end

	local cache_model = view.game.cacheModel
	local count = cache_model.shared.chartfiles_count
	local current = cache_model.shared.chartfiles_current

	gfx.setFont(self.font.status)

	local label = ("%s: %s\n%s: %s/%s\n%s: %0.02f%%"):format(
		self.text.path,
		path,
		self.text.chartsFound,
		current,
		count,
		self.text.chartsCached,
		current / count * 100
	)

	ui.frameWithShadow(label, 0, 0, w, h, "center", "center")

	gfx.setFont(self.font.warning)
	ui.frameWithShadow(self.text.warning, 0, -9, w, h, "center", "bottom")
end

function ViewConfig:goodbye(w, h)
	gfx.push()
	gfx.setColor(1, 1, 1)
	gfx.setFont(self.font.info)
	ui.frameWithShadow(self.text.goodbye, 0, 360, w, h, "center", "top")

	local bw, _ = self.startButton:getDimensions()
	gfx.translate(w / 2 - bw / 2, 480)
	self.startButton:update(true)
	self.startButton:draw()
	gfx.pop()
end

function ViewConfig:transit(a, b, progress, w, h)
	local prev_canvas = gfx.getCanvas()
	local canvas_a = ui.getCanvas("transit_a")
	local canvas_b = ui.getCanvas("transit_b")
	gfx.setBlendMode("alpha", "alphamultiply")

	gfx.setCanvas(canvas_a)
	gfx.clear()
	a(self, w, h)
	gfx.setCanvas(canvas_b)
	gfx.clear()
	b(self, w, h)
	gfx.setCanvas(prev_canvas)

	gfx.setBlendMode("alpha", "premultiplied")
	local alpha = 1 - progress
	gfx.setColor(alpha, alpha, alpha, alpha)
	gfx.origin()
	gfx.draw(canvas_a)
	alpha = progress
	gfx.setColor(alpha, alpha, alpha, alpha)
	gfx.draw(canvas_b)
end

function ViewConfig:draw()
	local w, h = Layout:move("base")

	local img = self.view.assets.images
	gfx.push()
	background(img.welcomeBackground)
	gfx.pop()

	local welcome_image = img.welcomeImage
	local iw, ih = welcome_image:getDimensions()
	gfx.setColor(1, 1, 1)
	gfx.draw(welcome_image, w / 2 - iw / 2)

	local view = self.view

	if view.state == "selecting" then
		self:options(w, h)
	elseif view.state == "transit_to_cache" then
		self:transit(self.options, self.progress, view.setupTransitProgress, w, h)
	elseif view.state == "setup" or view.state == "cache" then
		self:progress(w, h)
	elseif view.state == "transit_to_end" then
		self:transit(self.progress, self.goodbye, view.endTransitProgress, w, h)
	elseif view.state == "end" then
		self:goodbye(w, h)
	end
end

return ViewConfig
