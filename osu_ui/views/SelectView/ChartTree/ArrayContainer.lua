local Component = require("ui.Component")

---@class osu.ui.ArrayContainer : ui.Component
---@operator call: osu.ui.ArrayContainer
---@field children ui.Component[]
local ArrayContainer = Component + {}

---@param index integer
---@param child ui.Component
---@return ui.Component
function ArrayContainer:insertChild(index, child)
	if index < 1 or index > self.windowSize then
		self:error(("Index %s out of bounds"):format(index))
	end
	if self.children[index] then
		print(("Duplicate child with the index %s added to %s"):format(index, self.id))
	end
	child.id = tostring(index)
	child.parent = self
	child:load()
	child.killed = false
	self.children[index] = child
	self.deferBuild = true
	return child
end

---@param state ui.FrameState
function ArrayContainer:updateChildren(state)
	for i = 1, self.windowSize do
		local child = self.children[i]
		if child then
			love.graphics.push()
			child:updateTree(state)
			love.graphics.pop()
		end
	end
end

function ArrayContainer:drawChildren()
	for i = 1, self.windowSize do
		local child = self.children[i]
		if child then
			love.graphics.push("all")
			child:drawTree()
			love.graphics.pop()

			if child.debug then
				love.graphics.push("all")
				love.graphics.applyTransform(child.transform)
				love.graphics.setColor(1, 0, 0, 1)
				love.graphics.rectangle("line", 0, 0, child.width, child.height)
				love.graphics.pop()
			end
		end
	end
end

---@param event table
---@return boolean blocked
function ArrayContainer:receive(event)
	if self.disabled or not self.handleEvents then
		return false
	end

	if self[event.name] then
		if self[event.name](self, event) then
			return true
		end
	end

	for i = 1, self.windowSize do
		local child = self.children[i]
		if child then
			local blocked = child:receive(event)
			if blocked then
				return true
			end
		end
	end

	return false
end

return ArrayContainer
