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
	@prop TouchTap Signal<(touchPositions: {Vector2}, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchTap](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchTap).
]=]
--[=[
	@within Touch
	@prop TouchTapInWorld Signal<(position: Vector2, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchTapInWorld](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchTapInWorld).
]=]
--[=[
	@within Touch
	@prop TouchMoved Signal<(touch: InputObject, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchMoved](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchMoved).
]=]
--[=[
	@within Touch
	@prop TouchLongPress Signal<(touchPositions: {Vector2}, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchLongPress](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchLongPress).
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
	@within Touch
	@prop TouchRotate Signal<(touchPositions: {Vector2}, rotation: number, velocity: number, state: Enum.UserInputState, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchRotate](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchRotate).
]=]
--[=[
	@within Touch
	@prop TouchSwipe Signal<(swipeDirection: Enum.SwipeDirection, numberOfTouches: number, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchSwipe](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchSwipe).
]=]
--[=[
	@within Touch
	@prop TouchStarted Signal<(touch: InputObject, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchStarted](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchStarted).
]=]
--[=[
	@within Touch
	@prop TouchEnded Signal<(touch: InputObject, processed: boolean)>
	@tag Event
	Proxy for [UserInputService.TouchEnded](https://developer.roblox.com/en-us/api-reference/event/UserInputService/TouchEnded).
]=]


--[=[
	Constructs a new Touch input capturer.
]=]
function Touch.new()

	local self = setmetatable({}, Touch)

	self._trove = Trove.new()

	self.TouchTap = self._trove:Construct(Signal.Wrap, UserInputService.TouchTap)
	self.TouchTapInWorld = self._trove:Construct(Signal.Wrap, UserInputService.TouchTapInWorld)
	self.TouchMoved = self._trove:Construct(Signal.Wrap, UserInputService.TouchMoved)
	self.TouchLongPress = self._trove:Construct(Signal.Wrap, UserInputService.TouchLongPress)
	self.TouchPan = self._trove:Construct(Signal.Wrap, UserInputService.TouchPan)
	self.TouchPinch = self._trove:Construct(Signal.Wrap, UserInputService.TouchPinch)
	self.TouchRotate = self._trove:Construct(Signal.Wrap, UserInputService.TouchRotate)
	self.TouchSwipe = self._trove:Construct(Signal.Wrap, UserInputService.TouchSwipe)
	self.TouchStarted = self._trove:Construct(Signal.Wrap, UserInputService.TouchStarted)
	self.TouchEnded = self._trove:Construct(Signal.Wrap, UserInputService.TouchEnded)

	return self

end


--[=[
	Returns the value of [`UserInputService.TouchEnabled`](https://developer.roblox.com/en-us/api-reference/property/UserInputService/TouchEnabled).
]=]
function Touch:IsTouchEnabled(): boolean
	return UserInputService.TouchEnabled
end


--[=[
	Destroys the Touch input capturer.
]=]
function Touch:Destroy()
	self._trove:Destroy()
end


return Touch
