local IShellScript = require("Shell.IShellScript")
local math_util = require("math_util")

local ModifierModel = require("sphere.models.ModifierModel")
local Registry = require("sphere.models.ModifierModel.ModifierRegistry")

local Mod = IShellScript + {}

Mod.command = "mod"
Mod.description = "Apply chart/gameplay modifiers"

---@return string
function Mod:add(mod, mod_param)
	local modifier_select_model = self.shell.game.modifierSelectModel

	if mod == "rate" then
		return self:setRate(tonumber(mod_param) or 1)
	elseif mod == "fln" then
		modifier_select_model:add("FullLongNote")
		return "Added: FullLongNote"
	elseif mod == "altk" then
		modifier_select_model:add("Alternate")
		return "Added: Alternate"
	end

	return ("Unknown mod: %s"):format(mod)
end

---@param mod? string | integer
function Mod:remove(mod)
	local modifier_select_model = self.shell.game.modifierSelectModel
	local modifiers = modifier_select_model.playContext.modifiers

	if #modifiers == 0 then
		return "Nothing to remove"
	end

	if not mod then
		modifier_select_model:remove(#modifiers)
		return "Removed last modifier"
	elseif tonumber(mod) then
		modifier_select_model:remove(tonumber(mod))
		return ("Removed modifier at index: %i"):format(tonumber(mod))
	else
		return "Not implemented"
	end
end

function Mod:printActive()
	local modifier_select_model = self.shell.game.modifierSelectModel
	local str = ""

	local mods = modifier_select_model.playContext.modifiers

	if #mods == 0 then
		return "No mods active"
	end

	for i, mod in ipairs(mods) do
		local modifier = ModifierModel:getModifier(mod.id)
		local param = ""

		if type(modifier.defaultValue) == "number" then
			param = tostring(modifier:toNormValue(mod.value))
		elseif type(modifier.defaultValue) == "string" then
			param = modifier:toIndexValue(mod.value)
		end
		str = ("%s  %i. %s %s\n"):format(str, i, Registry:getName(mod.id), param)
	end

	return str
end

---@param rate number
---@return string
function Mod:setRate(rate)
	rate = math_util.round(rate, 0.001)
	rate = math_util.clamp(rate, 0.25, 4)
	local time_rate_model = self.shell.game.timeRateModel
	time_rate_model:set(rate)
	return ("New rate: %gx"):format(rate)
end

function Mod:clear()
	local modifier_select_model = self.shell.game.modifierSelectModel
	local modifiers = modifier_select_model.playContext.modifiers

	for i = 1, #modifiers do
		self:remove(1)
	end

	self:setRate(1)
	return "Cleared"
end

function Mod:showAvailableMods()
	return [[
Available mods:
  rate     <number>         - Music speed
  fln      <number>         - FullLN
  am       <number>         - Automap
  altk                      - Alternate
  mirror   [all|left|right]
]]
end

function Mod:processArgs(args)
	local action = args[2]
	local mod = args[3]
	local mod_param = args[4]

	if action == "add" then
		return self:add(mod, mod_param)
	elseif action == "mods" then
		return self:showAvailableMods()
	elseif action == "active" then
		return self:printActive()
	elseif action == "remove" then
		return self:remove(args[3])
	elseif action == "clear" then
		return self:clear()
	else
		return "Unknown action"
	end
end

---@param shell osu.ui.Shell
---@param args string[]
function Mod:execute(shell, args)
	self.shell = shell

	if #args == 1 then
		return ([[
No arguments were provided.
Usage: mod <action> [mod] [mod_param]
  Actions: 
    add             - add chart/gameplay modifier
    remove          - remove chart/gameplay modifier
    rate            - set music speed
    clear           - remove all modifiers
    mods            - show all available mods
    active          - show all active mods

  Examples:
    mod add nln     # Add NoLongNote
    mod add fln 3   # Add FullLN 3
    mod remove fln  # Remove FullLN from the top of the stack
    mod remove 2    # Remove mod at index 2
    mod remove      # Remove any mod from the top of the stack
]])
	end

	local output = self:processArgs(args) .. "\n"
	self.shell.game.modifierSelectModel:change()
	return output
end

return Mod
