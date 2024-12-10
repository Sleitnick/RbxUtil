export type TestExpect = {
	Not: (self: TestExpect) -> TestExpect,
	ToBe: (self: TestExpect, value: any) -> (),
	ToBeNaN: (self: TestExpect, value: any) -> (),
	ToBeNil: (self: TestExpect) -> (),
	ToBeOk: (self: TestExpect) -> (),
	ToBeTruthy: (self: TestExpect) -> (),
	ToBeFalsy: (self: TestExpect) -> (),
	ToThrow: (self: TestExpect, err: any?) -> (),
	ToHaveLength: (self: TestExpect, length: number) -> (),
	ToHaveProperty: (self: TestExpect, property: string) -> (),
	ToBeGreaterThan: (self: TestExpect, value: number) -> (),
	ToBeGreaterThanOrEqual: (self: TestExpect, value: number) -> (),
	ToBeLessThan: (self: TestExpect, value: number) -> (),
	ToBeLessThanOrEqual: (self: TestExpect, value: number) -> (),
	ToContain: (self: TestExpect, value: any) -> (),
	ToBeNear: (self: TestExpect, value: number, epsilon: number) -> (),
	ToBeA: (self: TestExpect, typeOf: string) -> (),
}

local TestExpect = {}
TestExpect.__index = TestExpect

function TestExpect:ToBe(value: any)
	local condition = self.Value == value
	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "!=" else "=="} {value}`, 0)
	end
end

function TestExpect:ToBeNil()
	local condition = self.Value == nil
	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "!=" else "=="} nil`, 0)
	end
end

function TestExpect:ToBeOk()
	local condition = self.Value ~= nil
	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "is not" else "is"} ok`, 0)
	end
end

function TestExpect:ToBeNaN()
	local condition = self.Value ~= self.Value
	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "!=" else "=="} NaN`, 0)
	end
end

function TestExpect:ToThrow(err: any?)
	local condition: boolean
	if err ~= nil then
		condition = (not self.Success) and self.Err == err
	else
		condition = not self.Success
	end

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{if self.Flip then "expected to not throw" else "expected to throw"}`, 0)
	end
end

function TestExpect:ToBeTruthy()
	local condition = not not self.Value

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "not truthy" else "truthy"}`, 0)
	end
end

function TestExpect:ToBeFalsy()
	local condition = not self.Value

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "not falsy" else "falsy"}`, 0)
	end
end

function TestExpect:ToHaveLength(length: number)
	local t = typeof(self.Value)
	local validType = t == "string" or t == "table"
	local condition = validType and #self.Value == length

	if self.Flip and validType then
		condition = not condition
	end

	if not condition then
		if validType then
			error(`{t} length ({#self.Value}) {if self.Flip then "!=" else "=="} {length}`, 0)
		else
			error(`invalid type "{t}" (expected table or string)`, 0)
		end
	end
end

function TestExpect:ToHaveProperty(property: string)
	local t = typeof(self.Value)
	local validType = t == "table"
	local condition = validType and self.Value[property] ~= nil

	if self.Flip and validType then
		condition = not condition
	end

	if not condition then
		if validType then
			error(`table {if self.Flip then "does not contain" else "contains"} property "{property}"`, 0)
		else
			error(`invalid type "{t}" (expected table)`, 0)
		end
	end
end

function TestExpect:ToBeGreaterThan(value: number)
	local condition = self.Value > value

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "<=" else ">"} {value}`, 0)
	end
end

function TestExpect:ToBeGreaterThanOrEqual(value: number)
	local condition = self.Value >= value

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "<" else ">="} {value}`, 0)
	end
end

function TestExpect:ToBeLessThan(value: number)
	local condition = self.Value < value

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then ">=" else "<"} {value}`, 0)
	end
end

function TestExpect:ToBeLessThanOrEqual(value: number)
	local condition = self.Value <= value

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then ">" else "<="} {value}`, 0)
	end
end

function TestExpect:ToContain(value: any)
	local t = typeof(self.Value)
	local valid = t == "table" or t == "string"
	if t == "string" then
		valid = typeof(value) == "string"
	end

	local condition = false

	if valid then
		if t == "table" then
			condition = table.find(self.Value, value) ~= nil
		else
			condition = string.find(self.Value, value) ~= nil
		end
	end

	if self.Flip and valid then
		condition = not condition
	end

	if not condition then
		if valid then
			error(`"{value}" {if self.Flip then "not in" else "in"} {t}`, 0)
		else
			error(`invalid type "{t}" (expected table or string)`, 0)
		end
	end
end

function TestExpect:ToBeA(t: string)
	local condition = typeof(self.Value) == t

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`"{typeof(self.Value)}" {if self.Flip then "!=" else "=="} "{t}"`, 0)
	end
end

function TestExpect:ToBeNear(value: number, epsilon: number)
	local condition = math.abs(self.Value - value) < epsilon

	if self.Flip then
		condition = not condition
	end

	if not condition then
		error(`{self.Value} {if self.Flip then "is not near" else "is near"} {value}`, 0)
	end
end

function TestExpect:Not()
	self.Flip = not self.Flip
	return self
end

------------------------------------------------------------------------------------------------------------

export type TestContext = {
	Test: (self: TestContext, name: string, fn: () -> ()) -> (),
	Describe: (self: TestContext, name: string, fn: () -> ()) -> (),
	Expect: (self: TestContext, value: any) -> TestExpect,
	BeforeAll: (self: TestContext, fn: () -> ()) -> (),
	AfterAll: (self: TestContext, fn: () -> ()) -> (),
	BeforeEach: (self: TestContext, fn: () -> ()) -> (),
	AfterEach: (self: TestContext, fn: () -> ()) -> (),
}

type TestContextGroup = {
	Name: string,
	Items: { any },
	AnyFail: boolean,
	AfterAllFns: { () -> () },
	BeforeEachFns: { () -> () },
	AfterEachFns: { () -> () },
}

local function CreateGroup(name: string): TestContextGroup
	return {
		Name = name,
		Items = {},
		AnyFail = false,
		AfterAllFns = {},
		BeforeEachFns = {},
		AfterEachFns = {},
	}
end

local TestContext = {}
TestContext.__index = TestContext

function TestContext.new(root: string): TestContext
	local testContext = setmetatable({
		TotalTests = 0,
		TotalFails = 0,
		Group = CreateGroup(root),
	}, TestContext) :: any

	testContext.Current = testContext.Group

	return testContext
end

function TestContext:Test(name: string, fn: () -> ())
	for _, fn in self.Current.BeforeEachFns do
		fn()
	end
	local success, err = pcall(fn)
	self.Current.Items[name] = {
		Success = success,
		Err = err,
	}
	self.TotalTests += 1
	if not success then
		self.TotalFails += 1
		self.Current.AnyFail = true
	end
	for _, fn in self.Current.AfterEachFns do
		fn()
	end
end

function TestContext:Describe(name: string, fn: () -> ())
	local parentGroup = self.Current
	local group = CreateGroup(name)
	self.Current = group
	parentGroup.Items[name] = group
	for _, fn in parentGroup.BeforeEachFns do
		fn()
	end
	fn()
	self.Current = parentGroup
	if group.AnyFail then
		parentGroup.AnyFail = true
	end
	for _, fn in group.AfterAllFns do
		fn()
	end
	for _, fn in parentGroup.AfterEachFns do
		fn()
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

function TestContext:BeforeAll(fn: () -> ())
	fn()
end

function TestContext:AfterAll(fn: () -> ())
	table.insert(self.Current.AfterAllFns, fn)
end

function TestContext:BeforeEach(fn: () -> ())
	table.insert(self.Current.BeforeEachFns, fn)
end

function TestContext:AfterEach(fn: () -> ())
	table.insert(self.Current.AfterEachFns, fn)
end

------------------------------------------------------------------------------------------------------------

local Test = {}

function Test.run(ancestors: { Instance })
	local tests: { [string]: () -> () } = {}

	for _, ancestor in ancestors do
		for _, child in ancestor:GetDescendants() do
			if child:IsA("ModuleScript") and string.match(child.Name, "%.test$") ~= nil then
				local name = (string.match(child.Name, "(.+)%.test$")) or child.Name
				if name == "init" then
					name = child.Parent.Name
				end
				local fn = require(child)
				tests[name] = fn
			end
		end
	end

	local results: { TestContext } = {}
	local allPass = true

	local totalTests = 0
	local totalFails = 0
	local totalSuccesses = 0

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
		context.Current = nil
		totalTests += context.TotalTests
		totalFails += context.TotalFails
	end
	totalSuccesses = totalTests - totalFails

	-- Build results:
	local output = { "Test Results" }
	local function out(str: string)
		table.insert(output, str)
	end

	out("---------")
	out(`{totalTests} Total`)
	out(`{totalSuccesses} Pass`)
	out(`{totalFails} Fail{if totalFails == 1 then "" else "s"}`)
	out("---------")

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
							then `\n{string.rep(tab, lvl + 2)}failed assertion: {item.Err}`
							else ""}`
					)
				end
			end
		end
		Output(res.Group, 0)
	end

	local outputTxt = table.concat(output, "\n")

	return {
		AllPass = allPass,
		Output = outputTxt,
	}
end

return Test
