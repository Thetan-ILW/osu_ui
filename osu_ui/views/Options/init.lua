local CanvasContainer = require("osu_ui.ui.CanvasContainer")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Container = require("osu_ui.ui.Container")

local math_util = require("math_util")
local flux = require("flux")
local Rectangle = require("osu_ui.ui.Rectangle")
local Label = require("osu_ui.ui.Label")
local TextBox = require("osu_ui.ui.TextBox")

local Section = require("osu_ui.views.Options.Section")

---@alias OptionsParams { assets: osu.ui.OsuAssets, localization: Localization, game: sphere.GameController }
---@alias SectionParams { name: string, icon: love.Text, buildFunction: fun(section: osu.ui.OptionsSection) }

---@class osu.ui.OptionsView : osu.ui.CanvasContainer
---@overload fun(params: OptionsParams): osu.ui.OptionsView
---@field game sphere.GameController
---@field assets osu.ui.OsuAssets
---@field localization Localization
---@field fadeTween table?
---@field sections {[string]: SectionParams}
---@field section string[]
local Options = CanvasContainer + {}

Options.panelWidth = 438
Options.tabsContrainerWidth = 64
Options.searchFormat = { { 1, 1, 1, 1 }, " ", { 1, 1, 1, 0.65 }, ""}

Options.sections = {}
Options.sectionsOrder = {}

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
	love.graphics.setScissor(0, 0, math.max(self.tabsContrainerWidth * scale, self.totalW * scale), self.totalH * scale)
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
	local new_tree = self:buildTree()

	if #new_tree.childrenOrder == 0 then
		self.search = TextBox.removeChar(self.search)
		return
	end

	if self.panel:getChild("tree") then
		self.panel:removeChild("tree")
	end

	self.tree = new_tree
	self.panel:addChild("tree", new_tree, true)
	self.panel:build()

	local label = self.children.searchLabel
	---@cast label osu.ui.Label

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

function Options:newSection(name, icon, build_function)
	if Options.sections[name] then
		return
	end

	Options.sections[name] = {
		name = name,
		icon = self.assets:awesomeIcon(icon, 36),
		buildFunction = build_function
	}
	table.insert(Options.sectionsOrder, name)
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

	self:newSection(
		self.text.Options_General:upper(),
		"",
		require("osu_ui.views.Options.sections.general")
	)
	self:newSection(
		self.text.Options_Gameplay:upper(),
		"",
		require("osu_ui.views.Options.sections.gameplay")
	)

	CanvasContainer.load(self)
	self:addTags({ "allowReload" })
	self.hoverState.tweenDuration = 0.5
	self.hoverState.ease = "quadout"

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
		y = -9999,
		totalW = self.panelWidth,
		totalH = 37,
		color = { 0, 0, 0, 0.5 }
	}))

	self.panel = panel
	self.sectionSpacing = 0
	self.tree = self:buildTree()
	self.panel:addChild("tree", self.tree, true)
	self.panel:build()

	self:addChild("optionEvents", Container({
		bindEvents = function(this)
			this:bindEvent(self, "textInput")
			this:bindEvent(self, "keyPressed")
		end,
		depth = 0
	})) -- cuz they should be called last

	self:build()
end

function Options:hoverOver(y, height)
	local r = self.koolRectangle
	local rt = self.koolRectangleTween
	if rt then
		rt:stop()
	end

	local target = self.tree.y + y

	if r.y < 0 then
		r.y = target
		r.totalH = height
	end

	self.koolRectangleTween = flux.to(r, 0.6, { y = target, totalH = height }):ease("elasticout"):onupdate(function ()
		r:applyTransform()
	end)
end

---@return osu.ui.Container
function Options:buildTree()
	local container = self.panel:addChild("temporaryTree", Container({
		y = 270,
		totalW = self.panel.totalW,
		depth = 0.5,
	}))
	---@cast container osu.ui.Container

	local y = 0
	local depth = 1
	for i, v in ipairs(self.sectionsOrder) do
		local section_params = self.sections[v]
		local name = section_params.name
		local icon = section_params.icon
		local build = section_params.buildFunction

		local section = container:addChild(name, Section({
			totalW = self.panelWidth,
			options = self,
			assets = self.assets,
			name = name,
			icon = icon,
			buildFunction = build,
			depth = depth - i * 0.000001,
		}))
		---@cast section osu.ui.OptionsSection
		if section.isEmpty then
			container:removeChild(name)
		else
			section.y = y
			section:applyTransform()
			y = y + section:getHeight() + self.sectionSpacing
		end
	end

	container:build()
	self.panel:removeChild("temporaryTree")

	return container
end

function Options:recalcPositions()
	local height = 0

	for _, v in ipairs(self.sectionsOrder) do
		local section_params = self.sections[v]
		local name = section_params.name
		local section = self.tree:getChild(name)
		---@cast section osu.ui.OptionsSection
		if section then
			section.y = height
			section:applyTransform()
			section:recalcPositions()
			height = height + section:getHeight()
		end
	end

	self.tree.totalH = height
end

return Options
