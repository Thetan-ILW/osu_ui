local IScript = require("Shell.IShellScript")

local version = require("version")

local SphereFetch = IScript + {}

SphereFetch.command = "spherefetch"
SphereFetch.description = "Show game and system info"

local gucci = [[
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
]]

local soundsphere = [[
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
]]

function SphereFetch:execute()
	local ui = self.shell.ui
	local sys = love.system.getOS()
	local ver = version.commit:sub(1, 6)

	local pkg_manager = self.shell.game.packageManager
	local pkgs = 0
	for _, _ in pairs(pkg_manager) do
		pkgs = pkgs + 1
	end

	local text = ui.gucci and gucci or soundsphere
	text = text:format(sys, ver, pkgs)
	self.shell:print(text)
end

return SphereFetch
