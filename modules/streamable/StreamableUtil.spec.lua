return function()
	local Streamable = require(script.Parent.Streamable)
	local StreamableUtil = require(script.Parent.StreamableUtil)

	local instanceFolder

	local function CreateInstance(name)
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Archivable = false
		folder.Parent = instanceFolder
		return folder
	end

	beforeAll(function()
		instanceFolder = Instance.new("Folder")
		instanceFolder.Name = "KnitTest"
		instanceFolder.Archivable = false
		instanceFolder.Parent = workspace
	end)

	afterEach(function()
		instanceFolder:ClearAllChildren()
	end)

	afterAll(function()
		instanceFolder:Destroy()
	end)

	describe("Compound", function()
		it("should capture multiple streams", function()
			local s1 = Streamable.new(instanceFolder, "ABC")
			local s2 = Streamable.new(instanceFolder, "XYZ")
			local observe = 0
			local cleaned = 0
			StreamableUtil.Compound({ S1 = s1, S2 = s2 }, function(_streamables, trove)
				observe += 1
				trove:Add(function()
					cleaned += 1
				end)
			end)
			local i1 = CreateInstance("ABC")
			local i2 = CreateInstance("XYZ")
			task.wait()
			i1.Parent = nil
			task.wait()
			i1.Parent = instanceFolder
			task.wait()
			i1.Parent = nil
			i2.Parent = nil
			task.wait()
			i2.Parent = instanceFolder
			task.wait()
			expect(observe).to.equal(2)
			expect(cleaned).to.equal(2)
			s1:Destroy()
			s2:Destroy()
		end)
	end)
end
