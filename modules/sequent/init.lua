export type Sequent<T...> = {}

-----------------------------------------------------------------------------
-- Connection
local SequentConnection = {}
SequentConnection.__index = SequentConnection

function SequentConnection:Disconnect()
	-- TODO
	self._sequent:_disconnect(self)
end
-----------------------------------------------------------------------------
-- Sequent

local Sequent = {}
Sequent.__index = Sequent

function Sequent.new<T...>(): Sequent<T...>
	local self = setmetatable({
		_connections = {},
		_firing = false,
	}, Sequent)
	return self
end

function Sequent:Fire(...)
	assert(not self._firing, "cannot fire while already firing")
	self._firing = true

	local thread = coroutine.running()
	for _, connection in self._connections do
		if not connection.Connected then
			continue
		end

		local success, err = nil, nil
		local taskThread = task.spawn(function(...)
			success, err = pcall(function(...)
				connection._callback(...)
			end, ...)
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread)
			end
		end, ...)

		if success == nil then
			coroutine.yield()
		end

		if not success then
			error(debug.traceback(taskThread, tostring(err)))
		end
	end

	self._firing = false
end

function Sequent:IsFiring()
	return self._firing
end

function Sequent:Connect(callback: () -> (), priority: number)
	local connection = setmetatable({
		Connected = true,
		_callbak = callback,
		_priority = priority,
		_sequent = self,
	}, SequentConnection)

	-- TODO: Find index:
	table.insert(self._connections, connection)
end

function Sequent:Destroy()
	-- TODO: Kill the running thread in Fire (if any)
	for _, connection in self._connections do
		connection.Connected = false
	end
end

function Sequent:_disconnect(connection)
	if not connection.Connected then
		return
	end

	local idx = table.find(self._connections, connection)
	if idx then
		table.remove(self._connections, idx)
	end
end

return {
	new = Sequent.new,
}
