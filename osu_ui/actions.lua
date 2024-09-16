local utf8 = require("utf8")

local actions = {}

---@enum VimMode
local vimModes = {
	normal = "Normal",
	insert = "Insert",
}

local disabled = false

---@type "vim" | "keyboard"
local inputMode = "keyboard"
---@type VimMode
local vimMode = vimModes.normal

---@type string?
local currentAction = nil
local currentDownAction = nil
local count = ""
local currentVimNode = {}
---@type string?
local text_input_event = nil

local comboActions = {} -- [keyCombo] = action_name
local operationsTree = {} -- [key] = [key, action_name] Tree of keys
local singleKeyActions = {} -- [key] = action_name

local currentConfig = {}

local bufferTime = 0.2
local keyPressTimestamps = {}
local keysDown = {}
local modKeysDown = {}
local modKeysList = {
	lctrl = true,
	rctrl = true,
	lshift = true,
	rshift = true,
	lgui = true,
	lalt = true,
	ralt = true,
}

local modFormat = {
	lctrl = "ctrl",
	rctrl = "ctrl",
	lshift = "shift",
	rshift = "shift",
	lalt = "alt",
	ralt = "alt",
}

local function getComboString(t)
	for i, v in ipairs(t) do
		local formatted = modFormat[v] or v
		t[i] = formatted
	end

	table.sort(t)
	return table.concat(t, "+")
end

---@param osu_config  osu.ui.OsuConfig
function actions.updateActions(osu_config)
	if osu_config.vimMotions then
		inputMode = "vim"
		currentConfig = osu_config.vimKeybinds
	else
		inputMode = "keyboard"
		currentConfig = osu_config.keybinds
	end

	singleKeyActions = {}
	comboActions = {}

	for actionName, action in pairs(currentConfig) do
		if type(action) == "string" then
			singleKeyActions[action] = actionName
		end

		if type(action) == "table" then
			if action.op then
				local keys = action.op
				local node = operationsTree
				for _, key in ipairs(keys) do
					node[key] = node[key] or {}
					node = node[key]
				end
				node.action = actionName
			end

			if action.mod then
				comboActions[getComboString(action.mod)] = actionName
			end
		end
	end

	currentVimNode = operationsTree
end

---@return string?
function actions.getAction()
	return currentAction
end

function actions.getCount()
	return tonumber(count) or 1
end

function actions.resetAction()
	count = ""
	currentAction = nil
end

---@param action string
---@return boolean
function actions.consumeAction(action)
	if currentAction == action then
		actions.resetAction()
		return true
	end

	return false
end

---@return boolean
function actions.isModKeyDown()
	local isDown = false

	for _, down in pairs(modKeysDown) do
		isDown = isDown or down
	end

	return isDown
end

---@return boolean
function actions.isVimMode()
	return "vim" == inputMode
end

---@return VimMode
function actions.getVimMode()
	return vimMode
end

---@param mode VimMode
function actions.setVimMode(mode)
	if mode == vimModes.insert then
		text_input_event = "ignore"
	end
	vimMode = mode
end

---@return boolean
function actions.isInsertMode()
	return vimMode == vimModes.insert
end

function actions.resetInputs()
	modKeysDown = {}
	keysDown = {}
	keyPressTimestamps = {}
	currentAction = nil
end

local function getDownModAction()
	local keys = {}
	local ctrl_down = false

	for k, _ in pairs(modKeysDown) do
		if ctrl_down then
			goto continue
		end

		table.insert(keys, k)

		if k == "lctrl" or k == "rctrl" then
			ctrl_down = true
		end

		::continue::
	end

	for k, _ in pairs(keysDown) do
		table.insert(keys, k)
	end

	return comboActions[getComboString(keys)]
end

local function getDownAction()
	for k, _ in pairs(keysDown) do
		local action = singleKeyActions[k]

		if action then
			return action
		end
	end

	return nil
end

---@param event table
-- Accepts keyboard events and finds which actions is down
function actions.inputChanged(event)
	if disabled then
		return
	end

	local key = event[3]
	local state = event[4]

	if modKeysList[key] then
		modKeysDown[key] = state or nil
	else
		keysDown[key] = state or nil
	end

	if actions.isModKeyDown() then
		currentDownAction = getDownModAction()
		return
	end

	currentDownAction = getDownAction()
end

---@param key string
---@param final boolean?
---@return string?
local function nextInTree(key, final)
	local new_node = currentVimNode[key]

	local action = nil

	if new_node then
		currentVimNode = new_node
	else
		currentVimNode = operationsTree

		if not final then -- makes inputs like "ooi" work
			return nextInTree(key, true)
		end
	end

	if currentVimNode.action then
		action = currentVimNode.action
		currentVimNode = operationsTree
	end

	return action
end

local function getComboAction()
	local keys = {}
	local ctrl_down = false
	local current_time = love.timer.getTime()

	for k, _ in pairs(modKeysDown) do
		if ctrl_down then
			goto continue
		end

		table.insert(keys, k)

		if k == "lctrl" or k == "rctrl" then
			ctrl_down = true
		end

		::continue::
	end

	for key, time in pairs(keyPressTimestamps) do
		if time + bufferTime > current_time then
			table.insert(keys, key)
		else
			keyPressTimestamps[key] = nil
		end
	end

	return comboActions[getComboString(keys)]
end

function actions.keyPressed(event)
	if disabled then
		return
	end

	local key = event[2]
	local repeatt = event[3]

	if not repeatt then
		if tonumber(key) and not actions.isInsertMode() then
			count = count .. key
		end

		if not modKeysList[key] then
			keyPressTimestamps[key] = event.time
		end

		if actions.isModKeyDown() then
			currentAction = getComboAction()
			return
		end

		if inputMode == "keyboard" then
			currentAction = singleKeyActions[key]
			return
		end
	end

	if actions.isInsertMode() and key ~= "escape" then
		return
	end

	if not repeatt then
		local action = nextInTree(key)

		if action then
			currentAction = action
			return
		end

		currentAction = singleKeyActions[key]
	end
end

function actions.textInputEvent(char)
	if text_input_event == "ignore" then
		text_input_event = nil
		return
	end
	text_input_event = char
end

---@param name string
---@return boolean
function actions.isActionDown(name)
	return currentDownAction == name
end

function actions.enable()
	disabled = false
	love.keyboard.setKeyRepeat(true)
end

function actions.disable()
	disabled = true
	love.keyboard.setKeyRepeat(false)
	actions.resetInputs()
end

function actions.isEnabled()
	return not disabled
end

---@param text string
---@param index number
---@return string
---@return string
local function text_split(text, index)
	local _index = utf8.offset(text, index) or 1
	return text:sub(1, _index - 1), text:sub(_index)
end

---@param text string
---@return string
function actions.textRemoveLast(text)
	local index = utf8.len(text) + 1
	local _
	local left, right = text_split(text, index)

	left, _ = text_split(left, utf8.len(left))
	index = math.max(1, index - 1)

	return left .. right
end

---@param text string
---@return boolean
---@return string
function actions.textInput(text)
	if text_input_event == nil then
		return false, text
	end

	if text_input_event == "backspace" then
		text = actions.textRemoveLast(text)
		text_input_event = nil
		return true, text
	end

	text = text .. text_input_event
	text_input_event = nil

	return true, text
end

return actions
