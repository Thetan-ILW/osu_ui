local Screen = require("osu_ui.views.Screen")
local CanvasComponent = require("ui.CanvasComponent")

---@class osu.ui.CanvasScreen : osu.ui.Screen
---@operator call: osu.ui.CanvasScreen
local CanvasScreen = Screen + {}

CanvasScreen.load = CanvasComponent.load
CanvasScreen.createCanvas = CanvasComponent.createCanvas
CanvasScreen.draw = CanvasComponent.draw
CanvasScreen.drawTree = CanvasComponent.drawTree

return CanvasScreen
