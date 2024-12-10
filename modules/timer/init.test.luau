local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Timer = require(script.Parent)

	ctx:Describe("Timer", function()
		local timer

		ctx:BeforeEach(function()
			timer = Timer.new(0.1)
			timer.TimeFunction = os.clock
		end)

		ctx:AfterEach(function()
			if timer then
				timer:Destroy()
				timer = nil
			end
		end)

		ctx:Test("should create a new timer", function()
			ctx:Expect(Timer.Is(timer)):ToBe(true)
		end)

		ctx:Test("should tick appropriately", function()
			local start = os.clock()
			timer:Start()
			timer.Tick:Wait()
			local duration = (os.clock() - start)
			ctx:Expect(duration):ToBeNear(duration, 0.02)
		end)

		ctx:Test("should start immediately", function()
			local start = os.clock()
			local stop = nil
			timer.Tick:Connect(function()
				if not stop then
					stop = os.clock()
				end
			end)
			timer:StartNow()
			timer.Tick:Wait()
			ctx:Expect(stop):ToBeA("number")
			local duration = (stop - start)
			ctx:Expect(duration):ToBeNear(0, 0.02)
		end)

		ctx:Test("should stop", function()
			local ticks = 0
			timer.Tick:Connect(function()
				ticks += 1
			end)
			timer:StartNow()
			timer:Stop()
			task.wait(1)
			ctx:Expect(ticks):ToBe(1)
		end)

		ctx:Test("should detect if running", function()
			ctx:Expect(timer:IsRunning()):ToBe(false)
			timer:Start()
			ctx:Expect(timer:IsRunning()):ToBe(true)
			timer:Stop()
			ctx:Expect(timer:IsRunning()):ToBe(false)
			timer:StartNow()
			ctx:Expect(timer:IsRunning()):ToBe(true)
			timer:Stop()
			ctx:Expect(timer:IsRunning()):ToBe(false)
		end)
	end)
end
