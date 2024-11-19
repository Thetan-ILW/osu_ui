local Container = require("osu_ui.ui.Container")

local Image = require("osu_ui.ui.Image")
local Label = require("osu_ui.ui.Label")

---@alias ChartInfoShowcase { assets: osu.ui.OsuAssets }

---@class osu.ui.ChartInfoShowcase : osu.ui.Container
---@overload fun(params: ChartInfoShowcase): osu.ui.ChartInfoShowcase
---@field assets osu.ui.OsuAssets
local ChartInfoShowcase = Container + {}

function ChartInfoShowcase:load()
	self.automaticSizeCalc = false
	Container.load(self)
	self:addTags({ "allowReload" })

	self.totalW = self.parent.totalW
	self.totalH = self.parent.totalH

	local image = self:addChild("image", Image({
		x = self.totalW / 2,
		origin = { x = 0.5, y = 0.5 },
		image = self.assets:loadImage("background-panel"),
		depth = 0.1
	}))
	---@cast image osu.ui.Image
	self.image = image

	function self.image:draw()
		love.graphics.draw(self.image)
	end

	self.chartName = self:addChild("chartName", Label({
		y = self.totalH / 2 + 70,
		origin = { x = 0.5, y = 0 },
		font = self.assets:loadFont("Bold", 56),
		text = "chartName",
	}))

	self.chartInfo = self:addChild("chartInfo", Label({
		y = self.totalH / 2 + 135,
		origin = { x = 0.5, y = 0 },
		font = self.assets:loadFont("Regular", 32),
		text = "chartInfo",
	}))

	self:build()
end

function ChartInfoShowcase:show(chart_name, chart_info, image)
	local text_scale = math.min(self.parent.textScale, (self.totalW - 40) / self.chartName.font:getWidth(chart_name))

	self.chartName.textScale = text_scale
	self.chartName:replaceText(chart_name)
	self.chartInfo:replaceText(chart_info)
	self.image.scale = 253 / image:getHeight()
	self.image:replaceImage(image)
end

function ChartInfoShowcase:update(dt, mouse_focus)
	self:forEachChild(function (child)
		child.alpha = self.alpha
	end)

	self.image.y = (self.totalH / 2 - 100) * self.alpha
	self.image:applyTransform()

	self.chartName.x = (self.totalW / 2) * self.alpha
	self.chartName:applyTransform()

	self.chartInfo.x = self.totalW - (self.totalW / 2) * self.alpha
	self.chartInfo:applyTransform()
	return Container.update(self, dt, mouse_focus)
end

return ChartInfoShowcase
