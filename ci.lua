print("Running unit tests...")

local TestService = game:GetService("TestService")
local TestEZ = require(TestService.Packages.TestEZ)

local tests = {}
for _,testFolder in ipairs(TestService.modules:GetChildren()) do
	local name = testFolder.Name:match("(.+)_test$")
	local module = testFolder:FindFirstChild(name)
	if module then
		table.insert(tests, module)
	else
		print("Failed to find module within " .. testFolder.Name)
	end
end

TestEZ.TestBootstrap:run(tests)
