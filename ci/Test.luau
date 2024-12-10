type TestResult = {}

type TestInstance = {
	Fn: () -> TestResult,
}

export type TestExpect = {
	Not: (self: TestExpect) -> TestExpect,
	ToBe: (self: TestExpect, value: any) -> (),
	ToBeNaN: (self: TestExpect, value: any) -> (),
	ToBeNil: (self: TestExpect) -> (),
	ToThrow: (self: TestExpect, err: any?) -> (),
}

local TestExpect = {}
TestExpect.__index = TestExpect

function TestExpect:ToBe(value: any)
	local condition = self.Value == value
	assert(if self.Flip then not condition else condition)
end

function TestExpect:ToBeNil()
	local condition = self.Value ~= nil
	assert(if self.Flip then not condition else condition)
end

function TestExpect:ToBeNaN()
	local nan = self.Value ~= self.Value
	assert(if self.Flip then not nan else nan)
end

function TestExpect:ToThrow(err: any?)
	local condition: boolean
	if err ~= nil then
		condition = (not self.Success) and self.Err == err
	else
		condition = not self.Success
	end
	assert(if self.Flip then not condition else condition)
end

function TestExpect:Not()
	self.Flip = not self.Flip
	return self
end

export type TestContext = {
	Test: (self: TestContext, name: string, fn: () -> ()) -> (),
	Describe: (self: TestContext, name: string, fn: () -> ()) -> (),
	Expect: (self: TestContext, value: any) -> TestExpect,
}

local TestContext = {}
TestContext.__index = TestContext

function TestContext.new(root: string): TestContext
	local testContext = setmetatable({
		Group = {
			Name = root,
			Items = {},
			AnyFail = false,
		},
	}, TestContext) :: any

	testContext.Current = testContext.Group

	return testContext
end

function TestContext:Test(name: string, fn: () -> ())
	local success, err = pcall(fn)
	self.Current.Items[name] = {
		Success = success,
		Err = err,
	}
	if not success then
		self.Current.AnyFail = true
	end
end

function TestContext:Describe(name: string, fn: () -> ())
	local parentGroup = self.Current
	local group = {
		Name = name,
		Items = {},
		AnyFail = false,
	}
	self.Current = group
	parentGroup.Items[name] = group
	fn()
	self.Current = parentGroup
	if group.AnyFail then
		parentGroup.AnyFail = true
	end
end

function TestContext:Expect(value: any): TestExpect
	local resolvedValue = value
	local success, err = true, nil
	if typeof(value) == "function" then
		success, err = pcall(value)
		resolvedValue = if success then err else nil
	end
	return setmetatable({ Value = resolvedValue, Success = success, Err = err, Flip = false }, TestExpect) :: any
end

local Test = {}

function Test.run(ancestors: { Instance })
	local tests: { [string]: TestInstance } = {}

	for _, ancestor in ancestors do
		for _, child in ancestor:GetDescendants() do
			if child:IsA("ModuleScript") and string.match(child.Name, "%.test$") ~= nil then
				local name = (string.match(child.Name, "(.+)%.test$")) or child.Name
				local fn = require(child)
				tests[name] = fn
			end
		end
	end

	local results: { TestContext } = {}
	local allPass = true

	for name, test in tests do
		local context = TestContext.new(name)
		local success, err = pcall(test, context)
		if not success then
			error(`Test runner failed: {err}`)
		end
		table.insert(results, context)
		if context.Group.AnyFail then
			allPass = false
		end
	end

	-- Print results:
	print(results)
	local output = { "Test Results" }
	local function out(str: string)
		table.insert(output, str)
	end
	local tab = "    "
	for _, res in results do
		local function Output(group, lvl)
			out(`{string.rep(tab, lvl)}[{if group.AnyFail then "x" else "✓"}] {group.Name}`)
			for name, item in group.Items do
				if item.Items then
					Output(item, lvl + 1)
				else
					out(
						`{string.rep(tab, lvl + 1)}[{if not item.Success then "x" else "✓"}] {name}{if not item.Success
							then `\n{string.rep(tab, lvl + 2)}[{item.Err}]`
							else ""}`
					)
				end
			end
		end
		Output(res.Group, 0)
	end
	local outputTxt = table.concat(output, "\n")

	return {
		Results = results,
		AllPass = allPass,
		Output = outputTxt,
	}
end

return Test
