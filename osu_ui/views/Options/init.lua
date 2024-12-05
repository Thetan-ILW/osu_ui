local CanvasComponent = require("ui.CanvasComponent")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Component = require("ui.Component")
local Blur = require("ui.Blur")

local math_util = require("math_util")
local text_input = require("ui.text_input")
local flux = require("flux")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")

local Section = require("osu_ui.views.Options.Section")

---@alias OptionsParams { assets: osu.ui.OsuAssets, localization: Localization, game: sphere.GameController }
---@alias SectionParams { name: string, icon: love.Text, buildFunction: fun(section: osu.ui.OptionsSection) }

---@class osu.ui.OptionsView : ui.CanvasComponent
---@overload fun(params: OptionsParams): osu.ui.OptionsView
---@field game sphere.GameController
---@field assets osu.ui.OsuAssets
---@field localization Localization
---@field fadeTween table?
---@field sections {[string]: SectionParams}
---@field section string[]
local Options = CanvasComponent + {}

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

	if target_value > 0 then
		self.disabled = false
	end
end

function Options:toggle()
	self:fade(self.state == "closed" and 1 or 0)
end

function Options:draw()
	local scale = self.viewportScale
	love.graphics.setScissor(0, 0, math.max(0, self.width * scale), self.height * scale)
	love.graphics.draw(self.canvas)
	love.graphics.setScissor()
end

function Options:update(dt)
	self.width = (self.panelWidth + self.tabsContrainerWidth) * self.alpha
	if self.alpha == 0 then
		self.disabled = true
	end
end

function Options:searchUpdated()
	--[[local new_tree = self:buildTree()

	if #new_tree.childrenOrder == 0 then
		self.search = text_input.removeChar(self.search)
		return
	end

	if self.panel:getChild("tree") then
		self.panel:removeChild("tree")
	end

	self.tree = new_tree
	self.panel:addChild("tree", new_tree, true)
	self.panel:build()
	]]

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

function Options:newSection(name, icon, build_function)
	if Options.sections[name] then
		return
	end

	Options.sections[name] = {
		name = name,
		--icon = self.assets:awesomeIcon(icon, 36),
		buildFunction = build_function
	}
	table.insert(Options.sectionsOrder, name)
end

function Options:reload()
	self.prevScrollPosition = self:getScrollPosition()
	self:clearTree()
	self:load()
end

function Options:load()
	local width, height = self.parent:getDimensions()
	local viewport = self:getViewport()
	local fonts = self.shared.fontManager
	local assets = self.shared.assets
	local osu_cfg = self:getConfigs().osu_ui
	self.viewportScale = viewport:getInnerScale()

	viewport:listenForResize(self)

	self.width = self.panelWidth + self.tabsContrainerWidth
	self.height = height
	self.state = "closed"
	self.text = self.localization.text
	self.searchFormat[4] = self.text.SongSelection_TypeToBegin
	self.search = ""

	self.stencil = true
	self:createCanvas(self.width, self.height)

	self.hoverSound = assets:loadAudio("click-short")

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
	self:newSection(
		self.text.Options_Graphics:upper(),
		"",
		require("osu_ui.views.Options.sections.graphics")
	)
	self:newSection(
		("audio"):upper(),
		"",
		require("osu_ui.views.Options.sections.audio")
	)

	self:addChild("tabsBackground", Rectangle({
		width = self.tabsContrainerWidth,
		height = height,
		color = { 0, 0, 0, 1 },
		blockMouseFocus = true,
		z = 0.01,
	}))

	self:addChild("panelBackground", Rectangle({
		x = self.tabsContrainerWidth,
		width = self.panelWidth,
		height = height,
		color = { 0, 0, 0, 0.6 },
		blockMouseFocus = true,
		z = 0.01,
	}))

	local panel = self:addChild("panel", ScrollAreaContainer({
		x = self.tabsContrainerWidth,
		width = self.panelWidth,
		height = height,
		scrollLimit = height,
		z = 0.1,
		update = function(this)
			this.width = self.width
		end
	}))
	---@cast panel osu.ui.ScrollAreaContainer

	if self.prevScrollPosition then
		panel.scrollPosition = self.prevScrollPosition
		self.prevScrollPosition = nil
	end

	panel:addChild("optionsLabel", Label({
		y = 60,
		width = panel.width,
		alignX = "center",
		text = self.text.Options_Options,
		font = fonts:loadFont("Light", 28),
	}))

	panel:addChild("gameBehaviorLabel", Label({
		y = 100,
		width = panel.width,
		alignX = "center",
		text = self.text.Options_HeaderBlurb,
		font = fonts:loadFont("Light", 19),
		color = { 0.83, 0.38, 0.47, 1 },
	}))

	self:addChild("headerBackground", Rectangle({
		x = self.tabsContrainerWidth,
		width = self.panelWidth,
		height = 200,
		color = { 0, 0, 0, 0.5 },
		z = 0.59,
		update = function(this)
			this.alpha = math_util.clamp(panel.scrollPosition / 110, 0, 1)
			this.y = -140
			if panel.scrollPosition < 0 then
				this.y = 0
				this.height = 200 + math.abs(panel.scrollPosition)
			elseif panel.scrollPosition < 140 then
				this.y = -panel.scrollPosition
			end
		end
	}))

	local search_font = fonts:loadFont("Regular", 25)
	search_font:addFallback(fonts:loadFont("Awesome", 25).instance)

	self:addChild("searchLabel", Label({
		x = self.tabsContrainerWidth, y = 160,
		width = panel.width,
		alignX = "center",
		text = self.searchFormat,
		font = search_font,
		z = 0.6,
		update = function(this)
			this.y = 160 - panel.scrollPosition
			if panel.scrollPosition > 140 then
				this.y = 20
			end
		end
	}))

	if osu_cfg.graphics.blur then
		local next_check = 0
		self:addChild("blur", Blur({
			percent = 0.01,
			z = 0,
			update = function(this)
				if love.timer.getTime() > next_check then
					local new_percent = osu_cfg.graphics.blurQuality
					if this.percent ~= new_percent then
						this.percent = new_percent
						this:load()
						next_check = love.timer.getTime() + 0.1
					end
				end
			end
		}))
	end

	---@class osu.ui.KoolRectangle : ui.Component
	---@field hoveringOverOptions boolean
	self.koolRectangle = panel:addChild("koolRectangle", Rectangle({
		y = -9999,
		width = self.panelWidth,
		height = 37,
		color = { 0, 0, 0, 1 },
		hoveringOverOptions = false,
		update = function(this, dt)
			local add_alpha = this.hoveringOverOptions and dt * 5 or dt * -5
			this.alpha = math_util.clamp(this.alpha + add_alpha, 0, 1)
			if this.alpha == 0 then
				this.y = -9999
			end
			this.hoveringOverOptions = false
		end
	}))
	self.koolRectangleHoverTargetY = self.koolRectangle.y

	self.panel = panel
	self.sectionSpacing = 0
	self.tree = self:buildTree()

	self:addChild("searchEvents", Component({
		z = 0,
		textInput = function(this, event)
			if self.alpha < 0.1 then
				return false
			end

			self.search = self.search .. event[1]
			self:searchUpdated()
			return true
		end,
		keyPressed = function(this, event)
			if self.alpha < 0.1 then
				return false
			end
			if event[2] == "escape" then
				self:fade(0)
				return true
			end
			if event[2] ~= "backspace" then
				return false
			end

			self.search = text_input.removeChar(self.search)
			self:searchUpdated()
			return true
		end
	}))
end

function Options:getScrollPosition()
	return self.panel.scrollPosition
end

function Options:hoveringOver(y, height)
	local r = self.koolRectangle
	local target = self.tree.y + y
	r.hoveringOverOptions = true

	if target == self.koolRectangleHoverTargetY then
		return
	end

	self.koolRectangleHoverTargetY = target

	if r.y < 0 then
		r.y = target
		r.height = height
	end

	local rt = self.koolRectangleTween
	if rt then
		rt:stop()
	end

	self.playSound(self.hoverSound)
	self.koolRectangleTween = flux.to(r, 0.6, { y = target, height = height }):ease("elasticout")
end

---@return ui.Component
function Options:buildTree()
	local tree = self.panel:addChild("tree", Component({
		y = 270,
		width = self.panelWidth,
		z = 0.5,
	}))

	local y = 0
	local z = 1
	for i, v in ipairs(self.sectionsOrder) do
		local section_params = self.sections[v]
		local name = section_params.name
		local icon = section_params.icon
		local build = section_params.buildFunction

		local section = tree:addChild(name, Section({
			width = self.panelWidth,
			options = self,
			assets = self.assets,
			name = name,
			icon = icon,
			buildFunction = build,
			z = z - i * 0.000001,
		}))
		---@cast section osu.ui.OptionsSection
		if section.isEmpty then
			tree:removeChild(name)
		else
			section.y = y
			y = y + section:getHeight() + self.sectionSpacing
			tree.height = y
		end
	end

	return tree
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
			section:recalcPositions()
			height = height + section:getHeight()
		end
	end

	self.tree.height = height
end

function Options:getConfigs()
	return self.game.configModel.configs
end

function Options:reloadViewport()
	self:getViewport():softReload()
end

return Options
