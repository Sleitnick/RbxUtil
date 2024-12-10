local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Option = require(script.Parent)

	ctx:Describe("Some", function()
		ctx:Test("should create some option", function()
			local opt = Option.Some(true)
			ctx:Expect(opt:IsSome()):ToBe(true)
		end)

		ctx:Test("should fail to create some option with nil", function()
			ctx:Expect(function()
				Option.Some(nil)
			end):ToThrow()
		end)

		ctx:Test("should not be none", function()
			local opt = Option.Some(10)
			ctx:Expect(opt:IsNone()):ToBe(false)
		end)
	end)

	ctx:Describe("None", function()
		ctx:Test("should be able to reference none", function()
			ctx:Expect(function()
				local _none = Option.None
			end)
				:Not()
				:ToThrow()
		end)

		ctx:Test("should be able to check if none", function()
			local none = Option.None
			ctx:Expect(none:IsNone()):ToBe(true)
		end)

		ctx:Test("should be able to check if not some", function()
			local none = Option.None
			ctx:Expect(none:IsSome()):ToBe(false)
		end)
	end)

	ctx:Describe("Equality", function()
		ctx:Test("should equal the same some from same options", function()
			local opt = Option.Some(32)
			ctx:Expect(opt):ToBe(opt)
		end)

		ctx:Test("should equal the same some from different options", function()
			local opt1 = Option.Some(32)
			local opt2 = Option.Some(32)
			ctx:Expect(opt1):ToBe(opt2)
		end)
	end)

	ctx:Describe("Assert", function()
		ctx:Test("should assert that a some option is an option", function()
			ctx:Expect(Option.Is(Option.Some(10))):ToBe(true)
		end)

		ctx:Test("should assert that a none option is an option", function()
			ctx:Expect(Option.Is(Option.None)):ToBe(true)
		end)

		ctx:Test("should assert that a non-option is not an option", function()
			ctx:Expect(Option.Is(10)):ToBe(false)
			ctx:Expect(Option.Is(true)):ToBe(false)
			ctx:Expect(Option.Is(false)):ToBe(false)
			ctx:Expect(Option.Is("Test")):ToBe(false)
			ctx:Expect(Option.Is({})):ToBe(false)
			ctx:Expect(Option.Is(function() end)):ToBe(false)
			ctx:Expect(Option.Is(coroutine.create(function() end))):ToBe(false)
			ctx:Expect(Option.Is(Option)):ToBe(false)
		end)
	end)

	ctx:Describe("Unwrap", function()
		ctx:Test("should unwrap a some option", function()
			local opt = Option.Some(10)
			ctx:Expect(function()
				opt:Unwrap()
			end)
				:Not()
				:ToThrow()
			ctx:Expect(opt:Unwrap()):ToBe(10)
		end)

		ctx:Test("should fail to unwrap a none option", function()
			local opt = Option.None
			ctx:Expect(function()
				opt:Unwrap()
			end):ToThrow()
		end)
	end)

	ctx:Describe("Expect", function()
		ctx:Test("should expect a some option", function()
			local opt = Option.Some(10)
			ctx:Expect(function()
				opt:Expect("Expecting some value")
			end)
				:Not()
				:ToThrow()
			ctx:Expect(opt:Unwrap()):ToBe(10)
		end)

		ctx:Test("should fail when expecting on a none option", function()
			local opt = Option.None
			ctx:Expect(function()
				opt:Expect("Expecting some value")
			end):ToThrow()
		end)
	end)

	ctx:Describe("ExpectNone", function()
		ctx:Test("should fail to expect a none option", function()
			local opt = Option.Some(10)
			ctx:Expect(function()
				opt:ExpectNone("Expecting some value")
			end):ToThrow()
		end)

		ctx:Test("should expect a none option", function()
			local opt = Option.None
			ctx:Expect(function()
				opt:ExpectNone("Expecting some value")
			end)
				:Not()
				:ToThrow()
		end)
	end)

	ctx:Describe("UnwrapOr", function()
		ctx:Test("should unwrap a some option", function()
			local opt = Option.Some(10)
			ctx:Expect(opt:UnwrapOr(20)):ToBe(10)
		end)

		ctx:Test("should unwrap a none option", function()
			local opt = Option.None
			ctx:Expect(opt:UnwrapOr(20)):ToBe(20)
		end)
	end)

	ctx:Describe("UnwrapOrElse", function()
		ctx:Test("should unwrap a some option", function()
			local opt = Option.Some(10)
			local result = opt:UnwrapOrElse(function()
				return 30
			end)
			ctx:Expect(result):ToBe(10)
		end)

		ctx:Test("should unwrap a none option", function()
			local opt = Option.None
			local result = opt:UnwrapOrElse(function()
				return 30
			end)
			ctx:Expect(result):ToBe(30)
		end)
	end)

	ctx:Describe("And", function()
		ctx:Test("should return the second option with and when both are some", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.Some(2)
			ctx:Expect(opt1:And(opt2)):ToBe(opt2)
		end)

		ctx:Test("should return none when first option is some and second option is none", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.None
			ctx:Expect(opt1:And(opt2):IsNone()):ToBe(true)
		end)

		ctx:Test("should return none when first option is none and second option is some", function()
			local opt1 = Option.None
			local opt2 = Option.Some(2)
			ctx:Expect(opt1:And(opt2):IsNone()):ToBe(true)
		end)

		ctx:Test("should return none when both options are none", function()
			local opt1 = Option.None
			local opt2 = Option.None
			ctx:Expect(opt1:And(opt2):IsNone()):ToBe(true)
		end)
	end)

	ctx:Describe("AndThen", function()
		ctx:Test("should pass the some value to the predicate", function()
			local opt = Option.Some(32)
			opt:AndThen(function(value)
				ctx:Expect(value):ToBe(32)
				return Option.None
			end)
		end)

		ctx:Test("should throw if an option is not returned from predicate", function()
			local opt = Option.Some(32)
			ctx:Expect(function()
				opt:AndThen(function() end)
			end):ToThrow()
		end)

		ctx:Test("should return none if the option is none", function()
			local opt = Option.None
			ctx:Expect(opt:AndThen(function()
				return Option.Some(10)
			end):IsNone()):ToBe(true)
		end)

		ctx:Test("should return option of predicate if option is some", function()
			local opt = Option.Some(32)
			local result = opt:AndThen(function()
				return Option.Some(10)
			end)
			ctx:Expect(result:IsSome()):ToBe(true)
			ctx:Expect(result:Unwrap()):ToBe(10)
		end)
	end)

	ctx:Describe("Or", function()
		ctx:Test("should return the first option if it is some", function()
			local opt1 = Option.Some(10)
			local opt2 = Option.Some(20)
			ctx:Expect(opt1:Or(opt2)):ToBe(opt1)
		end)

		ctx:Test("should return the second option if the first one is none", function()
			local opt1 = Option.None
			local opt2 = Option.Some(20)
			ctx:Expect(opt1:Or(opt2)):ToBe(opt2)
		end)
	end)

	ctx:Describe("OrElse", function()
		ctx:Test("should return the first option if it is some", function()
			local opt1 = Option.Some(10)
			local opt2 = Option.Some(20)
			ctx:Expect(opt1:OrElse(function()
				return opt2
			end)):ToBe(opt1)
		end)

		ctx:Test("should return the second option if the first one is none", function()
			local opt1 = Option.None
			local opt2 = Option.Some(20)
			ctx:Expect(opt1:OrElse(function()
				return opt2
			end)):ToBe(opt2)
		end)

		ctx:Test("should throw if the predicate does not return an option", function()
			local opt1 = Option.None
			ctx:Expect(function()
				opt1:OrElse(function() end)
			end):ToThrow()
		end)
	end)

	ctx:Describe("XOr", function()
		ctx:Test("should return first option if first option is some and second option is none", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.None
			ctx:Expect(opt1:XOr(opt2)):ToBe(opt1)
		end)

		ctx:Test("should return second option if first option is none and second option is some", function()
			local opt1 = Option.None
			local opt2 = Option.Some(2)
			ctx:Expect(opt1:XOr(opt2)):ToBe(opt2)
		end)

		ctx:Test("should return none if first and second option are some", function()
			local opt1 = Option.Some(1)
			local opt2 = Option.Some(2)
			ctx:Expect(opt1:XOr(opt2)):ToBe(Option.None)
		end)

		ctx:Test("should return none if first and second option are none", function()
			local opt1 = Option.None
			local opt2 = Option.None
			ctx:Expect(opt1:XOr(opt2)):ToBe(Option.None)
		end)
	end)

	ctx:Describe("Filter", function()
		ctx:Test("should return none if option is none", function()
			local opt = Option.None
			ctx:Expect(opt:Filter(function() end)):ToBe(Option.None)
		end)

		ctx:Test("should return none if option is some but fails predicate", function()
			local opt = Option.Some(10)
			ctx:Expect(opt:Filter(function(_v)
				return false
			end)):ToBe(Option.None)
		end)

		ctx:Test("should return self if option is some and passes predicate", function()
			local opt = Option.Some(10)
			ctx:Expect(opt:Filter(function(_v)
				return true
			end)):ToBe(opt)
		end)
	end)

	ctx:Describe("Contains", function()
		ctx:Test("should return true if some option contains the given value", function()
			local opt = Option.Some(32)
			ctx:Expect(opt:Contains(32)):ToBe(true)
		end)

		ctx:Test("should return false if some option does not contain the given value", function()
			local opt = Option.Some(32)
			ctx:Expect(opt:Contains(64)):ToBe(false)
		end)

		ctx:Test("should return false if option is none", function()
			local opt = Option.None
			ctx:Expect(opt:Contains(64)):ToBe(false)
		end)
	end)

	ctx:Describe("ToString", function()
		ctx:Test("should return string of none option", function()
			local opt = Option.None
			ctx:Expect(tostring(opt)):ToBe("Option<None>")
		end)

		ctx:Test("should return string of some option with type", function()
			local values = { 10, true, false, "test", {}, function() end, coroutine.create(function() end), workspace }
			for _, value in ipairs(values) do
				local expectedString = ("Option<%s>"):format(typeof(value))
				ctx:Expect(tostring(Option.Some(value))):ToBe(expectedString)
			end
		end)
	end)
end
