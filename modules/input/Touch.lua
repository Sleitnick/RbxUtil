-- Touch
-- Stephen Leitnick
-- March 14, 2021


local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)

local UserInputService = game:GetService("UserInputService")


--[=[
	@class Touch
	@client

	The Touch class is part of the Input package.

	```lua
	local Touch = require(packages.Input).Touch
	```
]=]
local Touch = {}
Touch.__index = Touch

--[=[
	@within Touch
	@prop TouchTapInWorld Signal<(position: Vector2, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchTapInWorld](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchTapInWorld).
]=]
--[=[
	@within Touch
	@prop TouchPan Signal<(touchPositions: {Vector2}, totalTranslation: Vector2, velocity: Vector2, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchPan](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchPan).
]=]
--[=[
	@within Touch
	@prop TouchPinch Signal<(touchPositions: {Vector2}, scale: number, velocity: Vector2, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchPinch](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchPinch).
]=]


--[=[
	Constructs a new Touch input capturer.
]=]
function Touch.new()

	local self = setmetatable({}, Touch)

	self._trove = Trove.new()

	self.TouchTapInWorld = self._trove:Add(Signal.Wrap(UserInputService.TouchTapInWorld))
	self.TouchPan = self._trove:Add(Signal.Wrap(UserInputService.TouchPan))
	self.TouchPinch = self._trove:Add(Signal.Wrap(UserInputService.TouchPinch))

	return self

end


--[=[
	Destroys the Touch input capturer.
]=]
function Touch:Destroy()
	self._trove:Destroy()
end


return Touch
