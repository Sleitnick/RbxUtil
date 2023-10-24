export type Sequent<T> = {
	Fire: (self: Sequent<T>, T) -> (),
	Connect: (self: Sequent<T>, callback: (SequentEvent<T>) -> ()) -> SequentConnection,
	Once: (self: Sequent<T>, callback: (SequentEvent<T>) -> ()) -> SequentConnection,
	Cancel: (self: Sequent<T>) -> (),
	Destroy: (self: Sequent<T>) -> (),
}

--[=[
	@interface SequentConnection
	@within Sequent
	.Connected boolean
	.Disconnect (self: SequentConnection) -> ()

	```lua
	print(sequent.Connected)
	sequent:Disconnect()
	```
]=]
export type SequentConnection = {
	Connected: boolean,
	Disconnect: (self: SequentConnection) -> (),
}

--[=[
	@interface SequentEvent<T>
	@within Sequent
	.Value T
	.Cancellable boolean
	.Cancel (self: SequentEvent<T>) -> ()

	Events are passed to connected callbacks when sequents are fired. Events
	can be cancelled as well, which prevents the event from propagating to
	other connected callbacks during the same firing. This can be used to
	sink events if desired.

	```lua
	sequent:Connect(function(event)
		print(event.Value)
		event:Cancel()
	end, 0)
	```
]=]
export type SequentEvent<T> = {
	Value: T,
	Cancellable: boolean,
	Cancel: (self: SequentEvent<T>) -> (),
}

type InternalSequentConnection = SequentConnection & {
	_priority: number,
	_sequent: Sequent<unknown>,
}

-----------------------------------------------------------------------------
-- Connection
local SequentConnection = {}
SequentConnection.__index = SequentConnection

function SequentConnection:Disconnect()
	self._sequent:_disconnect(self)
end

-----------------------------------------------------------------------------
-- Sequent

--[=[
	@interface Priority
	@within Sequent
	.Highest math.huge
	.High 1000
	.Normal 0
	.Low -1000
	.Lowest -math.huge

	```lua
	sequent:Connect(fn, Sequent.Priority.Highest)
	```
]=]
local Priority = {
	Highest = math.huge,
	High = 1000,
	Normal = 0,
	Low = -1000,
	Lowest = -math.huge,
}

--[=[
	@class Sequent

	Sequent is a signal-like structure that executes connections in a serial nature. Each
	connection must fully complete before the next is run. Connections can be prioritized
	and cancelled.

	```lua
	local sequent = Sequent.new()

	sequent:Connect(
		function(event)
			print("Got value", event.Value)
			event:Cancel()
		end,
		Sequent.Priority.Highest,
	)

	sequent:Connect(
		function(event)
			print("This won't print!")
		end,
		Sequent.Priority.Lowest,
	)

	sequent:Fire("Test")
	```
]=]
local Sequent = {}
Sequent.__index = Sequent

--[=[
	Constructs a new Sequent. If `cancellable` is `true`, then
	connected handlers can cancel event propagation.
]=]
function Sequent.new<T>(cancellable: boolean?): Sequent<T>
	local self = setmetatable({
		_connections = {},
		_firing = false,
		_queuedDisconnect = false,

		_firingThread = nil,
		_taskThread = nil,

		_cancellable = not not cancellable,
	}, Sequent)

	return self
end

--[=[
	@yields
	Fires the Sequent with the given value.

	This method will yield until all connections complete. Errors will
	bubble up if they occur within a connection.
]=]
function Sequent:Fire<T>(value: T)
	assert(not self._firing, "cannot fire while already firing")
	self._firing = true

	local cancelled = false
	local event: SequentEvent<T> = table.freeze({
		Value = value,
		Cancellable = self._cancellable,
		Cancel = function(evt)
			if not self._cancellable then
				return
			end
			cancelled = true
		end,
	})

	local thread = coroutine.running()
	self._firingThread = thread
	for _, connection in self._connections do
		if not connection.Connected then
			continue
		end

		-- Run the task:
		local success, err = nil, nil
		local taskThread = task.spawn(function()
			self._taskThread = coroutine.running()

			local s, e = pcall(function()
				connection._callback(event)
			end)

			self._taskThread = nil

			-- Resume the parent thread if it yielded:
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, s, e)
			else
				success, err = s, e
			end
		end)

		-- If the task thread yielded, yield this thread too:
		if success == nil then
			success, err = coroutine.yield()
		end

		self._firingThread = nil

		-- Throw error if the task failed:
		if not success then
			error(debug.traceback(taskThread, tostring(err)))
		end

		if cancelled then
			break
		end
	end

	-- If connections were disconnected while firing connections, disconnect them now:
	if self._queuedDisconnect then
		self._queuedDisconnect = false
		for i = #self._connections, 1, -1 do
			local connection = self._connections[i]
			if not connection.Connected then
				self:_removeConnection(connection)
			end
		end
	end

	self._firing = false
end

--[=[
	Returns `true` if the Sequent is currently firing.
]=]
function Sequent:IsFiring()
	return self._firing
end

--[=[
	Connects a callback to the Sequent, which gets called anytime `Fire`
	is called.

	The given `priority` indicates the firing priority of the callback. Higher
	priority values will be run first. There are a few defaults available via
	`Sequent.Priority`.
]=]
function Sequent:Connect(callback: (...unknown) -> (), priority: number): SequentConnection
	assert(self._firing, "cannot connect while firing")

	local connection = setmetatable({
		Connected = true,
		_callback = callback,
		_priority = priority,
		_sequent = self,
	}, SequentConnection)

	-- Find the correct index to remain sorted by priority:
	local idx = #self._connections + 1
	for i, c: InternalSequentConnection in self._connections do
		if c._priority < priority then
			idx = i
			break
		end
	end

	table.insert(self._connections, idx, connection)

	return connection
end

--[=[
	`Once()` is the same as `Connect()`, except the connection is automatically
	disconnected after being fired once.
]=]
function Sequent:Once(callback: (...unknown) -> (), priority: number)
	local connection: SequentConnection

	connection = self:Connect(function(...)
		if not connection.Connected then
			return
		end
		connection:Disconnect()
		callback(...)
	end, priority)

	return connection
end

--[=[
	Cancels a currently-firing Sequent.
]=]
function Sequent:Cancel()
	if not self._firing then
		return
	end

	if self._taskThread == coroutine.running() then
		error("cannot cancel sequent from connected task", 2)
	end

	if self._taskThread then
		-- pcall needed as the task thread may have yielded from a call to
		-- a roblox service, which will throw an error when calling task.cancel:
		pcall(function()
			task.cancel(self._taskThread)
		end)
		self._taskThread = nil
	end

	if self._firingThread then
		local thread = self._firingThread
		self._firingThread = nil
		task.spawn(thread, true)
	end
end

--[=[
	Cleans up the Sequent. All connections are disconnected. The Sequent is cancelled
	if it is currently firing.
]=]
function Sequent:Destroy()
	self:Cancel()

	for _, connection in self._connections do
		connection.Connected = false
	end
end

function Sequent:_disconnect(connection)
	if not connection.Connected then
		return
	end
	connection.Connected = false

	if self._firing then
		self._queuedDisconnect = true
		return
	end

	self:_removeConnection(connection)
end

function Sequent:_removeConnection(connection)
	local idx = table.find(self._connections, connection)
	if idx then
		table.remove(self._connections, idx)
	end
end

return table.freeze({
	new = Sequent.new,
	Priority = Priority,
})
