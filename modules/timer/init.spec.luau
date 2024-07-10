return function()
	local Timer = require(script.Parent)

	describe("Timer", function()
		local timer

		beforeEach(function()
			timer = Timer.new(0.1)
			timer.TimeFunction = os.clock
		end)

		afterEach(function()
			if timer then
				timer:Destroy()
				timer = nil
			end
		end)

		it("should create a new timer", function()
			expect(Timer.Is(timer)).to.equal(true)
		end)

		it("should tick appropriately", function()
			local start = os.clock()
			timer:Start()
			timer.Tick:Wait()
			local duration = (os.clock() - start)
			expect(duration).to.be.near(duration, 0.02)
		end)

		it("should start immediately", function()
			local start = os.clock()
			local stop = nil
			timer.Tick:Connect(function()
				if not stop then
					stop = os.clock()
				end
			end)
			timer:StartNow()
			timer.Tick:Wait()
			expect(stop).to.be.a("number")
			local duration = (stop - start)
			expect(duration).to.be.near(0, 0.02)
		end)

		it("should stop", function()
			local ticks = 0
			timer.Tick:Connect(function()
				ticks += 1
			end)
			timer:StartNow()
			timer:Stop()
			task.wait(1)
			expect(ticks).to.equal(1)
		end)

		it("should detect if running", function()
			expect(timer:IsRunning()).to.equal(false)
			timer:Start()
			expect(timer:IsRunning()).to.equal(true)
			timer:Stop()
			expect(timer:IsRunning()).to.equal(false)
			timer:StartNow()
			expect(timer:IsRunning()).to.equal(true)
			timer:Stop()
			expect(timer:IsRunning()).to.equal(false)
		end)
	end)
end
