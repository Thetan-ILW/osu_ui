local class = require("class")
local ui = require("osu_ui.ui")

local delay = require("delay")

---@class osu.ui.ScreenView
---@operator call: osu.ui.ScreenView
---@field ui osu.ui.UserInterface
---@field gameView osu.ui.GameView
---@field prevView osu.ui.ScreenView
---@field modal osu.ui.Modal?
---@field assetModel osu.ui.AssetModel
---@field assets osu.ui.OsuAssets
---@field notificationView osu.ui.NotificationView
---@field popupView osu.ui.PopupView
---@field cursor osu.ui.CursorView
---@field changingScreen boolean?
local ScreenView = class()

---@param game sphere.GameController
function ScreenView:new(game)
	self.game = game
end

---@param screenName string
---@param force boolean?
function ScreenView:changeScreen(screenName, force)
	if self.modal then
		self.modal.shouldClose = true
	end

	self:beginUnload()

	if force then
		self.gameView:forceSetView(self.ui[screenName])
		return
	end

	self.gameView:setView(self.ui[screenName])
end

---@param modal osu.ui.Modal
function ScreenView:setModal(modal)
	local openedModal = self.modal
	if not openedModal then
		self.modal = modal
		self.modal.mainView = self
		self.modal.notificationView = self.notificationView
		self.modal.alpha = 0

		ui.focus()

		self.modal:show()
		return
	end

	if openedModal.name == modal.name then
		self.modal.shouldClose = true
	end
end

function ScreenView:closeModal()
	if self.modal then
		self.modal.shouldClose = true
	end
end

---@param modal_name string
function ScreenView:openModal(modal_name, ...)
	---@type osu.ui.Modal
	local modal = require(modal_name)(self.game, self.assets, ...)
	self:setModal(modal)
end

function ScreenView:switchModal(modal_name)
	self:closeModal()
	delay.debounce(self, "modalSwitchDebounce", 0.22, self.openModal, self, modal_name)
end

function ScreenView:load() end
function ScreenView:beginUnload() end
function ScreenView:unload() end
function ScreenView:quit() end
function ScreenView:resolutionUpdated() end

---@param event table
function ScreenView:receive(event) end

---@param dt number
function ScreenView:update(dt)
	if self.modal then
		self.modal:update(dt)

		if self.modal.alpha < 0 then
			self.modal = nil
		end
	end
end

function ScreenView:drawModal()
	if self.modal then
		love.graphics.origin()
		love.graphics.setColor({ 0, 0, 0, self.modal.alpha * 0.85 })
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		self.modal:draw(self)
	end
end

function ScreenView:sendQuitSignal()
	if self.game.cacheModel.isProcessing then
		return
	end

	if self.modal then
		self.modal:quit()
		return
	end

	self:quit()
end

function ScreenView:draw() end

return ScreenView
