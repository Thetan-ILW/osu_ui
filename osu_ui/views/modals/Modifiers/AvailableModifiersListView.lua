local ListView = require("osu_ui.views.ListView")

local ui = require("osu_ui.ui")
local ModifierModel = require("sphere.models.ModifierModel")
local ModifierRegistry = require("sphere.models.ModifierModel.ModifierRegistry")

local AvailableModifierListView = ListView + {}

AvailableModifierListView.rows = 8
AvailableModifierListView.centerItems = false

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function AvailableModifierListView:new(game, assets)
	self.game = game
	self.text, self.font = assets.localization:get("modifiersModal")
	assert(self.text, self.font)
end

function AvailableModifierListView:reloadItems()
	self.items = ModifierRegistry.list
end

---@return number
function AvailableModifierListView:getItemIndex()
	return self.game.modifierSelectModel.availableModifierIndex
end

---@param count number
function AvailableModifierListView:scroll(count)
	self.game.modifierSelectModel:scrollAvailableModifier(count)
end

function AvailableModifierListView:mouseClick(w, h, i)
	local id = "Available modifier" .. i
	local changed, active, hovered = ui.button(id, ui.isOver(w, h))
	if changed then
		local modifier_select_model = self.game.modifierSelectModel
		local modifier = self.items[i]
		modifier_select_model:add(modifier)
	end
end

local gfx = love.graphics

---@param i number
---@param w number
---@param h number
function AvailableModifierListView:drawItem(i, w, h)
	local modifier_select_model = self.game.modifierSelectModel

	local item = self.items[i]
	local prev_item = self.items[i - 1]

	local id = "Available modifier" .. i
	local changed, active, hovered = ui.button(id, ui.isOver(w, h))
	self:drawItemBody(w, h, i, hovered)

	gfx.setColor(1, 1, 1, 1)

	if modifier_select_model:isOneUse(item) and modifier_select_model:isAdded(item) then
		gfx.setColor(1, 1, 1, 0.5)
	end

	local mod = ModifierModel:getModifier(item)

	gfx.setFont(self.font.modifierName)
	ui.frame(mod.name, 15, 0, w - 44, h, "left", "center")

	gfx.setColor(1, 1, 1, 1)
	if not prev_item or modifier_select_model:isOneUse(prev_item) ~= modifier_select_model:isOneUse(item) then
		local text = "One-time use modifiers"
		if not modifier_select_model:isOneUse(item) then
			text = "Sequential modifiers"
		end
		gfx.setFont(self.font.numberOfUses)
		ui.frame(text, 0, 15, w - 22, h / 4, "right", "center")
	end
end

return AvailableModifierListView
