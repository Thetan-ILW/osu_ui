local IScript = require("Shell.IShellScript")

local version = require("version")

local SphereFetch = IScript + {}

SphereFetch.command = "spherefetch"
SphereFetch.description = "Show game and system info"

---@param shell gucci.Shell
function SphereFetch:execute(shell)
	local ui = shell.ui

	local sys = love.system.getOS()
	local ver = version.commit:sub(1, 6)

	local pkg_manager = shell.game.packageManager
	local pkgs = 0
	for k, v in pairs(pkg_manager) do
		pkgs = pkgs + 1
	end

	if ui.gucci then
		return ([[
           @@@@             Game: gucci!mania
      @@@........@@@        Theme: osu!
    @@..............@@      OS: %s
   @..................@     Version: %s
  @......@@@@@@..@@....@    Packages: %s
 @.....@@@.......@@.....@ 
 @.....@@........@@.....@ 
 @.....@@....@@..@@.....@ 
 @.....@@@...@@.........@ 
  @.....@@@@.@@..@@....@  
   @..................@   
    @@..............@@    
      @@@........@@@      
           @@@@           
]]):format(sys, ver, pkgs)
	end

	return ([[
         ***###           Game: soundsphere
     *******#######       Theme: osu!
   *********#########     OS: %s
  **********####*#####    Version: %s
 ******####*####**#####   Packages: %s
 ***############***####=
***#############****###*
 *##############*******=
 *##############******+ 
  #############******+= 
   ###########******+   
     *######******+=    
        +++++++==       
]]):format(sys, ver, pkgs)
end

return SphereFetch
