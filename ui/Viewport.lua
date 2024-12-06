local Component = require("ui.Component")

local flux = require("flux")

---@alias ui.FrameState { deltaTime: number, mouseFocus: boolean, mouseX: number, mouseY: number }

---@class ui.Viewport : ui.Component
---@operator call: ui.Viewport
---@field targetHeight number
---@field fontManager ui.FontManager
---@field resizeListeners {[string]: ui.Component}
local Viewport = Component + {}

---@param params { targetHeight: number }
function Viewport:new(params)
	Component.new(self, params)
	self.id = self.id or "root"
	self.resizeTime = 0
	self.resizeDefered = false
	self.resizeListeners = {}
	self.innerTransform = love.math.newTransform()
	self:assert(self.targetHeight, "You should specify the target height for the viewport")
	self:assert(self.shared.fontManager, "You should provide FontManager class to the viewport.")

	self.mouseKeyDown = 0
	self.mouseTotalMovement = 0
	self.mouseLastX, self.mouseLastY = 0, 0
end

function Viewport:load()
	self.width, self.height = love.graphics.getDimensions()
	self.previousWindowSize = { w = self.width, h = self.height }
	Component.load(self)

	local screen_ratio_half = -16 / 9 / 2
	self.innerScale = 1 / self.targetHeight * self.height
	self.innerTransform:setTransformation(0.5 * self.width + screen_ratio_half * self.height, 0, 0, self.innerScale, self.innerScale)

	local x, y = self.innerTransform:inverseTransformPoint(0, 0)
	local xw, yh = self.innerTransform:inverseTransformPoint(self.width, self.height)
	self.scaledWidth, self.scaledHeight = xw - x, yh - y

	self.canvas = love.graphics.newCanvas(self.width, self.height)
	self.shared.fontManager:setVieportHeight(self.height)
end

function Viewport:getInnerScale()
	return self.innerScale
end

---@return number
function Viewport:getTextDpiScale()
	return math.ceil(self.height / self.targetHeight)
end

function Viewport:resize()
	local pw, ph = self.previousWindowSize.w, self.previousWindowSize.h
	local ww, wh = love.graphics.getDimensions()
	local time = love.timer.getTime()

	if ww ~= pw or wh ~= ph then
		self.previousWindowSize = { w = ww, h = wh }
		self.resizeTime = time + 0.2
		self.resizeDefered = true
		self.alpha = 0

		if self.alphaTween then
			self.alphaTween:stop()
		end
	end

	if self.resizeDefered and time > self.resizeTime then
		self:reload()
	end
end

function Viewport:reload()
	self.alpha = 0
	if self.alphaTween then
		self.alphaTween:stop()
	end
	self:load()

	for _, v in ipairs(self.resizeListeners) do
		if not v.killed then
			v:reload()
		end
	end

	self.resizeDefered = false
	self.alphaTween = flux.to(self, 0.4, { alpha = 1 }):ease("quadout")
end

function Viewport:softReload()
	self.alphaTween = flux.to(self, 0.2, { alpha = 0 }):ease("quadout"):oncomplete(function ()
		self:reload()
	end)
end

function Viewport:checkMouseMovement()
	local mx, my = love.mouse.getPosition()
	local nx, ny = math.abs(mx - self.mouseLastX), math.abs(my - self.mouseLastY)
	self.mouseTotalMovement = self.mouseTotalMovement + (math.sqrt(nx * nx + ny * ny))
	self.mouseLastX, self.mouseLastY = mx, my
end

---@return true
function Viewport:isParentFocused()
	return true
end

---@param dt number
function Viewport:updateTree(dt)
	self:resize()

	if self.mouseKeyDown ~= 0 then
		self:checkMouseMovement()
	end

	---@type ui.FrameState
	local frame_state = {
		mouseX = love.mouse.getX(),
		mouseY = love.mouse.getY(),
		time = love.timer.getTime(),
		deltaTime = dt,
		mouseFocus = true
	}

	love.graphics.origin()
	love.graphics.applyTransform(self.innerTransform)
	love.graphics.translate(love.graphics.inverseTransformPoint(0, 0))
	self.color[4] = self.alpha
	Component.updateTree(self, frame_state)
end

function Viewport:draw()
	love.graphics.draw(self.canvas)
end

function Viewport:drawTree()
	love.graphics.origin()
	love.graphics.applyTransform(self.innerTransform)
	love.graphics.translate(love.graphics.inverseTransformPoint(0, 0))

	love.graphics.setCanvas({ self.canvas, stencil = true })
	love.graphics.clear()
	love.graphics.setColor(1, 1, 1)
	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		love.graphics.push("all")
		child:drawTree()
		love.graphics.pop()
	end

	love.graphics.setCanvas()
	love.graphics.origin()
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(self.color)
	self:draw()
end

function Viewport:receive(event)
	if event.name == "mousepressed" then
		self.mouseKeyDown = event[3]
		self.mouseLastX, self.mouseLastY = love.mouse.getPosition()
		self.mouseTotalMovement = 0
	elseif event.name == "mousereleased" then
		if self.mouseTotalMovement < 6 and self.mouseKeyDown == event[3] then
			Component.receive(self, { name = "mouseClick", key = event[3] })
		end
		self.mouseKeyDown = 0
	elseif event.name == "wheelmoved" then
		Component.receive(self, { name = event[2] == 1 and "wheelUp" or "wheelDown" })
		return
	end

	Component.receive(self, event)
end

---@return ui.Viewport
function Viewport:getViewport()
	return self
end

---@param component ui.Component
function Viewport:listenForResize(component)
	for i, v in ipairs(self.resizeListeners) do
		if v == component then
			return
		end
	end
	table.insert(self.resizeListeners, component)
end

function Viewport:error(message)
	error(("%s :: %s"):format(self.id, message))
end

return Viewport
