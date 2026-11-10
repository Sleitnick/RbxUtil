local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Log = require(script.Parent)

	local logger = Log.new()

	ctx:Describe("Assert", function()
		ctx:Test("should not throw if the condition is truthy", function()
			ctx:Expect(function()
				logger:Assert(true, "Assertion failed")
			end)
				:Not()
				:ToThrow()
		end)

		ctx:Test("should throw if the condition is falsy", function()
			ctx:Expect(function()
				logger:Assert(false, "Assertion failed")
			end):ToThrow()
		end)
	end)

	ctx:Describe("LogItem Assert", function()
		ctx:Test("should not throw if the condition is truthy", function()
			ctx:Expect(function()
				logger:AtError():Assert(true, "Assertion failed")
			end)
				:Not()
				:ToThrow()
		end)

		ctx:Test("should throw if the condition is falsy", function()
			ctx:Expect(function()
				logger:AtError():Assert(false, "Assertion failed")
			end):ToThrow()
		end)
	end)
end
