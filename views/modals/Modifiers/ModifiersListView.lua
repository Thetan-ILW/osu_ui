local ListView = require("osu_ui.views.ListView")
local ui = require("osu_ui.ui")
local just = require("just")

local SliderView = require("sphere.views.SliderView")
local StepperView = require("sphere.views.StepperView")
local ModifierModel = require("sphere.models.ModifierModel")
local ModifierRegistry = require("sphere.models.ModifierModel.ModifierRegistry")

local ModifierListView = ListView + {}

ModifierListView.rows = 8
ModifierListView.centerItems = true

---@param game sphere.GameController
---@param assets osu.ui.OsuAssets
function ModifierListView:new(game, assets)
	ListView:new(game)
	self.game = game
	self.text, self.font = assets.localization:get("modifiersModal")
	assert(self.text, self.font)
end

function ModifierListView:reloadItems()
	self.items = self.game.playContext.modifiers
end

---@return number
function ModifierListView:getItemIndex()
	return self.game.modifierSelectModel.modifierIndex
end

---@param count number
function ModifierListView:scroll(count)
	self.game.modifierSelectModel:scrollModifier(count)
end

local gfx = love.graphics

local slider_w = 150
local stepper_w = 80

---@param i number
---@param w number
---@param h number
function ModifierListView:drawItem(i, w, h)
	local modifier_select_model = self.game.modifierSelectModel

	local item = self.items[i]

	local changed, active, hovered = ui.button(tostring(item) .. "1", ui.isOver(w, h), 2)
	if changed then
		modifier_select_model:remove(i)
	end

	self:drawItemBody(w, h, i, hovered)

	gfx.setFont(self.font.modifierName)
	gfx.setColor(1, 1, 1, 1)

	gfx.translate(15, 0)
	ui.frame(ModifierRegistry:getName(item.id) or "NONE", 0, 0, math.huge, h, "left", "center")

	local modifier = ModifierModel:getModifier(item.id)
	if not modifier then
		ui.frame("DELETED MODIFIER", 0, 0, math.huge, h, "left", "top")
	elseif modifier.defaultValue == nil then
	elseif type(modifier.defaultValue) == "number" then
		ui.frame(item.value, 0, 0, 220, h, "right", "center")
		gfx.translate(225, 0)

		local value = modifier:toNormValue(item.value)

		local over = SliderView:isOver(slider_w, h)
		local pos = SliderView:getPosition(slider_w, h)

		local delta = ui.wheelOver(item, over)
		local new_value = just.slider(item, over, pos, value)
		if new_value then
			ModifierModel:setModifierValue(item, modifier:fromNormValue(new_value))
			modifier_select_model:change()
		elseif delta then
			ModifierModel:increaseModifierValue(item, delta)
			modifier_select_model:change()
		end
		SliderView:draw(slider_w, h, value)
	elseif type(modifier.defaultValue) == "string" then
		ui.frame(item.value, 0, 0, 220, h, "right", "center")
		gfx.translate(225, 0)

		local value = modifier:toIndexValue(item.value)
		local count = modifier:getCount()

		local overAll, overLeft, overRight = StepperView:isOver(stepper_w, h)

		local id = tostring(item)
		local delta = ui.wheelOver(id .. "A", overAll)
		local changedLeft = ui.button(id .. "L", overLeft)
		local changedRight = ui.button(id .. "R", overRight)

		if changedLeft or delta == -1 then
			ModifierModel:increaseModifierValue(item, -1)
			modifier_select_model:change()
		elseif changedRight or delta == 1 then
			ModifierModel:increaseModifierValue(item, 1)
			modifier_select_model:change()
		end
		StepperView:draw(stepper_w, h, value, count)
	end
end

return ModifierListView
