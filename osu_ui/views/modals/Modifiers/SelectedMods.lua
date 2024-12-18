local ListView = require("osu_ui.views.ListView")

local ModifierModel = require("sphere.models.ModifierModel")
local ModifierRegistry = require("sphere.models.ModifierModel.ModifierRegistry")

---@class osu.ui.SelectedModsView : osu.ui.ListView
local SelectedMods = ListView + {}

function SelectedMods:load()
	self.rows = 8
	ListView.load(self)

	local area = self.scrollArea
	area.scrollDistance = 115

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.fonts = scene.fontManager

	self.stencilFunction = function()
		love.graphics.rectangle("fill", 0, 0, self.width, self.height, 5, 5)
	end



end

return SelectedMods
