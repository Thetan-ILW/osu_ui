local Component = require("ui.Component")

---@class osu.ui.VideoExporterPlayfield : ui.Component
---@operator call: osu.ui.VideoExporterPlayfield
---@field videoExporter osu.ui.VideoExporter
local Playfield = Component + {}

function Playfield:load()
	self.startIndex = 1

	self.notes = self.videoExporter.notes
	self.columns = self.videoExporter.columns
	self.noteImage = self.videoExporter.assets:loadImage("mania-note1")
	self.columnWidth = 80
	self.noteScale = self.columnWidth / self.noteImage:getWidth()
	self.noteHeight = self.noteImage:getHeight() * self.noteScale
	self.noteSpeed = 60
	self.hitPosition = 600

	self.width = self.columns * self.columnWidth
	self.height = self.height or self.parent:getHeight()
end

function Playfield:draw()
	love.graphics.setColor(1, 0, 0)
	love.graphics.rectangle("fill", 0, self.hitPosition, self.columnWidth * self.columns, self.noteHeight)

	local start_i = self.startIndex
	local current_time = self.videoExporter.currentTime

	love.graphics.setColor(1, 1, 1)
	for i = start_i, #self.notes do
		local note = self.notes[i]

		if note.time > current_time then
			if note.time > current_time + 1 then
				break
			end

			local y = self.noteHeight - (note.time - current_time) * self.noteHeight * self.noteSpeed + self.hitPosition - self.noteHeight
			love.graphics.draw(self.noteImage, (note.column - 1) * self.columnWidth, y, 0, self.noteScale, self.noteScale)
		else
			start_i = i
		end
	end
end

return Playfield
