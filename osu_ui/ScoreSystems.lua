local class = require("class")

---@class osu.ui.ScoreSystemMetadata
---@field display_name string
---@field timings_name sea.TimingsName
---@field timings_data_type? "number" | "string" purely visual, don't put strings in Timings, use index of timings_data_list - 1
---@field timings_data_min number?
---@field timings_data_max number?
---@field timings_data_step number?
---@field timings_data_list string[]?
---@field timings_data_default number?
---@field timings_data_prefix string?
---@field subtimings_name sea.SubtimingsName?
---@field subtimings_data number?
---@field nearest boolean?
---@field transformTimingData? fun(v: number): number

---@class osu.ui.ScoreSystemMetadatas
---@operator call: osu.ui.ScoreSystemMetadatas
---@field metadata_map {[string]: osu.ui.ScoreSystemMetadata}
local ScoreSystems = class()

---@type osu.ui.ScoreSystemMetadata[]
ScoreSystems.metadatas = {
	{
		display_name = "osu!mania V1",
		timings_name = "osuod",
		timings_data_type = "number",
		timings_data_min = 0,
		timings_data_max = 10,
		timings_data_step = 0.1,
		timings_data_default = 8,
		timings_data_prefix = "OD",
		subtimings_name = "scorev",
		subtimings_data = 1,
		transformTimingData = function(od_num)
			return math.floor(od_num * 10 + 0.5) / 10
		end
	},
	{
		display_name = "osu!mania V2",
		timings_name = "osuod",
		timings_data_type = "number",
		timings_data_min = 0,
		timings_data_max = 10,
		timings_data_step = 0.1,
		timings_data_default = 8,
		timings_data_prefix = "OD",
		subtimings_name = "scorev",
		subtimings_data = 2,
		nearest = true,
		transformTimingData = function(od_num)
			return math.floor(od_num * 10 + 0.5) / 10
		end
	},
	{
		display_name = "Etterna",
		timings_name = "etternaj",
		timings_data_type = "number",
		timings_data_min = 4,
		timings_data_max = 9,
		timings_data_step = 1,
		timings_data_default = 4,
		timings_data_prefix = "J",
		nearest = true,
	},
	{
		display_name = "Lunatic Rave 2",
		timings_name = "bmsrank",
		timings_data_type = "string",
		timings_data_list = { "Easy", "Normal", "Hard", "Very hard" }
	},
	{
		display_name = "Quaver",
		timings_name = "quaver",
	},
	{
		display_name = "soundsphere",
		timings_name = "sphere",
	},
}

---@param timings sea.Timings?
---@param subtimings sea.Subtimings?
---@return string?
local function getMetadataKey(timings, subtimings)
	if not timings or not timings.name then
		return
	end

	if subtimings then
		return ("%s%s%i"):format(timings.name, subtimings.name or "", subtimings.data or -1)
	end

	return timings.name
end

function ScoreSystems:new()
	self.metadata_map = {}

	for _, meta in ipairs(ScoreSystems.metadatas) do
		local key = getMetadataKey(
			{ name = meta.timings_name, data = 0 },
			meta.subtimings_name and { name = meta.subtimings_name, data = meta.subtimings_data }
		)
		assert(key)
		self.metadata_map[key] = meta
	end
end

---@return osu.ui.ScoreSystemMetadata[]
function ScoreSystems:getMetadatas()
	return self.metadatas
end

---@param timings sea.Timings?
---@param subtimings sea.Subtimings?
---@return osu.ui.ScoreSystemMetadata?
function ScoreSystems:getMetadataFrom(timings, subtimings)
	local key = getMetadataKey(timings, subtimings)
	return self.metadata_map[key]
end

---@param timings sea.Timings?
---@param subtimings sea.Subtimings?
---@return string?
function ScoreSystems:getJudgeName(timings, subtimings)
	local key = getMetadataKey(timings, subtimings)
	if not key or not timings then
		return
	end

	---@cast key string

	local metadata = self.metadata_map[key]

	local s = metadata.display_name

	if metadata.timings_data_type == "number" then
		if metadata.timings_data_prefix then
			s = ("%s %s%i"):format(s, metadata.timings_data_prefix, timings.data)
			return s
		else
			s = ("%s %i"):format(s, metadata.timings.data)
		end
	elseif metadata.timings_data_type == "string" then
		local judge_s = metadata.timings_data_list[timings.data + 1]

		if metadata.timings_data_prefix then
			s = ("%s %s%s"):format(s, metadata.timings_data_prefix, judge_s)
			return s
		else
			s = ("%s %i"):format(s, judge_s)
		end
	end

	return s
end

return ScoreSystems
