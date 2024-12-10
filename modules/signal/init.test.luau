local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

local function AwaitCondition(predicate: () -> boolean, timeout: number?)
	local start = os.clock()
	timeout = (timeout or 10)
	while true do
		if predicate() then
			return true
		end
		if (os.clock() - start) > timeout then
			return false
		end
		task.wait()
	end
end

return function(ctx: Test.TestContext)
	local Signal = require(script.Parent)

	local signal

	local function NumConns(sig)
		sig = sig or signal
		return #sig:GetConnections()
	end

	ctx:BeforeEach(function()
		signal = Signal.new()
	end)

	ctx:AfterEach(function()
		signal:Destroy()
	end)

	ctx:Describe("Constructor", function()
		ctx:Test("should create a new signal and fire it", function()
			ctx:Expect(Signal.Is(signal)):ToBe(true)
			task.defer(function()
				signal:Fire(10, 20)
			end)
			local n1, n2 = signal:Wait()
			ctx:Expect(n1):ToBe(10)
			ctx:Expect(n2):ToBe(20)
		end)

		ctx:Test("should create a proxy signal and connect to it", function()
			local signalWrap = Signal.Wrap(game:GetService("RunService").Heartbeat)
			ctx:Expect(Signal.Is(signalWrap)):ToBe(true)
			local fired = false
			signalWrap:Connect(function()
				fired = true
			end)
			ctx:Expect(AwaitCondition(function()
				return fired
			end, 2)):ToBe(true)
			signalWrap:Destroy()
		end)
	end)

	ctx:Describe("FireDeferred", function()
		ctx:Test("should be able to fire primitive argument", function()
			local send = 10
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:FireDeferred(send)
			ctx:Expect(AwaitCondition(function()
				return (send == value)
			end, 1)):ToBe(true)
		end)

		ctx:Test("should be able to fire a reference based argument", function()
			local send = { 10, 20 }
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:FireDeferred(send)
			ctx:Expect(AwaitCondition(function()
				return (send == value)
			end, 1)):ToBe(true)
		end)
	end)

	ctx:Describe("Fire", function()
		ctx:Test("should be able to fire primitive argument", function()
			local send = 10
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:Fire(send)
			ctx:Expect(value):ToBe(send)
		end)

		ctx:Test("should be able to fire a reference based argument", function()
			local send = { 10, 20 }
			local value
			signal:Connect(function(v)
				value = v
			end)
			signal:Fire(send)
			ctx:Expect(value):ToBe(send)
		end)
	end)

	ctx:Describe("ConnectOnce", function()
		ctx:Test("should only capture first fire", function()
			local value
			local c = signal:ConnectOnce(function(v)
				value = v
			end)
			ctx:Expect(c.Connected):ToBe(true)
			signal:Fire(10)
			ctx:Expect(c.Connected):ToBe(false)
			signal:Fire(20)
			ctx:Expect(value):ToBe(10)
		end)
	end)

	ctx:Describe("Wait", function()
		ctx:Test("should be able to wait for a signal to fire", function()
			task.defer(function()
				signal:Fire(10, 20, 30)
			end)
			local n1, n2, n3 = signal:Wait()
			ctx:Expect(n1):ToBe(10)
			ctx:Expect(n2):ToBe(20)
			ctx:Expect(n3):ToBe(30)
		end)
	end)

	ctx:Describe("DisconnectAll", function()
		ctx:Test("should disconnect all connections", function()
			signal:Connect(function() end)
			signal:Connect(function() end)
			ctx:Expect(NumConns()):ToBe(2)
			signal:DisconnectAll()
			ctx:Expect(NumConns()):ToBe(0)
		end)
	end)

	ctx:Describe("Disconnect", function()
		ctx:Test("should disconnect connection", function()
			local con = signal:Connect(function() end)
			ctx:Expect(NumConns()):ToBe(1)
			con:Disconnect()
			ctx:Expect(NumConns()):ToBe(0)
		end)

		ctx:Test("should still work if connections disconnected while firing", function()
			local a = 0
			local c
			signal:Connect(function()
				a += 1
			end)
			c = signal:Connect(function()
				c:Disconnect()
				a += 1
			end)
			signal:Connect(function()
				a += 1
			end)
			signal:Fire()
			ctx:Expect(a):ToBe(3)
		end)

		ctx:Test("should still work if connections disconnected while firing deferred", function()
			local a = 0
			local c
			signal:Connect(function()
				a += 1
			end)
			c = signal:Connect(function()
				c:Disconnect()
				a += 1
			end)
			signal:Connect(function()
				a += 1
			end)
			signal:FireDeferred()
			ctx:Expect(AwaitCondition(function()
				return a == 3
			end)):ToBe(true)
		end)
	end)
end
