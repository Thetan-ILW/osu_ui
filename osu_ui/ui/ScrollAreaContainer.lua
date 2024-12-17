local Component = require("ui.Component")

local math_util = require("math_util")

---@alias ScrollAreaContainerParams { scrollLimit: number }

---@class osu.ui.ScrollAreaContainer : ui.Component
---@overload fun(params: ScrollAreaContainerParams): osu.ui.ScrollAreaContainer
---@field scrollLimit number
local ScrollAreaContainer = Component + {}

local scroll_deceleration_default = -0.98
local velocity_cutoff = 0.01
local clamping_force_factor = 2
local throwing_scroll_decay = 0.996

local frame_aim_time = 1000 / 60

function ScrollAreaContainer:load()
	self.isDragging = false
	self.scrollLimit = self.scrollLimit or 0
	self.scrollPosition = 0
	self.scrollVelocity = 0
	self.scrollDeceleration = scroll_deceleration_default
	self.scrollDistance = self.scrollDistance or 232

	self.lastMouseY = 0
	self.dragOriginY = 0
	self.dragScrollOriginY = 0
	self.accumulatedTimeSinceLastMovement = 0

	self.viewport = self:getViewport()
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
		self.scrollVelocity = sign(distance_y) * velocity_cutoff -
		    distance_y * math.log(-self.scrollDeceleration)
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
		scroll_velocity_this_frame = ((self.scrollVelocity ~= scroll_velocity_this_frame) and (frame_ratio > 0)) and
		    ((self.scrollVelocity - scroll_velocity_this_frame) / (frame_ratio * math.log(clamping_decay))) or
		    self.scrollVelocity
	elseif self.scrollDeceleration < 0 then
		local time_to_cutoff = 0
		if not (math.abs(self.scrollVelocity) <= velocity_cutoff) then
			time_to_cutoff = math.log(velocity_cutoff / math.abs(self.scrollVelocity),
				-self.scrollDeceleration)
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
		scroll_velocity_this_frame = (scroll_velocity_this_frame + self.scrollVelocity) *
		    math.min(time_until_zero / dt_ms, 1) / 2
	end

	if (math.abs(scroll_velocity_this_frame) <= velocity_cutoff and math.abs(self.scrollVelocity) <= velocity_cutoff and math.abs(clamped_difference) < 0.5) then
		self.scrollPosition = clamped_position
		self.scrollVelocity = 0
		self.scrollDeceleration = scroll_deceleration_default
		scroll_velocity_this_frame = 0
	else
		local distance_to_shrink = clamped_difference -
		    clamped_difference * math.pow(1 - 0.005 * clamping_force_factor, dt_ms)
		scroll_velocity_this_frame = scroll_velocity_this_frame + (distance_to_shrink / dt_ms)
	end

	return scroll_velocity_this_frame
end

---@param dt number
function ScrollAreaContainer:tryDrag(dt)
	self.scrollDeceleration = self.scrollVelocity == 0 and 0.5 or
	    -math.max(0.5, throwing_scroll_decay - 0.002 / math.abs(self.scrollVelocity))

	love.graphics.push()
	love.graphics.replaceTransform(love.math.newTransform(0, 0, self.rotation, self.scale, self.scale))
	local _, new_mouse_y = love.graphics.inverseTransformPoint(love.mouse.getPosition())
	local _, drag_origin = love.graphics.inverseTransformPoint(0, self.dragOriginY)
	local _, drag_scroll_origin = love.graphics.inverseTransformPoint(0, self.dragScrollOriginY)
	love.graphics.pop()

	if self.lastMouseY ~= 0 and dt > 0 then
		self.accumulatedTimeSinceLastMovement = self.accumulatedTimeSinceLastMovement + (dt * 1000)
		local velocity = (self.lastMouseY - new_mouse_y) / self.accumulatedTimeSinceLastMovement

		local high_decay = sign(velocity) == -sign(self.scrollVelocity) or
		    math.abs(velocity) > math.abs(self.scrollVelocity)

		local decay = math.pow(high_decay and 0.90 or 0.95, self.accumulatedTimeSinceLastMovement)

		if velocity ~= 0 then
			self.accumulatedTimeSinceLastMovement = 0;
			self.scrollVelocity = self.scrollVelocity * decay + (1 - decay) * velocity
		end
	end

	self.lastMouseY = new_mouse_y
	local y = drag_scroll_origin + ((drag_origin - new_mouse_y) / self.viewport:getInnerScale())
	self.scrollPosition = math_util.clamp(y, 0, self.scrollLimit) * 0.5 + y * (1 - 0.5)
end

---@param state ui.FrameState
function ScrollAreaContainer:updateTree(state)
	local dt = state.deltaTime

	if self.isDragging then
		self:tryDrag(dt)
	end

	local clamped_position = math_util.clamp(self.scrollPosition, 0, self.scrollLimit)
	if not ((math.abs(self.scrollVelocity) <= velocity_cutoff and clamped_position == self.scrollVelocity)) then
		local scroll_velocity_this_frame = self:updateScrollVelocity(dt)
		self.scrollPosition = self.scrollPosition + scroll_velocity_this_frame * (dt * 1000)
	end

	Component.updateTree(self, state)
end

function ScrollAreaContainer:updateChildren(state)
	love.graphics.translate(0, -self.scrollPosition)
	Component.updateChildren(self, state)
end

function ScrollAreaContainer:drawChildren()
	love.graphics.translate(0, -self.scrollPosition)
	Component.drawChildren(self)
end

function ScrollAreaContainer:wheelUp()
	if self.mouseOver then
		if self.scrollVelocity > 0 then
			self.scrollVelocity = 0
		end
		self:scrollToPosition(-self.scrollDistance + self.scrollPosition, 0)
		return true
	end
	return false
end

function ScrollAreaContainer:wheelDown()
	if self.mouseOver then
		if self.scrollVelocity > 0 then
			self.scrollVelocity = 0
		end
		self:scrollToPosition(self.scrollDistance + self.scrollPosition, 0)
		return true
	end
	return false
end

function ScrollAreaContainer:loseFocus()
	self.isDragging = false
end

function ScrollAreaContainer:mousePressed(event)
	if event[3] == 2 then
		return false
	end

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

function ScrollAreaContainer:mouseReleased(event)
	if event[3] == 2 then
		return
	end

	if self.isDragging then
		self.scrollVelocity = self.scrollVelocity *
		    (math.pow(0.95, math.max(0, self.accumulatedTimeSinceLastMovement - 66)))
		self.accumulatedTimeSinceLastMovement = 0;
		self.lastMouseY = 0
	end

	self.isDragging = false
end

return ScrollAreaContainer
