local Container = require("osu_ui.ui.Container")

local TextBox = require("osu_ui.ui.TextBox")
local Rectangle = require("osu_ui.ui.Rectangle")
local Label = require("osu_ui.ui.Label")

---@class osu.ui.OptionsGroup : osu.ui.Container
---@field parent osu.ui.OptionsSection
---@field assets osu.ui.OsuAssets
---@field isEmpty boolean
---@field searchText string
---@field name string
---@field buildFunction fun(group: osu.ui.OptionsGroup)
local Group = Container + {}

function Group:bindEvent(child, event)
	self.parent:bindEvent(child, event)
end

function Group:load()
	self.automaticSizeCalc = false
	self.isEmpty = false
	self.indent = 12

	Container.load(self)

	self.totalH = 25
	self:buildFunction()

	if self.totalH == 0 then
		self.isEmpty = true
		return
	end

	self:addChild("rectangle", Rectangle({
		totalW = 5,
		totalH = self.totalH,
		color = { 1, 1, 1, 0.2 }
	}))

	self:addChild("label", Label({
		x = self.indent,
		text = self.name,
		font = self.assets:loadFont("Bold", 16)
	}))

	self:build()
end

---@param params { label: string, value: string? }
---@return osu.ui.TextBox?
function Group:textBox(params)
	if self.searchText ~= "" and not params.label:find(self.searchText) then
		return
	end

	self.textBoxes = self.textBoxes or 1
	local text_box = self:addChild("textBox" .. self.textBoxes, TextBox({
		x = self.indent, y = self.totalH,
		totalW = 380,
		assets = self.assets,
		labelText = params.label,
		input = params.value
	}))
	function text_box.justHovered()
		TextBox.justHovered(text_box)
		self.parent:hoverOver(text_box.y + self.y, text_box:getHeight())
	end

	---@cast text_box osu.ui.TextBox
	self.totalH = self.totalH + text_box:getHeight()
	self.textBoxes = self.textBoxes + 1
	return text_box
end

return Group
