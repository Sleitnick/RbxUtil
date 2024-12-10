local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

local function AwaitStop(shake): number
	local start = os.clock()
	shake:Update()
	while shake:IsShaking() do
		task.wait()
		shake:Update()
	end
	return os.clock() - start
end

return function(ctx: Test.TestContext)
	local Shake = require(script.Parent)

	ctx:Describe("Construct", function()
		ctx:Test("should construct a new shake instance", function()
			ctx:Expect(function()
				local _shake = Shake.new()
			end)
				:Not()
				:ToThrow()
		end)
	end)

	ctx:Describe("Static Functions", function()
		ctx:Test("should get next render name", function()
			local r1 = Shake.NextRenderName()
			local r2 = Shake.NextRenderName()
			local r3 = Shake.NextRenderName()
			ctx:Expect(r1):ToBeA("string")
			ctx:Expect(r2):ToBeA("string")
			ctx:Expect(r3):ToBeA("string")
			ctx:Expect(r1):Not():ToBe(r2)
			ctx:Expect(r2):Not():ToBe(r3)
			ctx:Expect(r3):Not():ToBe(r1)
		end)

		ctx:Test("should perform inverse square", function()
			local vector = Vector3.new(10, 10, 10)
			local distance = 10
			local expectedIntensity = 1 / (distance * distance)
			local expectedVector = vector * expectedIntensity
			local vectorInverseSq = Shake.InverseSquare(vector, distance)
			ctx:Expect(typeof(vectorInverseSq)):ToBe("Vector3")
			ctx:Expect(vectorInverseSq):ToBe(expectedVector)
		end)
	end)

	ctx:Describe("Cloning", function()
		ctx:Test("should clone a shake instance", function()
			local shake1 = Shake.new()
			shake1.Amplitude = 5
			shake1.Frequency = 2
			shake1.FadeInTime = 3
			shake1.FadeOutTime = 4
			shake1.SustainTime = 6
			shake1.Sustain = true
			shake1.PositionInfluence = Vector3.new(1, 2, 3)
			shake1.RotationInfluence = Vector3.new(3, 2, 1)
			shake1.TimeFunction = function()
				return os.clock()
			end
			local shake2 = shake1:Clone()
			ctx:Expect(shake2):ToBeA("table")
			ctx:Expect(getmetatable(shake2)):ToBe(getmetatable(shake1))
			ctx:Expect(shake2):Not():ToBe(shake1)
			local clonedFields = {
				"Amplitude",
				"Frequency",
				"FadeInTime",
				"FadeOutTime",
				"SustainTime",
				"Sustain",
				"PositionInfluence",
				"RotationInfluence",
			}
			for _, field in clonedFields do
				ctx:Expect(shake1[field]):ToBe(shake2[field])
			end
			ctx:Expect(shake1.TimeFunction == shake2.TimeFunction):ToBe(true)
		end)

		ctx:Test("should clone a shake instance but ignore running state", function()
			local shake1 = Shake.new()
			shake1:Start()
			local shake2 = shake1:Clone()
			ctx:Expect(shake1:IsShaking()):ToBe(true)
			ctx:Expect(shake2:IsShaking()):ToBe(false)
		end)
	end)

	ctx:Describe("Shaking", function()
		ctx:Test("should start", function()
			local shake = Shake.new()
			ctx:Expect(shake:IsShaking()):ToBe(false)
			shake:Start()
			ctx:Expect(shake:IsShaking()):ToBe(true)
		end)

		ctx:Test("should stop", function()
			local shake = Shake.new()
			shake:Start()
			ctx:Expect(shake:IsShaking()):ToBe(true)
			shake:Stop()
			ctx:Expect(shake:IsShaking()):ToBe(false)
		end)

		ctx:Test("should shake for nearly no time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0, 0.05)
		end)

		ctx:Test("should shake for fade in time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.1, 0.05)
		end)

		ctx:Test("should shake for fade out time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.1, 0.05)
		end)

		ctx:Test("should shake for sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.1, 0.05)
		end)

		ctx:Test("should shake for fade in and sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.2, 0.05)
		end)

		ctx:Test("should shake for fade out and sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.2, 0.05)
		end)

		ctx:Test("should shake for fade in and fade out time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.2, 0.05)
		end)

		ctx:Test("should shake for fading and sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.3, 0.05)
		end)

		ctx:Test("should shake indefinitely", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0
			shake.SustainTime = 0
			shake.Sustain = true
			shake:Start()
			local shakeTime = 0.1
			task.delay(shakeTime, function()
				shake:StopSustain()
			end)
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(shakeTime, 0.05)
		end)

		ctx:Test("should shake indefinitely and fade out", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0
			shake.Sustain = true
			shake:Start()
			local shakeTime = 0.1
			task.delay(shakeTime, function()
				shake:StopSustain()
			end)
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.2, 0.05)
		end)

		ctx:Test("should shake indefinitely and fade out with fade in time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0
			shake.Sustain = true
			shake:Start()
			local shakeTime = 0.3
			task.delay(shakeTime, function()
				shake:StopSustain()
			end)
			local duration = AwaitStop(shake)
			ctx:Expect(duration):ToBeNear(0.4, 0.05)
		end)

		ctx:Test("should connect to signal", function()
			local shake = Shake.new()
			shake.SustainTime = 0.1
			shake:Start()
			local signaled = false
			local connection = shake:OnSignal(RunService.Heartbeat, function()
				signaled = true
			end)
			ctx:Expect(typeof(connection)):ToBe("RBXScriptConnection")
			ctx:Expect(connection.Connected):ToBe(true)
			AwaitStop(shake)
			ctx:Expect(signaled):ToBe(true)
			ctx:Expect(connection.Connected):ToBe(false)
		end)

		-- RenderStepped only works on the client:
		if RunService:IsClient() and RunService:IsRunning() then
			ctx:Test("should bind to render step", function()
				local shake = Shake.new()
				shake.SustainTime = 0.1
				shake:Start()
				local bound = false
				shake:BindToRenderStep("ShakeTest", Enum.RenderPriority.Last.Value, function()
					bound = true
				end)
				AwaitStop(shake)
				ctx:Expect(bound):ToBe(true)
			end)
		end
	end)
end
