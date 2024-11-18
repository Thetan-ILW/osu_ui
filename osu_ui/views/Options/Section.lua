local Container = require("osu_ui.ui.Container")

local Group = require("osu_ui.views.Options.Group")
local Label = require("osu_ui.ui.Label")

---@alias OptionsSectionParams { options: osu.ui.OptionsView, buildFunction: fun(section: osu.ui.OptionsSection) }

---@class osu.ui.OptionsSection : osu.ui.Container
---@overload fun(params: OptionsSectionParams): osu.ui.OptionsSection
---@field name string
---@field icon love.Text
---@field options osu.ui.OptionsView
---@field isEmpty boolean
---@field buildFunction fun(section: osu.ui.OptionsSection)
local Section = Container + {}

function Section:load()
	self.automaticSizeCalc = false
	Container.load(self)
	self.startY = 60
	self.groupSpacing = 24
	self.totalH = 0
	self.isEmpty = false

	local groups = self:addChild("groups", Container({
		x = 24, y = self.startY,
	}))
	---@cast groups osu.ui.Container
	self.groups = groups

	self.buildFunction(self)

	if self.totalH == 0 then
		self.isEmpty = true
		return
	end

	self.totalH = self.totalH + self.startY

	groups:build()

	self:addChild("sectionName", Label({
		totalW = self.totalW - 15,
		alignX = "right",
		text = self.name,
		font = self.options.assets:loadFont("Regular", 33),
		color = { 0.13, 0.6, 0.73, 1 },
		alpha = 1
	}))

	self:build()
end

function Section:update(dt, mouse_focus)
	local range = self.options.totalH
	local scroll = math.max(0, self.options:getScrollPosition())

	local y_start = self.y + self.parent.y
	local y_end = y_start + self.totalH

	local in_view = scroll > y_start - range and scroll < y_end

	self.alpha = in_view and 1 or 0

	if not in_view then
		if scroll > y_end then
			for _, group in pairs(self.groups.children) do
				---@cast group osu.ui.OptionsGroup
				if group:hasOpenCombos() then
					self.alpha = 1
					break
				end
			end
		end
	end

	if self.alpha ~= 0 then
		Container.update(self, dt, mouse_focus)
	end
end

function Section:hoverOver(y, height)
	self.options:hoverOver(y + self.y + self.startY, height)
end

---@param build_function fun(group: osu.ui.OptionsGroup)
function Section:group(name, build_function)
	self.groupCount = self.groupCount or 0

	local group = self.groups:addChild(name, Group({
		y = self.totalH,
		section = self,
		name = name,
		buildFunction = build_function,
		depth = 1 - self.groupCount * 0.000001
	}))
	---@cast group osu.ui.OptionsGroup

	if group.isEmpty then
		self.groups:removeChild(name)
		return
	end

	self.totalH = self.totalH + group:getHeight() + self.groupSpacing
	self.groupCount = self.groupCount + 1
end

function Section:recalcPositions()
	self.totalH = 0

	for _, v in ipairs(self.groups.childrenOrder) do
		local child = self.groups.children[v]
		child.y = self.totalH
		child:applyTransform()
		self.totalH = self.totalH + child:getHeight() + self.groupSpacing
	end

	self.totalH = self.totalH + self.startY
	self.groups:build()
end

return Section
