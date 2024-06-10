local RunService = game:GetService("RunService")

local function AwaitStop(shake): number
	local start = os.clock()
	shake:Update()
	while shake:IsShaking() do
		task.wait()
		shake:Update()
	end
	return os.clock() - start
end

return function()
	local Shake = require(script.Parent)

	describe("Construct", function()
		it("should construct a new shake instance", function()
			expect(function()
				local _shake = Shake.new()
			end).to.never.throw()
		end)
	end)

	describe("Static Functions", function()
		it("should get next render name", function()
			local r1 = Shake.NextRenderName()
			local r2 = Shake.NextRenderName()
			local r3 = Shake.NextRenderName()
			expect(r1).to.be.a("string")
			expect(r2).to.be.a("string")
			expect(r3).to.be.a("string")
			expect(r1).to.never.equal(r2)
			expect(r2).to.never.equal(r3)
			expect(r3).to.never.equal(r1)
		end)

		it("should perform inverse square", function()
			local vector = Vector3.new(10, 10, 10)
			local distance = 10
			local expectedIntensity = 1 / (distance * distance)
			local expectedVector = vector * expectedIntensity
			local vectorInverseSq = Shake.InverseSquare(vector, distance)
			expect(typeof(vectorInverseSq)).to.equal("Vector3")
			expect(vectorInverseSq).to.equal(expectedVector)
		end)
	end)

	describe("Cloning", function()
		it("should clone a shake instance", function()
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
			expect(shake2).to.be.a("table")
			expect(getmetatable(shake2)).to.equal(Shake)
			expect(shake2).to.never.equal(shake1)
			local clonedFields = {
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
			for _, field in ipairs(clonedFields) do
				expect(shake1[field]).to.equal(shake2[field])
			end
		end)

		it("should clone a shake instance but ignore running state", function()
			local shake1 = Shake.new()
			shake1:Start()
			local shake2 = shake1:Clone()
			expect(shake1:IsShaking()).to.equal(true)
			expect(shake2:IsShaking()).to.equal(false)
		end)
	end)

	describe("Shaking", function()
		it("should start", function()
			local shake = Shake.new()
			expect(shake:IsShaking()).to.equal(false)
			shake:Start()
			expect(shake:IsShaking()).to.equal(true)
		end)

		it("should stop", function()
			local shake = Shake.new()
			shake:Start()
			expect(shake:IsShaking()).to.equal(true)
			shake:Stop()
			expect(shake:IsShaking()).to.equal(false)
		end)

		it("should shake for nearly no time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0, 0.05)
		end)

		it("should shake for fade in time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0.1, 0.05)
		end)

		it("should shake for fade out time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0.1, 0.05)
		end)

		it("should shake for sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0.1, 0.05)
		end)

		it("should shake for fade in and sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0.2, 0.05)
		end)

		it("should shake for fade out and sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0.2, 0.05)
		end)

		it("should shake for fade in and fade out time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0.2, 0.05)
		end)

		it("should shake for fading and sustain time", function()
			local shake = Shake.new()
			shake.FadeInTime = 0.1
			shake.FadeOutTime = 0.1
			shake.SustainTime = 0.1
			shake:Start()
			local duration = AwaitStop(shake)
			expect(duration).to.be.near(0.3, 0.05)
		end)

		it("should shake indefinitely", function()
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
			expect(duration).to.be.near(shakeTime, 0.05)
		end)

		it("should shake indefinitely and fade out", function()
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
			expect(duration).to.be.near(0.2, 0.05)
		end)

		it("should shake indefinitely and fade out with fade in time", function()
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
			expect(duration).to.be.near(0.4, 0.05)
		end)

		it("should connect to signal", function()
			local shake = Shake.new()
			shake.SustainTime = 0.1
			shake:Start()
			local signaled = false
			local connection = shake:OnSignal(RunService.Heartbeat, function()
				signaled = true
			end)
			expect(typeof(connection)).to.equal("RBXScriptConnection")
			expect(connection.Connected).to.equal(true)
			AwaitStop(shake)
			expect(signaled).to.equal(true)
			expect(connection.Connected).to.equal(false)
		end)

		it("should bind to render step", function()
			local shake = Shake.new()
			shake.SustainTime = 0.1
			shake:Start()
			local bound = false
			shake:BindToRenderStep("ShakeTest", Enum.RenderPriority.Last.Value, function()
				bound = true
			end)
			AwaitStop(shake)
			expect(bound).to.equal(true)
		end)
	end)
end
