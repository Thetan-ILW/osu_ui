local IShellScript = require("Shell.IShellScript")

local loop = require("loop")

local Diag = IShellScript + {}

Diag.command = "diag"
Diag.description = "Display FPS"

function Diag:execute()
	return ([[Performance:
  FPS:        %i
  Update:     %0.02fMS
  Draw:       %0.02fMS
  Draw calls: %i
]]):format(1 / loop.dt, loop.timings.update * 1000, loop.timings.draw * 1000, loop.stats.drawcalls)
end

return Diag
