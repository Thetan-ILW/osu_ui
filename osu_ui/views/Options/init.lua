local CanvasComponent = require("ui.CanvasComponent")
local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")
local Component = require("ui.Component")
local Blur = require("ui.Blur")

local math_util = require("math_util")
local text_input = require("ui.text_input")
local flux = require("flux")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local BackButton = require("osu_ui.ui.BackButton")

local Section = require("osu_ui.views.Options.Section")

---@alias OptionsParams { assets: osu.ui.OsuAssets, localization: Localization, game: sphere.GameController }
---@alias SectionParams { name: string, icon: ui.Label, buildFunction: fun(section: osu.ui.OptionsSection) }

---@class osu.ui.OptionsView : ui.CanvasComponent
---@overload fun(params: OptionsParams): osu.ui.OptionsView
---@field game sphere.GameController
---@field ui osu.ui.UserInterface
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

	self.panel:loseFocus()

	if target_value > 0 then
		self.alpha = 0.01
		self.disabled = false
		self.handleEvents = true
	elseif target_value == 0 then
		self.handleEvents = false
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
	local new_tree = self:buildTree()
	new_tree:build()

	if #new_tree.childrenOrder == 0 then
		self.search = text_input.removeChar(self.search)
		self.panel:removeChild("newTree")
		return
	end

	self.panel:scrollToPosition(0, 0)
	self.koolRectangleHoverTargetY = -1000
	self.koolRectangle.alpha = 0
	self.panel:removeChild("tree")
	self.panel:renameChild("newTree", "tree")
	self.tree = new_tree
	self:recalcPositions()
	self:addTabs()

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

function Options:newSection(id, name, icon, build_function)
	if Options.sections[id] then
		return
	end

	Options.sections[id] = {
		name = name,
		icon = icon,
		buildFunction = build_function
	}
	table.insert(Options.sectionsOrder, id)
end

---@return { scrollPosition: number, wasOpen: boolean }
function Options:getState()
	return {
		scrollPosition = self.panel.scrollPosition,
		wasOpen = self.alpha == 1
	}
end

---@param state { scrollPosition: number, wasOpen: boolean }
function Options:setState(state)
	if state.wasOpen then
		self.panel.scrollPosition = state.scrollPosition
		self.alpha = 1
		self.disabled = false
		self.handleEvents = true
	end
end

function Options:reload()
	self:clearTree()
	self:load()
end

function Options:event_onlineReady()
	self:reload()
end

function Options:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.game = scene.game

	local width, height = self.parent:getDimensions()
	local viewport = self:getViewport()
	local fonts = scene.fontManager
	local assets = scene.assets
	local osu_cfg = self:getConfigs().osu_ui
	self.viewportScale = viewport:getInnerScale()
	self.assets = assets

	viewport:listenForResize(self)
	viewport:listenForEvent(self, "event_onlineReady")

	self.width = self.panelWidth + self.tabsContrainerWidth
	self.height = height
	self.state = "closed"
	self.text = self.localization.text
	self.searchFormat[4] = self.text.SongSelection_TypeToBegin
	self.search = ""

	self.stencil = true
	self:createCanvas(self.width, self.height)

	self.hoverSound = assets:loadAudio("click-short")
	self.fontAwesome = fonts:loadFont("Awesome", 24)

	self:newSection(
		"general",
		self.text.Options_TabGeneral:upper(),
		"",
		require("osu_ui.views.Options.sections.general")
	)
	self:newSection(
		"graphics",
		self.text.Options_TabGraphics:upper(),
		"",
		require("osu_ui.views.Options.sections.graphics")
	)
	self:newSection(
		"gameplay",
		self.text.Options_TabGameplay:upper(),
		"",
		require("osu_ui.views.Options.sections.gameplay")
	)
	self:newSection(
		"audio",
		self.text.Options_TabAudio:upper(),
		"",
		require("osu_ui.views.Options.sections.audio")
	)
	self:newSection(
		"skin",
		self.text.Options_TabSkin:upper(),
		"",
		require("osu_ui.views.Options.sections.skin")
	)
	self:newSection(
		"input",
		self.text.Options_TabInput:upper(),
		"",
		require("osu_ui.views.Options.sections.input")
	)
	self:newSection(
		"online",
		self.text.Options_TabOnline:upper(),
		"",
		require("osu_ui.views.Options.sections.online")
	)
	self:newSection(
		"maintenance",
		self.text.Options_TabMaintenance:upper(),
		"",
		require("osu_ui.views.Options.sections.maintenance")
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
		scrollLimit = 0,
		z = 0.1,
		update = function(this)
			this.width = self.width
		end
	}))
	---@cast panel osu.ui.ScrollAreaContainer

	panel:addChild("optionsLabel", Label({
		y = 60,
		boxWidth = panel.width,
		alignX = "center",
		text = self.text.Options_Options,
		font = fonts:loadFont("Light", 28),
	}))

	panel:addChild("gameBehaviorLabel", Label({
		y = 100,
		boxWidth = panel.width,
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
		boxWidth = panel.width,
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
			local add_alpha = self.mouseOver and dt * 5 or dt * -5
			this.alpha = math_util.clamp(this.alpha + add_alpha, 0, 1)
			if this.alpha == 0 then
				this.y = -9999
			end
			this.hoveringOverOptions = false
		end
	}))
	self.koolRectangleHoverTargetY = self.koolRectangle.y

	self:addChild("backButton", BackButton({
		y = height - 58,
		font = fonts:loadFont("Regular", 20),
		text = "back",
		hoverWidth = 93,
		hoverHeight = 58,
		onClick = function ()
			self:fade(0)
		end,
		z = 0.9,
	}))

	self.tabButtons = self:addChild("tabButtonsContainer", Component({
		y = height / 2,
		origin = { y = 0.5 },
		z = 0.1,
	}))

	self.panel = panel
	self.sectionSpacing = 0
	self.tree = self:buildTree()
	self.panel:renameChild("newTree", "tree")
	self:recalcPositions()
	self:addTabs()
	panel.scrollLimit = self.tree:getHeight()

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

function Options:addTabs()
	self.tabButtons:clearTree()

	local hover_sound = self.assets:loadAudio("click-short")
	local click_sound = self.assets:loadAudio("click-short-confirm")

	local added = 0
	for i, v in ipairs(self.sectionsOrder) do
		local section = self.tree:getChild(v)

		if section then
			self.tabButtons:addChild(v, Label({
				y = added * 64,
				boxWidth = 64,
				boxHeight = 64,
				text = self.sections[v].icon,
				font = self.fontAwesome,
				alignX = "center",
				alignY = "center",
				alpha = 0.6,
				update = function(this, dt)
					local scroll_position = math_util.clamp(self.panel.scrollPosition, 0, self.tree:getHeight() - 20)
					local y = section.y - 20
					local h = section:getHeight()

					if scroll_position >= y and scroll_position <= y + h then
						this.alpha = math.min(1, this.alpha + dt * 5)
					else
						this.alpha = math.max(0.6, this.alpha - dt * 5)
					end

					this.alpha = math.min(1, this.alpha + (this.mouseOver and 1 or 0))
				end,
				mousePressed = function(this)
					if this.mouseOver then
						self.panel:scrollToPosition(section.y, 0)
						self.playSound(click_sound)
						return true
					end
				end,
				justHovered = function()
					self.playSound(hover_sound)
				end
			}))
			self.tabButtons:addChild(i .. "rect", Rectangle({
				x = self.tabsContrainerWidth,
				y = added * 64,
				width = 6,
				height = 64,
				origin = { x = 1 },
				color = { 0.92, 0.46, 0.55, 1 },
				alpha = 0,
				update = function(this, dt)
					local scroll_position = math_util.clamp(self.panel.scrollPosition, 0, self.tree:getHeight() - 20)
					local y = section.y - 20
					local h = section:getHeight()
					if scroll_position >= y and scroll_position <= y + h then
						this.alpha = math.min(1, this.alpha + dt * 5)
					else
						this.alpha = math.max(0, this.alpha - dt * 5)
					end
				end
			}))
			added = added + 1
		end
	end

	self.tabButtons:autoSize()
end


---@param height number
function Options:addAdditionalScrollLimit(height)
	self.panel.scrollLimit = self.tree:getHeight() + height
end

function Options:getScrollPosition()
	return self.panel.scrollPosition
end

function Options:hoveringOver(y, height)
	local r = self.koolRectangle
	local target = self.tree.y + y

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
	self.panel:removeChild("newTree")
	local tree = self.panel:addChild("newTree", Component({
		y = 270,
		width = self.panelWidth,
		z = 0.5,
	}))

	local z = 1
	for i, v in ipairs(self.sectionsOrder) do
		local section_params = self.sections[v]
		local name = section_params.name
		local build = section_params.buildFunction

		local section = tree:addChild(v, Section({
			width = self.panelWidth,
			options = self,
			assets = self.assets,
			name = name,
			buildFunction = build,
			z = z - i * 0.000001,
		}))
		---@cast section osu.ui.OptionsSection
		if section.isEmpty then
			tree:removeChild(v)
		end
	end

	return tree
end

function Options:recalcPositions()
	local height = 0

	for _, v in ipairs(self.sectionsOrder) do
		local section_params = self.sections[v]
		local section = self.tree:getChild(v)
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
