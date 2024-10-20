local Container = require("osu_ui.ui.Container")

local math_util = require("math_util")
local actions = require("osu_ui.actions")
local ui = require("osu_ui.ui")

---@class osu.ui.ScrollAreaContainer : osu.ui.Container
---@operator call: osu.ui.ScrollAreaContainer
local ScrollAreaContainer = Container + {}

local scroll_deceleration_default = -0.98
local velocity_cutoff = 0.01
local clamping_force_factor = 2

---@param depth number?
---@param transform love.Transform?
---@param scroll_limit number?
---@param width number?
---@param height number?
function ScrollAreaContainer:new(depth, transform, scroll_limit, width, height)
	self.depth = depth or 0
	self.totalW = width or 1368
	self.totalH = height or 768
	self.children = {}
	self:setTransform(transform or love.math.newTransform(0, 0))

	self.isDragging = false
	self.scrollLimit = scroll_limit or 0
	self.scrollPosition = 0
	self.scrollVelocity = 0
	self.scrollDeceleration = scroll_deceleration_default
end

local function sign(v)
	return (v > 0 and 1) or (v == 0 and 0) or -1
end


local frame_aim_time = 1000 / 60
local function getFrameRatio(dt_ms)
	return dt_ms / frame_aim_time
end

function ScrollAreaContainer:isScrolling()
	return math.abs(self.scrollVelocity) > velocity_cutoff or self.isDragging
end

function ScrollAreaContainer:scrollToPosition(position, deceleration)
	if deceleration == 0 then
		self.scrollDeceleration = scroll_deceleration_default
	end

	local distance_y = position - self.scrollPosition

	if self.scrollDeceleration < 0 then
		self.scrollVelocity = sign(distance_y) * velocity_cutoff - distance_y * math.log(-self.scrollDeceleration)
	else
		self.scrollVelocity = sign(distance_y) * math.sqrt(math.abs(distance_y * self.scrollDeceleration * 2))
	end
end

function ScrollAreaContainer:updateScrollVelocity(dt)
	local scroll_velocity_this_frame = self.scrollVelocity

	local dt_ms = dt * 1000
	local frame_ratio = getFrameRatio(dt_ms)
	local clamped_position = math_util.clamp(self.scrollPosition, 0, self.scrollLimit)
	local clamped_difference = clamped_position - self.scrollPosition

	if clamped_difference ~= 0 and not self.isDragging then
		local clamping_decay = 1 - 0.2 * clamping_force_factor
		if sign(self.scrollVelocity) ~= sign(clamped_difference) then
			self.scrollVelocity = self.scrollVelocity * (math.pow(clamping_decay, frame_ratio))
		end
		scroll_velocity_this_frame = ((self.scrollVelocity ~= scroll_velocity_this_frame) and (frame_ratio > 0)) and ((self.scrollVelocity - scroll_velocity_this_frame) / (frame_ratio * math.log(clamping_decay))) or self.scrollVelocity
	elseif self.scrollDeceleration < 0 then
		local time_to_cutoff = 0
		if not (math.abs(self.scrollVelocity) <= velocity_cutoff) then
			time_to_cutoff = math.log(velocity_cutoff / math.abs(self.scrollVelocity), -self.scrollDeceleration)
		end

		local elapsed_time = math.min(time_to_cutoff, dt_ms)
		self.scrollVelocity = self.scrollVelocity * (math.pow(-self.scrollDeceleration, elapsed_time))

		if (elapsed_time > 0 and self.scrollVelocity ~= scroll_velocity_this_frame) then
			scroll_velocity_this_frame = ((self.scrollVelocity - scroll_velocity_this_frame) / (elapsed_time * math.log(-self.scrollDeceleration)))
		else
			scroll_velocity_this_frame = self.scrollVelocity
		end
		scroll_velocity_this_frame = scroll_velocity_this_frame * (elapsed_time / dt_ms)
	elseif self.scrollDeceleration > 0 then
		local time_until_zero = math.abs(self.scrollVelocity) / self.scrollDeceleration
		if self.scrollVelocity > 0 then
			self.scrollVelocity = math.max(0, self.scrollVelocity - self.scrollDeceleration * dt_ms)
		elseif self.scrollVelocity < 0 then
			self.scrollVelocity = math.max(0, self.scrollVelocity + self.scrollDeceleration * dt_ms)
		end
		scroll_velocity_this_frame = (scroll_velocity_this_frame + self.scrollVelocity) * math.min(time_until_zero / dt_ms, 1) / 2
	end

	if (math.abs(scroll_velocity_this_frame) <= velocity_cutoff and math.abs(self.scrollVelocity) <= velocity_cutoff and math.abs(clamped_difference) < 0.5) then
		self.scrollPosition = clamped_position
		self.scrollVelocity = 0
		self.scrollDeceleration = scroll_deceleration_default
		scroll_velocity_this_frame = 0
	else
		local distance_to_shrink = clamped_difference - clamped_difference * math.pow(1 - 0.005 * clamping_force_factor, dt_ms)
		scroll_velocity_this_frame = scroll_velocity_this_frame + (distance_to_shrink / dt_ms)
	end

	return scroll_velocity_this_frame
end

function ScrollAreaContainer:update(dt)
	Container.update(self, dt)

	local clamped_position = math_util.clamp(self.scrollPosition, 0, self.scrollLimit)
        if (math.abs(self.scrollVelocity) <= velocity_cutoff and clamped_position == self.scrollVelocity) then
		return
	end

	local scroll_velocity_this_frame = self:updateScrollVelocity(dt)
	self.scrollPosition = self.scrollPosition + scroll_velocity_this_frame * (dt * 1000)
end

function ScrollAreaContainer:mouseInput(has_focus)
	if not has_focus then
		return
	end

	if not ui.isOver(self.totalW, self.totalH) then
		return
	end

	local scroll = actions:getWheelScroll()

	if scroll > 0 then
		if (self.scrollVelocity > 0) then
			self.scrollVelocity = 0
		end
		self:scrollToPosition(-100 + self.scrollPosition, 0)
	elseif scroll < 0 then
		if (self.scrollVelocity < 0) then
			self.scrollVelocity = 0
		end
		self:scrollToPosition(100 + self.scrollPosition, 0)
	end
end

function ScrollAreaContainer:updateTransform()
	self.transform:apply(love.math.newTransform(0, -self.scrollPosition))
end

return ScrollAreaContainer
