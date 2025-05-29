local Component = require("ui.Component")
local Image = require("ui.Image")

local flux = require("flux")

---@class osu.ui.ResultView.Grade : ui.Component
---@operator call: osu.ui.ResultView.Grade
---@field grade string
local Grade = Component + {}

local grades = {
	"X",
	"S",
	"A",
	"B",
	"C",
	"D",
	"-"
}

function Grade:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local assets = scene.assets

	---@type table<string, ui.Image>
	self.images = {}

	---@type table<ui.Image, table>
	self.tweens = {}

	for i, v in ipairs(grades) do
		self.images[v] = self:addChild(v, Image({
			image = assets:loadImage(("ranking-%s"):format(v)),
			origin = { x = 0.5, y = 0.5 },
			alpha = 0,
			disabled = true,
			z = 1 - (i * 0.00001)
		}))
	end

	local img = self.images[self.grade]

	if not img then
		return
	end

	img.disabled = false
	img.alpha = 1
end

function Grade:switchTo(grade)
	if grade == self.grade then
		return
	end

	local prev = self.images[self.grade]
	local next = self.images[grade]
	next.disabled = false
	if self.tweens[prev] then
		self.tweens[prev]:stop()
	end
	if self.tweens[next] then
		self.tweens[next]:stop()
	end
	self.tweens[prev] = flux.to(prev, 0.4, { alpha = 0 }):ease("cubicout"):oncomplete(function ()
		prev.disabled = true
	end)
	self.tweens[next] = flux.to(next, 0.4, { alpha = 1 }):ease("cubicout")
	self.grade = grade
end

return Grade
