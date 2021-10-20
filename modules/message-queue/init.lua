--!strict

-- MessageQueue
-- Stephen Leitnick
-- November 20, 2021


--[=[
	@class MessageQueue
	A queue that flushes all objects at the end of the current
	execution step. This works by scheduling all tasks with
	`task.defer`.

	A possible use-case is to batch all requests being sent through
	a RemoteEvent to help prevent calling it too many times on
	the same frame.

	```lua
	local bulletQueue = MessageQueue.new(function(bullets)
		bulletRemoteEvent:FireAllClients(bullets)
	end)

	-- Add 3 bullets. Because they're all added on the same
	-- execution step, they will all be grouped together on
	-- the next queue flush, which the above function will
	-- handle.
	bulletQueue:Add(someBullet)
	bulletQueue:Add(someBullet)
	bulletQueue:Add(someBullet)
	```
]=]
local MessageQueue = {}
MessageQueue.__index = MessageQueue


--[=[
	@param onFlush ({T}) -> nil
	@return MessageQueue<T>
	Constructs a new MessageQueue.
]=]
function MessageQueue.new<T>(onFlush: ({T}) -> nil)
	local self = setmetatable({}, MessageQueue)
	self._queue = {}
	self._flushing = false
	self._flushingScheduled = false
	self._onFlush = onFlush
	return self
end


--[=[
	@param object T
	Add an object to the queue.
]=]
function MessageQueue:Add<T>(object: T)
	table.insert(self._queue, object)
	if not self._flushingScheduled then
		self._flushingScheduled = true
		task.defer(function()
			if not self._flushingScheduled then
				return
			end
			self._flushing = true
			self._onFlush(self._queue)
			table.clear(self._queue)
			self._flushing = false
			self._flushingScheduled = false
		end)
	end
end


--[=[
	Clears the MessageQueue. This will clear any tasks
	that were scheduled to be flushed on the current
	execution frame.

	```lua
	queue:Add(something1)
	queue:Add(something2)
	queue:Clear()
	```
]=]
function MessageQueue:Clear()
	if self._flushing then return end
	table.clear(self._queue)
	self._flushingScheduled = false
end


--[=[
	Destroys the MessageQueue. Just an alias for `Clear()`.
]=]
function MessageQueue:Destroy()
	self:Clear()
end


return MessageQueue
