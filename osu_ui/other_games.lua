local path_util = require("path_util")
local string_util = require("string_util")

local other_games = {}
other_games.games = {}
other_games.gamesFound = 0

---@return table?
function other_games:readOsuConfig()
	local winapi = require("winapi")
	local osu_path = self.games["osu!"]
	local user = winapi.getenv("username")
	local config_path = path_util.join(osu_path, ("osu!.%s.cfg"):format(user))
	local osu_config = winapi.open(config_path, "r")

	if osu_config == nil then
		return
	end

	---@type string?
	local line = osu_config:read()
	---@type {[string]: any}
	local c = {}

	while(line) do
		if line:sub(1, 1) ~= "#" then
			local kv_split = string_util.split(line, "=")
			if #kv_split == 2 then
				local k = kv_split[1]:sub(1, -2)
				local v = kv_split[2]:sub(2)
				c[k] = v
			end
		end

		line = osu_config:read()
	end

	return {
		volume = {
			master = (c.VolumeUniversal or 100) / 100,
			music = (c.VolumeMusic or 80) / 100,
			effect = (c.VolumeEffect or 80) / 100,
		},
		osu = {
			cursorSize = c.CursorSize or 1,
		},
		gameplay = {
			dim = (c.DimLevel or 80) / 100,
			scrollSpeed = c.ManiaSpeed or 12,
			skin = c.Skin or "Default"
		},
	}
end

function other_games:findOtherGames()
	local winapi = require("winapi")
	---@type table<string, string>
	self.games = {}

	local osu_reg_path = winapi.get_reg_value_sz(
		winapi.hkey.HKEY_CLASSES_ROOT,
		"osustable.File.osz\\shell\\open\\command"
	)

	if osu_reg_path then
		local split = string_util.split(osu_reg_path, '"')
		if #split > 1 then
			self.games["osu!"] = split[2]:gsub("osu!.exe", ""):gsub("\\", "/")
		end
	end

	local etterna_reg_path = winapi.get_reg_value_sz(
		winapi.hkey.HKEY_LOCAL_MACHINE,
		"SOFTWARE\\WOW6432Node\\Etterna Team\\Etterna"
	)

	if etterna_reg_path then
		self.games["Etterna"] = etterna_reg_path
	end

	local quaver_reg_path = winapi.get_reg_value_sz(
		winapi.hkey.HKEY_CURRENT_USER,
		"SOFTWARE\\Classes\\quaver\\shell\\open\\command"
	)

	if quaver_reg_path then
		local split = string_util.split(quaver_reg_path, '"')
		if #split > 1 then
			self.games["Quaver"] = split[2]:gsub("Quaver.exe", ""):gsub("\\", "/")
		end
	end

	for _, _ in pairs(self.games) do
		self.gamesFound = self.gamesFound + 1
	end
end

return other_games
