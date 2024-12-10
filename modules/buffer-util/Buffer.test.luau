local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

-- local BufferReader = require(script.Parent.BufferReader)
-- local BufferWriter = require(script.Parent.BufferWriter)

return function(ctx: Test.TestContext)
	ctx:Describe("Some test", function()
		ctx:Test("1 + 1 == 2", function()
			ctx:Expect(1 + 1):ToBe(2)
		end)
		ctx:Test("1 + 1 != 3", function()
			ctx:Expect(1 + 1):Not():ToBe(3)
		end)
		ctx:Describe("Nested group", function()
			ctx:Test("true == true", function()
				ctx:Expect(true):ToBe(true)
				ctx:Expect(function()
					return 32
				end):ToBe(3)
			end)
		end)
	end)
end
