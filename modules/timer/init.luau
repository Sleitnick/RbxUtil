-- Timer
-- Stephen Leitnick
-- July 28, 2021

--[=[
	@within Timer
	@type CallbackFn () -> ()
	Callback function.
]=]
type CallbackFn = () -> nil

--[=[
	@within Timer
	@type TimeFn () -> number
	Time function.
]=]
type TimeFn = () -> number

local Signal = require(script.Parent.Signal)

local RunService = game:GetService("RunService")

--[=[
	@class Timer

	The Timer class allows for code to run periodically at specified intervals.

	```lua
	local timer = Timer.new(2)
	timer.Tick:Connect(function()
		print("Tock")
	end)
	timer:Start()
	```
]=]
local Timer = {}
Timer.__index = Timer

--[=[
	@within Timer
	@prop Interval number
	Interval at which the `Tick` event fires.
]=]
--[=[
	@within Timer
	@prop UpdateSignal RBXScriptSignal | Signal
	The signal which updates the timer internally.
]=]
--[=[
	@within Timer
	@prop TimeFunction TimeFn
	The function which gets the current time.
]=]
--[=[
	@within Timer
	@prop AllowDrift boolean
	Flag which indicates if the timer is allowed to drift. This
	is set to `true` by default. This flag must be set before
	calling `Start` or `StartNow`. This flag should only be set
	to `false` if it is necessary for drift to be eliminated.
]=]
--[=[
	@within Timer
	@prop Tick RBXScriptSignal | Signal
	The event which is fired every time the timer hits its interval.
]=]

--[=[
	@return Timer
	
	Creates a new timer.
]=]
function Timer.new(interval: number)
	assert(type(interval) == "number", "Argument #1 to Timer.new must be a number; got " .. type(interval))
	assert(interval >= 0, "Argument #1 to Timer.new must be greater or equal to 0; got " .. tostring(interval))
	local self = setmetatable({}, Timer)
	self._runHandle = nil
	self.Interval = interval
	self.UpdateSignal = RunService.Heartbeat
	self.TimeFunction = time
	self.AllowDrift = true
	self.Tick = Signal.new()
	return self
end

--[=[
	@return RBXScriptConnection

	Creates a simplified timer which just fires off a callback function at the given interval.

	```lua
	-- Basic:
	Timer.Simple(1, function()
		print("Tick")
	end)

	-- Using other arguments:
	Timer.Simple(1, function()
		print("Tick")
	end, true, RunService.Heartbeat, os.clock)
	```
]=]
function Timer.Simple(
	interval: number,
	callback: CallbackFn,
	startNow: boolean?,
	updateSignal: RBXScriptSignal?,
	timeFn: TimeFn?
)
	local update = updateSignal or RunService.Heartbeat
	local t = timeFn or time
	local nextTick = t() + interval
	if startNow then
		task.defer(callback)
	end
	return update:Connect(function()
		local now = t()
		if now >= nextTick then
			nextTick = now + interval
			task.defer(callback)
		end
	end)
end

--[=[
	Returns `true` if the given object is a Timer.
]=]
function Timer.Is(obj: any): boolean
	return type(obj) == "table" and getmetatable(obj) == Timer
end

function Timer:_startTimer()
	local t = self.TimeFunction
	local nextTick = t() + self.Interval
	self._runHandle = self.UpdateSignal:Connect(function()
		local now = t()
		if now >= nextTick then
			nextTick = now + self.Interval
			self.Tick:Fire()
		end
	end)
end

function Timer:_startTimerNoDrift()
	assert(self.Interval > 0, "Interval must be greater than 0 when AllowDrift is set to false")
	local t = self.TimeFunction
	local n = 1
	local start = t()
	local nextTick = start + self.Interval
	self._runHandle = self.UpdateSignal:Connect(function()
		local now = t()
		while now >= nextTick do
			n += 1
			nextTick = start + (self.Interval * n)
			self.Tick:Fire()
		end
	end)
end

--[=[
	Starts the timer. Will do nothing if the timer is already running.

	```lua
	timer:Start()
	```
]=]
function Timer:Start()
	if self._runHandle then
		return
	end
	if self.AllowDrift then
		self:_startTimer()
	else
		self:_startTimerNoDrift()
	end
end

--[=[
	Starts the timer and fires off the Tick event immediately. Will do
	nothing if the timer is already running.

	```lua
	timer:StartNow()
	```
]=]
function Timer:StartNow()
	if self._runHandle then
		return
	end
	self.Tick:Fire()
	self:Start()
end

--[=[
	Stops the timer. Will do nothing if the timer is already stopped.

	```lua
	timer:Stop()
	```
]=]
function Timer:Stop()
	if not self._runHandle then
		return
	end
	self._runHandle:Disconnect()
	self._runHandle = nil
end

--[=[
	Returns `true` if the timer is currently running.

	```lua
	if timer:IsRunning() then
		-- Do something
	end
	```
]=]
function Timer:IsRunning(): boolean
	return self._runHandle ~= nil
end

--[=[
	Destroys the timer. This will also stop the timer.
]=]
function Timer:Destroy()
	self.Tick:Destroy()
	self:Stop()
end

return Timer
