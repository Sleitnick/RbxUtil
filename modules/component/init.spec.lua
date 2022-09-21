return function()
	local Component = require(script.Parent)

	local CollectionService = game:GetService("CollectionService")
	local RunService = game:GetService("RunService")

	local TAG = "__KnitTestComponent__"

	local taggedInstanceFolder

	local function CreateTaggedInstance()
		local folder = Instance.new("Folder")
		CollectionService:AddTag(folder, TAG)
		folder.Name = "ComponentTest"
		folder.Archivable = false
		folder.Parent = taggedInstanceFolder
		return folder
	end

	local ExtensionTest = {}
	function ExtensionTest.ShouldConstruct(_component)
		return true
	end
	function ExtensionTest.Constructing(component)
		component.Data = "a"
		component.DidHeartbeat = false
		component.DidStepped = false
		component.DidRenderStepped = false
	end
	function ExtensionTest.Constructed(component)
		component.Data ..= "c"
	end
	function ExtensionTest.Starting(component)
		component.Data ..= "d"
	end
	function ExtensionTest.Started(component)
		component.Data ..= "f"
	end
	function ExtensionTest.Stopping(component)
		component.Data ..= "g"
	end
	function ExtensionTest.Stopped(component)
		component.Data ..= "i"
	end

	local TestComponentMain = Component.new({
		Tag = TAG,
		Ancestors = { workspace, game:GetService("Lighting") },
		Extensions = { ExtensionTest },
	})

	local AnotherComponent = Component.new({ Tag = TAG })
	function AnotherComponent:GetData()
		return true
	end

	function TestComponentMain:Construct()
		self.Data ..= "b"
	end

	function TestComponentMain:Start()
		self.Another = self:GetComponent(AnotherComponent)
		self.Data ..= "e"
	end

	function TestComponentMain:Stop()
		self.Data ..= "h"
	end

	function TestComponentMain:HeartbeatUpdate(_dt)
		self.DidHeartbeat = true
	end

	function TestComponentMain:SteppedUpdate(_dt)
		self.DidStepped = true
	end

	function TestComponentMain:RenderSteppedUpdate(_dt)
		self.DidRenderStepped = true
	end

	beforeAll(function()
		taggedInstanceFolder = Instance.new("Folder")
		taggedInstanceFolder.Name = "KnitComponentTest"
		taggedInstanceFolder.Archivable = false
		taggedInstanceFolder.Parent = workspace
	end)

	afterEach(function()
		taggedInstanceFolder:ClearAllChildren()
	end)

	afterAll(function()
		taggedInstanceFolder:Destroy()
		TestComponentMain:Destroy()
	end)

	describe("Component", function()
		it("should capture start and stop events", function()
			local didStart = 0
			local didStop = 0
			local started = TestComponentMain.Started:Connect(function()
				didStart += 1
			end)
			local stopped = TestComponentMain.Stopped:Connect(function()
				didStop += 1
			end)
			local instance = CreateTaggedInstance()
			task.wait()
			instance:Destroy()
			task.wait()
			started:Disconnect()
			stopped:Disconnect()
			expect(didStart).to.equal(1)
			expect(didStop).to.equal(1)
		end)

		it("should be able to get component from the instance", function()
			local instance = CreateTaggedInstance()
			task.wait()
			local component = TestComponentMain:FromInstance(instance)
			expect(component).to.be.ok()
		end)

		it("should be able to get all component instances existing", function()
			local numComponents = 3
			local instances = table.create(numComponents)
			for i = 1, numComponents do
				local instance = CreateTaggedInstance()
				instances[i] = instance
			end
			task.wait()
			local components = TestComponentMain:GetAll()
			expect(components).to.be.a("table")
			expect(#components).to.equal(numComponents)
			for _, c in ipairs(components) do
				expect(table.find(instances, c.Instance)).to.be.ok()
			end
		end)

		it("should call lifecycle methods and extension functions", function()
			local instance = CreateTaggedInstance()
			task.wait(0.2)
			local component = TestComponentMain:FromInstance(instance)
			expect(component).to.be.ok()
			expect(component.Data).to.equal("abcdef")
			expect(component.DidHeartbeat).to.equal(true)
			expect(component.DidStepped).to.equal(RunService:IsRunning())
			expect(component.DidRenderStepped).to.never.equal(true)
			instance:Destroy()
			task.wait()
			expect(component.Data).to.equal("abcdefghi")
		end)

		it("should get another component linked to the same instance", function()
			local instance = CreateTaggedInstance()
			task.wait()
			local component = TestComponentMain:FromInstance(instance)
			expect(component).to.be.ok()
			expect(component.Another).to.be.ok()
			expect(component.Another:GetData()).to.equal(true)
		end)

		it("should use extension to decide whether or not to construct", function()
			local e1 = { c = true }
			function e1.ShouldConstruct(_component)
				return e1.c
			end

			local e2 = { c = true }
			function e2.ShouldConstruct(_component)
				return e2.c
			end

			local e3 = { c = true }
			function e3.ShouldConstruct(_component)
				return e3.c
			end

			local c1 = Component.new({ Tag = TAG, Extensions = { e1 } })
			local c2 = Component.new({ Tag = TAG, Extensions = { e1, e2 } })
			local c3 = Component.new({ Tag = TAG, Extensions = { e1, e2, e3 } })

			local function SetE(a, b, c)
				e1.c = a
				e2.c = b
				e3.c = c
			end

			local function Check(inst, comp, shouldExist)
				local c = comp:FromInstance(inst)
				if shouldExist then
					expect(c).to.be.ok()
				else
					expect(c).to.never.be.ok()
				end
			end

			local function CreateAndCheckAll(a, b, c)
				local instance = CreateTaggedInstance()
				task.wait()
				Check(instance, c1, a)
				Check(instance, c2, b)
				Check(instance, c3, c)
			end

			-- All green:
			SetE(true, true, true)
			CreateAndCheckAll(true, true, true)

			-- All red:
			SetE(false, false, false)
			CreateAndCheckAll(false, false, false)

			-- One red:
			SetE(true, false, true)
			CreateAndCheckAll(true, false, false)

			-- One green:
			SetE(false, false, true)
			CreateAndCheckAll(false, false, false)
		end)

		it("should decide whether or not to use extend", function()
			local e1 = { extend = true }
			function e1.ShouldExtend(_component)
				return e1.extend
			end
			function e1.Constructing(component)
				component.E1 = true
			end

			local e2 = { extend = true }
			function e2.ShouldExtend(_component)
				return e2.extend
			end
			function e2.Constructing(component)
				component.E2 = true
			end

			local TestComponent = Component.new({ Tag = TAG, Extensions = { e1, e2 } })

			local function SetAndCheck(ex1, ex2)
				e1.extend = ex1
				e2.extend = ex2
				local instance = CreateTaggedInstance()
				task.wait()
				local component = TestComponent:FromInstance(instance)
				expect(component).to.be.ok()
				if ex1 then
					expect(component.E1).to.equal(true)
				else
					expect(component.E1).to.never.be.ok()
				end
				if ex2 then
					expect(component.E2).to.equal(true)
				else
					expect(component.E2).to.never.be.ok()
				end
			end

			SetAndCheck(true, true)
			SetAndCheck(false, false)
			SetAndCheck(true, false)
			SetAndCheck(false, true)
		end)

		it("should allow yielding within construct", function()
			local CUSTOM_TAG = "CustomTag"

			local TestComponent = Component.new({ Tag = CUSTOM_TAG })

			local numConstruct = 0

			function TestComponent:Construct()
				numConstruct += 1
				task.wait(0.5)
			end

			local p = Instance.new("Part")
			p.Anchored = true
			p.Parent = game:GetService("ReplicatedStorage")
			CollectionService:AddTag(p, CUSTOM_TAG)
			local newP = p:Clone()
			newP.Parent = workspace

			task.wait(0.6)

			expect(numConstruct).to.equal(1)
			p:Destroy()
			newP:Destroy()
		end)

		it("should wait for instance", function()
			local p = Instance.new("Part")
			p.Anchored = true
			p.Parent = workspace
			task.delay(0.1, function()
				CollectionService:AddTag(p, TAG)
			end)
			local success, c = TestComponentMain:WaitForInstance(p):timeout(1):await()
			expect(success).to.equal(true)
			expect(c).to.be.a("table")
			expect(c.Instance).to.equal(p)
			p:Destroy()
		end)
	end)
end
