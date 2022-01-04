-- Symbol
-- Stephen Leitnick
-- January 04, 2022


--[=[
	@class Symbol

	Represents a unique object.

	Symbols are often used as unique keys in tables. This is useful to avoid possible collisions
	with a key in a table, since the symbol will always be unique and cannot be reconstructed.

	
	:::note All Unique
	Every creation of a symbol is unique, even if the
	given names are the same.
	:::

	```lua
	local Symbol = require(packages.Symbol)
	
	-- Create a symbol:
	local symbol = Symbol("MySymbol")

	-- The name is optional:
	local anotherSymbol = Symbol()

	-- Comparison:
	print(symbol == symbol) --> true

	-- All symbol constructions are unique, regardless of the name:
	print(Symbol("Hello") == Symbol("Hello")) --> false

	-- Commonly used as unique keys in a table:
	local DATA_KEY = Symbol("Data")
	local t = {
		-- Can only be accessed using the DATA_KEY symbol:
		[DATA_KEY] = {}
	}

	print(t[DATA_KEY]) --> {}
	```
]=]

local function Symbol(name: string?)
	local symbol = newproxy(true)
	if not name then
		name = ""
	end
	getmetatable(symbol).__tostring = function()
		return "Symbol(" .. name .. ")"
	end
	return symbol
end

return Symbol
