return function()

	local EnumList = require(script.Parent)

	describe("Constructor", function()

		it("should create a new enumlist", function()
			expect(function()
				EnumList.new("Test", {"ABC", "XYZ"})
			end).never.to.throw()
		end)

		it("should fail to create a new enumlist with no name", function()
			expect(function()
				EnumList.new(nil, {"ABC", "XYZ"})
			end).to.throw()
		end)

		it("should fail to create a new enumlist with no enums", function()
			expect(function()
				EnumList.new("Test")
			end).to.throw()
		end)

		it("should fail to create a new enumlist with non string enums", function()
			expect(function()
				EnumList.new("Test", {true, false, 32, "ABC"})
			end).to.throw()
		end)

	end)

	describe("Access", function()

		it("should be able to access enum items", function()
			local test = EnumList.new("Test", {"ABC", "XYZ"})
			expect(function()
				local _item = test.ABC
			end).never.to.throw()
			expect(test:BelongsTo(test.ABC)).to.equal(true)
		end)

		it("should throw if trying to modify the enumlist", function()
			local test = EnumList.new("Test", {"ABC", "XYZ"})
			expect(function()
				test.Hello = 32
			end).to.throw()
			expect(function()
				test.ABC = 32
			end).to.throw()
		end)

		it("should throw if trying to modify an enumitem", function()
			local test = EnumList.new("Test", {"ABC", "XYZ"})
			expect(function()
				local abc = test.ABC
				abc.XYZ = 32
			end).to.throw()
			expect(function()
				local abc = test.ABC
				abc.Name = "NewName"
			end).to.throw()
		end)

		it("should get the name", function()
			local test = EnumList.new("Test", {"ABC", "XYZ"})
			local name = test:GetName()
			expect(name).to.equal("Test")
		end)

	end)

	describe("Get Items", function()

		it("should be able to get all enum items", function()
			local test = EnumList.new("Test", {"ABC", "XYZ"})
			local items = test:GetEnumItems()
			expect(items).to.be.a("table")
			expect(#items).to.equal(2)
			for i,enumItem in ipairs(items) do
				expect(enumItem).to.be.a("table")
				expect(enumItem.Name).to.be.a("string")
				expect(enumItem.Value).to.be.a("number")
				expect(enumItem.Value).to.equal(i)
				expect(enumItem.EnumType).to.equal(test)
			end
		end)
	
	end)

end
