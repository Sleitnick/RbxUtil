-- Keyboard
-- Stephen Leitnick
-- October 10, 2021


local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)

local UserInputService = game:GetService("UserInputService")


--[=[
	@class Keyboard
	@client

	The Keyboard class is part of the Input package.

	```lua
	local Keyboard = require(packages.Input).Keyboard
	```
]=]
local Keyboard = {}
Keyboard.__index = Keyboard

--[=[
	@within Keyboard
	@prop KeyDown Signal<Enum.KeyCode, boolean>
	@tag Event
	Fired when a key is pressed.
	```lua
	keyboard.KeyDown:Connect(function(key: KeyCode, processed)
		print("Key pressed", key)
	end)
	```
]=]
--[=[
	@within Keyboard
	@prop KeyUp Signal<Enum.KeyCode, boolean>
	@tag Event
	Fired when a key is released.
	```lua
	keyboard.KeyUp:Connect(function(key: KeyCode, processed)
		print("Key released", key)
	end)
	```
]=]


--[=[
	@return Keyboard

	Constructs a new keyboard input capturer.

	```lua
	local keyboard = Keyboard.new()
	```
]=]
function Keyboard.new()
	local self = setmetatable({}, Keyboard)
	self._trove = Trove.new()
	self._keysProcessed = {}
	self._keysDown = {}
	self.KeyDown = self._trove:Construct(Signal)
	self.KeyUp = self._trove:Construct(Signal)
	self:_setup()
	return self
end


--[=[
	@param keyCode Enum.KeyCode
	@return isDown: boolean
    @return isProcessed: boolean

	Returns `true` if the key is down, and also returns another boolean indicating if the keycode
	was processed by the game engine or not.

	```lua
	local w, isProcessed = keyboard:IsKeyDown(Enum.KeyCode.W)
	if w and not isProcessed then ... end
	```
]=]
function Keyboard:IsKeyDown(keyCode)
	return self._keysDown[keyCode] == true, self._keysProcessed[keyCode]
end

--[=[
	@param keycodes table
	@return areAllKeysDown: boolean

	Returns `true` if all keys in `keycodes` are down.

	```lua
	local areAllDown = keyboard:AreAllKeysDown({Enum.KeyCode.LeftShift, Enum.KeyCode.A})
	if areAllDown then ... end
	```
]=]

function Keyboard:AreAllKeysDown(keycodes)
	for _, keycode in ipairs(keycodes) do
		local down, processed  =  self:IsKeyDown(keycode)
		
		if not down or processed then
			return false
		end
	end

	return true
end		

--[=[
	@param keycodes table
	@return areAnyKeysDown: boolean
	@return processed: boolean

	Returns `true` if any keys in `keycodes` are down.

	```lua
	local areAnyDown = keyboard:AreAnyKeysDown({Enum.KeyCode.LeftShift, Enum.KeyCode.A})
	if areAnyDown then ... end
	```
]=]

function Keyboard:AreAnyKeysDown(keycodes)
	for _, keycode in ipairs(keycodes) do
		local down, processed  =  self:IsKeyDown(keycode)
		
		if not down or processed then
			continue
		end
	end

	return true
end		

function Keyboard:_setup()

	self._trove:Connect(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.KeyDown:Fire(input.KeyCode, processed)
			self._keysProcessed[input.KeyCode] = processed
			self._keysDown[input.KeyCode] = true				
		end
	end)

	self._trove:Connect(UserInputService.InputEnded, function(input, processed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.KeyUp:Fire(input.KeyCode, processed)
			self._keysProcessed[input.KeyCode] = false
			self._keysDown[input.KeyCode] = false
		end
	end)
end


--[=[
	Destroy the keyboard input capturer.
]=]
function Keyboard:Destroy()
	self._trove:Destroy()
end


return Keyboard
