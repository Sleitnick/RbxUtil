print("Running unit tests...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage.Test.Packages.TestEZ)

-- local tests = {}
-- for _,testFolder in ipairs(TestService.modules:GetChildren()) do
-- 	local name = testFolder.Name:match("(.+)_test$")
-- 	local module = testFolder:FindFirstChild(name)
-- 	if module then
-- 		table.insert(tests, module)
-- 	else
-- 		print("Failed to find module within " .. testFolder.Name)
-- 	end
-- end

-- TestEZ.TestBootstrap:run(tests)

-- Clear out package test files
for _,testFolder in ipairs(ReplicatedStorage.Test.modules:GetChildren()) do
	local index = testFolder:FindFirstChild("_Index")
	if index then
		for _,item in ipairs(index:GetDescendants()) do
			if item.Name:match("%.spec$") and item:IsA("ModuleScript") then
				item:Destroy()
			end
		end
	end
end

-- Run tests
TestEZ.TestBootstrap:run({ReplicatedStorage.Test.modules})
