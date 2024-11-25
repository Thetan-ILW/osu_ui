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
end

function GroupsContainer:updateTree(state)
	local current_h = 0
	local max_h = 0
	for _, v in pairs(self.children) do
		---@cast v osu.ui.WindowListView
		current_h = math.max(current_h, v.y + v.height)
		max_h = max_h + #v.items * v.panelHeight
	end
	self.height = current_h
	self.scrollLimit = current_h

	if self.scrollPosition > self.scrollLimit then
		self.scrollLimit = max_h
	end

	if love.mouse.isDown(2) then
		local scale = 768 / love.graphics.getHeight()
		local my = love.mouse.getY() * scale
		local y = math.min(math.max(0, my - 117) / 560, 1)
		self:scrollToPosition(self.scrollLimit * y)
	end

	local add_x = math.abs(self.scrollVelocity) * 3
	if add_x > 20 then
		if self.children.charts then
			self.children.charts.x = add_x
		end
		if self.children.root then
			self.children.root.x = add_x
		end
	end

	ScrollAreaContainer.updateTree(self, state)
end

return GroupsContainer
