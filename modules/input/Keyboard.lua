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
	@prop KeyDown Signal<Enum.KeyCode>
	@tag Event
	Fired when a key is pressed.
	```lua
	keyboard.KeyDown:Connect(function(key: KeyCode)
		print("Key pressed", key)
	end)
	```
]=]
--[=[
	@within Keyboard
	@prop KeyUp Signal<Enum.KeyCode>
	@tag Event
	Fired when a key is released.
	```lua
	keyboard.KeyUp:Connect(function(key: KeyCode)
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
	self.KeyDown = self._trove:Construct(Signal)
	self.KeyUp = self._trove:Construct(Signal)
	self:_setup()
	return self
end


--[=[
	@param keyCode Enum.KeyCode
	@return isDown: boolean

	Returns `true` if the key is down.

	```lua
	local w = keyboard:IsKeyDown(Enum.KeyCode.W)
	if w then ... end
	```
]=]
function Keyboard:IsKeyDown(keyCode)
	return UserInputService:IsKeyDown(keyCode)
end


--[=[
	@param keyCodeOne Enum.KeyCode
	@param keyCodeTwo Enum.KeyCode
	@return areKeysDown: boolean

	Returns `true` if both keys are down. Useful for key combinations.

	```lua
	local shiftA = keyboard:AreKeysDown(Enum.KeyCode.LeftShift, Enum.KeyCode.A)
	if shiftA then ... end
	```
]=]
function Keyboard:AreKeysDown(keyCodeOne, keyCodeTwo)
	return self:IsKeyDown(keyCodeOne) and self:IsKeyDown(keyCodeTwo)
end


function Keyboard:_setup()

	self._trove:Connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.KeyDown:Fire(input.KeyCode)
		end
	end)

	self._trove:Connect(UserInputService.InputEnded, function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.KeyUp:Fire(input.KeyCode)
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
