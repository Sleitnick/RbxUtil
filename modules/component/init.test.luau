local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Component = require(script.Parent)

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

	ctx:BeforeAll(function()
		taggedInstanceFolder = Instance.new("Folder")
		taggedInstanceFolder.Name = "KnitComponentTest"
		taggedInstanceFolder.Archivable = false
		taggedInstanceFolder.Parent = workspace
	end)

	ctx:AfterAll(function()
		taggedInstanceFolder:Destroy()
		TestComponentMain:Destroy()
	end)

	ctx:Describe("Component", function()
		ctx:AfterEach(function()
			taggedInstanceFolder:ClearAllChildren()
		end)

		ctx:Test("should capture start and stop events", function()
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
			ctx:Expect(didStart):ToBe(1)
			ctx:Expect(didStop):ToBe(1)
		end)

		ctx:Test("should be able to get component from the instance", function()
			local instance = CreateTaggedInstance()
			task.wait()
			local component = TestComponentMain:FromInstance(instance)
			ctx:Expect(component):ToBeOk()
		end)

		ctx:Test("should be able to get all component instances existing", function()
			local numComponents = 3
			local instances = table.create(numComponents)
			for i = 1, numComponents do
				local instance = CreateTaggedInstance()
				instances[i] = instance
			end
			task.wait()
			local components = TestComponentMain:GetAll()
			ctx:Expect(components):ToBeA("table")
			ctx:Expect(components):ToHaveLength(numComponents)
			for _, c in components do
				ctx:Expect(table.find(instances, c.Instance)):ToBeOk()
			end
		end)

		ctx:Test("should call lifecycle methods and extension functions", function()
			local instance = CreateTaggedInstance()
			task.wait(0.2)
			local component = TestComponentMain:FromInstance(instance)
			ctx:Expect(component):ToBeOk()
			ctx:Expect(component.Data):ToBe("abcdef")
			ctx:Expect(component.DidHeartbeat):ToBe(true)
			ctx:Expect(component.DidStepped):ToBe(RunService:IsRunning())
			ctx:Expect(component.DidRenderStepped):Not():ToBe(true)
			instance:Destroy()
			task.wait()
			ctx:Expect(component.Data):ToBe("abcdefghi")
		end)

		ctx:Test("should get another component linked to the same instance", function()
			local instance = CreateTaggedInstance()
			task.wait()
			local component = TestComponentMain:FromInstance(instance)
			ctx:Expect(component):ToBeOk()
			ctx:Expect(component.Another):ToBeOk()
			ctx:Expect(component.Another:GetData()):ToBe(true)
		end)

		ctx:Test("should use extension to decide whether or not to construct", function()
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
					ctx:Expect(c):ToBeOk()
				else
					ctx:Expect(c):ToBeNil()
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

		ctx:Test("should decide whether or not to use extend", function()
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
				ctx:Expect(component):ToBeOk()
				if ex1 then
					ctx:Expect(component.E1):ToBe(true)
				else
					ctx:Expect(component.E1):ToBeNil()
				end
				if ex2 then
					ctx:Expect(component.E2):ToBe(true)
				else
					ctx:Expect(component.E2):ToBeNil()
				end
			end

			SetAndCheck(true, true)
			SetAndCheck(false, false)
			SetAndCheck(true, false)
			SetAndCheck(false, true)
		end)

		ctx:Test("should allow yielding within construct", function()
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

			ctx:Expect(numConstruct):ToBe(1)
			p:Destroy()
			newP:Destroy()
		end)

		ctx:Test("should wait for instance", function()
			local p = Instance.new("Part")
			p.Anchored = true
			p.Parent = workspace
			task.delay(0.1, function()
				CollectionService:AddTag(p, TAG)
			end)
			local success, c = TestComponentMain:WaitForInstance(p):timeout(1):await()
			ctx:Expect(success):ToBe(true)
			ctx:Expect(c):ToBeA("table")
			ctx:Expect(c.Instance):ToBe(p)
			p:Destroy()
		end)
	end)
end
