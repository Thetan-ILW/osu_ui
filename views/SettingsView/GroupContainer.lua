local class = require("class")

local consts = require("osu_ui.views.SettingsView.Consts")
local ui = require("osu_ui.ui")

local Label = require("osu_ui.ui.Label")

---@class osu.SettingsView.GroupContainer
---@operator call: osu.SettingsView.GroupContainer
---@field assets osu.OsuAssets
---@field icon love.Image
---@field groups table<string, {name: string, height: number, elements: osu.ui.UiElement[]}>
---@field groupOrder string[]
---@field elementsHeight number
---@field position number
---@field height number
---@field hoverPosition number
---@field hoverSize number
---@field tabLabel osu.ui.Label
---@field isEmpty boolean
---@field openCombos osu.ui.Combo[]
local GroupContainer = class()

---@type table<string, love.Font>
local font

---@param name string
---@param fonts table<string, love.Font>
---@param icon love.Image
function GroupContainer:new(name, assets, fonts, icon)
	self.assets = assets
	self.icon = icon

	font = fonts
	self.groups = {}
	self.groupOrder = {}
	self.elementsHeight = 0
	self.position = 0
	self.height = 0
	self.hoverPosition = 0
	self.hoverSize = 0
	self.isEmpty = true
	self.openCombos = {}

	assert(name, "Tab name is not specified.")

	self.tabLabel = Label(assets, {
		text = name,
		pixelWidth = consts.labelWidth - 24 - 20,
		font = fonts.tabLabel,
		color = { 0.51, 0.78, 0.88, 1 },
		align = "right",
	})
end

function GroupContainer:clear()
	self.groups = {}
	self.groupOrder = {}
end

function GroupContainer:createGroup(id, name)
	self.groups[id] = {
		name = name,
		height = 0,
		elements = {},
	}

	table.insert(self.groupOrder, id)
end

function GroupContainer:removeEmptyGroups()
	---@type number[]
	local groups_to_remove = {}

	for i, id in ipairs(self.groupOrder) do
		if #self.groups[id].elements == 0 then
			table.insert(groups_to_remove, id)
		end
	end

	for i = #groups_to_remove, 1, -1 do
		local id = groups_to_remove[i]
		for j = #self.groupOrder, 1, -1 do
			if self.groupOrder[j] == id then
				table.remove(self.groupOrder, j)
				break
			end
		end
		self.groups[id] = nil
	end
end

function GroupContainer:updateHeight()
	local group_count = #self.groupOrder
	local ts = math.min(ui.getTextScale(), 1)
	local tab_label = font.tabLabel:getHeight() * ts + consts.tabLabelSpacing
	local group_labels = (font.groupLabel:getHeight() * ts + consts.groupLabelSpacing) * group_count
	local spacing = (group_count - 1) * consts.groupSpacing

	self.height = tab_label + group_labels + spacing + self.elementsHeight + consts.containerSpacing
end

---@param element osu.ui.UiElement
function GroupContainer:add(group, element)
	self.isEmpty = false
	assert(self.groups[group], "Group does not exist.")
	table.insert(self.groups[group].elements, element)

	local h = element:getHeight()
	self.elementsHeight = self.elementsHeight + h
	self.groups[group].height = self.groups[group].height + h
end

local gfx = love.graphics

---@param has_focus boolean
function GroupContainer:draw(has_focus)
	gfx.translate(consts.tabIndent, 0)

	self.hoverPosition = 0
	self.hoverSize = 0

	gfx.translate(0, consts.containerSpacing)
	self.tabLabel:update()
	self.tabLabel:draw()
	gfx.translate(0, consts.tabLabelSpacing)
	local current_position = self.tabLabel:getHeight() + consts.tabLabelSpacing + consts.containerSpacing

	self.openCombos = {}

	local focus = has_focus

	for _, id in ipairs(self.groupOrder) do
		local group = self.groups[id]

		gfx.setColor(1, 1, 1, 0.2)
		gfx.rectangle(
			"fill",
			0,
			0,
			5,
			group.height + font.groupLabel:getHeight() * ui.getTextScale() + consts.groupLabelSpacing
		)

		gfx.translate(consts.tabIndentIndent, 0)

		gfx.setColor(1, 1, 1)
		gfx.setFont(font.groupLabel)
		ui.text(group.name)

		gfx.translate(0, consts.groupLabelSpacing)
		current_position = current_position
			+ (font.groupLabel:getHeight() * ui.getTextScale())
			+ consts.groupLabelSpacing

		for _, element in ipairs(group.elements) do
			element:update(focus)

			if element.state and element.state ~= "hidden" then
				gfx.push()
				---@cast element osu.ui.Combo
				table.insert(self.openCombos, element)
				focus = not element:isFocused()
			end

			gfx.translate(-consts.tabIndentIndent, 0)
			element:drawYellowThingIfNotDefault()
			gfx.translate(consts.tabIndentIndent, 0)
			element:draw()

			if element:isMouseOver() then
				self.hoverPosition = current_position
				self.hoverSize = element:getHeight()
			end

			current_position = current_position + element:getHeight()
		end

		gfx.translate(-consts.tabIndentIndent, consts.groupSpacing)
		current_position = current_position + consts.groupSpacing
	end

	gfx.translate(-consts.tabIndent, -consts.groupSpacing)
end

return GroupContainer
