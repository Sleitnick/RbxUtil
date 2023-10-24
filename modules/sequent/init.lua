export type Sequent<T> = {
	Fire: (self: Sequent<T>, T) -> (),
	Connect: (self: Sequent<T>, callback: (SequentEvent<T>) -> ()) -> SequentConnection,
	Once: (self: Sequent<T>, callback: (SequentEvent<T>) -> ()) -> SequentConnection,
	Cancel: (self: Sequent<T>) -> (),
	Destroy: (self: Sequent<T>) -> (),
}

export type SequentConnection = {
	Disconnect: (self: SequentConnection) -> (),
	Connected: boolean,
}

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

local Priority = {
	Highest = math.huge,
	High = 1000,
	Normal = 0,
	Low = -1000,
	Lowest = -math.huge,
}

local Sequent = {}
Sequent.__index = Sequent

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

			success, err = pcall(function()
				connection._callback(event)
			end)

			self._taskThread = nil

			-- Resume the parent thread if it yielded:
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread)
			end
		end)

		-- If the task thread yielded, yield this thread too:
		if success == nil then
			coroutine.yield()
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

function Sequent:IsFiring()
	return self._firing
end

function Sequent:Connect(callback: (...unknown) -> (), priority: number)
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
		task.cancel(self._firingThread)
		self._firingThread = nil
	end
end

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

return {
	new = Sequent.new,
	Priority = Priority,
}
