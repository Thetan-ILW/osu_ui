local class = require("class")

---@class gucci.IShellScript
local IShellScript = class()

IShellScript.command = "script"
IShellScript.description = ""

---@param shell gucci.Shell
---@param args string[]
---@return string
function IShellScript:execute(shell, args) end

return IShellScript
