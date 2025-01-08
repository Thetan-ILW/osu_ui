local class = require("class")

---@class gucci.IShellScript
---@operator call: gucci.IShellScript
---@field shell gucci.Shell
local IShellScript = class()

IShellScript.command = "script"
IShellScript.description = ""

---@param shell gucci.Shell
---@param args string[]
function IShellScript:execute(shell, args) end

function IShellScript:update(dt) end
function IShellScript:receive(event) end

return IShellScript
