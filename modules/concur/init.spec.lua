return function()

	local Concur = require(script.Parent)

	local function Awaiter(timeout: number)
		local awaiter = {}
		local thread
		local delayThread
		function awaiter.Resume(...)
			if coroutine.running() ~= delayThread then
				task.cancel(delayThread)
			end
			task.spawn(thread, ...)
		end
		function awaiter.Yield()
			thread = coroutine.running()
			delayThread = task.delay(timeout, function()
				awaiter.Resume()
			end)
			return coroutine.yield()
		end
		return awaiter
	end

	local bindableEvent
	beforeEach(function()
		bindableEvent = Instance.new("BindableEvent")
	end)
	afterEach(function()
		bindableEvent:Destroy()
		bindableEvent = nil
	end)

	describe("Single", function()

		it("should spawn a new concur instance", function()
			local value = nil
			expect(function()
				Concur.spawn(function() value = 10 end)
			end).to.never.throw()
			expect(value).to.equal(10)
		end)

		it("should defer a new concur instance", function()
			local awaiter = Awaiter(1)
			expect(function()
				Concur.defer(function() awaiter.Resume(10) end)
			end).to.never.throw()
			local value = awaiter.Yield()
			expect(value).to.equal(10)
		end)

		it("should delay a new concur instance", function()
			local awaiter = Awaiter(1)
			expect(function()
				Concur.delay(0.1, function() awaiter.Resume(10) end)
			end).to.never.throw()
			local value = awaiter.Yield()
			expect(value).to.equal(10)
		end)

		it("should create an immediate value concur instance", function()
			local c
			expect(function()
				c = Concur.value(10)
			end).to.never.throw()
			expect(c).to.be.ok()
			expect(c:IsCompleted()).to.equal(true)
			local err, val = c:Await()
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)

		it("should create a concur instance to watch an event with no predicate", function()
			local c
			expect(function()
				c = Concur.event(bindableEvent.Event)
			end).to.never.throw()
			expect(c:IsCompleted()).to.equal(false)
			bindableEvent:Fire(10)
			local err, val = c:Await(1)
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)

		it("should create a concur instance to watch an event with a predicate", function()
			local c
			expect(function()
				c = Concur.event(bindableEvent.Event, function(v)
					return v < 10
				end)
			end).to.never.throw()
			expect(c:IsCompleted()).to.equal(false)
			bindableEvent:Fire(10)
			bindableEvent:Fire(5)
			local err, val = c:Await(1)
			expect(err).to.never.be.ok()
			expect(val).to.equal(5)
		end)

	end)

	describe("Multi", function()

		it("should complete all concur instances", function()
			local c1 = Concur.spawn(function() return 10 end)
			local c2 = Concur.defer(function() return 20 end)
			local c3 = Concur.delay(0, function() return 30 end)
			local c4 = Concur.spawn(function() error("fail") end)
			local c5 = Concur.event(bindableEvent.Event)
			local c = Concur.all({c1, c2, c3, c4, c5})
			expect(c:IsCompleted()).to.equal(false)
			bindableEvent:Fire(40)
			local err, res = c:Await(1)
			expect(err).to.never.be.ok()
			expect(res[1][1]).to.never.be.ok()
			expect(res[1][2]).to.equal(10)
			expect(res[2][1]).to.never.be.ok()
			expect(res[2][2]).to.equal(20)
			expect(res[3][1]).to.never.be.ok()
			expect(res[3][2]).to.equal(30)
			expect(res[4][1]).to.be.ok()
			expect(res[4][2]).to.never.be.ok()
			expect(res[5][1]).to.never.be.ok()
			expect(res[5][2]).to.equal(40)
		end)

		it("should complete the first concur instance", function()
			local c1 = Concur.defer(function() return 10 end)
			local c2 = Concur.spawn(function() return 20 end)
			local c = Concur.first({c1, c2})
			local err, res = c:Await(1)
			expect(err).to.never.be.ok()
			expect(res).to.equal(20)
		end)
		
	end)

	describe("Stop", function()

		it("should stop a single concur", function()
			local c1 = Concur.defer(function() return 10 end)
			expect(c1:IsCompleted()).to.equal(false)
			c1:Stop()
			expect(c1:IsCompleted()).to.equal(true)
			local err, val = c1:Await()
			expect(err).to.equal(Concur.Errors.Cancelled)
			expect(val).to.never.be.ok()
		end)

		it("should stop multiple concurs", function()
			local c1 = Concur.defer(function() end)
			local c2 = Concur.delay(1, function() end)
			local c3 = Concur.event(bindableEvent.Event)
			local c = Concur.all({c1, c2, c3})
			c:Stop()
			local err, val = c:Await()
			expect(err).to.equal(Concur.Errors.Cancelled)
			expect(val).to.never.be.ok()
		end)

		it("should not stop an already completed concur", function()
			local c1 = Concur.spawn(function() return 10 end)
			expect(c1:IsCompleted()).to.equal(true)
			c1:Stop()
			local err, val = c1:Await()
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)
	
	end)

	describe("IsCompleted", function()
	
		it("should correctly check if a concur instance is completed", function()
			local c1 = Concur.defer(function() end)
			expect(c1:IsCompleted()).to.equal(false)
			local err = c1:Await()
			expect(err).to.never.be.ok()
			expect(c1:IsCompleted()).to.equal(true)
		end)

		it("should be marked as completed if error", function()
			local c1 = Concur.spawn(function() error("err") end)
			expect(c1:IsCompleted()).to.equal(true)
		end)

		it("should be marked as completed if stopped", function()
			local c1 = Concur.defer(function() end)
			c1:Stop()
			expect(c1:IsCompleted()).to.equal(true)
		end)

	end)

	describe("Await", function()

		it("should await concur to be completed", function()
			local c1 = Concur.defer(function() return 10 end)
			local err, val = c1:Await(1)
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)

		it("should await concur to be completed even if error", function()
			local c1 = Concur.defer(function() return error("err") end)
			local err, val = c1:Await(1)
			expect(err).to.be.ok()
			expect(val).to.never.be.ok()
		end)

		it("should await concur to be completed even if stopped", function()
			local c1 = Concur.delay(0.1, function() return 10 end)
			task.defer(function()
				c1:Stop()
			end)
			local err, val = c1:Await(1)
			expect(err).to.equal(Concur.Errors.Cancelled)
			expect(val).to.never.be.ok()
		end)

		it("should return completed values immediately if already completed", function()
			local c1 = Concur.spawn(function() return 10 end)
			expect(c1:IsCompleted()).to.equal(true)
			local err, val = c1:Await()
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)

		it("should timeout", function()
			local c1 = Concur.delay(0.2, function() return 10 end)
			local err, val = c1:Await(0.1)
			expect(err).to.equal(Concur.Errors.Timeout)
			expect(val).to.never.be.ok()
			err, val = c1:Await()
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)
	
	end)

	describe("OnCompleted", function()

		it("should fire function once completed", function()
			local awaiter = Awaiter(0.1)
			local c1 = Concur.defer(function() return 10 end)
			expect(c1:IsCompleted()).to.equal(false)
			c1:OnCompleted(function(err, val)
				awaiter.Resume(err, val)
			end)
			local err, val = awaiter.Yield()
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)

		it("should fire function even if already completed", function()
			local c1 = Concur.spawn(function() return 10 end)
			expect(c1:IsCompleted()).to.equal(true)
			local err, val
			c1:OnCompleted(function(e, v)
				err, val = e, v
			end)
			expect(err).to.never.be.ok()
			expect(val).to.equal(10)
		end)

		it("should fire function even if error", function()
			local awaiter = Awaiter(0.1)
			local c1 = Concur.defer(function() error("err") end)
			c1:OnCompleted(function(err, val)
				awaiter.Resume(err, val)
			end)
			local err, val = awaiter.Yield()
			expect(err).to.be.ok()
			expect(val).to.never.be.ok()
		end)

		it("should fire function even if stopped", function()
			local awaiter = Awaiter(0.2)
			local c1 = Concur.delay(0.1, function() error("err") end)
			c1:OnCompleted(function(err, val)
				awaiter.Resume(err, val)
			end)
			task.defer(function()
				c1:Stop()
			end)
			local err, val = awaiter.Yield()
			expect(err).to.equal(Concur.Errors.Cancelled)
			expect(val).to.never.be.ok()
		end)

		it("should fire function even if timeout", function()
			local awaiter = Awaiter(0.5)
			local c1 = Concur.delay(0.2, function() error("err") end)
			c1:OnCompleted(function(err, val)
				awaiter.Resume(err, val)
			end, 0.1)
			local err, val = awaiter.Yield()
			expect(err).to.equal(Concur.Errors.Timeout)
			expect(val).to.never.be.ok()
		end)

		it("should unbind function", function()
			local c1 = Concur.defer(function() end)
			local val = nil
			local unbind = c1:OnCompleted(function() val = 10 end)
			unbind()
			local err = c1:Await()
			expect(err).to.never.be.ok()
			task.wait()
			expect(val).to.never.be.ok()
		end)
	
	end)

end
