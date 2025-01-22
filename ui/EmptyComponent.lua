local Component = require("ui.Component")

---@class ui.EmptyComponent : ui.Component
---@operator call: ui.EmptyComponent
local EmptyComponent = Component + {}

function EmptyComponent:drawTree() end
function EmptyComponent:updateTree(state)
	self:update(state.deltaTime)
end

return EmptyComponent
