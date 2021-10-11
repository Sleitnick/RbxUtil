-- Touch
-- Stephen Leitnick
-- March 14, 2021

--[[

	touch = Touch.new([janitor: Janitor])

	touch:Destroy()

	touch.TouchTapInWorld(position: Vector2, processed: boolean)
	touch.TouchPan(positions: Vector2[], totalTranslation: Vector2, velocity: Vector2, state: UserInputState, processed: boolean)
	touch.TouchPinch(positions: Vector2[], scale: number, velocity: number, state: UserInputState, processed: boolean)

--]]


local Janitor = require(script.Parent.Parent.Janitor)
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

	self._janitor = Janitor.new()

	self.TouchTapInWorld = self._janitor:Add(Signal.Wrap(UserInputService.TouchTapInWorld))
	self.TouchPan = self._janitor:Add(Signal.Wrap(UserInputService.TouchPan))
	self.TouchPinch = self._janitor:Add(Signal.Wrap(UserInputService.TouchPinch))

	return self

end


--[=[
	Destroys the Touch input capturer.
]=]
function Touch:Destroy()
	self._janitor:Destroy()
end


return Touch
