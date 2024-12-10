local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local EnumList = require(script.Parent)

	ctx:Describe("Constructor", function()
		ctx:Test("should create a new enumlist", function()
			ctx:Expect(function()
				EnumList.new("Test", { "ABC", "XYZ" })
			end)
				:Not()
				:ToThrow()
		end)

		ctx:Test("should fail to create a new enumlist with no name", function()
			ctx:Expect(function()
				EnumList.new(nil, { "ABC", "XYZ" })
			end):ToThrow()
		end)

		ctx:Test("should fail to create a new enumlist with no enums", function()
			ctx:Expect(function()
				EnumList.new("Test")
			end):ToThrow()
		end)

		ctx:Test("should fail to create a new enumlist with non string enums", function()
			ctx:Expect(function()
				EnumList.new("Test", { true, false, 32, "ABC" })
			end):ToThrow()
		end)
	end)

	ctx:Describe("Access", function()
		ctx:Test("should be able to access enum items", function()
			local test = EnumList.new("Test", { "ABC", "XYZ" })
			ctx:Expect(function()
				local _item = test.ABC
			end)
				:Not()
				:ToThrow()
			ctx:Expect(test:BelongsTo(test.ABC)):ToBe(true)
		end)

		ctx:Test("should throw if trying to modify the enumlist", function()
			local test = EnumList.new("Test", { "ABC", "XYZ" })
			ctx:Expect(function()
				test.Hello = 32
			end):ToThrow()
			ctx:Expect(function()
				test.ABC = 32
			end):ToThrow()
		end)

		ctx:Test("should throw if trying to modify an enumitem", function()
			local test = EnumList.new("Test", { "ABC", "XYZ" })
			ctx:Expect(function()
				local abc = test.ABC
				abc.XYZ = 32
			end):ToThrow()
			ctx:Expect(function()
				local abc = test.ABC
				abc.Name = "NewName"
			end):ToThrow()
		end)

		ctx:Test("should get the name", function()
			local test = EnumList.new("Test", { "ABC", "XYZ" })
			local name = test:GetName()
			ctx:Expect(name):ToBe("Test")
		end)
	end)

	ctx:Describe("Get Items", function()
		ctx:Test("should be able to get all enum items", function()
			local test = EnumList.new("Test", { "ABC", "XYZ" })
			local items = test:GetEnumItems()
			ctx:Expect(items):ToBeA("table")
			ctx:Expect(#items):ToBe(2)
			for i, enumItem in ipairs(items) do
				ctx:Expect(enumItem):ToBeA("table")
				ctx:Expect(enumItem.Name):ToBeA("string")
				ctx:Expect(enumItem.Value):ToBeA("number")
				ctx:Expect(enumItem.Value):ToBe(i)
				ctx:Expect(enumItem.EnumType):ToBe(test)
			end
		end)
	end)
end
