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

local function getMinaCalc(pkg_manager)
	local minacalc_pkg = pkg_manager:getPackage("msd_calculator")
	local etterna_msd = minacalc_pkg and require("minacalc.etterna_msd") or {
		getMsdFromData = function()
			return nil
		end,
		simplifySsr = function()
			return "minacalc not installed"
		end
	}

	return etterna_msd
end

return function(game)
	local package_manager = game.packageManager

	local pkgs = {}
	pkgs.playerProfile = getPlayerProfile(game, package_manager)
	--pkgs.minacalc = getMinaCalc(package_manager)

	local manip_factor_pkg = package_manager:getPackage("manip_factor")
	pkgs.manipFactor = manip_factor_pkg and require("manip_factor") or nil

	local gucci = package_manager:getPackage("gucci")
	pkgs.gucci = gucci and require("gucci_init") or nil

	return pkgs
end
