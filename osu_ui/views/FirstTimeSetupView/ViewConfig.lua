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

	self.infoText = text.underLogo
	self.infoFont = font.info

	self.checkboxContainer = {
		Checkbox(assets, {
			text = text.useOsuSongs,
			font = font.checkboxes,
			pixelHeight = 37
		}, function ()
			return view.useOsuSongs
		end,  function ()
			view.useOsuSongs = not view.useOsuSongs
		end),
		Checkbox(assets, {
			text = text.useEtternaSongs,
			font = font.checkboxes,
			pixelHeight = 37
		}, function ()
			return view.useEtternaSongs
		end,  function ()
			view.useEtternaSongs = not view.useEtternaSongs
		end),
		Checkbox(assets, {
			text = text.useQuaverSongs,
			font = font.checkboxes,
			pixelHeight = 37
		}, function ()
			return view.useQuaverSongs
		end,  function ()
			view.useQuaverSongs = not view.useQuaverSongs
		end),
		Checkbox(assets, {
			text = text.useOsuSkins,
			font = font.checkboxes,
			pixelHeight = 37
		}, function ()
			return view.useOsuSkins
		end,  function ()
			view.useOsuSkins = not view.useOsuSkins
		end),
		Checkbox(assets, {
			text = text.applyOsuSettings,
			font = font.checkboxes,
			pixelHeight = 37
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

local  checkbox_y = 380
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


function ViewConfig:draw()
	local w, h = Layout:move("base")

	local img = self.view.assets.images
	gfx.push()
	background(img.background)
	gfx.pop()

	gfx.setFont(self.infoFont)

	gfx.setColor(1, 1, 1)
	ui.frameWithShadow(self.infoText, 0, 270, w, h, "center", "top")

	self:checkboxes(w, h)

	local welcome_image = img.welcomeImage
	local iw, ih = welcome_image:getDimensions()
	gfx.draw(welcome_image, w / 2 - iw / 2)


	local bw, _ = self.doneButton:getDimensions()
	gfx.translate(w / 2 - bw / 2, 620)
	self.doneButton:update(true)
	self.doneButton:draw()
end

return ViewConfig
