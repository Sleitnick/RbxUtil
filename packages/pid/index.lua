-- PID
-- August 11, 2020


--[=[
	@class PID
	The PID class simulates a [PID controller](https://en.wikipedia.org/wiki/PID_controller). PID is an acronym
	for _proportional, intergral, derivative_. PIDs are input feedback loops that try to reach a specific
	goal by measuring the difference between the input and the desired value, and then returning a new
	desired input.
	
	A common example is a car's cruise control, which would give a PID the current speed
	and the desired speed, and the PID controller would return the desired throttle input to reach the
	desired speed.

	Original code based upon the [Arduino PID Library](https://github.com/br3ttb/Arduino-PID-Library).
]=]
local PID = {}
PID.__index = PID

--[=[
	@within PID
	@prop POnE boolean

	POnE stands for "Proportional on Error".

	Set to `true` by default.

	- `true`: The PID applies the proportional calculation on the _error_.
	- `false`: The PID applies the proportional calculation on the _measurement_.

	Setting this value to `false` may help the PID move smoother and help
	elimiate overshoot.

	```lua
	local pid = PID.new(...)
	pid.POnE = true|false
	```
]=]


--[=[
	@param min number -- Minimum value the PID can output
	@param max number -- Maximum value the PID can output
	@param kp number -- Proportional coefficient
	@param ki number -- Integral coefficient
	@param kd number -- Derivative coefficient
	@return PID

	Constructs a new PID.

	```lua
	local pid = PID.new(0, 1, 0.1, 0, 0)
	```
]=]
function PID.new(min: number, max: number, kp: number, ki: number, kd: number)
	local self = setmetatable({}, PID)
	self._min = min
	self._max = max
	self._kp = kp
	self._ki = ki
	self._kd = kd
	self._lastInput = 0
	self._outputSum = 0
	self.POnE = true
	return self
end


--[=[
	Resets the PID to a zero start state.
]=]
function PID:Reset()
	self._lastInput = 0
	self._outputSum = 0
end


--[=[
	@param setpoint number -- The desired point to reach
	@param input number -- The current inputted value
	@return output: number

	Calculates the new output based on the setpoint and input. For example,
	if the PID was being used for a car's throttle control where the throttle
	can be in the range of [0, 1], then the PID calculation might look like
	the following:
	```lua
	local cruisePID = PID.new(0, 1, ...)
	local desiredSpeed = 50

	RunService.Heartbeat:Connect(function()
		local throttle = cruisePID:Calculate(desiredSpeed, car.CurrentSpeed)
		car:SetThrottle(throttle)
	end)
	```
]=]
function PID:Calculate(setpoint: number, input: number)
	local err = (setpoint - input)
	local dInput = (input - self._lastInput)
	self._outputSum += (self._ki * err)
	
	if not self.POnE then
		self._outputSum -= self._kp * dInput
	end
	
	self._outputSum = math.clamp(self._outputSum, self._min, self._max)
	
	local output = 0
	if self.POnE then
		output = self._kp * err
	end
	
	output += self._outputSum - self._kd * dInput
	output = math.clamp(output, self._min, self._max)
	
	self._lastInput = input
	
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
]=]
function PID:Debug(name: string, parent: Instance?)
	if self._debug then return end
	if not game:GetService("RunService"):IsStudio() then return end
	local folder = Instance.new("Folder")
	folder.Name = name
	local function Bind(attrName, propName)
		folder:SetAttribute(attrName, self[propName])
		folder:GetAttributeChangedSignal(attrName):Connect(function()
			self[propName] = folder:GetAttribute(attrName)
			self:Reset()
		end)
	end
	Bind("Min", "_min")
	Bind("Max", "_max")
	Bind("KP", "_kp")
	Bind("KI", "_ki")
	Bind("KD", "_kd")
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


return PID
