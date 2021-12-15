return function()

	local Streamable = require(script.Parent.Streamable)

	local instanceFolder
	local instanceModel

	local function CreateInstance(name)
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Archivable = false
		folder.Parent = instanceFolder
		return folder
	end

	local function CreatePrimary()
		local primary = Instance.new("Part")
		primary.Anchored = true
		primary.Parent = instanceModel
		instanceModel.PrimaryPart = primary
		return primary
	end

	beforeAll(function()
		instanceFolder = Instance.new("Folder")
		instanceFolder.Name = "KnitTestFolder"
		instanceFolder.Archivable = false
		instanceFolder.Parent = workspace
		instanceModel = Instance.new("Model")
		instanceModel.Name = "KnitTestModel"
		instanceModel.Archivable = false
		instanceModel.Parent = workspace
	end)

	afterEach(function()
		instanceFolder:ClearAllChildren()
		instanceModel:ClearAllChildren()
	end)

	afterAll(function()
		instanceFolder:Destroy()
		instanceModel:Destroy()
	end)

	describe("Streamable", function()

		it("should detect instance that is immediately available", function()
			local testInstance = CreateInstance("TestImmediate")
			local streamable = Streamable.new(instanceFolder, "TestImmediate")
			local observed = 0
			local cleaned = 0
			streamable:Observe(function(_instance, trove)
				observed += 1
				trove:Add(function()
					cleaned += 1
				end)
			end)
			task.wait()
			testInstance.Parent = nil
			task.wait()
			testInstance.Parent = instanceFolder
			task.wait()
			streamable:Destroy()
			task.wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)

		it("should detect instance that is not immediately available", function()
			local streamable = Streamable.new(instanceFolder, "TestImmediate")
			local observed = 0
			local cleaned = 0
			streamable:Observe(function(_instance, trove)
				observed += 1
				trove:Add(function()
					cleaned += 1
				end)
			end)
			task.wait(0.1)
			local testInstance = CreateInstance("TestImmediate")
			task.wait()
			testInstance.Parent = nil
			task.wait()
			testInstance.Parent = instanceFolder
			task.wait()
			streamable:Destroy()
			task.wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)
		
		it("should detect primary part that is immediately available", function()
			local testInstance = CreatePrimary()
			local streamable = Streamable.primary(instanceModel)
			local observed = 0
			local cleaned = 0
			streamable:Observe(function(_instance, trove)
				observed += 1
				trove:Add(function()
					cleaned += 1
				end)
			end)
			task.wait()
			testInstance.Parent = nil
			task.wait()
			testInstance.Parent = instanceModel
			instanceModel.PrimaryPart = testInstance
			task.wait()
			streamable:Destroy()
			task.wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)
		
		it("should detect primary part that is not immediately available", function()
			local streamable = Streamable.primary(instanceModel)
			local observed = 0
			local cleaned = 0
			streamable:Observe(function(_instance, trove)
				observed += 1
				trove:Add(function()
					cleaned += 1
				end)
			end)
			task.wait(0.1)
			local testInstance = CreatePrimary()
			task.wait()
			testInstance.Parent = nil
			task.wait()
			testInstance.Parent = instanceModel
			instanceModel.PrimaryPart = testInstance
			task.wait()
			streamable:Destroy()
			task.wait()
			expect(observed).to.equal(2)
			expect(cleaned).to.equal(2)
		end)

	end)

end
