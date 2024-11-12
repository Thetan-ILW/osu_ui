local CanvasContainer = require("osu_ui.ui.CanvasContainer")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

local utf8 = require("utf8")
local flux = require("flux")
local Rectangle = require("osu_ui.ui.Rectangle")
local Label = require("osu_ui.ui.Label")

---@alias OptionsParams { assets: osu.ui.OsuAssets }

---@class osu.ui.OptionsView : osu.ui.CanvasContainer
---@overload fun(params: OptionsParams): osu.ui.OptionsView
---@field assets osu.ui.OsuAssets
---@field fadeTween table?
local Options = CanvasContainer + {}

Options.panelWidth = 438
Options.tabsContrainerWidth = 64

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
	love.graphics.setScissor(0, 0, math.max(self.tabsContrainerWidth * scale, self.totalW), self.totalH)
	love.graphics.draw(self.canvas)
	love.graphics.setScissor()
end

function Options:update(dt, mouse_focus)
	self.totalW = (self.panelWidth + self.tabsContrainerWidth) * self.alpha
	return CanvasContainer.update(self, dt, mouse_focus)
end

function Options:searchUpdated()
	local text = self.search
	if self.search == "" then
		text = " Type To Search"
	end
	self.children.searchLabel:replaceText(text)
end

function Options:textInput(event)
	if self.alpha < 0.1 then
		return false
	end
	self.search = self.search .. event[1]
	self:searchUpdated()
	return true
end

local function text_split(text, index)
	local _index = utf8.offset(text, index) or 1
	return text:sub(1, _index - 1), text:sub(_index)
end

function Options:keyPressed(event)
	if self.alpha < 0.1 then
		return false
	end
	if event[2] ~= "backspace" then
		return false
	end

	local index = utf8.len(self.search) + 1
	local _
	local left, right = text_split(self.search, index)

	left, _ = text_split(left, utf8.len(left))
	index = math.max(1, index - 1)

	self.search = left .. right
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
	self.search = ""

	CanvasContainer.load(self)
	self:addTags({ "allowReload" })
	self:bindEvent(self, "textInput")
	self:bindEvent(self, "keyPressed")

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
		scrollLimit = 200,
		depth = 0.5
	}))
	---@cast panel osu.ui.ScrollAreaContainer

	panel:addChild("optionsLabel", Label({
		y = 60,
		totalW = panel.totalW,
		alignX = "center",
		text = "Options",
		font = assets:loadFont("Light", 28),
	}))

	panel:addChild("gameBehaviorLabel", Label({
		y = 100,
		totalW = panel.totalW,
		alignX = "center",
		text = "Change the way gucci!mania behaves",
		font = assets:loadFont("Light", 19),
		color = { 0.83, 0.38, 0.47, 1 },
	}))

	local header_background = self:addChild("headerBackground", Rectangle({
		x = self.tabsContrainerWidth,
		totalW = self.panelWidth,
		totalH = 200,
		color = { 0, 0, 0, 0.5 },
	}))
	function header_background:update(dt, mouse_focus)
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
		text = " Type To Search",
		font = search_font,
		depth = 0.1
	}))
	function search:update(dt, mouse_focus)
		if panel.scrollPosition < 140 then
			search.y = -panel.scrollPosition + 160
		end
		self:applyTransform()
		return Label.update(self, dt, mouse_focus)
	end

	panel:build()
	self:build()
end

return Options
