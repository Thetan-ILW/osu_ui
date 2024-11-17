---@param group osu.ui.OptionsGroup
local function login(group)
	local email_tb = group:textBox({ label = "Email" })
	local password_tb = group:textBox({ label = "Password" })
	if email_tb and password_tb then
		group:button({ label = "Sign In", color = { 0.05, 0.52, 0.65, 1 },
			onClick = function ()
				group.game.onlineModel.authManager:login(email_tb.input, password_tb.input)
			end
		})
		group:button({ label = "Create an account", color = { 0.05, 0.52, 0.65, 1 },
			onClick = function ()
				love.system.openURL("https://soundsphere.xyz/register")
			end
		})
	end
end

---@param group osu.ui.OptionsGroup
local function loggedIn(group)
	local username = group.game.configModel.configs.online.user.name
	group:label({
		totalH = 100,
		label = ("You are logged in as %s"):format(username or "?"),
		onClick = function ()
			group.game.onlineModel.authManager:logout()
		end
	} )
end

---@param section osu.ui.OptionsSection
return function(section)
	section:group("SIGN IN", function(group)
		local active = next(group.game.configModel.configs.online.session)
		if active then
			loggedIn(group)
		else
			login(group)
		end
	end)
end
