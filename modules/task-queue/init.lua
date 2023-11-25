-- TaskQueue
-- Stephen Leitnick
-- November 20, 2021

--[=[
	@class TaskQueue
	A queue that flushes all objects at the end of the current
	execution step. This works by scheduling all tasks with
	`task.defer`.

	A possible use-case is to batch all requests being sent through
	a RemoteEvent to help prevent calling it too many times on
	the same frame.

	```lua
	local bulletQueue = TaskQueue.new(function(bullets)
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
local TaskQueue = {}
TaskQueue.__index = TaskQueue

--[=[
	@param onFlush ({T}) -> ()
	@return TaskQueue<T>
	Constructs a new TaskQueue.
]=]
function TaskQueue.new<T>(onFlush: ({ T }) -> ())
	local self = setmetatable({}, TaskQueue)

	self._queue = {}
	self._flushing = false
	self._scheduled = nil
	self._onFlush = onFlush

	return self
end

--[=[
	@param object T
	Add an object to the queue.
]=]
function TaskQueue:Add<T>(object: T)
	table.insert(self._queue, object)

	if self._scheduled == nil then
		self._scheduled = task.defer(function()
			self._flushing = true
			self._onFlush(self._queue)
			table.clear(self._queue)
			self._flushing = false
			self._scheduled = nil
		end)
	end
end

--[=[
	Clears the TaskQueue. This will clear any tasks
	that were scheduled to be flushed on the current
	execution frame.

	```lua
	queue:Add(something1)
	queue:Add(something2)
	queue:Clear()
	```
]=]
function TaskQueue:Clear()
	if self._flushing then
		return
	end

	if self._scheduled ~= nil then
		task.cancel(self._scheduled)
		self._scheduled = nil
	end

	table.clear(self._queue)
end

--[=[
	Destroys the TaskQueue. Just an alias for `Clear()`.
]=]
function TaskQueue:Destroy()
	self:Clear()
end

return TaskQueue
