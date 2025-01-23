local Component = require("ui.Component")

---@class osu.ui.Spectrum : ui.Component
---@operator call: osu.ui.Spectrum
---@field emptyFft number[]
---@field smoothedFft number[]
---@field audio audio.Source?
local Spectrum = Component + {}

local radius = 253

function Spectrum:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local img = scene.assets:loadImage("menu-vis")

	self.spriteBatch = love.graphics.newSpriteBatch(img)
	self.color = scene.assets.params.menuGlow

	self.velocityAdjustment = 1
	self.musicFft = scene.musicFft
	self.angles = {} ---@type number[]
	self.angularDirX = {} ---@type number[]
	self.angularDirY = {} ---@type number[]

	self.vectorScaleX = {} ---@type number[]
	self.rotation = 0

	local width = 1
	local overshoot = 8
	local sample_size = self.musicFft.sampleSize

	for i = 0, sample_size - 1 do
		local angle = (math.pi * 2) * (0.4 + (i / sample_size * (overshoot * width)))
		table.insert(self.angles, angle)
		table.insert(self.angularDirX, math.cos(angle))
		table.insert(self.angularDirY, math.sin(angle))
		table.insert(self.vectorScaleX, 0)
		self.spriteBatch:add(0, 0)
	end
end

local sixty_frame_time = 1 / 60
local max_alpha = 0.4
local cutoff = 0.1
local max_velocity = 4

function Spectrum:update(dt)
	local data = self.musicFft.data

	self.velocityAdjustment = self.velocityAdjustment * 0.97 + 0.03 * math.max(0,  1 - math.max(0, (math.pow(dt / sixty_frame_time, 4) - 1)))

	local frame_ratio = dt / sixty_frame_time
	local decay_factor = math.pow(self.musicFft.decay, frame_ratio)
	local sample_size = self.musicFft.sampleSize

	for i = 1, sample_size do
		local new_value = data[i - 1] * self.velocityAdjustment * max_velocity
		---@cast new_value number

		if new_value <= self.vectorScaleX[i] then
			new_value = self.vectorScaleX[i] * decay_factor
		elseif new_value < self.musicFft.decayCutoff then
			new_value = 0
		end

		self.vectorScaleX[i] = new_value

		local alpha = math.max(0, max_alpha * math.min(1, (self.vectorScaleX[i] - cutoff) / (cutoff * 2)))
		self.spriteBatch:setColor(1, 1, 1, alpha)
		self.spriteBatch:set(i,
			self.angularDirX[i] * radius,
			self.angularDirY[i] * radius,
			self.angles[i],
			self.vectorScaleX[i],
			1
		)
	end
end

function Spectrum:draw()
	love.graphics.setBlendMode("add")
	love.graphics.draw(self.spriteBatch)
	love.graphics.setBlendMode("alpha")
end

return Spectrum
