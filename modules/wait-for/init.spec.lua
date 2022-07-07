return function()
	local WaitFor = require(script.Parent)
	local Promise = require(script.Parent.Parent.Promise)

	local instances = {}

	local function Create(name, parent)
		local instance = Instance.new("Folder")
		instance.Name = name
		instance.Parent = parent
		table.insert(instances, instance)
		return instance
	end

	afterEach(function()
		for _, inst in ipairs(instances) do
			task.delay(0, function()
				inst:Destroy()
			end)
		end
		table.clear(instances)
	end)

	describe("WaitFor", function()
		it("should wait for child", function()
			local parent = workspace
			local childName = "TestChild"

			task.delay(0.1, Create, childName, parent)

			local success, instance = WaitFor.Child(parent, childName):await()
			expect(success).to.equal(true)
			expect(typeof(instance)).to.equal("Instance")
			expect(instance.Name).to.equal(childName)
			expect(instance.Parent).to.equal(parent)
		end)

		it("should stop waiting for child if parent is unparented", function()
			local parent = Create("SomeParent", workspace)
			local childName = "TestChild"

			task.delay(0.1, function()
				parent:Destroy()
			end)

			local success, err = WaitFor.Child(parent, childName):await()
			expect(success).to.equal(false)
			expect(err).to.equal(WaitFor.Error.Unparented)
		end)

		it("should stop waiting for child if timeout is reached", function()
			local success, err = WaitFor.Child(workspace, "InstanceThatDoesNotExist", 0.1):await()
			expect(success).to.equal(false)
			expect(Promise.Error.isKind(err, Promise.Error.Kind.TimedOut)).to.equal(true)
		end)

		it("should wait for children", function()
			local parent = workspace
			local childrenNames = { "TestChild01", "TestChild02", "TestChild03" }

			task.delay(0.1, Create, childrenNames[1], parent)
			task.delay(0.2, Create, childrenNames[2], parent)
			task.delay(0.05, Create, childrenNames[3], parent)

			local success, children = WaitFor.Children(parent, childrenNames):await()
			expect(success).to.equal(true)
			for i, child in ipairs(children) do
				expect(typeof(child)).to.equal("Instance")
				expect(child.Name).to.equal(childrenNames[i])
				expect(child.Parent).to.equal(parent)
			end
		end)

		it("should fail if any children are no longer parented in parent", function()
			local parent = workspace
			local childrenNames = { "TestChild04", "TestChild05", "TestChild06" }

			local child3

			task.delay(0.1, Create, childrenNames[1], parent)
			task.delay(0.2, Create, childrenNames[2], parent)
			task.delay(0.05, function()
				child3 = Create(childrenNames[3], parent)
			end)
			task.delay(0.1, function()
				child3:Destroy()
			end)

			local success, err = WaitFor.Children(parent, childrenNames):await()
			expect(success).to.equal(false)
			expect(err).to.equal(WaitFor.Error.ParentChanged)
		end)

		it("should wait for descendant", function()
			local parent = workspace
			local descendantName = "TestDescendant"

			task.delay(0.1, Create, descendantName, Create("TestFolder", parent))

			local success, descendant = WaitFor.Descendant(parent, descendantName):await()
			expect(success).to.equal(true)
			expect(typeof(descendant)).to.equal("Instance")
			expect(descendant.Name).to.equal(descendantName)
			expect(descendant:IsDescendantOf(parent)).to.equal(true)
		end)

		it("should wait for many descendants", function()
			local parent = workspace
			local descendantNames = { "TestDescendant01", "TestDescendant02", "TestDescendant03" }

			task.delay(0.1, Create, descendantNames[1], Create("TestFolder1", parent))
			task.delay(0.05, Create, descendantNames[2], Create("TestFolder2", parent))
			task.delay(0.2, Create, descendantNames[3], Create("TestFolder4", Create("TestFolder3", parent)))

			local success, descendants = WaitFor.Descendants(parent, descendantNames):await()
			expect(success).to.equal(true)
			for i, descendant in ipairs(descendants) do
				expect(typeof(descendant)).to.equal("Instance")
				expect(descendant.Name == descendantNames[i]).to.equal(true)
				expect(descendant:IsDescendantOf(parent)).to.equal(true)
			end
		end)

		it("should wait for primarypart", function()
			local model = Instance.new("Model")
			local part = Instance.new("Part")
			part.Anchored = true

			part.Parent = model
			model.Parent = workspace

			task.delay(0.1, function()
				model.PrimaryPart = part
			end)

			local success, primary = WaitFor.PrimaryPart(model):await()
			expect(success).to.equal(true)
			expect(typeof(primary)).to.equal("Instance")
			expect(primary).to.equal(part)
			expect(model.PrimaryPart).to.equal(primary)

			model:Destroy()
		end)

		it("should wait for objectvalue", function()
			local objValue = Instance.new("ObjectValue")
			objValue.Parent = workspace

			local instance = Create("SomeInstance", workspace)

			task.delay(0.1, function()
				objValue.Value = instance
			end)

			local success, value = WaitFor.ObjectValue(objValue):await()
			expect(success).to.equal(true)
			expect(typeof(value)).to.equal("Instance")
			expect(value).to.equal(instance)
			expect(objValue.Value == value)

			objValue:Destroy()
		end)

		it("should wait for custom predicate", function()
			local instance
			task.delay(0.1, function()
				instance = Create("CustomInstance", workspace)
			end)

			local success, inst = WaitFor.Custom(function()
				return instance
			end):await()
			expect(success).to.equal(true)
			expect(typeof(inst)).to.equal("Instance")
			expect(inst).to.equal(instance)
		end)
	end)
end
