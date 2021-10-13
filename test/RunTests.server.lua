print("Running unit tests...")
local tests = {}
for _,testFolder in ipairs(script.Parent.modules:GetChildren()) do
	local name = testFolder.Name:match("(.+)_test$")
	local module = testFolder[name]
	table.insert(tests, module)
end
require(script.Parent.Packages.TestEZ).TestBootstrap:run(tests)
