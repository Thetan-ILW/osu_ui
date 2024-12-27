local Component = require("ui.Component")

local function events()
	local mouse_pressed = false

	local c = Component({
		width = 200,
		height = 200,
		mousepressed = function()
			mouse_pressed = true
		end
	})
	c:build()

	c:receive({ name = "mousepressed" })
	assert(mouse_pressed)

	local who_blocked = "no one"
	local releases_count = 0

	for i = 1, 100 do
		local child = c:addChild(tostring(i), Component({
			z = 1 - (i * 0.00001),
			textinput = function(this)
				who_blocked = this.id
				return true
			end,
			mousereleased = function ()
				releases_count = releases_count + 1
				return false
			end
		}))
		child:build()
	end
	c:build()

	c:receive({ name = "textinput" })
	assert(who_blocked == "1", who_blocked)
	c:receive({ name = "mousereleased" })
	assert(releases_count == 100, releases_count)
end

events()
