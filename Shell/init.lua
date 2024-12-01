local class = require("class")
local math_util = require("math_util")

---@class gucci.Shell
---@operator call: gucci.Shell
---@field scripts gucci.IShellScript
local Shell = class()

Shell.scripts = {
	require("Shell.scripts.help"),
	require("Shell.scripts.spherefetch"),
	require("Shell.scripts.mod"),
	require("Shell.scripts.diag")
}

---@param game sphere.GameController
---@param ui osu.ui.UserInterface
function Shell:new(game, ui)
	self.game = game
	self.ui = ui

	self.installedScripts = {}

	for i, v in ipairs(self.scripts) do
		self.installedScripts[v.command] = v
	end

	self.buffer = ""
	self.history = {}
	self.historyIndex = 0
	self.stateCounter = 0

	local base_print = print
	print = function(...)
		base_print(...)

		local str = ""
		if type(...) == "table" then
			for i, v in ipairs(...) do
				str = ("%s %s"):format(str, v)
			end
		else
			str = tostring(...)
		end

		self:appendToBuffer(str .. "\n")
	end
end

---@param str string
function Shell:appendToBuffer(str)
	self.buffer = self.buffer .. str
	self.stateCounter = self.stateCounter + 1
end

---@param delta number
---@return string
function Shell:scrollHistory(delta)
	if #self.history == 0 then
		return ""
	end

	self.historyIndex = math_util.clamp(self.historyIndex + delta, 1, #self.history)
	return self.history[self.historyIndex]
end

---@param command string
function Shell:execute(command)
	self:appendToBuffer(("$ %s\n"):format(command))
	table.insert(self.history, command)
	self.historyIndex = #self.history + 1

	if command == "" then
		return
	end

	if command == "clear" then
		self.buffer = ""
		self.stateCounter = self.stateCounter + 1
		return
	end

	local split = command:trim():split(" ")

	local script = self.installedScripts[split[1]]
	if script then
		local output = script:execute(self, split)
		self:appendToBuffer(output)
		return
	end

	return self:appendToBuffer(("Shell: %s: command not found.\n"):format(split[1]))
end

return Shell
