local ScrollAreaContainer = require("osu_ui.ui.ScrollAreaContainer")

---@alias ListContainerParams { scrollLimit: number, root: osu.ui.WindowListView, assets: osu.ui.OsuAssets }

---@class osu.ui.ListContainer : osu.ui.ScrollAreaContainer
---@overload fun(params: ListContainerParams): osu.ui.ListContainer
---@field root osu.ui.WindowListView
---@field assets osu.ui.OsuAssets
local GroupsContainer = ScrollAreaContainer + {}

function GroupsContainer:load()
	ScrollAreaContainer.load(self)
	self:addChild("root", self.root)
	self:build()
end

function GroupsContainer:update(dt, mouse_focus)
	local new_mouse_focus = ScrollAreaContainer.update(self, dt, mouse_focus)

	local h = self.root.y + self.root.totalH
	self.totalH = h
	self.hoverHeight = h
	self.scrollLimit = h

	if love.mouse.isDown(2) then
		local y = math.min(math.max(0, love.mouse.getY() - 117) / 560, 1)
		self:scrollToPosition(self.scrollLimit * y)
	end

	return new_mouse_focus
end

return GroupsContainer
