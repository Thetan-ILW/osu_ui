local class = require("class")

---@alias ui.ComponentEvent "mousePressed" | "mouseReleased" | "keyPressed" | "keyReleased" | "wheelUp" | "wheelDown" | "textInput" | "mouseClick" | "viewportResized"

---@class ui.EventHandler
local EventHandler = class()

function EventHandler.wheelmoved(component, event)
	if event[2] == 1 then
		return component:callbackFirstChild("wheelUp", event)
	else
		return component:callbackFirstChild("wheelDown", event)
	end
end

function EventHandler.mousepressed(component, event)
	return component:callbackFirstChild("mousePressed", event)
end

function EventHandler.mousereleased(component, event)
	return component:callbackForEachChild("mouseReleased", event)
end

function EventHandler.keypressed(component, event)
	return component:callbackFirstChild("keyPressed", event)
end

function EventHandler.keyreleased(component, event)
	return component:callbackForEachChild("keyReleased", event)
end

function EventHandler.textinput(component, event)
	return component:callbackFirstChild("textInput", event)
end

function EventHandler.mouseClick(component, event)
	return component:callbackFirstChild("mouseClick", event)
end

function EventHandler.viewportResized(component, event)
	return component:callbackForEachChild("viewportResized", event)
end

return EventHandler
