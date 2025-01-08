local class = require("class")
local math_util = require("math_util")

---@class gucci.Shell
---@operator call: gucci.Shell
---@field scripts gucci.IShellScript
---@field process gucci.IShellScript?
local Shell = class()

Shell.scripts = {
	require("Shell.scripts.help"),
	require("Shell.scripts.spherefetch"),
	require("Shell.scripts.mod"),
	require("Shell.scripts.diag")
}

Shell.colors = {
	white = {love.math.colorFromBytes(239, 241, 245)},
	blue = {love.math.colorFromBytes(30, 102, 245)},
	red = {love.math.colorFromBytes(210, 15, 57)},
	green = {love.math.colorFromBytes(64, 160, 43)}
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

	self.buffer = {}
	self.history = {}
	self.historyIndex = 0
	self.stateCounter = 0

	self.charsWidth = 0
	self.charsHeight = 0

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

		self:appendToBuffer({ Shell.colors.white, str .. "\n" })
	end
end

---@param t table
function Shell:appendToBuffer(t)
	for _, v in ipairs(t) do
		table.insert(self.buffer, v)
	end
	self.stateCounter = self.stateCounter + 1
end

function Shell:print(text)
	self:appendToBuffer({ Shell.colors.white, text })
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
	if command == "" then
		return
	end

	if command == "clear" then
		self.buffer = {}
		self.stateCounter = self.stateCounter + 1
		return
	end

	local split = command:trim():split(" ")
	local script = self.installedScripts[split[1]]

	local input_fmt = { script and Shell.colors.green or Shell.colors.red, ("$ %s "):format(split[1]) }

	if #split > 1 then
		table.insert(input_fmt, Shell.colors.white)
		for i = 2, #split do
			table.insert(input_fmt, split[i] .. " ")
		end
	end

	input_fmt[#input_fmt] = input_fmt[#input_fmt] .. "\n"
	self:appendToBuffer(input_fmt)

	if script then
		table.insert(self.history, command)
		self.historyIndex = #self.history + 1

		script.shell = self
		local success, err = pcall(script.execute, script, split)
		if not success then
			self:appendToBuffer({ Shell.colors.red, err .. "\n"})
		end
		return
	end

	self:print(("Shell: %s: command not found.\n"):format(split[1]))
end

function Shell:update(dt)
	if self.process then
		self.process:update(dt)
	end
end

function Shell:receive(event)
	if self.process then
		self.process:receive(event)
	end
end

return Shell
