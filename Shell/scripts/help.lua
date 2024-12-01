local IShellScript = require("Shell.IShellScript")

local Help = IShellScript + {}

Help.command = "help"
Help.description = "Print this info"

---@param shell gucci.Shell
function Help:execute(shell)
	local str = "Available commands:\n"
	for i, v in ipairs(shell.scripts) do
		str = ("%s  %s - %s\n"):format(str, v.command, v.description)
	end
	return str
end

return Help
