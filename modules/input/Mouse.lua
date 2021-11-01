-- Mouse
-- Stephen Leitnick
-- November 07, 2020


local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)

local UserInputService = game:GetService("UserInputService")

local RAY_DISTANCE = 1000

--[=[
	@class Mouse
	@client

	The Mouse class is part of the Input package.

	```lua
	local Mouse = require(packages.Input).Mouse
	```
]=]
local Mouse = {}
Mouse.__index = Mouse

--[=[
	@within Mouse
	@prop LeftDown Signal
	@tag Event
]=]
--[=[
	@within Mouse
	@prop LeftUp Signal
	@tag Event
]=]
--[=[
	@within Mouse
	@prop RightDown Signal
	@tag Event
]=]
--[=[
	@within Mouse
	@prop RightUp Signal
	@tag Event
]=]
--[=[
	@within Mouse
	@prop Scrolled Signal<number>
	@tag Event
	```lua
	mouse.Scrolled:Connect(function(scrollAmount) ... end)
	```
]=]


--[=[
	@return Mouse

	Constructs a new mouse input capturer.

	```lua
	local mouse = Mouse.new()
	```
]=]
function Mouse.new()

	local self = setmetatable({}, Mouse)

	self._trove = Trove.new()

	self.LeftDown = self._trove:Construct(Signal)
	self.LeftUp = self._trove:Construct(Signal)
	self.RightDown = self._trove:Construct(Signal)
	self.RightUp = self._trove:Construct(Signal)
	self.Scrolled = self._trove:Construct(Signal)

	self._trove:Connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.LeftDown:Fire()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.RightDown:Fire()
		end
	end)

	self._trove:Connect(UserInputService.InputEnded, function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.LeftUp:Fire()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.RightUp:Fire()
		end
	end)

	self._trove:Connect(UserInputService.InputChanged, function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			self.Scrolled:Fire(input.Position.Z)
		end
	end)

	return self

end


--[=[
	@return isLeftDown: boolean
]=]
function Mouse:IsLeftDown()
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end


--[=[
	@return isRightDown: boolean
]=]
function Mouse:IsRightDown()
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end


--[=[
	@return screenPosition: Vector2

	Gets the 2D mouse position on the screen.
]=]
function Mouse:GetPosition()
	return UserInputService:GetMouseLocation()
end


--[=[
	@return deltaScreenPosition: Vector2

	:::info Only When Mouse Locked
	Getting the mouse delta is only intended for when the mouse is locked. If the
	mouse is _not_ locked, this will return a zero Vector2. The mouse can be locked
	using the `mouse:Lock()` and `mouse:LockCenter()` method.
]=]
function Mouse:GetDelta()
	return UserInputService:GetMouseDelta()
end


--[=[
	@param overridePos Vector2?
	@return viewportMouseRay: Ray

	Returns the viewport point ray for the mouse at the current mouse
	position (or the override position if provided).
]=]
function Mouse:GetRay(overridePos)
	local mousePos = overridePos or UserInputService:GetMouseLocation()
	local viewportMouseRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
	return viewportMouseRay
end


--[=[
	@param raycastParams RaycastParams
	@param distance number?
	@param overridePos Vector2?
	@return result: RaycastResult?

	Performs a raycast operation out from the mouse position (or the
	`overridePos` if provided) into world space. The ray will go
	`distance` studs forward (or 1000 studs if not provided).

	Returns the `RaycastResult` if something was hit, else returns `nil`.
]=]
function Mouse:Raycast(raycastParams, distance, overridePos)
	local viewportMouseRay = self:GetRay(overridePos)
	local result = workspace:Raycast(viewportMouseRay.Origin, viewportMouseRay.Direction * (distance or RAY_DISTANCE), raycastParams)
	return result
end


--[=[
	Locks the mouse in its current position on screen. Call `mouse:Unlock()`
	to unlock the mouse.

	:::caution Must explicitly unlock
	Be sure to explicitly call `mouse:Unlock()` before cleaning up the mouse.
	The `Destroy` method does _not_ unlock the mouse since there is no way
	to guarantee who "owns" the mouse lock.
]=]
function Mouse:Lock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end


--[=[
	Locks the mouse in the center of the screen. Call `mouse:Unlock()`
	to unlock the mouse.

	:::caution Must explicitly unlock
	See cautionary in `Lock` method above.
]=]
function Mouse:LockCenter()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end


--[=[
	Unlocks the mouse.
]=]
function Mouse:Unlock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end


--[=[
	Destroys the mouse.
]=]
function Mouse:Destroy()
	self._trove:Destroy()
end


return Mouse
