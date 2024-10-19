local class = require("class")
local ui = require("osu_ui.ui")
local actions = require("osu_ui.actions")
local flux = require("flux")
local math_util = require("math_util")

local ViewConfig = require("osu_ui.views.SettingsView.ViewConfig")
local Label = require("osu_ui.ui.Label")
local Spacing = require("osu_ui.ui.Spacing")
local BackButton = require("osu_ui.ui.BackButton")
local SkinPreview = require("osu_ui.ui.SkinPreview")
local consts = require("osu_ui.views.SettingsView.Consts")

local Elements = require("osu_ui.views.SettingsView.Elements")
local general = require("osu_ui.views.SettingsView.general")
local graphics = require("osu_ui.views.SettingsView.graphics")
local gameplay = require("osu_ui.views.SettingsView.gameplay")
local audio = require("osu_ui.views.SettingsView.audio")
local skin = require("osu_ui.views.SettingsView.skin")
local input = require("osu_ui.views.SettingsView.input")
local maintenance = require("osu_ui.views.SettingsView.maintenance")

local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.SettingsView
---@operator call: osu.ui.SettingsView
---@field assets osu.ui.OsuAssets
---@field game sphere.GameController
---@field state "hidden" | "fade_in" | "visible" | "fade_out"
---@field visibility number
---@field visibilityTween table?
---@field scrollPosition number
---@field scrollTargetPosition number
---@field scrollTween table?
---@field hoverTime number
---@field hoverPosition number
---@field hoverSize number
---@field containers osu.SettingsView.GroupContainer[]
---@field totalHeight number
---@field topSpacing osu.ui.Spacing
---@field headerSpacing osu.ui.Spacing
---@field bottomSpacing osu.ui.Spacing
---@field optionsLabel osu.ui.Label
---@field gameBehaviorLabel osu.ui.Label
---@field searchLabel osu.ui.Label
---@field searchText string
---@field osuSkins string[]
---@field modalActive boolean
---@field backButton osu.ui.BackButton
---@field skinPreview osu.ui.SkinPreview
local SettingsView = class()

---@type table<string, string>
local text
---@type table<string, love.Font>
local font

---@param assets osu.ui.OsuAssets
---@param game sphere.GameController
---@param game_ui osu.ui.UserInterface
function SettingsView:new(assets, game, game_ui)
	self.assets = assets
	self.game = game
	self.ui = game_ui
	self.viewConfig = ViewConfig(self, assets)
	self.visibility = 0
	self.state = "hidden"
	self.scrollPosition = 0
	self.scrollTargetPosition = 0
	self.containers = {}
	self.totalHeight = 0
	self.searchText = ""
	self.hoverTime = 0
	self.modalActive = true

	local asset_model = game_ui.assetModel
	self.osuSkins = asset_model:getOsuSkins()
	self.skinPreview = SkinPreview(assets, consts.settingsWidth - consts.tabIndentIndent - consts.tabIndent)

	local input_mode = tostring(game.selectController.state.inputMode)

	if input_mode ~= "" then
		local selected_note_skin = game.noteSkinModel:getNoteSkin(input_mode)

		if selected_note_skin then
			local skin_preview_img = asset_model:loadSkinPreview(selected_note_skin.directoryPath)
			self.skinPreview:setImage(skin_preview_img)
		end
	end

	text, font = assets.localization:get("settings")
	assert(font)

	self:build()
end

---@param tab string?
function SettingsView:build(tab)
	ui.setTextScale(math.min(768 / love.graphics.getHeight(), 1))
	local prev_containers = self.containers or {}
	self.topSpacing = Spacing(64)
	self.headerSpacing = Spacing(100)
	self.bottomSpacing = Spacing(256)

	self.optionsLabel = Label(self.assets, {
		text = "Options",
		pixelWidth = consts.labelWidth,
		font = font.optionsLabel,
	})

	self.gameBehaviorLabel = Label(self.assets, {
		text = "Change the way gucci!mania behaves",
		pixelWidth = consts.labelWidth,
		font = font.gameBehaviorLabel,
		color = { 0.83, 0.38, 0.47, 1 },
	})

	local assets = self.assets

	Elements.searchText = self.searchText

	if not tab then
		self.containers = {}
		table.insert(self.containers, general(assets, self))
		table.insert(self.containers, graphics(assets, self))
		table.insert(self.containers, gameplay(assets, self))
		table.insert(self.containers, audio(assets, self))
		table.insert(self.containers, skin(assets, self, self.skinPreview))
		table.insert(self.containers, input(assets, self, self.ui))
		table.insert(self.containers, maintenance(assets, self))
	else
		if tab == "gameplay" then
			table.remove(self.containers, 3)
			table.insert(self.containers, 3, gameplay(assets, self))
		elseif tab == "graphics" then
			table.remove(self.containers, 2)
			table.insert(self.containers, 2, graphics(assets, self))
		else
			error("you forgor")
		end
	end

	if #self.containers == 0 then
		self.containers = prev_containers
		self.searchText = actions.textRemoveLast(self.searchText)
	end

	local search = self.searchText == "" and "Type to search!" or self.searchText

	self.searchLabel = Label(self.assets, {
		text = search,
		pixelWidth = consts.labelWidth,
		pixelHeight = 100,
		font = font.search,
	})

	------------- Setting positions and heights
	local pos = self.optionsLabel:getHeight()
	pos = pos + self.gameBehaviorLabel:getHeight()
	pos = pos + self.topSpacing:getHeight()
	pos = pos + self.headerSpacing:getHeight()

	for _, c in ipairs(self.containers) do
		c:updateHeight()
		c.position = pos
		pos = pos + c.height
	end

	------------- Scroll limit
	pos = self.optionsLabel:getHeight()
	pos = pos + self.gameBehaviorLabel:getHeight()
	pos = pos + self.topSpacing:getHeight()
	pos = pos + self.headerSpacing:getHeight()
	pos = pos + self.bottomSpacing:getHeight()

	for _, c in ipairs(self.containers) do
		pos = pos + c.height
	end

	self.totalHeight = pos

	self.backButton = BackButton(assets, { w = 64, h = 200 }, function()
		self:processState("hide")
	end)
end

---@private
function SettingsView:open()
	if self.visibilityTween then
		self.visibilityTween:stop()
	end
	self.visibilityTween = flux.to(self, 0.5, { visibility = 1 }):ease("quadout")
	self.state = "fade_in"
end

---@private
function SettingsView:close()
	if self.visibilityTween then
		self.visibilityTween:stop()
	end
	self.visibilityTween = flux.to(self, 0.5, { visibility = 0 }):ease("quadout")
	self.state = "fade_out"

	for i, v in ipairs(self.viewConfig.openCombos) do
		v:close()
	end
end

---@param event? "toggle" | "hide"
function SettingsView:processState(event)
	local state = self.state
	local toggle = event == "toggle"

	if state == "hidden" then
		if toggle then
			self:open()
		end
	elseif state == "fade_in" then
		if self.visibility == 1 then
			self.state = "visible"
			return
		end
		if toggle or event == "hide" then
			self:close()
		end
	elseif state == "fade_out" then
		if self.visibility == 0 then
			self.state = "hidden"
			return
		end
		if toggle then
			self:open()
		end
	elseif state == "visible" then
		if toggle or event == "hide" then
			self:close()
		end
	end
end

function SettingsView:isFocused()
	if self.state == "hidden" then
		return false
	end

	return self.viewConfig.focus
end

function SettingsView:update(dt)
	self:processState()
	self.modalActive = self.ui.gameView.view.modal ~= nil
	self.viewConfig.modalActive = self.modalActive

	local additional_pos = 0

	for i, c in ipairs(self.containers) do
		if c.hoverPosition ~= 0 then
			self.hoverTime = love.timer.getTime()
			self.hoverPosition = c.hoverPosition + additional_pos
			self.hoverSize = c.hoverSize
		end

		additional_pos = additional_pos + c.height
	end

	Layout:move("base")
	if self.state == "hidden" or not ui.isOver(438 + 64, 768) or self.modalActive then
		return
	end

	if actions.isInsertMode() or not actions.isVimMode() then
		local changed = false
		local prev = self.searchText
		changed, self.searchText = actions.textInput(self.searchText)

		if changed and prev ~= self.searchText then
			self.scrollPosition = 0
			self.scrollTargetPosition = 0
			self:build()
		end
	end
end

---@param container_index integer
function SettingsView:jumpTo(container_index)
	self.scrollTargetPosition = self.containers[container_index].position

	if self.scrollTween then
		self.scrollTween:stop()
	end

	self.scrollTween = flux.to(self, 0.4, { scrollPosition = -self.scrollTargetPosition + 64 }):ease("cubicout")
end

function SettingsView:resolutionUpdated()
	self:build()
end

---@param event table
function SettingsView:receive(event)
	if event.name == "wheelmoved" and self.state ~= "hidden" and self.viewConfig.focus then
		local total_height = #self.viewConfig.openCombos and math.huge or self.totalHeight
		---@type number
		local delta = -event[2]
		local max = math_util.clamp(total_height - 768, 0, total_height - 768)
		self.scrollTargetPosition = math_util.clamp(self.scrollTargetPosition + (delta * 90), 0, max)

		if self.scrollTween then
			self.scrollTween:stop()
		end

		self.scrollTween = flux.to(self, 0.2, { scrollPosition = -self.scrollTargetPosition }):ease("quadout")
	end
end

function SettingsView:draw()
	if self.state == "hidden" then
		return
	end

	self.viewConfig:draw(self)
end

return SettingsView
