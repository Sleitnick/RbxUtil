-- -----------------------------------------------------------------------------
--               Batched Yield-Safe Signal Implementation                     --
-- This is a Signal class which has effectively identical behavior to a       --
-- normal RBXScriptSignal, with the only difference being a couple extra      --
-- stack frames at the bottom of the stack trace when an error is thrown.     --
-- This implementation caches runner coroutines, so the ability to yield in   --
-- the signal handlers comes at minimal extra cost over a naive signal        --
-- implementation that either always or never spawns a thread.                --
--                                                                            --
-- API:                                                                       --
--   local Signal = require(THIS MODULE)                                      --
--   local sig = Signal.new()                                                 --
--   local connection = sig:Connect(function(arg1, arg2, ...) ... end)        --
--   sig:Fire(arg1, arg2, ...)                                                --
--   connection:Disconnect()                                                  --
--   sig:DisconnectAll()                                                      --
--   local arg1, arg2, ... = sig:Wait()                                       --
--                                                                            --
-- License:                                                                   --
--   Licensed under the MIT license.                                          --
--                                                                            --
-- Authors:                                                                   --
--   stravant - July 31st, 2021 - Created the file.                           --
--   sleitnick - August 3rd, 2021 - Modified for Knit.                        --
-- -----------------------------------------------------------------------------

export type Type<T...> = {
	Connect: (Type<T...>, func: (T...) -> ()) -> Connection<T...>,
	Fire: (Type<T...>, T...) -> (),
	FireDeferred: (Type<T...>, T...) -> (),
	Wait: (Type<T...>) -> (T...),
	GetConnections: (Type<T...>) -> {Connection<T...>},
	DisconnectAll: (Type<T...>) -> (),
	Destroy: (Type<T...>) -> (),

	_handlerListHead: any,
	_proxyHandler: any,
}

type Connection<T...> = {
	Disconnect: (Connection<T...>) -> (),
	Destroy: (Connection<T...>) -> (),
}

-- The currently idle thread to run the next handler on
local freeRunnerThread = nil

-- Function which acquires the currently idle handler runner thread, runs the
-- function fn on it, and then releases the thread, returning it to being the
-- currently idle one.
-- If there was a currently idle runner thread already, that's okay, that old
-- one will just get thrown and eventually GCed.
local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
end

-- Coroutine runner that we create coroutines of. The coroutine can be 
-- repeatedly resumed with functions to run followed by the argument to run
-- them with.
local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end


-- Connection class
local Connection = {}
Connection.__index = Connection


function Connection.new<T...>(signal, fn: (T...) -> ())
	return setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Connection)
end


function Connection:Disconnect()
	if not self._connected then return end
	self._connected = false

	-- Unhook the node, but DON'T clear it. That way any fire calls that are
	-- currently sitting on this node will be able to iterate forwards off of
	-- it, but any subsequent fire calls will not hit it, and it will be GCed
	-- when no more fire calls are sitting on it.
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

Connection.Destroy = Connection.Disconnect

-- Make Connection strict
--[[setmetatable(Connection, {
	__index = function(_tb, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_tb, key, _value)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end
})]]
table.freeze(Connection)


--[=[
	@class Signal

	Signals allow events to be dispatched and handled.

	For example:
	```lua
	local signal = Signal.new()

	signal:Connect(function(msg)
		print("Got message:", msg)
	end)

	signal:Fire("Hello world!")
	```
]=]
local Signal = {}
Signal.__index = Signal

--[=[
	Constructs a new Signal

	@return Signal
]=]
function Signal.new<T...>(): Type<T...>
	local self = setmetatable({
		_handlerListHead = false,
		_proxyHandler = nil,
	}, Signal)
	return self :: Type<T...>
end


--[=[
	Constructs a new Signal that wraps around an RBXScriptSignal.

	@param rbxScriptSignal RBXScriptSignal -- Existing RBXScriptSignal to wrap
	@return Signal

	For example:
	```lua
	local signal = Signal.Wrap(workspace.ChildAdded)
	signal:Connect(function(part) print(part.Name .. " added") end)
	Instance.new("Part").Parent = workspace
	```
]=]
function Signal.Wrap<T...>(rbxScriptSignal) : Type<T...>
	assert(typeof(rbxScriptSignal) == "RBXScriptSignal", "Argument #1 to Signal.Wrap must be a RBXScriptSignal; got " .. typeof(rbxScriptSignal))
	local signal = Signal.new()
	signal._proxyHandler = rbxScriptSignal:Connect(function(...)
		signal:Fire(...)
	end)
	return signal :: Type<T...>
end


--[=[
	Checks if the given object is a Signal.

	@param obj any -- Object to check
	@return boolean -- `true` if the object is a Signal.
]=]
function Signal.Is(obj): boolean
	return type(obj) == "table" and getmetatable(obj) == Signal
end


--[=[
	Connects a function to the signal, which will be called anytime the signal is fired.

	@param fn (...any) -> nil
	@return Connection -- A connection to the signal
]=]
function Signal:Connect<T...>(fn: (T...) -> ()): Connection<T...>
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection :: Connection<T...>
end


function Signal:GetConnections<T...>(): {Connection<T...>}
	local items = {}
	local item = self._handlerListHead
	while item do
		table.insert(items, item)
		item = item._next
	end
	return items :: {Connection<T...>}
end


-- Disconnect all handlers. Since we use a linked list it suffices to clear the
-- reference to the head handler.
--[=[
	Disconnects all connections from the signal.
]=]
function Signal:DisconnectAll()
	self._handlerListHead = false
end


-- Signal:Fire(...) implemented by running the handler functions on the
-- coRunnerThread, and any time the resulting thread yielded without returning
-- to us, that means that it yielded to the Roblox scheduler and has been taken
-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
--[=[
	Fire the signal, which will call all of the connected functions with the given arguments.

	@param ... any -- Arguments to pass to the connected functions
]=]
function Signal:Fire<T...>(...: T...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end


--[=[
	Same as `Fire`, but uses `task.defer` internally & doesn't take advantage of thread reuse.

	@param ... any -- Arguments to pass to the connected functions
]=]
function Signal:FireDeferred<T...>(...: T...)
	local item = self._handlerListHead
	while item do
		task.defer(item._fn, ...)
		item = item._next
	end
end


--[=[
	Yields the current thread until the signal is fired, and returns the arguments fired from the signal.

	@return ... any -- Arguments passed to the signal when it was fired
	@yields
]=]
function Signal:Wait<T...>(): T...
	local waitingCoroutine = coroutine.running()
	local cn
	cn = (self :: Type<T...>):Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end


--[=[
	Cleans up the signal.
]=]
function Signal:Destroy()
	self:DisconnectAll()
	local proxyHandler = rawget(self, "_proxyHandler")
	if proxyHandler then
		proxyHandler:Disconnect()
	end
	self = nil
end


-- Make signal strict
--[[setmetatable(Signal, {
	__index = function(_tb, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_tb, key, _value)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end
})]]

table.freeze(Signal)

return Signal
