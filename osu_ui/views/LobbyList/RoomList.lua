local ListView = require("osu_ui.views.ListView")
local Component = require("ui.Component")
local Rectangle = require("ui.Rectangle")
local Label = require("ui.Label")
local Image = require("ui.Image")

---@class osu.ui.RoomList : osu.ui.ListView
---@operator call: osu.ui.RoomList
local RoomList = ListView + {}

function RoomList:load()
	ListView.load(self)

	local scene = self:findComponent("scene") ---@cast scene osu.ui.Scene
	self.multiplayerApi = scene.ui.multiplayerApi

	self.assets = scene.assets
	self.fonts = scene.fontManager
	self.searchInput = ""

	self:loadItems(self.multiplayerApi:getLobbies())
	self.nextCheck = love.timer.getTime() + 1
end

---@param lobbies table
function RoomList:shouldReloadItems(lobbies)
	if love.timer.getTime() < self.nextCheck then
		return
	end
	self.nextCheck = love.timer.getTime() + 1

	if #lobbies ~= #self.previousItems then
		return true
	end

	for i, v in ipairs(lobbies) do
		if v ~= self.previousItems[i] then
			return true
		end
	end

	return false
end

---@param input string
function RoomList:setSearchInput(input)
	self.searchInput = input
	self:loadItems(self.multiplayerApi:getLobbies())
end

function RoomList:update()
	local lobbies = self.multiplayerApi:getLobbies()
	if self:shouldReloadItems(lobbies) then
		self:loadItems(lobbies)
	end
end

---@param items table
function RoomList:loadItems(items)
	self.previousItems = {}
	self:removeCells()

	local mania_icon = self.assets:loadImage("mode-mania-small-for-charts")
	local avatar_frame = self.assets:loadImage("lobby-avatar")
	local room_name_font = self.fonts:loadFont("Bold", 16)
	local game_type = room_name_font
	local chart_name_font = self.fonts:loadFont("Regular", 15)
	local color_inactive = { 1, 1, 1, 0.1 }
	local color_hover = { 1, 1, 1, 0.16 }

	for i, v in ipairs(items) do
		table.insert(self.previousItems, v)
		if self.searchInput == "" or v.name:find(self.searchInput) then
			local cell = Component()
			cell:addChild("background", Rectangle({
				width = self.width,
				height = self:getCellHeight() - 1,
				color = color_inactive,
				blockMouseFocus = true,
				update = function(this)
					this.color = this.mouseOver and	color_hover or color_inactive
				end,
				onClick = function(this)
					if this.mouseOver then
						self.multiplayerApi:joinRoom(i)
					end
				end
			}))
			cell:addChild("modeIcon", Image({
				y = 4,
				image = mania_icon,
				z = 0.1,
			}))
			cell:addChild("gameType", Label({
				x = 34,
				font = game_type,
				text = ("VSRG (head-to-head)\n%i/∞"):format(#v.users),
				shadow = true,
				z = 0.1,
			}))
			cell:addChild("avatarFrame", Image({
				x = 300, y = 3,
				image = avatar_frame,
				color = { 0.91, 0.19, 0, 1 },
				z = 0.1,
			}))

			for frame = 1, 7 do
				cell:addChild("avatarFrame" .. frame, Image({
					x = 381 + ((frame - 1) * 52), y = 34,
					image = avatar_frame,
					scale = 0.6,
					color = { 0.52, 0.72, 0.12, 0.5 },
					z = 0.1,
				}))
			end

			cell:addChild("roomName", Label({
				x = 385,
				font = room_name_font,
				text = v.name,
				shadow = true,
				z = 0.1
			}))
			cell:addChild("chartName", Label({
				x = 385, y = 17,
				font = chart_name_font,
				text = ("%s - %s [%s]"):format(v.notechart.artist or "No artist", v.notechart.title or "No title", v.notechart.name or "No name"),
				shadow = true,
				color = { 1, 0.84, 0.42, 1 },
				z = 0.1,
			}))
			self:addCell(cell)
		end
	end
end

return RoomList
