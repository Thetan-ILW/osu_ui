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

function Locations:loadLocations()
	self.manager:selectLocations()
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

---@param name string
function Locations:changeName(name)
	local id = self:getSelectedLocationId()
	self.repo:updateLocation({
		id = id,
		name = name,
	})
	self.manager:selectLocations()
	self.manager:selectLocation(id)
end

---@param path string
function Locations:changePath(path)
	self.manager:updateLocationPath(path)
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

---@param id integer
function Locations:deleteLocation(id)
	self.manager:deleteLocation(id)
	self.manager:selectLocations()
	local locs = self:getLocations()
	self.manager:selectLocation(locs[#locs].id)
	self.game.selectModel:noDebouncePullNoteChartSet()
end

---@param id integer
function Locations:selectLocation(id)
	self.manager:selectLocation(id)
end

function Locations:deleteChartCache()
	local c = self.game.cacheModel
	c.chartfilesRepo:deleteChartfiles()
	c.chartfilesRepo:deleteChartfileSets()
	c.chartsRepo:deleteChartmetas()
	c.chartsRepo:deleteChartdiffs()
end

function Locations:recalculateScores()
	local c = self.game.cacheModel
	c:computeChartplays()
end

---@param id integer
function Locations:updateLocation(id)
	self.game.selectController:updateCacheLocation(id)
end

---@return boolean
function Locations:isProcessingCharts()
	return self.game.cacheModel.isProcessing
end

---@return number chart_count
---@return number charts_processed
function Locations:getProcessingInfo()
	local count = self.game.cacheModel.shared.chartfiles_count
	local current = self.game.cacheModel.shared.chartfiles_current
	return count, current
end

return Locations
