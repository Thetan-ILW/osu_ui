local Container = require("osu_ui.ui.Container")

local math_util = require("math_util")

---@alias ScrollAreaContainerParams { width: number, height: number, scrollLimit: number }

---@class osu.ui.ScrollAreaContainer : osu.ui.Container
---@overload fun(params: ScrollAreaContainerParams): osu.ui.ScrollAreaContainer
---@field width number
---@field height number
---@field scrollLimit number
local ScrollAreaContainer = Container + {}

local scroll_deceleration_default = -0.98
local velocity_cutoff = 0.01
local clamping_force_factor = 2
local scroll_distance = 232
local throwing_scroll_decay = 0.996

local frame_aim_time = 1000 / 60

function ScrollAreaContainer:load()
	self.totalW = self.width
	self.totalH = self.height

	self.isDragging = false
	self.scrollLimit = self.scrollLimit or 0
	self.scrollPosition = 0
	self.scrollVelocity = 0
	self.scrollDeceleration = scroll_deceleration_default

	self.lastMouseY = 0
	self.dragOriginY = 0
	self.dragScrollOriginY = 0
        self.accumulatedTimeSinceLastMovement = 0
	Container.load(self)
end

function ScrollAreaContainer:bindEvents()
	self.parent:bindEvent(self, "wheelUp")
	self.parent:bindEvent(self, "wheelDown")
	self.parent:bindEvent(self, "mousePressed")
	self.parent:bindEvent(self, "mouseReleased")
end

local function sign(v)
	return (v > 0 and 1) or (v == 0 and 0) or -1
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
	if self.isDragging then
		return 0
	end

	local scroll_velocity_this_frame = self.scrollVelocity

	local dt_ms = dt * 1000
	local frame_ratio = dt_ms / frame_aim_time
	local clamped_position = math_util.clamp(self.scrollPosition, 0, self.scrollLimit)
	local clamped_difference = clamped_position - self.scrollPosition

	if clamped_difference ~= 0 then
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

---@param dt number
function ScrollAreaContainer:tryDrag(dt)
	if not self.isDragging then
		return
	end

	self.scrollDeceleration = self.scrollVelocity == 0 and 0.5 or -math.max(0.5, throwing_scroll_decay - 0.002 / math.abs(self.scrollVelocity))

	love.graphics.push()
	love.graphics.replaceTransform(love.math.newTransform(0, 0, self.rotation, self.scale, self.scale, self:getOrigin()))
	local _, new_mouse_y = love.graphics.inverseTransformPoint(love.mouse.getPosition())
	local _, drag_origin = love.graphics.inverseTransformPoint(0, self.dragOriginY)
	local _, drag_scroll_origin = love.graphics.inverseTransformPoint(0, self.dragScrollOriginY)
	love.graphics.pop()

	if self.lastMouseY ~= 0 and dt > 0 then
		self.accumulatedTimeSinceLastMovement = self.accumulatedTimeSinceLastMovement + (dt * 1000)
		local velocity = (self.lastMouseY - new_mouse_y) / self.accumulatedTimeSinceLastMovement

		local high_decay = sign(velocity) == -sign(self.scrollVelocity) or math.abs(velocity) > math.abs(self.scrollVelocity)

		local decay = math.pow(high_decay and 0.90 or 0.95, self.accumulatedTimeSinceLastMovement)

		if velocity ~= 0 then
			self.accumulatedTimeSinceLastMovement = 0;
			self.scrollVelocity = self.scrollVelocity * decay + (1 - decay) * velocity
		end
	end

	self.lastMouseY = new_mouse_y
	local y = drag_scroll_origin + (drag_origin - new_mouse_y)
	self.scrollPosition = math_util.clamp(y, 0, self.scrollLimit) * 0.5 + y * (1 - 0.5)
end

function ScrollAreaContainer:applyTransform()
	self.transform = love.math.newTransform(self.x, self.y - self.scrollPosition, self.rotation, self.scale, self.scale, self:getOrigin())
end

---@param dt number
function ScrollAreaContainer:update(dt)
	Container.update(self, dt)

	self:tryDrag(dt)

	local clamped_position = math_util.clamp(self.scrollPosition, 0, self.scrollLimit)
        if (math.abs(self.scrollVelocity) <= velocity_cutoff and clamped_position == self.scrollVelocity) then
		self:applyTransform()
		return
	end

	local scroll_velocity_this_frame = self:updateScrollVelocity(dt)
	self.scrollPosition = self.scrollPosition + scroll_velocity_this_frame * (dt * 1000)
	self:applyTransform()
end

function ScrollAreaContainer:wheelUp()
	if self.mouseOver then
		if self.scrollVelocity > 0 then
			self.scrollVelocity = 0
		end
		self:scrollToPosition(-scroll_distance + self.scrollPosition, 0)
		return true
	end
	return false
end

function ScrollAreaContainer:wheelDown()
	if self.mouseOver then
		if self.scrollVelocity > 0 then
			self.scrollVelocity = 0
		end
		self:scrollToPosition(scroll_distance + self.scrollPosition, 0)
		return true
	end
	return false
end

function ScrollAreaContainer:mousePressed()
	if self.mouseOver then
		self.isDragging = true
		self.accumulatedTimeSinceLastMovement = 0;
		self.lastMouseY = 0
		self.dragOriginY = love.mouse.getY()
		local clamped_position = math_util.clamp(self.scrollPosition, 0, self.scrollLimit)
		self.dragScrollOriginY = self.scrollPosition + (self.scrollPosition - clamped_position)
	end
	return false
end

function ScrollAreaContainer:mouseReleased()
	if self.isDragging then
		self.scrollVelocity = self.scrollVelocity * (math.pow(0.95, math.max(0, self.accumulatedTimeSinceLastMovement - 66)))
		self.accumulatedTimeSinceLastMovement = 0;
		self.lastMouseY = 0
	end

	self.isDragging = false
	return true
end

return ScrollAreaContainer
