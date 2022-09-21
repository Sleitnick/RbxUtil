return function()
	local Trove = require(script.Parent)

	describe("Trove", function()
		local trove

		beforeEach(function()
			trove = Trove.new()
		end)

		afterEach(function()
			if trove then
				trove:Destroy()
				trove = nil
			end
		end)

		it("should add and clean up roblox instance", function()
			local part = Instance.new("Part")
			part.Parent = workspace
			trove:Add(part)
			trove:Destroy()
			expect(part.Parent).to.equal(nil)
		end)

		it("should add and clean up roblox connection", function()
			local connection = workspace.Changed:Connect(function() end)
			trove:Add(connection)
			trove:Destroy()
			expect(connection.Connected).to.equal(false)
		end)

		it("should add and clean up a table with a destroy method", function()
			local tbl = { Destroyed = false }
			function tbl:Destroy()
				self.Destroyed = true
			end
			trove:Add(tbl)
			trove:Destroy()
			expect(tbl.Destroyed).to.equal(true)
		end)

		it("should add and clean up a table with a disconnect method", function()
			local tbl = { Connected = true }
			function tbl:Disconnect()
				self.Connected = false
			end
			trove:Add(tbl)
			trove:Destroy()
			expect(tbl.Connected).to.equal(false)
		end)

		it("should add and clean up a function", function()
			local fired = false
			trove:Add(function()
				fired = true
			end)
			trove:Destroy()
			expect(fired).to.equal(true)
		end)

		it("should allow a custom cleanup method", function()
			local tbl = { Cleaned = false }
			function tbl:Cleanup()
				self.Cleaned = true
			end
			trove:Add(tbl, "Cleanup")
			trove:Destroy()
			expect(tbl.Cleaned).to.equal(true)
		end)

		it("should return the object passed to add", function()
			local part = Instance.new("Part")
			local part2 = trove:Add(part)
			expect(part).to.equal(part2)
			trove:Destroy()
		end)

		it("should fail to add object without proper cleanup method", function()
			local tbl = {}
			expect(function()
				trove:Add(tbl)
			end).to.throw()
		end)

		it("should construct an object and add it", function()
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
			expect(typeof(obj)).to.equal("table")
			expect(getmetatable(obj)).to.equal(class)
			expect(obj._msg).to.equal(msg)
			expect(obj._destroyed).to.equal(false)
			trove:Destroy()
			expect(obj._destroyed).to.equal(true)
		end)

		it("should connect to a signal", function()
			local connection = trove:Connect(workspace.Changed, function() end)
			expect(typeof(connection)).to.equal("RBXScriptConnection")
			expect(connection.Connected).to.equal(true)
			trove:Destroy()
			expect(connection.Connected).to.equal(false)
		end)

		it("should remove an object", function()
			local connection = trove:Connect(workspace.Changed, function() end)
			expect(trove:Remove(connection)).to.equal(true)
			expect(connection.Connected).to.equal(false)
		end)

		it("should not remove an object not in the trove", function()
			local connection = workspace.Changed:Connect(function() end)
			expect(trove:Remove(connection)).to.equal(false)
			expect(connection.Connected).to.equal(true)
			connection:Disconnect()
		end)

		it("should attach to instance", function()
			local part = Instance.new("Part")
			part.Parent = workspace
			local connection = trove:AttachToInstance(part)
			expect(connection.Connected).to.equal(true)
			part:Destroy()
			expect(connection.Connected).to.equal(false)
		end)

		it("should fail to attach to instance not in hierarchy", function()
			local part = Instance.new("Part")
			expect(function()
				trove:AttachToInstance(part)
			end).to.throw()
		end)

		it("should extend itself", function()
			local subTrove = trove:Extend()
			local called = false
			subTrove:Add(function()
				called = true
			end)
			expect(subTrove).to.be.a("table")
			expect(getmetatable(subTrove)).to.equal(Trove)
			trove:Clean()
			expect(called).to.equal(true)
		end)

		it("should clone an instance", function()
			local name = "TroveCloneTest"
			local p1 = trove:Construct(Instance.new, "Part")
			p1.Name = name
			local p2 = trove:Clone(p1)
			expect(typeof(p2)).to.equal("Instance")
			expect(p2).to.never.equal(p1)
			expect(p2.Name).to.equal(name)
			expect(p1.Name).to.equal(p2.Name)
		end)

		it("should clean up a thread", function()
			local co = coroutine.create(function() end)
			trove:Add(co)
			expect(coroutine.status(co)).to.equal("suspended")
			trove:Clean()
			expect(coroutine.status(co)).to.equal("dead")
		end)

		it("should not allow objects added during cleanup", function()
			expect(function()
				trove:Add(function()
					trove:Add(function() end)
				end)
				trove:Clean()
			end).to.throw()
		end)

		it("should not allow objects to be removed during cleanup", function()
			expect(function()
				local f = function() end
				trove:Add(f)
				trove:Add(function()
					trove:Remove(f)
				end)
				trove:Clean()
			end).to.throw()
		end)
	end)
end
