local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Trove = require(script.Parent)

	ctx:Describe("Trove", function()
		local trove

		ctx:BeforeEach(function()
			trove = Trove.new()
		end)

		ctx:AfterEach(function()
			if trove then
				trove:Destroy()
				trove = nil
			end
		end)

		ctx:Test("should add and clean up roblox instance", function()
			local part = Instance.new("Part")
			part.Parent = workspace
			trove:Add(part)
			trove:Destroy()
			ctx:Expect(part.Parent):ToBeNil()
		end)

		ctx:Test("should add and clean up roblox connection", function()
			local connection = workspace.Changed:Connect(function() end)
			trove:Add(connection)
			trove:Destroy()
			ctx:Expect(connection.Connected):ToBe(false)
		end)

		ctx:Test("should add and clean up a table with a destroy method", function()
			local tbl = { Destroyed = false }
			function tbl:Destroy()
				self.Destroyed = true
			end
			trove:Add(tbl)
			trove:Destroy()
			ctx:Expect(tbl.Destroyed):ToBe(true)
		end)

		ctx:Test("should add and clean up a table with a disconnect method", function()
			local tbl = { Connected = true }
			function tbl:Disconnect()
				self.Connected = false
			end
			trove:Add(tbl)
			trove:Destroy()
			ctx:Expect(tbl.Connected):ToBe(false)
		end)

		ctx:Test("should add and clean up a function", function()
			local fired = false
			trove:Add(function()
				fired = true
			end)
			trove:Destroy()
			ctx:Expect(fired):ToBe(true)
		end)

		ctx:Test("should allow a custom cleanup method", function()
			local tbl = { Cleaned = false }
			function tbl:Cleanup()
				self.Cleaned = true
			end
			trove:Add(tbl, "Cleanup")
			trove:Destroy()
			ctx:Expect(tbl.Cleaned):ToBe(true)
		end)

		ctx:Test("should return the object passed to add", function()
			local part = Instance.new("Part")
			local part2 = trove:Add(part)
			ctx:Expect(part):ToBe(part2)
			trove:Destroy()
		end)

		ctx:Test("should fail to add object without proper cleanup method", function()
			local tbl = {}
			ctx:Expect(function()
				trove:Add(tbl)
			end):ToThrow()
		end)

		ctx:Test("should construct an object and add it", function()
			local class = {}
			class.__index = class
			function class.new(msg)
				local self = setmetatable({}, class)
				self._msg = msg
				self._destroyed = false
				return self
			end
			function class:Destroy()
				self._destroyed = true
			end
			local msg = "abc"
			local obj = trove:Construct(class, msg)
			ctx:Expect(typeof(obj)):ToBe("table")
			ctx:Expect(getmetatable(obj)):ToBe(class)
			ctx:Expect(obj._msg):ToBe(msg)
			ctx:Expect(obj._destroyed):ToBe(false)
			trove:Destroy()
			ctx:Expect(obj._destroyed):ToBe(true)
		end)

		ctx:Test("should connect to a signal", function()
			local connection = trove:Connect(workspace.Changed, function() end)
			ctx:Expect(typeof(connection)):ToBe("RBXScriptConnection")
			ctx:Expect(connection.Connected):ToBe(true)
			trove:Destroy()
			ctx:Expect(connection.Connected):ToBe(false)
		end)

		ctx:Test("should remove an object", function()
			local connection = trove:Connect(workspace.Changed, function() end)
			ctx:Expect(trove:Remove(connection)):ToBe(true)
			ctx:Expect(connection.Connected):ToBe(false)
		end)

		ctx:Test("should not remove an object not in the trove", function()
			local connection = workspace.Changed:Connect(function() end)
			ctx:Expect(trove:Remove(connection)):ToBe(false)
			ctx:Expect(connection.Connected):ToBe(true)
			connection:Disconnect()
		end)

		ctx:Test("should attach to instance", function()
			local part = Instance.new("Part")
			part.Parent = workspace
			local connection = trove:AttachToInstance(part)
			ctx:Expect(connection.Connected):ToBe(true)
			part:Destroy()
			ctx:Expect(connection.Connected):ToBe(false)
		end)

		ctx:Test("should fail to attach to instance not in hierarchy", function()
			local part = Instance.new("Part")
			ctx:Expect(function()
				trove:AttachToInstance(part)
			end):ToThrow()
		end)

		ctx:Test("should extend itself", function()
			local subTrove = trove:Extend()
			local called = false
			subTrove:Add(function()
				called = true
			end)
			ctx:Expect(typeof(subTrove)):ToBe("table")
			ctx:Expect(getmetatable(subTrove)):ToBe(getmetatable(trove))
			trove:Clean()
			ctx:Expect(called):ToBe(true)
		end)

		ctx:Test("should clone an instance", function()
			local name = "TroveCloneTest"
			local p1 = trove:Construct(Instance.new, "Part")
			p1.Name = name
			local p2 = trove:Clone(p1)
			ctx:Expect(typeof(p2)):ToBe("Instance")
			ctx:Expect(p2):Not():ToBe(p1)
			ctx:Expect(p2.Name):ToBe(name)
			ctx:Expect(p1.Name):ToBe(p2.Name)
		end)

		ctx:Test("should clean up a thread", function()
			local co = coroutine.create(function() end)
			trove:Add(co)
			ctx:Expect(coroutine.status(co)):ToBe("suspended")
			trove:Clean()
			ctx:Expect(coroutine.status(co)):ToBe("dead")
		end)

		ctx:Test("should not allow objects added during cleanup", function()
			local added = false
			trove:Add(function()
				trove:Add(function() end)
				added = true
			end)
			trove:Clean()

			ctx:Expect(added):ToBe(false)
		end)

		ctx:Test("should not allow objects to be removed during cleanup", function()
			local f = function() end
			local removed = false
			trove:Add(f)
			trove:Add(function()
				trove:Remove(f)
				removed = true
			end)

			ctx:Expect(removed):ToBe(false)
		end)
	end)
end
