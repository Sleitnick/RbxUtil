local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Promise = require(script.Parent.Parent.Promise)
	local WaitFor = require(script.Parent)

	local instances = {}

	local function Create(name, parent)
		local instance = Instance.new("Folder")
		instance.Name = name
		instance.Parent = parent
		table.insert(instances, instance)
		return instance
	end

	ctx:Describe("WaitFor", function()
		ctx:AfterEach(function()
			for _, inst in ipairs(instances) do
				task.delay(0, function()
					inst:Destroy()
				end)
			end
			table.clear(instances)
		end)

		ctx:Test("should wait for child", function()
			local parent = workspace
			local childName = "TestChild"

			task.delay(0.1, Create, childName, parent)

			local success, instance = WaitFor.Child(parent, childName):await()
			ctx:Expect(success):ToBe(true)
			ctx:Expect(typeof(instance)):ToBe("Instance")
			ctx:Expect(instance.Name):ToBe(childName)
			ctx:Expect(instance.Parent):ToBe(parent)
		end)

		ctx:Test("should stop waiting for child if parent is unparented", function()
			local parent = Create("SomeParent", workspace)
			local childName = "TestChild"

			task.delay(0.1, function()
				parent:Destroy()
			end)

			local success, err = WaitFor.Child(parent, childName):await()
			ctx:Expect(success):ToBe(false)
			ctx:Expect(err):ToBe(WaitFor.Error.Unparented)
		end)

		ctx:Test("should stop waiting for child if timeout is reached", function()
			local success, err = WaitFor.Child(workspace, "InstanceThatDoesNotExist", 0.1):await()
			ctx:Expect(success):ToBe(false)
			ctx:Expect(Promise.Error.isKind(err, Promise.Error.Kind.TimedOut)):ToBe(true)
		end)

		ctx:Test("should wait for children", function()
			local parent = workspace
			local childrenNames = { "TestChild01", "TestChild02", "TestChild03" }

			task.delay(0.1, Create, childrenNames[1], parent)
			task.delay(0.2, Create, childrenNames[2], parent)
			task.delay(0.05, Create, childrenNames[3], parent)

			local success, children = WaitFor.Children(parent, childrenNames):await()
			ctx:Expect(success):ToBe(true)
			for i, child in ipairs(children) do
				ctx:Expect(typeof(child)):ToBe("Instance")
				ctx:Expect(child.Name):ToBe(childrenNames[i])
				ctx:Expect(child.Parent):ToBe(parent)
			end
		end)

		ctx:Test("should fail if any children are no longer parented in parent", function()
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
			ctx:Expect(success):ToBe(false)
			ctx:Expect(err):ToBe(WaitFor.Error.ParentChanged)
		end)

		ctx:Test("should wait for descendant", function()
			local parent = workspace
			local descendantName = "TestDescendant"

			task.delay(0.1, Create, descendantName, Create("TestFolder", parent))

			local success, descendant = WaitFor.Descendant(parent, descendantName):await()
			ctx:Expect(success):ToBe(true)
			ctx:Expect(typeof(descendant)):ToBe("Instance")
			ctx:Expect(descendant.Name):ToBe(descendantName)
			ctx:Expect(descendant:IsDescendantOf(parent)):ToBe(true)
		end)

		ctx:Test("should wait for many descendants", function()
			local parent = workspace
			local descendantNames = { "TestDescendant01", "TestDescendant02", "TestDescendant03" }

			task.delay(0.1, Create, descendantNames[1], Create("TestFolder1", parent))
			task.delay(0.05, Create, descendantNames[2], Create("TestFolder2", parent))
			task.delay(0.2, Create, descendantNames[3], Create("TestFolder4", Create("TestFolder3", parent)))

			local success, descendants = WaitFor.Descendants(parent, descendantNames):await()
			ctx:Expect(success):ToBe(true)
			for i, descendant in ipairs(descendants) do
				ctx:Expect(typeof(descendant)):ToBe("Instance")
				ctx:Expect(descendant.Name == descendantNames[i]):ToBe(true)
				ctx:Expect(descendant:IsDescendantOf(parent)):ToBe(true)
			end
		end)

		ctx:Test("should wait for primarypart", function()
			local model = Instance.new("Model")
			local part = Instance.new("Part")
			part.Anchored = true

			part.Parent = model
			model.Parent = workspace

			task.delay(0.1, function()
				model.PrimaryPart = part
			end)

			local success, primary = WaitFor.PrimaryPart(model):await()
			ctx:Expect(success):ToBe(true)
			ctx:Expect(typeof(primary)):ToBe("Instance")
			ctx:Expect(primary):ToBe(part)
			ctx:Expect(model.PrimaryPart):ToBe(primary)

			model:Destroy()
		end)

		ctx:Test("should wait for objectvalue", function()
			local objValue = Instance.new("ObjectValue")
			objValue.Parent = workspace

			local instance = Create("SomeInstance", workspace)

			task.delay(0.1, function()
				objValue.Value = instance
			end)

			local success, value = WaitFor.ObjectValue(objValue):await()
			ctx:Expect(success):ToBe(true)
			ctx:Expect(typeof(value)):ToBe("Instance")
			ctx:Expect(value):ToBe(instance)
			ctx:Expect(objValue.Value == value)

			objValue:Destroy()
		end)

		ctx:Test("should wait for custom predicate", function()
			local instance
			task.delay(0.1, function()
				instance = Create("CustomInstance", workspace)
			end)

			local success, inst = WaitFor.Custom(function()
				return instance
			end):await()
			ctx:Expect(success):ToBe(true)
			ctx:Expect(typeof(inst)):ToBe("Instance")
			ctx:Expect(inst):ToBe(instance)
		end)
	end)
end
