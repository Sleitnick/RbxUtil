return function()

	local Component = require(script.Parent)

	local CollectionService = game:GetService("CollectionService")

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
	function ExtensionTest.Constructing(component)
		component.Data = "a"
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
		Ancestors = {workspace, game:GetService("Lighting")},
		Extensions = {ExtensionTest}
	})

	local AnotherComponent = Component.new({Tag = TAG})
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
			local component = Component.FromInstance(instance, TestComponentMain)
			expect(component).to.be.ok()
		end)

		it("should call lifecycle methods and extension functions", function()
			local instance = CreateTaggedInstance()
			task.wait(0.2)
			local component = Component.FromInstance(instance, TestComponentMain)
			expect(component).to.be.ok()
			expect(component.Data).to.equal("abcdef")
			expect(component.DidHeartbeat).to.equal(true)
			expect(component.DidStepped).to.equal(true)
			expect(component.DidRenderStepped).to.never.equal(true)
			instance:Destroy()
			task.wait()
			expect(component.Data).to.equal("abcdefghi")
		end)

		it("should get another component linked to the same instance", function()
			local instance = CreateTaggedInstance()
			task.wait()
			local component = Component.FromInstance(instance, TestComponentMain)
			expect(component).to.be.ok()
			expect(component.Another).to.be.ok()
			expect(component.Another:GetData()).to.equal(true)
		end)

	end)

end
