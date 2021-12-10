-- Shake
-- Stephen Leitnick
-- December 09, 2021


--[=[
	@within Shake
	@type UpdateCallbackFn () -> (position: Vector3, rotation: Vector3, completed: boolean)
]=]
type UpdateCallbackFn = () -> (Vector3, Vector3, boolean)

local RunService = game:GetService("RunService")

local Trove = require(script.Parent.Trove)


local rng = Random.new()


--[=[
	@class Shake
	Create realistic shake effects, such as camera or object shakes.
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
	Construct a new Shake instance.
]=]
function Shake.new()
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
	self._timeOffset = rng:NextNumber(-1e9, 1e9)
	self._startTime = 0
	self._trove = Trove.new()
	return self
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
end


--[=[
	Stops the shake effect. If using `OnSignal` or `BindToRenderStep`, those bound
	functions will be disconnected/unbound.

	`Stop` is automatically called when the shake effect is completed _or_ when the
	`Destroy` method is called.
]=]
function Shake:Stop()
	self._trove:Clean()
end


--[=[
	Schedules a sustained shake to stop. This works by setting the
	`Sustain` field to `false` and letting the shake effect fade out
	based on the `FadeOutTime` field.
]=]
function Shake:StopSustain()
	self.Sustain = false
	self.SustainTime = self._startTime + self.FadeInTime
end


--[=[
	@return (position: Vector3, rotation: Vector3, completed: boolean)
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

	local noiseInput = (now + self._timeOffset) / self.Frequency

	local multiplierFadeIn = 1
	local multiplierFadeOut = 1
	if dur < self.FadeInTime then
		multiplierFadeIn = dur / self.FadeInTime
	end
	if dur > self.FadeInTime + self.SustainTime then
		multiplierFadeOut = 1 - (dur - self.FadeInTime - self.SustainTime) / self.FadeOutTime
		if (not self.Sustain) and dur >= self.FadeInTime + self.SustainTime + self.FadeOutTime then
			done = true
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
	return self._trove:Connect(signal, function()
		callbackFn(self:Update())
	end)
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
	self._trove:BindToRenderStep(name, priority, function()
		callbackFn(self:Update())
	end)
end


--[=[
	@param vector Vector3
	@param distance number
	@return Vector3
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
	Destroy the Shake instance. Will call `Stop()`.
]=]
function Shake:Destroy()
	self:Stop()
end


return Shake
