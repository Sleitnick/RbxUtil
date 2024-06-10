--!native

-- Shake
-- Stephen Leitnick
-- December 09, 2021

local RunService = game:GetService("RunService")

--[=[
	@within Shake
	@type UpdateCallbackFn () -> (position: Vector3, rotation: Vector3, completed: boolean)
]=]
type UpdateCallbackFn = () -> (Vector3, Vector3, boolean)

export type Shake = {
	Amplitude: number,
	Frequency: number,
	FadeInTime: number,
	FadeOutTime: number,
	SustainTime: number,
	Sustain: boolean,
	PositionInfluence: Vector3,
	RotationInfluence: Vector3,
	TimeFunction: () -> number,

	Start: (self: Shake) -> (),
	Stop: (self: Shake) -> (),
	IsShaking: (self: Shake) -> boolean,
	StopSustain: (self: Shake) -> (),
	Update: (self: Shake) -> (Vector3, Vector3, boolean),
	OnSignal: (
		self: Shake,
		signal: RBXScriptSignal,
		callback: (Vector3, Vector3, boolean) -> ()
	) -> RBXScriptConnection,
	BindToRenderStep: (self: Shake, name: string, priority: number, callback: (Vector3, Vector3, boolean) -> ()) -> (),
	Clone: (self: Shake) -> Shake,
	Destroy: (self: Shake) -> (),
}

local rng = Random.new()
local renderId = 0

--[=[
	@class Shake
	Create realistic shake effects, such as camera or object shakes.

	Creating a shake is very simple with this module. For every shake,
	simply create a shake instance by calling `Shake.new()`. From
	there, configure the shake however desired. Once configured,
	call `shake:Start()` and then bind a function to it with either
	`shake:OnSignal(...)` or `shake:BindToRenderStep(...)`.
	
	The shake will output its values to the connected function, and then
	automatically stop and clean up its connections once completed.

	Shake instances can be reused indefinitely. However, only one shake
	operation per instance can be running. If more than one is needed
	of the same configuration, simply call `shake:Clone()` to duplicate
	it.

	Example of a simple camera shake:
	```lua
	local priority = Enum.RenderPriority.Last.Value

	local shake = Shake.new()
	shake.FadeInTime = 0
	shake.Frequency = 0.1
	shake.Amplitude = 5
	shake.RotationInfluence = Vector3.new(0.1, 0.1, 0.1)

	shake:Start()
	shake:BindToRenderStep(Shake.NextRenderName(), priority, function(pos, rot, isDone)
		camera.CFrame *= CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
	end)
	```

	Shakes will automatically stop once the shake has been completed. Shakes can
	also be used continuously if the `Sustain` property is set to `true`.

	Here are some more helpful configuration examples:

	```lua
	local shake = Shake.new()

	-- The magnitude of the shake. Larger numbers means larger shakes.
	shake.Amplitude = 5

	-- The speed of the shake. Smaller frequencies mean faster shakes.
	shake.Frequency = 0.1

	 -- Fade-in time before max amplitude shake. Set to 0 for immediate shake.
	shake.FadeInTime = 0

	-- Fade-out time. Set to 0 for immediate cutoff.
	shake.FadeOutTime = 0

	-- How long the shake sustains full amplitude before fading out
	shake.SustainTime = 1

	-- Set to true to never end the shake. Call shake:StopSustain() to start the fade-out.
	shake.Sustain = true

	-- Multiplies against the shake vector to control the final amplitude of the position.
	-- Can be seen internally as: position = shakeVector * fadeInOut * positionInfluence
	shake.PositionInfluence = Vector3.one

	-- Multiplies against the shake vector to control the final amplitude of the rotation.
	-- Can be seen internally as: position = shakeVector * fadeInOut * rotationInfluence
	shake.RotationInfluence = Vector3.new(0.1, 0.1, 0.1)

	```
]=]
local Shake = {}
Shake.__index = Shake

--[=[
	@within Shake
	@prop Amplitude number
	Amplitude of the overall shake. For instance, an amplitude of `3` would mean the
	peak magnitude for the outputted shake vectors would be about `3`.

	Defaults to `1`.
]=]

--[=[
	@within Shake
	@prop Frequency number
	Frequency of the overall shake. This changes how slow or fast the
	shake occurs.

	Defaults to `1`.
]=]

--[=[
	@within Shake
	@prop FadeInTime number
	How long it takes for the shake to fade in, measured in seconds.

	Defaults to `1`.
]=]

--[=[
	@within Shake
	@prop FadeOutTime number
	How long it takes for the shake to fade out, measured in seconds.

	Defaults to `1`.
]=]

--[=[
	@within Shake
	@prop SustainTime number
	How long it takes for the shake sustains itself after fading in and
	before fading out.
	
	To sustain a shake indefinitely, set `Sustain`
	to `true`, and call the `StopSustain()` method to stop the sustain
	and fade out the shake effect.

	Defaults to `0`.
]=]

--[=[
	@within Shake
	@prop Sustain boolean
	If `true`, the shake will sustain itself indefinitely once it fades
	in. If `StopSustain()` is called, the sustain will end and the shake
	will fade out based on the `FadeOutTime`.

	Defaults to `false`.
]=]

--[=[
	@within Shake
	@prop PositionInfluence Vector3
	This is similar to `Amplitude` but multiplies against each axis
	of the resultant shake vector, and only affects the position vector.

	Defaults to `Vector3.one`.
]=]

--[=[
	@within Shake
	@prop RotationInfluence Vector3
	This is similar to `Amplitude` but multiplies against each axis
	of the resultant shake vector, and only affects the rotation vector.

	Defaults to `Vector3.one`.
]=]

--[=[
	@within Shake
	@prop TimeFunction () -> number
	The function used to get the current time. This defaults to
	`time` during runtime, and `os.clock` otherwise. Usually this
	will not need to be set, but it can be optionally configured
	if desired.
]=]

--[=[
	@return Shake
	Construct a new Shake instance.
]=]
function Shake.new(): Shake
	local self = setmetatable({}, Shake)

	self.Amplitude = 1
	self.Frequency = 1
	self.FadeInTime = 1
	self.FadeOutTime = 1
	self.SustainTime = 0
	self.Sustain = false
	self.PositionInfluence = Vector3.one
	self.RotationInfluence = Vector3.one
	self.TimeFunction = if RunService:IsRunning() then time else os.clock

	self._timeOffset = rng:NextNumber(-1e6, 1e6)
	self._startTime = 0
	self._running = false
	self._signalConnections = {}
	self._renderBindings = {}

	return self
end

--[=[
	Apply an inverse square intensity multiplier to the given vector based on the
	distance away from some source. This can be used to simulate shake intensity
	based on the distance the shake is occurring from some source.

	For instance, if the shake is caused by an explosion in the game, the shake
	can be calculated as such:

	```lua
	local function Explosion(positionOfExplosion: Vector3)

		local cam = workspace.CurrentCamera
		local renderPriority = Enum.RenderPriority.Last.Value

		local shake = Shake.new()
		-- Set shake properties here

		local function ExplosionShake(pos: Vector3, rot: Vector3)
			local distance = (cam.CFrame.Position - positionOfExplosion).Magnitude
			pos = Shake.InverseSquare(pos, distance)
			rot = Shake.InverseSquare(rot, distance)
			cam.CFrame *= CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
		end

		shake:BindToRenderStep("ExplosionShake", renderPriority, ExplosionShake)

	end
	```
]=]
function Shake.InverseSquare(shake: Vector3, distance: number): Vector3
	if distance < 1 then
		distance = 1
	end
	local intensity = 1 / (distance * distance)
	return shake * intensity
end

--[=[
	Returns a unique render name for every call, which can
	be used with the `BindToRenderStep` method optionally.

	```lua
	shake:BindToRenderStep(Shake.NextRenderName(), ...)
	```
]=]
function Shake.NextRenderName(): string
	renderId += 1
	return ("__shake_%.4i__"):format(renderId)
end

--[=[
	Start the shake effect.

	:::note
	This **must** be called before calling `Update`. As such, it should also be
	called once before or after calling `OnSignal` or `BindToRenderStep` methods.
	:::
]=]
function Shake:Start()
	self._startTime = self.TimeFunction()
	self._running = true
end

--[=[
	Stops the shake effect. If using `OnSignal` or `BindToRenderStep`, those bound
	functions will be disconnected/unbound.

	`Stop` is automatically called when the shake effect is completed _or_ when the
	`Destroy` method is called.
]=]
function Shake:Stop()
	self._running = false

	for _, name in self._renderBindings do
		RunService:UnbindFromRenderStep(name)
	end
	table.clear(self._renderBindings)

	for _, conn in self._signalConnections do
		conn:Disconnect()
	end
	table.clear(self._signalConnections)
end

--[=[
	Returns `true` if the shake instance is currently running,
	otherwise returns `false`.
]=]
function Shake:IsShaking(): boolean
	return self._running
end

--[=[
	Schedules a sustained shake to stop. This works by setting the
	`Sustain` field to `false` and letting the shake effect fade out
	based on the `FadeOutTime` field.
]=]
function Shake:StopSustain()
	local now = self.TimeFunction()
	self.Sustain = false
	self.SustainTime = (now - self._startTime) - self.FadeInTime
end

--[=[
	Calculates the current shake vector. This should be continuously
	called inside a loop, such as `RunService.Heartbeat`. Alternatively,
	`OnSignal` or `BindToRenderStep` can be used to automatically call
	this function.

	Returns a tuple of three values:
	1. `position: Vector3` - Position shake offset
	2. `rotation: Vector3` - Rotation shake offset
	3. `completed: boolean` - Flag indicating if the shake is finished

	```lua
	local hb
	hb = RunService.Heartbeat:Connect(function()
		local offsetPosition, offsetRotation, isDone = shake:Update()
		if isDone then
			hb:Disconnect()
		end
		-- Use `offsetPosition` and `offsetRotation` here
	end)
	```
]=]
function Shake:Update(): (Vector3, Vector3, boolean)
	local done = false

	local now = self.TimeFunction()
	local dur = now - self._startTime

	local noiseInput = ((now + self._timeOffset) / self.Frequency) % 10000

	local multiplierFadeIn = 1
	local multiplierFadeOut = 1
	if dur < self.FadeInTime then
		-- Fade in
		multiplierFadeIn = dur / self.FadeInTime
	end
	if not self.Sustain and dur > self.FadeInTime + self.SustainTime then
		if self.FadeOutTime == 0 then
			done = true
		else
			-- Fade out
			multiplierFadeOut = 1 - (dur - self.FadeInTime - self.SustainTime) / self.FadeOutTime
			if not self.Sustain and dur >= self.FadeInTime + self.SustainTime + self.FadeOutTime then
				done = true
			end
		end
	end

	local offset = Vector3.new(
		math.noise(noiseInput, 0) / 2,
		math.noise(0, noiseInput) / 2,
		math.noise(noiseInput, noiseInput) / 2
	) * self.Amplitude * math.min(multiplierFadeIn, multiplierFadeOut)

	if done then
		self:Stop()
	end

	return self.PositionInfluence * offset, self.RotationInfluence * offset, done
end

--[=[
	@param signal Signal | RBXScriptSignal
	@param callbackFn UpdateCallbackFn
	@return Connection | RBXScriptConnection

	Bind the `Update` method to a signal. For instance, this can be used
	to connect to `RunService.Heartbeat`.

	All connections are cleaned up when the shake instance is stopped
	or destroyed.

	```lua
	local function SomeShake(pos: Vector3, rot: Vector3, completed: boolean)
		-- Shake
	end

	shake:OnSignal(RunService.Heartbeat, SomeShake)
	```
]=]
function Shake:OnSignal(signal, callbackFn: UpdateCallbackFn)
	local conn = signal:Connect(function()
		callbackFn(self:Update())
	end)

	table.insert(self._signalConnections, conn)

	return conn
end

--[=[
	@param name string -- Name passed to `RunService:BindToRenderStep`
	@param priority number -- Priority passed to `RunService:BindToRenderStep`
	@param callbackFn UpdateCallbackFn

	Bind the `Update` method to RenderStep.

	All bond functions are cleaned up when the shake instance is stopped
	or destroyed.

	```lua
	local renderPriority = Enum.RenderPriority.Camera.Value

	local function SomeShake(pos: Vector3, rot: Vector3, completed: boolean)
		-- Shake
	end

	shake:BindToRenderStep("SomeShake", renderPriority, SomeShake)
	```
]=]
function Shake:BindToRenderStep(name: string, priority: number, callbackFn: UpdateCallbackFn)
	RunService:BindToRenderStep(name, priority, function()
		callbackFn(self:Update())
	end)

	table.insert(self._renderBindings, name)
end

--[=[
	@return Shake
	Creates a new shake with identical properties as
	this one. This does _not_ clone over playing state,
	and thus the cloned instance will be in a stopped
	state.

	A use-case for using `Clone` would be to create a module
	with a list of shake presets. These presets can be cloned
	when desired for use. For instance, there might be presets
	for explosions, recoil, or earthquakes.

	```lua
	--------------------------------------
	-- Example preset module
	local ShakePresets = {}

	local explosion = Shake.new()
	-- Configure `explosion` shake here
	ShakePresets.Explosion = explosion

	return ShakePresets
	--------------------------------------

	-- Use the module:
	local ShakePresets = require(somewhere.ShakePresets)
	local explosionShake = ShakePresets.Explosion:Clone()
	```
]=]
function Shake:Clone()
	local shake = Shake.new()
	local cloneFields = {
		"Amplitude",
		"Frequency",
		"FadeInTime",
		"FadeOutTime",
		"SustainTime",
		"Sustain",
		"PositionInfluence",
		"RotationInfluence",
		"TimeFunction",
	}
	for _, field in cloneFields do
		shake[field] = self[field]
	end
	return shake
end

--[=[
	Alias for `Stop()`.
]=]
function Shake:Destroy()
	self:Stop()
end

return {
	new = Shake.new,
	InverseSquare = Shake.InverseSquare,
	NextRenderName = Shake.NextRenderName,
}
