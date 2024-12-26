local class = require("class")

---@class game.LocationsApi
---@operator call: game.LocationsApi
local Locations = class()

---@alias Location { name: string, id: integer, path: string }

---@param game sphere.GameController
function Locations:new(game)
	self.game = game
	assert(self.game)

	self.repo = self.game.cacheModel.locationsRepo
	self.manager = self.game.cacheModel.locationManager
end

---@return Location[]
function Locations:getLocations()
	return self.manager.locations
end

---@return integer
function Locations:getSelectedLocationId()
	return self.manager.selected_id
end

---@return Location
function Locations:getSelectedLocation()
	return self.manager.selected_loc
end

---@return { chartfile_sets: integer, chartfiles: integer, hashed_chartfiles: integer }
function Locations:getLocationInfo()
	return self.manager.location_info
end

function Locations:changeName(name)
	local id = self:getSelectedLocationId()
	self.repo:updateLocation({
		id = id,
		name = name,
	})
	self.manager:selectLocations()
	self.manager:selectLocation(id)
end

function Locations:createLocation()
	local location = self.repo:insertLocation({
		name = "New location",
		is_relative = false,
		is_internal = false,
	})
	self.manager:selectLocations()
	self.manager:selectLocation(location.id)
end

function Locations:deleteLocation(id)
	self.manager:deleteLocation(id)
	self.manager:selectLocations()
	local locs = self:getLocations()
	self.manager:selectLocation(locs[#locs].id)
	self.game.selectModel:noDebouncePullNoteChartSet()
end

function Locations:selectLocation(id)
	self.manager:selectLocation(id)
end

function Locations:deleteChartCache()
	local c = self.game.cacheModel
	c.chartfilesRepo:deleteChartfiles()
	c.chartfilesRepo:deleteChartfileSets()
	c.chartmetasRepo:deleteChartmetas()
	c.chartdiffsRepo:deleteChartdiffs()
end

return Locations
