return function()
	local Symbol = require(script.Parent)

	describe("Constructor", function()
		it("should create a new symbol", function()
			local symbol = Symbol("Test")
			expect(symbol).to.be.a("userdata")
			expect(symbol == symbol).to.equal(true)
			expect(tostring(symbol)).to.equal("Symbol(Test)")
		end)

		it("should create a new symbol with no name", function()
			local symbol = Symbol()
			expect(symbol).to.be.a("userdata")
			expect(symbol == symbol).to.equal(true)
			expect(tostring(symbol)).to.equal("Symbol()")
		end)

		it("should be unique regardless of the name", function()
			expect(Symbol("Test") == Symbol("Test")).to.equal(false)
			expect(Symbol() == Symbol()).to.equal(false)
			expect(Symbol("Test") == Symbol()).to.equal(false)
			expect(Symbol("Test1") == Symbol("Test2")).to.equal(false)
		end)

		it("should be useable as a table key", function()
			local symbol = Symbol()
			local t = {}
			t[symbol] = 100
			expect(t[symbol]).to.equal(100)
		end)
	end)
end
