--!strict

-- Concur
-- Stephen Leitnick
-- May 01, 2022

type Error = any
type AnyFn = (...any) -> ...any

--[=[
	@class Concur

	Concurrency class for helping run tasks concurrently. In other words, Concur allows
	developers to watch coroutines/threads. Completion status, returned values, and
	errors can all be tracked.

	For instance, Concur could be used to concurrently save all player data
	at the same time when the game closes down:

	```lua
	game:BindToClose(function()
		local all = {}
		for _,player in ipairs(Players:GetPlayers()) do
			local save = Concur.spawn(function()
				DoSomethingToSaveData(player)
			end)
		end
		local allConcur = Concur.all(all)
		allConcur:Await()
	end)
	```
]=]
local Concur = {}
Concur.__index = Concur

--[=[
	@within Concur
	@interface Errors
	.Stopped "Stopped"
	.Timeout "Timeout"
]=]

--[=[
	@within Concur
	@readonly
	@prop Errors Errors
]=]
Concur.Errors = {
	Stopped = "Stopped",
	Timeout = "Timeout",
}

function Concur._new(fn: AnyFn, spawner: AnyFn, ...: any): Concur
	local self: Concur = setmetatable({
		_completed = false,
		_res = nil,
		_err = nil,
		_awaitingThreads = {},
		_thread = nil,
	}, Concur)

	self._thread = spawner(function(...)
		local pcallRes = table.pack(pcall(fn, ...))
		self._completed = true
		self._err = if not pcallRes[1] then pcallRes[2] else nil
		if self._err ~= nil then
			for _, thread in ipairs(self._awaitingThreads) do
				task.spawn(thread, self._err)
			end
		else
			local res = table.move(pcallRes, 2, #pcallRes, 1, table.create(#pcallRes - 1))
			self._res = res
			for _, thread in ipairs(self._awaitingThreads) do
				task.spawn(thread, nil, table.unpack(res, 1, res.n))
			end
		end
	end, ...)

	return self
end

--[=[
	Spawns the function using `task.spawn`.

	```lua
	local c = Concur.spawn(function()
		task.wait(5)
		return "Hello!"
	end)

	c:OnCompleted(function(err, msg)
		if err then
			error(err)
		end
		print(msg) --> Hello!
	end))
	```
]=]
function Concur.spawn(fn: AnyFn, ...: any): Concur
	if type(fn) ~= "function" then
		error("Concur.spawn argument must be a function; got " .. type(fn), 2)
	end
	return Concur._new(fn, task.spawn, ...)
end

--[=[
	Same as `Concur.spawn`, but uses `task.defer` internally.
]=]
function Concur.defer(fn: AnyFn, ...: any): Concur
	if type(fn) ~= "function" then
		error("Concur.defer argument must be a function; got " .. type(fn), 2)
	end
	return Concur._new(fn, task.defer, ...)
end

--[=[
	Same as `Concur.spawn`, but uses `task.delay` internally.
]=]
function Concur.delay(delayTime: number, fn: AnyFn, ...: any): Concur
	if type(fn) ~= "function" then
		error("Concur.delay argument must be a function; got " .. type(fn), 2)
	end
	return Concur._new(fn, function(...)
		return task.delay(delayTime, ...)
	end, ...)
end

--[=[
	Resolves to the given value right away.

	```lua
	local val = Concur.value(10)
	val:OnCompleted(function(v)
		print(v) --> 10
	end)
	```
]=]
function Concur.value(value: any): Concur
	return Concur.spawn(function()
		return value
	end)
end

--[=[
	Completes the Concur instance once the event is fired and the predicate
	function returns `true` (if no predicate is given, then completes once
	the event first fires).

	The Concur instance will return the values given by the event.

	```lua
	-- Wait for next player to touch an object:
	local touch = Concur.event(part.Touched, function(toucher)
		return Players:GetPlayerFromCharacter(toucher.Parent) ~= nil
	end)

	touch:OnCompleted(function(err, toucher)
		print(toucher)
	end)
	```
]=]
function Concur.event(event: RBXScriptSignal, predicate: ((...any) -> boolean)?)
	local connection, thread

	connection = event:Connect(function(...)
		if not thread then
			return
		end
		if predicate == nil or predicate(...) then
			connection:Disconnect()
			task.spawn(thread, ...)
		end
	end)

	local c = Concur.spawn(function()
		thread = coroutine.running()
		return coroutine.yield()
	end)

	c:OnCompleted(function(err)
		connection:Disconnect()
		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, err)
		end
	end)

	return c
end

--[=[
	Completes once _all_ Concur instances have been completed. All values
	will be available in a packed table in the same order they were passed.

	```lua
	local c1 = Concur.spawn(function()
		return 10
	end)

	local c2 = Concur.delay(0.5, function()
		return 15
	end)

	local c3 = Concur.value(20)

	local c4 = Concur.spawn(function()
		error("failed")
	end)

	Concur.all({c1, c2, c3}):OnCompleted(function(err, values)
		print(values) --> {{nil, 10}, {nil, 15}, {nil, 20}, {"failed", nil}}
	end)
	```
]=]
function Concur.all(concurs: { Concur }): Concur
	if #concurs == 0 then
		return Concur.value(nil)
	end

	return Concur.spawn(function()
		local numCompleted = 0
		local total = #concurs
		local thread = coroutine.running()
		local allRes = table.create(total)
		for i, concur in ipairs(concurs) do
			concur:OnCompleted(function(...)
				allRes[i] = table.pack(...)
				numCompleted += 1
				if numCompleted >= total and coroutine.status(thread) == "suspended" then
					task.spawn(thread)
				end
			end)
		end
		if numCompleted < total then
			coroutine.yield()
		end
		return allRes
	end)
end

--[=[
	Completes once the first Concur instance is completed _without an error_. All other Concur
	instances are then stopped.

	```lua
	local c1 = Concur.delay(1, function()
		return 10
	end)

	local c2 = Concur.delay(0.5, function()
		return 5
	end)

	Concur.first({c1, c2}):OnCompleted(function(err, num)
		print(num) --> 5
	end)
	```
]=]
function Concur.first(concurs: { Concur }): Concur
	if #concurs == 0 then
		return Concur.value(nil)
	end

	return Concur.spawn(function()
		local thread = coroutine.running()
		local res = nil
		local firstConcur = nil
		for _, concur in ipairs(concurs) do
			concur:OnCompleted(function(err, ...)
				if res or err ~= nil then
					return
				end
				firstConcur = concur
				res = table.pack(...)
				if coroutine.status(thread) == "suspended" then
					task.spawn(thread)
				end
			end)
		end
		if res == nil then
			coroutine.yield()
		end
		for _, concur in ipairs(concurs) do
			if concur == firstConcur then
				continue
			end
			concur:Stop()
		end
		return table.unpack(res, 1, res.n)
	end)
end

--[=[
	Stops the Concur instance. The underlying thread will be cancelled using
	`task.cancel`. Any bound `OnCompleted` functions or threads waiting with
	`Await` will be completed with the error `Concur.Errors.Stopped`.

	```lua
	local c = Concur.spawn(function()
		for i = 1,10 do
			print(i)
			task.wait(1)
		end
	end)

	task.wait(2.5)
	c:Stop() -- At this point, will have only printed 1 and 2
	```
]=]
function Concur:Stop()
	if self._completed then
		return
	end
	self._completed = true
	self._err = Concur.Errors.Stopped
	task.cancel(self._thread)
	for _, thread: thread in ipairs(self._awaitingThreads) do
		task.spawn(thread, Concur.Errors.Stopped)
	end
end

--[=[
	Check if the Concur instance is finished.
]=]
function Concur:IsCompleted(): boolean
	return self._completed
end

--[=[
	@yields
	Yields the calling thread until the Concur instance is completed:
	
	```lua
	local c = Concur.delay(5, function()
		return "Hi"
	end)

	local err, msg = c:Await()
	print(msg) --> Hi
	```

	The `Await` method can be called _after_ the Concur instance
	has been completed too, in which case the completed values
	will be returned immediately without yielding the thread:

	```lua
	local c = Concur.spawn(function()
		return 10
	end)

	task.wait(5)
	-- Called after 'c' has been completed, but still captures the value:
	local err, num = c:Await()
	print(num) --> 10
	```

	It is always good practice to make sure that the `err` value is handled
	by checking if it is not nil:

	```lua
	local c = Concur.spawn(function()
		error("failed")
	end)

	local err, value = c:Await()

	if err ~= nil then
		print(err) --> failed
		-- Handle error `err`
	else
		-- Handle `value`
	end
	```

	This will stop awaiting if the Concur instance was stopped
	too, in which case the `err` will be equal to
	`Concur.Errors.Stopped`:

	```lua
	local c = Concur.delay(10, function() end)
	c:Stop()
	local err = c:Await()
	if err == Concur.Errors.Stopped then
		print("Was stopped")
	end
	```

	An optional timeout can be given, which will return the
	`Concur.Errors.Timeout` error if timed out. Timing out
	does _not_ stop the Concur instance, so other callers
	to `Await` or `OnCompleted` can still grab the resulting
	values.

	```lua
	local c = Concur.delay(10, function() end)
	local err = c:Await(1)
	if err == Concur.Errors.Timeout then
		-- Handle timeout
	end
	```
]=]
function Concur:Await(timeout: number?): (Error, ...any?)
	if self._completed then
		if self._err ~= nil then
			return self._err
		else
			return nil, if self._res == nil then nil else table.unpack(self._res, 1, self._res.n)
		end
	end

	local thread = coroutine.running()
	table.insert(self._awaitingThreads, thread)

	if timeout then
		local delayThread = task.delay(timeout, function()
			local index = table.find(self._awaitingThreads, thread)
			if index then
				table.remove(self._awaitingThreads, index)
				task.spawn(thread, Concur.Errors.Timeout)
			end
		end)
		local res = table.pack(coroutine.yield())
		if coroutine.status(delayThread) ~= "normal" then
			task.cancel(delayThread)
		end
		return table.unpack(res, 1, res.n)
	else
		return coroutine.yield()
	end
end

--[=[
	Calls the given function once the Concur instance is completed:

	```lua
	local c = Concur.delay(5, function()
		return "Hi"
	end)

	c:OnCompleted(function(err, msg)
		print(msg) --> Hi
	end)
	```

	A function is returned that can be used to unbind the function to
	no longer fire when the Concur instance is completed:

	```lua
	local c = Concur.delay(5, function() end)
	local unbind = c:OnCompleted(function()
		print("Completed")
	end)
	unbind()
	-- Never prints "Completed"
	```

	The `OnCompleted` method can be called _after_ the Concur instance
	has been completed too, in which case the given function will be
	called immediately with the completed values:

	```lua
	local c = Concur.spawn(function()
		return 10
	end)

	task.wait(5)
	-- Called after 'c' has been completed, but still captures the value:
	c:OnCompleted(function(err, num)
		print(num) --> 10
	end)
	```

	It is always good practice to make sure that the `err` value is handled
	by checking if it is not nil:

	```lua
	local c = Concur.spawn(function()
		error("failed")
	end)

	c:OnCompleted(function(err, value)
		if err ~= nil then
			print(err) --> failed
			-- Handle error `err`
			return
		end
		-- Handle `value`
	end)
	```

	This will call the function if the Concur instance was stopped
	too, in which case the `err` will be equal to
	`Concur.Errors.Stopped`:

	```lua
	local c = Concur.delay(10, function() end)
	c:OnCompleted(function(err)
		if err == Concur.Errors.Stopped then
			print("Was stopped")
		end
	end)
	c:Stop()
	```

	An optional timeout can also be supplied, which will call the
	function with the `Concur.Errors.Timeout` error:

	```lua
	local c = Concur.delay(10, function() end)
	c:OnCompleted(function(err)
		if err == Concur.Errors.Timeout then
			-- Handle timeout
		end
	end, 1)
	```
]=]
function Concur:OnCompleted(fn: (Error, ...any?) -> (), timeout: number?): () -> ()
	local thread = task.spawn(function()
		fn(self:Await(timeout))
	end)

	-- Unbind:
	return function()
		task.cancel(thread)
		local index = table.find(self._awaitingThreads, thread)
		if index then
			table.remove(self._awaitingThreads, index)
		end
	end
end

type ConcurObj = {
	_completed: boolean,
	_res: { any }?,
	_err: string?,
	_awaitingThreads: { thread },
	_thread: thread?,
}

export type Concur = typeof(setmetatable({} :: ConcurObj, Concur))

return Concur
