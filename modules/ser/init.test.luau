local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Option = require(script.Parent.Parent.Option)
	local Ser = require(script.Parent)

	ctx:Describe("SerializeArgs", function()
		ctx:Test("should serialize an option", function()
			local opt = Option.Some(32)
			local serOpt = table.unpack(Ser.SerializeArgs(opt))
			ctx:Expect(serOpt.ClassName):ToBe("Option")
			ctx:Expect(serOpt.Value):ToBe(32)
		end)
	end)

	ctx:Describe("SerializeArgsAndUnpack", function()
		ctx:Test("should serialize an option", function()
			local opt = Option.Some(32)
			local serOpt = Ser.SerializeArgsAndUnpack(opt)
			ctx:Expect(serOpt.ClassName):ToBe("Option")
			ctx:Expect(serOpt.Value):ToBe(32)
		end)
	end)

	ctx:Describe("DeserializeArgs", function()
		ctx:Test("should deserialize args to option", function()
			local serOpt = {
				ClassName = "Option",
				Value = 32,
			}
			local opt = table.unpack(Ser.DeserializeArgs(serOpt))
			ctx:Expect(Option.Is(opt)):ToBe(true)
			ctx:Expect(opt:Contains(32)):ToBe(true)
		end)
	end)

	ctx:Describe("DeserializeArgsAndUnpack", function()
		ctx:Test("should deserialize args to option", function()
			local serOpt = {
				ClassName = "Option",
				Value = 32,
			}
			local opt = Ser.DeserializeArgsAndUnpack(serOpt)
			ctx:Expect(Option.Is(opt)):ToBe(true)
			ctx:Expect(opt:Contains(32)):ToBe(true)
		end)
	end)
end
