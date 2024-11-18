local wait_for_login = false
local wait_for_logout = false

---@param group osu.ui.OptionsGroup
local function login(group)
	local email_tb = group:textBox({ label = "Email" })
	local password_tb = group:textBox({ label = "Password", password = true })
	if email_tb and password_tb then
		group:button({ label = "Sign In", color = { 0.05, 0.52, 0.65, 1 },
			onClick = function ()
				group.game.onlineModel.authManager:login(email_tb.input, password_tb.input)
				wait_for_login = true
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
			wait_for_logout = true
		end
	} )
end

---@param section osu.ui.OptionsSection
return function(section)
	section:group("SIGN IN", function(group)
		local active = next(group.game.configModel.configs.online.session)

		local base_update = group.update
		function group:update(dt, mouse_focus)
			if wait_for_login then
				local logged_in = next(group.game.configModel.configs.online.session)
				if logged_in then
					local username = group.game.configModel.configs.online.user.name
					if username then
						wait_for_login = false
						group:load()
						section.options:recalcPositions()
					end
				end
			end
			if wait_for_logout then
				local logged_in = next(group.game.configModel.configs.online.session)
				if not logged_in then
					wait_for_logout = false
					group:load()
					section.options:recalcPositions()
				end
			end
			return base_update(group, dt, mouse_focus)
		end

		if active then
			loggedIn(group)
		else
			login(group)
		end

		local boolean = { "true", "false", "nil", "not sure", "no", "maybe", "in between", "not true", "not false" }
		local value = boolean[1]
		group:combo({
			label = "Booleans",
			items = boolean,
			getValue = function ()
				return value
			end,
			onChange = function(index)
				value = boolean[index]
			end,
			format = function(v)
				return v:upper()
			end
		})
	end)

	section:group("UPDATES", function(group)
		group:textBox({ label = "hallo" })
	end)
end
