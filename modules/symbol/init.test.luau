local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Symbol = require(script.Parent)

	ctx:Describe("Constructor", function()
		ctx:Test("should create a new symbol", function()
			local symbol = Symbol("Test")
			ctx:Expect(symbol):ToBeA("userdata")
			ctx:Expect(symbol == symbol):ToBe(true)
			ctx:Expect(tostring(symbol)):ToBe("Symbol(Test)")
		end)

		ctx:Test("should create a new symbol with no name", function()
			local symbol = Symbol()
			ctx:Expect(symbol):ToBeA("userdata")
			ctx:Expect(symbol == symbol):ToBe(true)
			ctx:Expect(tostring(symbol)):ToBe("Symbol()")
		end)

		ctx:Test("should be unique regardless of the name", function()
			ctx:Expect(Symbol("Test") == Symbol("Test")):ToBe(false)
			ctx:Expect(Symbol() == Symbol()):ToBe(false)
			ctx:Expect(Symbol("Test") == Symbol()):ToBe(false)
			ctx:Expect(Symbol("Test1") == Symbol("Test2")):ToBe(false)
		end)

		ctx:Test("should be useable as a table key", function()
			local symbol = Symbol()
			local t = {}
			t[symbol] = 100
			ctx:Expect(t[symbol]):ToBe(100)
		end)
	end)
end
