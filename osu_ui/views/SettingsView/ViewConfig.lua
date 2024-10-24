local IViewConfig = require("osu_ui.views.IViewConfig")

local ui = require("osu_ui.ui")
local flux = require("flux")
local math_util = require("math_util")
local consts = require("osu_ui.views.SettingsView.Consts")
local Layout = require("osu_ui.views.OsuLayout")

---@class osu.ui.SettingsViewConfig : osu.ui.IViewConfig
---@operator call: osu.ui.SettingsViewConfig
---@field focus boolean
---@field modalActive boolean
---@field hoverRectPosition number
---@field hoverRectTargetPosition number
---@field hoverRectTargetSize number
---@field hoverRectTween table?
---@field tabFocusAnimation number
---@field tabFocusTween table?
local ViewConfig = IViewConfig + {}

local visibility = 0

local tab_focus = 0

local gfx = love.graphics

---@param view osu.SettingsView
---@param assets osu.OsuAssets
function ViewConfig:new(view, assets)
	self.focus = false
	self.modalActive = false
	self.hoverRectPosition = 0
	self.hoverRectTargetPosition = 0
	self.hoverRectTargetSize = 0
	self.tabFocusAnimation = 1
end

local tab_image_height = 64

---@param view osu.ui.SettingsView
function ViewConfig:tabs(view)
	local w, h = Layout:move("base")

	gfx.setColor(0, 0, 0, visibility)
	gfx.rectangle("fill", 0, 0, 64, h)

	local tab_count = #view.containers

	local total_h = tab_count * tab_image_height + (tab_count - 1)

	gfx.translate(0, h / 2 - total_h / 2)

	for i, c in ipairs(view.containers) do
		gfx.setColor(0.6, 0.6, 0.6, visibility)

		if ui.isOver(64, 64) and not self.modalActive then
			gfx.setColor(1, 1, 1, visibility)

			if ui.mousePressed(1) then
				view:jumpTo(i)
			end
		end

		gfx.draw(c.icon, 32, 32, 0, 1, 1, 13, 13)

		gfx.translate(0, tab_image_height)
	end

	w, h = Layout:move("base")

	gfx.setColor(0.92, 0.46, 0.55, visibility)
	local i = self.tabFocusAnimation - 1
	gfx.translate(59, h / 2 - total_h / 2 + tab_image_height * i)
	gfx.rectangle("fill", 0, 0, 6, tab_image_height)
end

---@param view osu.SettingsView
function ViewConfig:panel(view)
	local w, h = Layout:move("base")
	local scale = gfx.getHeight() / 768

	gfx.setColor(0, 0, 0, 0.7 * visibility)
	self.focus = ui.isOver(64 + 438 * visibility, h) and not self.modalActive

	gfx.translate(64, 0)
	gfx.rectangle("fill", 0, 0, 438 * visibility, h)

	local prev_canvas = gfx.getCanvas()
	local canvas = ui.getCanvas("settings_containers")

	gfx.setCanvas(canvas)

	gfx.clear()
	gfx.setBlendMode("alpha", "alphamultiply")

	if view.hoverPosition ~= self.hoverRectPosition and self.focus then
		if self.hoverRectTween then
			self.hoverRectTween:stop()
		end
		self.hoverRectPosition = view.hoverPosition
		self.hoverRectTween =
			flux.to(self, 0.6, { hoverRectTargetPosition = view.hoverPosition, hoverRectTargetSize = view.hoverSize })
				:ease("elasticout")
	end

	gfx.translate(0, view.scrollPosition)

	local search_pos = view.topSpacing:getHeight() + view.optionsLabel:getHeight() + view.gameBehaviorLabel:getHeight()
	local floating_search = -view.scrollPosition > search_pos

	view.topSpacing:draw()
	view.optionsLabel:update()
	view.optionsLabel:draw()
	view.gameBehaviorLabel:update()
	view.gameBehaviorLabel:draw()

	gfx.push()
	if not floating_search then
		view.searchLabel:draw()
	end
	gfx.pop()

	view.headerSpacing:draw()

	gfx.setColor(0, 0, 0, 0.6 * (1 - math_util.clamp(love.timer.getTime() - view.hoverTime, 0, 0.5) * 2))
	gfx.rectangle("fill", 0, self.hoverRectTargetPosition, 438, self.hoverRectTargetSize)

	---@type osu.ui.Combo[]
	self.openCombos = {}

	for _, c in ipairs(view.containers) do
		if #c.openCombos ~= 0 or (-view.scrollPosition + 768 > c.position and -view.scrollPosition < c.position + c.height) then
			c:draw(self.focus)

			if #c.openCombos ~= 0 then
				for _, combo in ipairs(c.openCombos) do
					table.insert(self.openCombos, combo)
				end
			end
		else
			gfx.translate(0, c.height)
		end
	end

	view.bottomSpacing:draw()

	if #self.openCombos ~= 0 then
		for i = #self.openCombos, 1, -1 do
			gfx.pop()
			self.openCombos[i]:drawBody()
		end
	end

	if floating_search then
		w, h = Layout:move("base")
		local a = math_util.clamp(-view.scrollPosition - search_pos, 0, 100) / 100
		gfx.setColor(0, 0, 0, 0.6 * a)
		gfx.translate(64, -24 * a)
		gfx.rectangle("fill", 0, 0, consts.settingsWidth, 80)
		view.searchLabel:draw()
	end

	gfx.setCanvas(prev_canvas)

	gfx.origin()
	gfx.setColor(1 * visibility, 1 * visibility, 1 * visibility, 1 * visibility)
	gfx.setScissor(64 * scale, 0, visibility * (438 * scale), h * scale)
	gfx.setBlendMode("alpha", "premultiplied")
	gfx.draw(canvas)
	gfx.setBlendMode("alpha")
	gfx.setScissor()
end

---@param view osu.SettingsView
function ViewConfig:back(view)
	local btn = view.backButton
	local w, h = Layout:move("base")
	gfx.translate(0, h - 58)
	btn.alpha = visibility
	btn:update(self.focus)
	btn:draw()
end

---@param view osu.SettingsView
function ViewConfig:draw(view)
	visibility = view.visibility

	local last_tab_focus = tab_focus

	for i, c in ipairs(view.containers) do
		if -view.scrollPosition + 768 / 2 > c.position then
			tab_focus = i
			gfx.setColor(1, 1, 1, visibility)
		end
	end

	if last_tab_focus ~= tab_focus then
		if self.tabFocusTween then
			self.tabFocusTween:stop()
		end
		self.tabFocusTween = flux.to(self, 0.2, { tabFocusAnimation = tab_focus }):ease("cubicout")
	end

	self:tabs(view)
	self:panel(view)
	self:back(view)
end

return ViewConfig
