--!native

export type PID = {
	Reset: (self: PID) -> (),
	Calculate: (self: PID, setpoint: number, input: number, deltaTime: number) -> number,
	Debug: (self: PID, name: string, parent: Instance?) -> (),
	Destroy: (self: PID) -> (),
}

--[=[
	@class PID
	The PID class simulates a [PID controller](https://en.wikipedia.org/wiki/PID_controller). PID is an acronym
	for _proportional, integral, derivative_. PIDs are input feedback loops that try to reach a specific
	goal by measuring the difference between the input and the desired value, and then returning a new
	desired input.

	A common example is a car's cruise control, which would give a PID the current speed
	and the desired speed, and the PID controller would return the desired throttle input to reach the
	desired speed.
]=]
local PID = {}
PID.__index = PID

--[=[
	@param min number -- Minimum value the PID can output
	@param max number -- Maximum value the PID can output
	@param kp number -- Proportional gain coefficient (P)
	@param ki number -- Integral gain coefficient (I)
	@param kd number -- Derivative gain coefficient (D)
	@return PID

	Constructs a new PID.

	```lua
	local pid = PID.new(0, 1, 0.1, 0, 0)
	```
]=]
function PID.new(min: number, max: number, kp: number, ki: number, kd: number): PID
	local self = setmetatable({}, PID)
	self._min = min
	self._max = max
	self._kp = kp
	self._ki = ki
	self._kd = kd
	self._lastError = 0 -- Store the last error for derivative calculation
	self._integralSum = 0 -- Store the sum of errors for integral calculation
	return self
end

--[=[
	Resets the PID to a zero start state.
]=]
function PID:Reset()
	self._lastError = 0
	self._integralSum = 0
end

--[=[
	@param setpoint number	-- The desired point to reach
	@param processVariable number	-- The measured value of the system to compare against the setpoint
	@param deltaTime number	-- Delta time. This is the time between each PID calculation
	@return output: number

	Calculates the new output based on the setpoint and input. For example,
	if the PID was being used for a car's throttle control where the throttle
	can be in the range of [0, 1], then the PID calculation might look like
	the following:
	```lua
	local cruisePID = PID.new(0, 1, ...)
	local desiredSpeed = 50

	RunService.Heartbeat:Connect(function(dt)
		local throttle = cruisePID:Calculate(desiredSpeed, car.CurrentSpeed, dt)
		car:SetThrottle(throttle)
	end)
	```
]=]
function PID:Calculate(setpoint: number, processVariable: number, deltaTime: number): number
	-- Calculate the error e(t) = SP - PV(t)
	local err = setpoint - processVariable

	-- Proportional term
	local pOut = self._kp * err

	-- Integral term
	self._integralSum = self._integralSum + err * deltaTime
	local iOut = self._ki * self._integralSum

	-- Derivative term
	local derivative = (err - self._lastError) / deltaTime
	local dOut = self._kd * derivative

	-- Combine terms
	local output = pOut + iOut + dOut

	-- Clamp output to min/max
	output = math.clamp(output, self._min, self._max)

	-- Save the current error for the next derivative calculation
	self._lastError = err

	return output
end

--[=[
	@param name string -- Folder name
	@param parent Instance? -- Folder parent

	Creates a folder that contains attributes that can be used to
	tune the PID during runtime within the explorer.

	:::info Studio Only
	This will only create the folder in Studio. In a real game server,
	this function will do nothing.
	:::
]=]
function PID:Debug(name: string, parent: Instance?)
	if not game:GetService("RunService"):IsStudio() then
		return
	end

	if self._debug then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder:AddTag("PIDDebug")

	local function Bind(attrName, propName)
		folder:SetAttribute(attrName, self[propName])
		folder:GetAttributeChangedSignal(attrName):Connect(function()
			self[propName] = folder:GetAttribute(attrName)
			self:Reset()
		end)
	end

	folder:SetAttribute("MinMax", NumberRange.new(self._min, self._max))
	folder:GetAttributeChangedSignal("MinMax"):Connect(function()
		local minMax = folder:GetAttribute("MinMax") :: NumberRange
		self._min = minMax.Min
		self._max = minMax.Max
		self:Reset()
	end)

	Bind("kP", "_kp")
	Bind("kI", "_ki")
	Bind("kD", "_kd")

	folder:SetAttribute("Output", self._min)

	local lastOutput = 0
	self.Calculate = function(s, sp, pv, ...)
		lastOutput = PID.Calculate(s, sp, pv, ...)
		folder:SetAttribute("Output", lastOutput)
		return lastOutput
	end

	local delayThread: thread? = nil
	folder:SetAttribute("ShowDebugger", false)
	folder:GetAttributeChangedSignal("ShowDebugger"):Connect(function()
		if delayThread then
			task.cancel(delayThread)
		end

		local showDebugger = folder:GetAttribute("ShowDebugger")

		if showDebugger then
			delayThread = task.delay(0.1, function()
				delayThread = nil
				if folder:GetAttribute("ShowDebugger") then
					folder:SetAttribute("ShowDebugger", false)
					warn("Install the PID Debug plugin: https://create.roblox.com/store/asset/16279661108/PID-Debug")
				end
			end)
		end
	end)

	folder.Parent = parent or workspace
	self._debug = folder
end

--[=[
	Destroys the PID. This is only necessary if calling `PID:Debug`.
]=]
function PID:Destroy()
	if self._debug then
		self._debug:Destroy()
		self._debug = nil
	end
end

return {
	new = PID.new,
}
