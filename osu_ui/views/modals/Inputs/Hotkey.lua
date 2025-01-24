local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")

---@class osu.ui.InputsModal.Hotkey : ui.Component
---@operator call: osu.ui.InputsModal.Hotkey
---@field column integer
---@field row integer
---@field virtualKey string
---@field key string
---@field selected fun(column: integer, row: integer)
---@field cleared fun(column: integer, row: integer)
local Hotkey = Component + {}

function Hotkey:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager

	self.blockMouseFocus = true
	self.focus = false
	self.lastHoverTime = -math.huge
	self.hoverSound = scene.assets:loadAudio("menuclick")

	self:addChild("background", Rectangle({
		x = self.width / 2,
		y = self.height / 2,
		width = self.width * 0.9,
		height = self.height * 0.65,
		rounding = 5,
		origin = { x = 0.5, y = 0.5 },
		color = { 0, 0, 0, 0.4 },
		---@param this ui.Rectangle
		update = function(this)
			if self.focus then
				this.color[1] = 1
				this.color[2] = 1
				this.color[3] = 1
				return
			end
			local d = 1 - math.min(1, love.timer.getTime() - self.lastHoverTime)
			d = d * d * d
			this.color[1] = d * 0.5
			this.color[2] = d * 0.87
			this.color[3] = d * 1
		end,
	}))

	local label = self:addChild("label", Label({
		alignX = "center",
		alignY = "center",
		boxWidth = self.width,
		boxHeight = self.height,
		font = fonts:loadFont("Regular", 20),
		text = self.key,
		z = 1,
	})) ---@cast label ui.Label
	self.label = label
end

function Hotkey:replaceText(text)
	self.label:replaceText(text)
end

function Hotkey:update()
	if self.mouseOver then
		self.lastHoverTime = love.timer.getTime()

		if love.mouse.isDown(2) then
			self.cleared(self.column, self.row)
		end
	end
end

function Hotkey:justHovered()
	self.playSound(self.hoverSound)
end

function Hotkey:mousePressed(event)
	if self.mouseOver and event[3] == 1 then
		self.selected(self.column, self.row)
		return true
	end
end


return Hotkey
