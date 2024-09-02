local class = require("class")

---@class osu.ui.IViewConfig
---@operator call: osu.ui.IViewConfig
local IViewConfig = class()

function IViewConfig:resolutionUpdated() end
function IViewConfig:draw() end

return IViewConfig
