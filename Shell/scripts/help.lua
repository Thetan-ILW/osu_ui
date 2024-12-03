local IShellScript = require("Shell.IShellScript")

local Help = IShellScript + {}

Help.command = "help"
Help.description = "Print this info"

function Help:execute()
	local str = "Available commands:\n"
	for i, v in ipairs(self.shell.scripts) do
		str = ("%s  %s - %s\n"):format(str, v.command, v.description)
	end
	self.shell:print(str)
end

return Help
