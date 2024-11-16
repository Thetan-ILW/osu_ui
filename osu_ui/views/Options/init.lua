local CanvasContainer = require("osu_ui.ui.CanvasContainer")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local math_util = require("math_util")
local flux = require("flux")
local Rectangle = require("osu_ui.ui.Rectangle")
local Label = require("osu_ui.ui.Label")
local TextBox = require("osu_ui.ui.TextBox")

local Section = require("osu_ui.views.Options.Section")

---@alias OptionsParams { assets: osu.ui.OsuAssets, localization: Localization }

---@class osu.ui.OptionsView : osu.ui.CanvasContainer
---@overload fun(params: OptionsParams): osu.ui.OptionsView
---@field assets osu.ui.OsuAssets
---@field localization Localization
---@field fadeTween table?
local Options = CanvasContainer + {}

Options.panelWidth = 438
Options.tabsContrainerWidth = 64
Options.searchFormat = { { 1, 1, 1, 1 }, " ", { 1, 1, 1, 0.65 }, ""}

function Options:fade(target_value)
	if self.fadeTween then
		self.fadeTween:stop()
	end
	self.fadeTween = flux.to(self, 0.5, { alpha = target_value }):ease("quadout")
	self.state = target_value == 0 and "closed" or "open"
end

function Options:toggle()
	self:fade(self.state == "closed" and 1 or 0)
end

function Options:drawCanvas()
	local scale = self.viewportScale
	love.graphics.setScissor(0, 0, math.max(self.tabsContrainerWidth * scale, self.totalW * scale), self.totalH)
	love.graphics.draw(self.canvas)
	love.graphics.setScissor()
end

function Options:update(dt, mouse_focus)
	self.totalW = (self.panelWidth + self.tabsContrainerWidth) * self.alpha

	local p = self.hoverState.progress
	self.koolRectangle.color[4] = p
	if p == 0 then
		self.koolRectangle.y = -1
	end

	return CanvasContainer.update(self, dt, mouse_focus)
end

function Options:searchUpdated()
	local label = self.children.searchLabel

	if self.search == "" then
		self.searchFormat[4] = self.text.SongSelection_TypeToBegin
		self.searchFormat[3] = { 1, 1, 1, 0.7 }
	else
		self.searchFormat[4] = self.search
		self.searchFormat[3] = { 1, 1, 1, 1 }
	end

	label:replaceText(self.searchFormat)
end

function Options:textInput(event)
	if self.alpha < 0.1 then
		return false
	end
	self.search = self.search .. event[1]
	self:searchUpdated()
	return true
end

function Options:keyPressed(event)
	if self.alpha < 0.1 then
		return false
	end
	if event[2] ~= "backspace" then
		return false
	end

	self.search = TextBox.removeChar(self.search)
	self:searchUpdated()
	return true
end

function Options:load()
	local assets = self.assets
	local width, height = self.parent:getDimensions()
	local viewport = self.parent:getViewport()
	self.viewportScale = viewport:getScale()

	self.totalW = (self.panelWidth + self.tabsContrainerWidth) * self.viewportScale
	self.totalH = viewport.screenH * self.viewportScale
	self.state = "closed"
	self.alpha = 0
	self.text = self.localization.text
	self.searchFormat[4] = self.text.SongSelection_TypeToBegin
	self.search = ""
	self.stencil = true

	CanvasContainer.load(self)
	self:addTags({ "allowReload" })
	self.hoverState.tweenDuration = 0.5
	self.hoverState.ease = "quadout"

	local options = self

	self:addChild("tabsBackground", Rectangle({
		totalW = self.tabsContrainerWidth,
		totalH = height,
		color = { 0, 0, 0, 1 },
		depth = 0,
	}))

	self:addChild("panelBackground", Rectangle({
		x = self.tabsContrainerWidth,
		totalW = self.panelWidth,
		totalH = height,
		color = { 0, 0, 0, 0.7 },
		depth = 0,
	}))

	local panel = self:addChild("panel", ScrollAreaContainer({
		x = self.tabsContrainerWidth,
		totalW = self.panelWidth,
		totalH = height,
		scrollLimit = height,
		depth = 0.1
	}))
	---@cast panel osu.ui.ScrollAreaContainer

	function panel:bindEvent(child, event)
		options:bindEvent(child, event)
	end

	panel:addChild("optionsLabel", Label({
		y = 60,
		totalW = panel.totalW,
		alignX = "center",
		text = self.text.Options_Options,
		font = assets:loadFont("Light", 28),
	}))

	panel:addChild("gameBehaviorLabel", Label({
		y = 100,
		totalW = panel.totalW,
		alignX = "center",
		text = self.text.Options_HeaderBlurb,
		font = assets:loadFont("Light", 19),
		color = { 0.83, 0.38, 0.47, 1 },
	}))

	local header_background = self:addChild("headerBackground", Rectangle({
		x = self.tabsContrainerWidth,
		totalW = self.panelWidth,
		totalH = 200,
		color = { 0, 0, 0, 0.5 },
		blockMouseFocus = false,
		depth = 0.59
	}))
	function header_background:update(dt, mouse_focus)
		header_background.alpha = math_util.clamp(panel.scrollPosition / 110, 0, 1)
		if panel.scrollPosition < 0 then
			header_background.y = 0
			header_background.totalH = 200 + math.abs(panel.scrollPosition)
		elseif panel.scrollPosition < 140 then
			header_background.y = -panel.scrollPosition
		end
		self:applyTransform()
		return Rectangle.update(header_background, dt, mouse_focus)
	end

	local search_font = assets:loadFont("Regular", 25)
	search_font:setFallbacks(assets:loadFont("Awesome", 25))

	local search = self:addChild("searchLabel", Label({
		x = self.tabsContrainerWidth, y = 160,
		totalW = panel.totalW,
		alignX = "center",
		text = self.searchFormat,
		font = search_font,
		alpha = 1,
		blockMouseFocus = false,
		depth = 0.6
	}))
	function search:update(dt, mouse_focus)
		if panel.scrollPosition < 140 then
			search.y = -panel.scrollPosition + 160
		end
		self:applyTransform()
		return Label.update(self, dt, mouse_focus)
	end

	self.koolRectangle = panel:addChild("koolRectangle", Rectangle({
		y = -1,
		totalW = self.panelWidth,
		totalH = 37,
		color = { 0, 0, 0, 0.5 }
	}))

	self.panel = panel
	self.sectionsStartY = 270
	self.sectionsHeight = 0

	self:addSection("General", function(section)
		section:group("SIGN IN", function(group)
			group:textBox({ label = "Username" })
			group:textBox({ label = "Password" })
			group:textBox({ label = "Ur mom" })
		end)
	end)

	panel:build()
	self:build()

	self:bindEvent(self, "textInput")
	self:bindEvent(self, "keyPressed")
end

function Options:hoverOver(y, height)
	local r = self.koolRectangle
	local rt = self.koolRectangleTween
	if rt then
		rt:stop()
	end

	if r.y == -1 then
		r.y = y
	end

	self.koolRectangleTween = flux.to(r, 0.6, { y = y, totalH = height }):ease("elasticout"):onupdate(function ()
		r:applyTransform()
	end)
end

---@param name string
---@param build_function fun(section: osu.ui.OptionsSection)
function Options:addSection(name, build_function)
	local section = self.panel:addChild(name, Section({
		y = self.sectionsHeight + self.sectionsStartY,
		options = self,
		assets = self.assets,
		name = name,
		searchText = self.search,
		buildFunction = build_function,
		depth = 0.1
	}))
	---@cast section osu.ui.OptionsSection

	if section.isEmpty then
		self:removeChild(name)
		return
	end

	self.sectionsHeight = self.sectionsHeight + section:getHeight()
end

return Options
