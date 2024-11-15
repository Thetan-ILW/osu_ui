local Container = require("osu_ui.ui.Container")

local Group = require("osu_ui.views.Options.Group")

---@class osu.ui.OptionsSection : osu.ui.Container
---@field options osu.ui.OptionsView
---@field assets osu.ui.OsuAssets
---@field isEmpty boolean
---@field searchText string
---@field buildFunction fun(section: osu.ui.OptionsSection)
local Section = Container + {}

function Section:bindEvent(child, event)
	self.parent:bindEvent(child, event)
end

function Section:load()
	Container.load(self)
	self.totalH = 0
	self.isEmpty = false

	self:buildFunction()

	if self.totalH == 0 then
		self.isEmpty = true
		return
	end

	self:build()
end

function Section:hoverOver(y, height)
	self.options:hoverOver(y + self.y, height)
end

---@param build_function fun(group: osu.ui.OptionsGroup)
function Section:group(name, build_function)
	local group = self:addChild(name, Group({
		x = 24,
		assets = self.assets,
		name = name,
		searchText = self.searchText,
		buildFunction = build_function
	}))
	---@cast group osu.ui.OptionsGroup

	if group.isEmpty then
		self:removeChild(name)
		return
	end

	self.totalH = self.totalH + group:getHeight()
end

return Section
