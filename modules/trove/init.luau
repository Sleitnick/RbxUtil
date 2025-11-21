--!strict
local RunService = game:GetService("RunService")


--[=[
	@class Trove
	A Trove is helpful for tracking any sort of object during
	runtime that needs to get cleaned up at some point.
]=]
local Trove = {}
Trove.__index = Trove

export type Trove = typeof(setmetatable({} :: {
	_objects: { any },
	_cleaning: boolean,
}, Trove))

--[=[
	@within Trove
	@type Trackable<T = any, A... = ...any> Instance | RBXScriptConnection | ConnectionLike<T> | ConnectLikeMetatable<T> | PromiseLike<T> | PromiseLikeMetatable<T> | thread | ((...any) -> ...any) | Destroyable<T> | DestroyableMetatable<T> | DestroyableLowercase<T> | DestroyableLowercaseMetatable<T> | Disconnectable<T> | DisconnectableMetatable<T> | DisconnectableLowercase<T> | DisconnectableLowercaseMetatable<T> | SignalLike<A...> | SignalLikeMetatable<A...>
	Represents all trackable objects by Trove.
]=]
export type Trackable<T = any, A... = ...any> =
	| Instance
	| RBXScriptConnection
	| ConnectionLike<T>
	| ConnectionLikeMetatable<T>
	| PromiseLike<T>
	| PromiseLikeMetatable<T>
	| thread
	| ((...any) -> ...any)
	| Destroyable<T>
	| DestroyableMetatable<T>
	| DestroyableLowercase<T>
	| DestroyableLowercaseMetatable<T>
	| Disconnectable<T>
	| DisconnectableMetatable<T>
	| DisconnectableLowercase<T>
	| DisconnectableLowercaseMetatable<T>
	| SignalLike<A...>
	| SignalLikeMetatable<A...>

--[=[
	@within Trove
	@interface ConnectionLike<T = any>
	.Connected boolean
	.Disconnect (self: T) -> ()
	.Destroy ((self: T) -> ())?
]=]
type ConnectionLike<T = any> = {
	Connected: boolean,
	Disconnect: (self: T) -> (),
	Destroy: ((self: T) -> ())?,
}

--[=[
	@within Trove
	@interface ConnectionLikeMetatable<T = any>
	.Connected boolean
	.Disconnect (self: T) -> ()
	.Destroy ((self: T) -> ())?
	@tag Metatable
]=]
type ConnectionLikeMetatable<T = any> = typeof(setmetatable({}, {} :: ConnectionLike<T>))

--[=[
	@within Trove
	@interface SignalLike<T... = ...any>
	.Connect (self: any, callback: (T...) -> ()) -> ConnectionLike
	.Once (self: any, callback: (T...) -> ()) -> ConnectionLike
]=]
type SignalLike<T... = ...any> = {
	Connect: (self: any, callback: (T...) -> ()) -> ConnectionLike,
	Once: (self: any, callback: (T...) -> ()) -> ConnectionLike,
}

--[=[
	@within Trove
	@interface SignalLikeMetatable<T... = ...any>
	.Connect (self: SignalLikeMetatable<T...>, callback: (T...) -> ()) -> ConnectionLike
	.Once (self: SignalLikeMetatable<T...>, callback: (T...) -> ()) -> ConnectionLike
	@tag Metatable
]=]
type SignalLikeMetatable<T... = ...any> = typeof(setmetatable({}, {} :: {
	Connect: (self: SignalLikeMetatable<T...>, callback: (T...) -> ()) -> ConnectionLike,
	Once: (self: SignalLikeMetatable<T...>, callback: (T...) -> ()) -> ConnectionLike,
}))

--[=[
	@within Trove
	@type PromiseLikeStatus
]=]
type PromiseLikeStatus =
	| "Started"
	| "Resolved"
	| "Rejected"
	| "Cancelled"
	| string

--[=[
	@within Trove
	@interface PromiseLike<T = any>
	.getStatus (self: T) -> string | "Started" | "Resolved" | "Rejected" | "Cancelled"
	.finally (self: T, callback: (...any) -> ...any) -> T
	.cancel (self: T) -> ()
]=]
type PromiseLike<T = any> = {
	getStatus: (self: T) -> PromiseLikeStatus,
	finally: (self: T, callback: (...any) -> ...any) -> T,
	cancel: (self: T) -> (),
}

--[=[
	@within Trove
	@interface PromiseLikeMetatable<T = any>
	.getStatus (self: T) -> string | "Started" | "Resolved" | "Rejected" | "Cancelled"
	.finally (self: T, callback: (...any) -> ...any) -> T
	.cancel (self: T) -> ()
	@tag Metatable
]=]
type PromiseLikeMetatable<T = any> = typeof(setmetatable({}, {} :: PromiseLike<T>))

--[=[
	@within Trove
	@type Constructable<T = any, A... = ...any> { new: (A...) -> T }
]=]
type Constructable<T = any, A... = ...any> = { new: (A...) -> T } | (A...) -> T

--[=[
	@within Trove
	@interface Destroyable<T = any>
	.Destroy (self: T) -> ()
]=]
type Destroyable<T = any> = {
	Destroy: (self: T) -> (),
}

--[=[
	@within Trove
	@interface DestroyableMetatable<T = any>
	.Destroy (self: T) -> ()
]=]
type DestroyableMetatable<T = any> = typeof(setmetatable({}, {} :: Destroyable<T>))

--[=[
	@within Trove
	@interface DestroyableLowercase<T = any>
	.destroy (self: T) -> ()
]=]
type DestroyableLowercase<T = any> = {
	destroy: (self: T) -> (),
}

--[=[
	@within Trove
	@interface DestroyableLowercaseMetatable<T = any>
	.destroy (self: T) -> ()
]=]
type DestroyableLowercaseMetatable<T = any> = typeof(setmetatable({}, {} :: DestroyableLowercase<T>))

--[=[
	@within Trove
	@interface Disconnectable<T = any>
	.Disconnect (self: T) -> ()
]=]
type Disconnectable<T = any> = {
	Disconnect: (self: T) -> (),
}

--[=[
	@within Trove
	@interface DisconnectableMetatable<T = any>
	.Disconnect (self: T) -> ()
]=]
type DisconnectableMetatable<T = any> = typeof(setmetatable({}, {} :: Disconnectable<T>))

--[=[
	@within Trove
	@interface DisconnectableLowercase<T = any>
	.disconnect (self: T) -> ()
]=]
type DisconnectableLowercase<T = any> = {
	disconnect: (self: T) -> (),
}

--[=[
	@within Trove
	@interface DisconnectableLowercaseMetatable<T = any>
	.disconnect (self: T) -> ()
]=]
type DisconnectableLowercaseMetatable<T = any> = typeof(setmetatable({}, {} :: DisconnectableLowercase<T>))

--[=[
	@within Trove
	@interface Cloneable<T = any>
	.Clone (self: T) -> T
]=]
type Cloneable<T = any> = {
	Clone: (self: T) -> T,
}

--[=[
	@within Trove
	@interface CloneableMetatable<T = any>
	.Clone (self: T) -> T
]=]
type CloneableMetatable<T = any> = typeof(setmetatable({}, {} :: Cloneable<T>))


local FN_MARKER = newproxy()
local THREAD_MARKER = newproxy()
local GENERIC_OBJECT_CLEANUP_METHODS = table.freeze({ "Destroy", "Disconnect", "destroy", "disconnect" })

local function getObjectCleanupFunction(object: any, cleanupMethod: string?)
	local t = typeof(object)

	if t == "function" then
		return FN_MARKER
	elseif t == "thread" then
		return THREAD_MARKER
	end

	if cleanupMethod then
		return cleanupMethod
	end

	if t == "Instance" then
		return "Destroy"
	elseif t == "RBXScriptConnection" then
		return "Disconnect"
	elseif t == "table" then
		for _, genericCleanupMethod in GENERIC_OBJECT_CLEANUP_METHODS do
			if typeof(object[genericCleanupMethod]) == "function" then
				return genericCleanupMethod
			end
		end
	end

	error(`failed to get cleanup function for object {t}: {object}`, 3)
end

local function assertPromiseLike(object: any)
	if
		typeof(object) ~= "table"
		or typeof(object.getStatus) ~= "function"
		or typeof(object.finally) ~= "function"
		or typeof(object.cancel) ~= "function"
	then
		error("did not receive a promise as an argument", 3)
	end
end

local function assertSignalLike(object: any)
	if
		typeof(object) ~= "RBXScriptSignal"
		and (typeof(object) ~= "table" or typeof(object.Connect) ~= "function" or typeof(object.Once) ~= "function")
	then
		error("did not receive a signal as an argument", 3)
	end
end

--[=[
	@return Trove
	Constructs a Trove object.

	```lua
	local trove = Trove.new()
	```
]=]
function Trove.new(): Trove
	local self = setmetatable({
		_objects = {},
		_cleaning = false,
	}, Trove)

	return self
end

--[=[
	@method Add
	@within Trove
	@param object Trackable<T> -- Object to track
	@param cleanupMethod string? -- Optional cleanup name override
	@return object: T
	Adds an object to the trove. Once the trove is cleaned or
	destroyed, the object will also be cleaned up.

	The following types are accepted (e.g. `typeof(object)`):

	| Type | Cleanup |
	| ---- | ------- |
	| `Instance` | `object:Destroy()` |
	| `RBXScriptConnection` | `object:Disconnect()` |
	| `function` | `object()` |
	| `thread` | `task.cancel(object)` |
	| `table` | `object:Destroy()` _or_ `object:Disconnect()` _or_ `object:destroy()` _or_ `object:disconnect()` |
	| `table` with `cleanupMethod` | `object:<cleanupMethod>()` |

	Returns the object added.

	```lua
	-- Add a part to the trove, then destroy the trove,
	-- which will also destroy the part:
	local part = Instance.new("Part")
	trove:Add(part)
	trove:Destroy()

	-- Add a function to the trove:
	trove:Add(function()
		print("Cleanup!")
	end)
	trove:Destroy()

	-- Standard cleanup from table:
	local tbl = {}
	function tbl:Destroy()
		print("Cleanup")
	end
	trove:Add(tbl)

	-- Custom cleanup from table:
	local tbl = {}
	function tbl:DoSomething()
		print("Do something on cleanup")
	end
	trove:Add(tbl, "DoSomething")
	```
]=]
function Trove.Add<T>(self: Trove, object: Trackable<T>, cleanupMethod: string?): T
	if self._cleaning then
		error("cannot call trove:Add() while cleaning", 2)
	end

	local cleanup = getObjectCleanupFunction(object, cleanupMethod)
	table.insert(self._objects, { object, cleanup })

	return object :: any
end

--[=[
	@method Clone
	@within Trove
	@param object Instance | Cloneable<T> | CloneableMetatable<T>
	@return T
	Clones the given object and adds it to the trove. Shorthand for
	`trove:Add(object:Clone())`.

	```lua
	local clonedPart = trove:Clone(somePart)
	```
]=]
function Trove.Clone<T>(self: Trove, object: Instance | Cloneable<T> | CloneableMetatable<T>): T
	if self._cleaning then
		error("cannot call trove:Clone() while cleaning", 2)
	end

	return self:Add((object :: any):Clone())
end

--[=[
	@method Construct
	@within Trove
	@param class { new(Args...) -> T } | (Args...) -> T
	@param ... Args...
	@return T
	Constructs a new object from either the
	table or function given.

	If a table is given, the table's `new`
	function will be called with the given
	arguments.

	If a function is given, the function will
	be called with the given arguments.

	The result from either of the two options
	will be added to the trove.

	This is shorthand for `trove:Add(SomeClass.new(...))`
	and `trove:Add(SomeFunction(...))`.

	```lua
	local Signal = require(somewhere.Signal)

	-- All of these are identical:
	local s = trove:Construct(Signal)
	local s = trove:Construct(Signal.new)
	local s = trove:Construct(function() return Signal.new() end)
	local s = trove:Add(Signal.new())

	-- Even Roblox instances can be created:
	local part = trove:Construct(Instance, "Part")
	```
]=]
function Trove.Construct<T, A...>(self: Trove, class: Constructable<T, A...>, ...: A...): T
	if self._cleaning then
		error("Cannot call trove:Construct() while cleaning", 2)
	end

	local object = if type(class) == "table"
		then class.new(...)
		else class(...)
	
	return self:Add(object :: any)
end

--[=[
	@method Connect
	@within Trove
	@param signal RBXScriptSignal
	@param fn (...: any) -> ()
	@return RBXScriptConnection
	Connects the function to the signal, adds the connection
	to the trove, and then returns the connection.

	This is shorthand for `trove:Add(signal:Connect(fn))`.

	```lua
	trove:Connect(workspace.ChildAdded, function(instance)
		print(instance.Name .. " added to workspace")
	end)
	```
]=]
function Trove.Connect<T...>(
	self: Trove,
	signal: SignalLike<T...> | SignalLikeMetatable<T...> | RBXScriptSignal<T...>,
	fn: (T...) -> ()
): ConnectionLike
	if self._cleaning then
		error("Cannot call trove:Connect() while cleaning", 2)
	end

	assertSignalLike(signal)
	local confirmedSignal = signal :: SignalLike<T...>

	return self:Add(confirmedSignal:Connect(fn))
end

--[=[
	@method Once
	@within Trove
	@param signal RBXScriptSignal
	@param fn (...: any) -> ()
	@return RBXScriptConnection
	Connects the function to the signal using the `Once`
	method, adds the connection to the trove, and then
	returns the connection.

	This is shorthand for `trove:Add(signal:Once(fn))`.

	```lua
	trove:Connect(workspace.ChildAdded, function(instance)
		print(instance.Name .. " added to workspace")
	end)
	```
]=]
function Trove.Once<T...>(
	self: Trove,
	signal: SignalLike<T...> | SignalLikeMetatable<T...> | RBXScriptSignal<T...>,
	fn: (T...) -> ()
): ConnectionLike
	if self._cleaning then
		error("Cannot call trove:Connect() while cleaning", 2)
	end
	assertSignalLike(signal)

	local confirmedSignal = signal :: SignalLike<T...>

	local conn
	conn = confirmedSignal:Once(function(...)
		fn(...)
		self:Pop(conn)
	end)

	return self:Add(conn)
end

--[=[
	@method BindToRenderStep
	@within Trove
	@param name string
	@param priority number
	@param fn (dt: number) -> ()
	Calls `RunService:BindToRenderStep` and registers a function in the
	trove that will call `RunService:UnbindFromRenderStep` on cleanup.

	```lua
	trove:BindToRenderStep("Test", Enum.RenderPriority.Last.Value, function(dt)
		-- Do something
	end)
	```
]=]
function Trove.BindToRenderStep(self: Trove, name: string, priority: number, fn: (dt: number) -> ())
	if self._cleaning then
		error("cannot call trove:BindToRenderStep() while cleaning", 2)
	end

	RunService:BindToRenderStep(name, priority, fn)

	self:Add(function()
		RunService:UnbindFromRenderStep(name)
	end)
end

--[=[
	@method AddPromise
	@within Trove
	@param promise Promise
	@return Promise
	Gives the promise to the trove, which will cancel the promise if the trove is cleaned up or if the promise
	is removed. The exact promise is returned, thus allowing chaining.

	```lua
	trove:AddPromise(doSomethingThatReturnsAPromise())
		:andThen(function()
			print("Done")
		end)
	-- Will cancel the above promise (assuming it didn't resolve immediately)
	trove:Clean()

	local p = trove:AddPromise(doSomethingThatReturnsAPromise())
	-- Will also cancel the promise
	trove:Remove(p)
	```

	:::caution Promise v4 Only
	This is only compatible with the [roblox-lua-promise](https://eryn.io/roblox-lua-promise/) library, version 4.
	:::
]=]
function Trove.AddPromise<T>(self: Trove, promise: PromiseLike<T>): T
	if self._cleaning then
		error("cannot call trove:AddPromise() while cleaning", 2)
	end

	assertPromiseLike(promise)
	local confirmedPromise = promise :: PromiseLike

	if confirmedPromise:getStatus() == "Started" then
		confirmedPromise:finally(function()
			if self._cleaning then
				return
			end

			self:_findAndRemoveFromObjects(confirmedPromise, false)
		end)

		self:Add(confirmedPromise, "cancel")
	end

	return confirmedPromise :: any
end

--[=[
	@method Remove
	@within Trove
	@param object Trackable<T>
	Removes the object from the Trove and cleans it up. To remove without
	cleaning, use the `Pop` method instead.

	```lua
	local part = Instance.new("Part")
	trove:Add(part)
	trove:Remove(part) -- Part is destroyed
	```
]=]
function Trove.Remove<T>(self: Trove, object: Trackable<T>): boolean
	if self._cleaning then
		error("cannot call trove:Remove() while cleaning", 2)
	end

	return self:_findAndRemoveFromObjects(object, true)
end

--[=[
	@method Pop
	@within Trove
	@param object Trackable<T>
	Removes the object from the Trove, but does _not_ clean it up. To
	clean up the object on removal, use the `Remove` method instead.

	```lua
	local part = Instance.new("Part")
	trove:Add(part)
	trove:Pop(part)
	trove:Clean() -- Part is NOT destroyed
	```
]=]
function Trove.Pop<T>(self: Trove, object: Trackable<T>): boolean
	if self._cleaning then
		error("cannot call trove:Pop() while cleaning", 2)
	end

	return self:_findAndRemoveFromObjects(object, false)
end

--[=[
	@method Extend
	@within Trove
	@return Trove
	Creates and adds another trove to itself. This is just shorthand
	for `trove:Construct(Trove)`. This is useful for contexts where
	the trove object is present, but the class itself isn't.

	:::note
	This does _not_ clone the trove. In other words, the objects in the
	trove are not given to the new constructed trove. This is simply to
	construct a new Trove and add it as an object to track.
	:::

	```lua
	local trove = Trove.new()
	local subTrove = trove:Extend()

	trove:Clean() -- Cleans up the subTrove too
	```
]=]
function Trove.Extend(self: Trove): Trove
	if self._cleaning then
		error("cannot call trove:Extend() while cleaning", 2)
	end

	return self:Construct(Trove)
end

--[=[
	@method Clean
	@within Trove
	Cleans up all objects in the trove. This is
	similar to calling `Remove` on each object
	within the trove. The ordering of the objects
	removed is _not_ guaranteed.

	```lua
	trove:Clean()
	```
]=]
function Trove.Clean(self: Trove)
	if self._cleaning then
		return
	end

	self._cleaning = true

	for _, obj in self._objects do
		self:_cleanupObject(obj[1], obj[2])
	end

	table.clear(self._objects)
	self._cleaning = false
end

--[=[
	@method WrapClean
	@within Trove
	Returns a function that wraps the trove's `Clean()`
	method. Calling the returned function will clean up
	the trove.

	This is often useful in contexts where functions
	are the primary mode for cleaning up an environment,
	such as in many "observer" patterns.

	```lua
	local cleanup = trove:WrapClean()

	-- Sometime later...
	cleanup()
	```

	```lua
	-- Common observer pattern example:
	someObserver(function()
		local trove = Trove.new()
		-- Foo
		return trove:WrapClean()
	end)
	```
]=]
function Trove.WrapClean(self: Trove)
	return function()
		self:Clean()
	end
end

--- INTERNAL FUNCTION, DO NOT USE!
--  FIXME: Just make this a local function if it isn't used elsewhere? Is it used for testing?
function Trove._findAndRemoveFromObjects(self: Trove, object: any, cleanup: boolean): boolean
	local objects = self._objects

	for i, obj in objects do
		if obj[1] == object then
			local n = #objects
			objects[i] = objects[n]
			objects[n] = nil

			if cleanup then
				self:_cleanupObject(obj[1], obj[2])
			end

			return true
		end
	end

	return false
end

--- INTERNAL FUNCTION, DO NOT USE!
--  FIXME: Just make this a local function if it isn't used elsewhere? Is it used for testing?
function Trove._cleanupObject(_self: any, object: any, cleanupMethod: string?)
	if cleanupMethod == FN_MARKER then
		task.spawn(object)
	elseif cleanupMethod == THREAD_MARKER then
		pcall(task.cancel, object)
	else
		object[cleanupMethod](object)
	end
end

--[=[
	@method AttachToInstance
	@within Trove
	@param instance Instance
	@return RBXScriptConnection
	Attaches the trove to a Roblox instance. Once this
	instance is removed from the game (parent or ancestor's
	parent set to `nil`), the trove will automatically
	clean up.

	This inverses the ownership of the Trove object, and should
	only be used when necessary. In other words, the attached
	instance dictates when the trove is cleaned up, rather than
	the trove dictating the cleanup of the instance.

	:::caution
	Will throw an error if `instance` is not a descendant
	of the game hierarchy.
	:::

	```lua
	trove:AttachToInstance(somePart)
	trove:Add(function()
		print("Cleaned")
	end)

	-- Destroying the part will cause the trove to clean up, thus "Cleaned" printed:
	somePart:Destroy()
	```
]=]
function Trove.AttachToInstance(self: Trove, instance: Instance)
	if self._cleaning then
		error("cannot call trove:AttachToInstance() while cleaning", 2)
	elseif not instance:IsDescendantOf(game) then
		error("instance is not a descendant of the game hierarchy", 2)
	end

	return self:Connect(instance.Destroying, function()
		self:Destroy()
	end)
end

--[=[
	@method Destroy
	@within Trove
	Alias for `trove:Clean()`.

	```lua
	trove:Destroy()
	```
]=]
function Trove.Destroy(self: Trove)
	self:Clean()
end

return {
	new = Trove.new,
}
