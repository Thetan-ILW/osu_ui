local Component = require("ui.Component")

local Group = require("osu_ui.views.Options.Group")
local Label = require("ui.Label")

---@alias OptionsSectionParams { options: osu.ui.OptionsView, buildFunction: fun(section: osu.ui.OptionsSection) }

---@class osu.ui.OptionsSection : ui.Component
---@overload fun(params: OptionsSectionParams): osu.ui.OptionsSection
---@field name string
---@field icon love.Text
---@field options osu.ui.OptionsView
---@field isEmpty boolean
---@field buildFunction fun(section: osu.ui.OptionsSection)
local Section = Component + {}

function Section:load()
	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	local fonts = scene.fontManager

	self.startY = 60
	self.currentY = 0
	self.groupSpacing = 24
	self.isEmpty = false

	local groups = self:addChild("groups", Component({
		x = 24, y = self.startY,
		boxWidth = self.width,
	}))
	---@cast groups ui.Component
	self.groups = groups

	self.buildFunction(self)
	groups:autoSize()

	if groups.height == 0 then
		self.isEmpty = true
		return
	end

	self:addChild("sectionName", Label({
		boxWidth = self.width - 15,
		alignX = "right",
		text = self.name,
		font = fonts:loadFont("Regular", 33),
		color = { 0.13, 0.6, 0.73, 1 },
	}))

	self:autoSize()
end

function Section:update()
	local range = self.options:getHeight()
	local scroll = math.max(0, self.options:getScrollPosition())

	local y_start = self.y + self.parent.y
	local y_end = y_start + self.height

	local in_view = scroll > y_start - range and scroll < y_end

	self.alpha = 1
	self.canUpdateChildren = true

	if not in_view then
		self.alpha = 0
		self.canUpdateChildren = false
		if scroll > y_end then
			for _, group in pairs(self.groups.children) do
				---@cast group osu.ui.OptionsGroup
				if group:hasOpenCombos() then
					self.alpha = 1
					self.canUpdateChildren = true
					break
				end
			end
		end
	end
end

function Section:hoveringOver(y, height)
	self.options:hoveringOver(y + self.y + self.startY, height)
end

---@param build_function fun(group: osu.ui.OptionsGroup)
function Section:group(name, build_function)
	self.groupCount = self.groupCount or 0

	local group = self.groups:addChild(name, Group({
		y = self.currentY,
		width = self.width,
		section = self,
		name = name:upper(),
		buildFunction = build_function,
		z = 1 - self.groupCount * 0.000001,
	}))
	---@cast group osu.ui.OptionsGroup

	if group.isEmpty then
		self.groups:removeChild(name)
		return
	end

	self.currentY = self.currentY + group:getHeight() + self.groupSpacing
	self.groupCount = self.groupCount + 1
end

function Section:recalcPositions()
	self.height = 0

	for _, v in ipairs(self.groups.childrenOrder) do
		local child = self.groups.children[v]
		child.y = self.height
		self.height = self.height + child:getHeight() + self.groupSpacing
	end

	self.height = self.height + self.startY
	self.deferBuild = true
end

return Section
