local ListView = require("osu_ui.views.ListView")
local ui = require("osu_ui.ui")

local DanTableView = ListView + {}

---@param assets osu.ui.OsuAssets
---@param cleared_dans { name: string, time: string? }
function DanTableView:new(assets, cleared_dans)
	self.assets = assets
	self.items = cleared_dans

	local text, font = self.assets.localization:get("playerStats")
	assert(text and font)
	self.text, self.font = text, font

	self.rows = 10
end

local gfx = love.graphics
local dan_name_w = 120
local table_w = 400

---@param i number
---@param w number
---@param h number
function DanTableView:drawItem(i, w, h)
	local item = self.items[i]

	self:drawItemBody(w, h, i, false)

	local font = self.font.danTable
	gfx.setFont(font)
	gfx.setColor(1, 1, 1)

	ui.frame(item.name, 0, 0, dan_name_w, h, "right", "center")

	if item.time then
		ui.frame(item.time, dan_name_w, 0, table_w - dan_name_w, h, "center", "center")
	end
end

return DanTableView
