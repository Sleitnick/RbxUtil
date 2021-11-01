print("Running unit tests...")
local TestService = game:GetService("TestService")
local tests = {}
for _,testFolder in ipairs(TestService.modules:GetChildren()) do
	local name = testFolder.Name:match("(.+)_test$")
	local module = testFolder[name]
	table.insert(tests, module)
end
require(TestService.Packages.TestEZ).TestBootstrap:run(tests)
