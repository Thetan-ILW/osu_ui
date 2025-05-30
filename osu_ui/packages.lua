local function getPlayerProfile(game, pkg_manager)
	local player_profile_pkg = pkg_manager:getPackage("player_profile")

	local player_profile

	if player_profile_pkg then
		player_profile = game.playerProfileModel
	end

	if not player_profile or (player_profile and player_profile.version ~= 1) then
		player_profile = {
			notInstalled = true,
			pp = 0,
			ssr = 0,
			liveSsr = 0,
			accuracy = 0,
			osuLevel = 0,
			osuLevelPercent = 0,
			rank = 69,
			getScore = function()
				return nil
			end,
			getDanClears = function(_self, mode)
				return "-", "-"
			end,
			isDanIsCleared = function()
				return false, false
			end,
			getActivity = function()
				return nil
			end,
			getAvailableDans = function()
				return nil
			end,
			getDanTable = function(_self, mode, type)
				return nil
			end,
			getOverallStats = function()
				return nil
			end,
			getModeStats = function()
				return nil
			end
		}
	end

	return player_profile
end

return function(game)
	local package_manager = game.packageManager

	local pkgs = {}
	pkgs.playerProfile = getPlayerProfile(game, package_manager)

	local manip_factor_pkg = package_manager:getPackage("manip_factor")
	pkgs.manipFactor = manip_factor_pkg and require("manip_factor") or nil

	local msd_calc = package_manager:getPackage("msd_calculator")
	---@type table
	pkgs.msdCalc = msd_calc and require("minacalc.lib")

	return pkgs
end
